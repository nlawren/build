# Caddy and Tailscale - remote access for a Homelab

## Background

### Configure a LXC Debian container

* Tailscale install [instructions](https://tailscale.com/kb/1174/install-debian-bookworm)
* Install additional packages on base minimal image: `apt install curl sudo`
* Set no expiry on the tailscale key
