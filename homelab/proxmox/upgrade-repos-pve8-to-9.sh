#!/usr/bin/env bash
set -euo pipefail

# Taken from https://www.virtualizationhowto.com/2025/08/how-to-upgrade-from-proxmox-ve-8-to-9-fast-and-hassle-free/
# Also a useful document (linked above): https://pve.proxmox.com/wiki/Upgrade_from_8_to_9

# Upgrade APT repos from Proxmox VE 8 (Bookworm) to Proxmox VE 9 (Trixie)
# - Backs up APT lists
# - Comments out Bookworm entries
# - Writes Trixie + Proxmox 9 + Ceph Squid repos in Deb822 format
# Usage:
#   sudo bash upgrade-repos-pve8-to-9.sh [--enterprise] [--dry-run]

ENTERPRISE=0
DRYRUN=0
for arg in "$@"; do
  case "$arg" in
    --enterprise) ENTERPRISE=1 ;;
    --dry-run)    DRYRUN=1 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="/root/apt-repo-backup-$timestamp"
mkdir -p "$backup_dir"

say() { echo -e "\e[1;32m[INFO]\e[0m $*"; }
warn() { echo -e "\e[1;33m[WARN]\e[0m $*"; }
act() {
  if [[ $DRYRUN -eq 1 ]]; then
    echo -e "\e[1;34m[DRYRUN]\e[0m $*"
  else
    eval "$@"
  fi
}

say "Backing up APT repo files to: $backup_dir"
act "cp -a /etc/apt/sources.list $backup_dir/ 2>/dev/null || true"
act "cp -a /etc/apt/sources.list.d $backup_dir/ 2>/dev/null || true"

# Comment out *bookworm* lines in the classic .list files
say "Commenting out Bookworm entries in sources.list and sources.list.d/*.list"
list_files=()
while IFS= read -r -d '' f; do list_files+=("$f"); done < <(find /etc/apt -maxdepth 2 -type f \( -name '*.list' -o -name 'sources.list' \) -print0)

for f in "${list_files[@]}"; do
  if grep -qE 'bookworm' "$f"; then
    say " - Updating: $f"
    act "sed -ri 's/^(\\s*deb(\\-src)?\\s+[^#]*bookworm[^$]*)$/# \\1/g' '$f'"
  fi
done

# Optionally remove old deb822 sources that explicitly mention bookworm
deb822_files=()
while IFS= read -r -d '' f; do deb822_files+=("$f"); done < <(find /etc/apt/sources.list.d -type f -name '*.sources' -print0 2>/dev/null || true)

for f in "${deb822_files[@]}"; do
  if grep -qi 'bookworm' "$f"; then
    say " - Disabling Deb822 file referencing Bookworm: $f"
    act "mv '$f' '$f.disabled-$timestamp'"
  fi
done

# Make sure keyrings exist (on Proxmox they should)
[[ -f /usr/share/keyrings/proxmox-archive-keyring.gpg ]] || warn "proxmox-archive-keyring.gpg not found (expected on Proxmox)."
[[ -f /usr/share/keyrings/debian-archive-keyring.gpg  ]] || warn "debian-archive-keyring.gpg not found (expected on Debian/Proxmox)."

# Write clean Deb822 Debian sources for Trixie
say "Writing Debian 13 (Trixie) Deb822 sources"
debian_sources="/etc/apt/sources.list.d/debian.sources"
act "cat > '$debian_sources' <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF"

# Proxmox VE 9 repo (Deb822)
say "Writing Proxmox VE 9 Deb822 source"
pve_sources="/etc/apt/sources.list.d/pve.sources"
if [[ $ENTERPRISE -eq 1 ]]; then
  act "cat > '$pve_sources' <<'EOF'
Types: deb
URIs: https://enterprise.proxmox.com/debian/pve
Suites: trixie
Components: pve-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF"
else
  act "cat > '$pve_sources' <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF"
fi

# Ceph Squid repo for Trixie
say "Writing Ceph Squid Deb822 source"
ceph_sources="/etc/apt/sources.list.d/ceph.sources"
if [[ $ENTERPRISE -eq 1 ]]; then
  act "cat > '$ceph_sources' <<'EOF'
Types: deb
URIs: https://enterprise.proxmox.com/debian/ceph-squid
Suites: trixie
Components: enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF"
else
  act "cat > '$ceph_sources' <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF"
fi

# Clean any leftover bookworm references in ceph.list (if it exists)
if [[ -f /etc/apt/sources.list.d/ceph.list ]]; then
  say "Commenting out legacy Bookworm ceph.list entries"
  act "sed -ri 's/^(\\s*deb(\\-src)?\\s+[^#]*bookworm[^$]*)$/# \\1/g' /etc/apt/sources.list.d/ceph.list"
fi

say "Final sanity check: show new Deb822 sources"
act "grep -Hn 'Suites:' /etc/apt/sources.list.d/*.sources || true"

say "Updating package lists (apt update)"
if [[ $DRYRUN -eq 1 ]]; then
  echo "[DRYRUN] Skipping apt update"
else
  apt update
  say "Done. Backup of your old repo files: $backup_dir"
  say "Next steps: run 'pve8to9 --full' and then 'apt dist-upgrade'"
fi