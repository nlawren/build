# Caddy and Tailscale - remote access for a Homelab

## Background

This setup and configuration is based on the YouTube [video](https://youtu.be/Vt4PDUXB_fg?si=VmRGVFMaYVJdvUy8) by Tailscale/Alex.

The idea as I'm implementing it is simply client nodes (laptops, desktop, phones etc) use Tailscale to access parts of the homelab but only via Tailscale. This then also gives the benefit of getting signed valid https certificates and no more reliance on remembering port numbers for the various services (Bookshelf, LibreNMS, Proxmox, Jellyfin etc). It also means that the access can be from anywhere (using Tailscale) not just from the local lan.

### Configure a LXC Debian container

* Install additional packages on base minimal image: `apt install curl sudo`
* Tailscale install [instructions](https://tailscale.com/kb/1174/install-debian-bookworm)
* Set no expiry on the tailscale key
* add a caddy user and group then configure systemd.

### Cloudflare

* Use a CNAME in Cloudflare DNS with a `*.homelab` wildcare to point to the Caddy Debian install hostname. Refer to this point in the [YouTube](https://www.youtube.com/watch?v=Vt4PDUXB_fg&t=393s).
* Tim goes into detail what is required from a Cloudflare token perspective. Reference here - Technotim's YouTube [video](https://www.youtube.com/watch?v=n1vOfdz5Nm8) and his Traefik3 [article](https://techno-tim.github.io/posts/traefik-3-docker-certificates/). Note, this is different as it is using this for internal name resolution and not via Tailscale but the Cloudflare steps for the token are the same.
