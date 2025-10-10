# Self-hosted VPN in One Script

A complete VPN setup with web management, automatic ad-blocking, and built-in security. Adapted and inspired by [wg-easy](https://github.com/wg-easy/wg-easy).

## Overview

![Visual Diagram](./assets/diagram.jpg)
***High-level architecture overview. (Image Credit: Diagram by ernvk23)***

## What You Get

- Web Management: Add and configure VPN clients through a browser interface
- Automatic HTTPS: SSL certificates via Let's Encrypt (Traefik)
- Network-wide Ad Blocking: AdGuard Home filters ads and trackers for all clients
- Protected Access: Basic Authentication on all web interfaces
- Automated Maintenance: Optional weekly system updates
- Security Features: Optional UDP rate-limiting
- One-command Setup: Interactive installation script handles everything

## Requirements

- Linux server (**RHEL-based**, ***tested on AlmaLinux 9.6***) with public IP
- Domain name pointed to your server
- `curl` and `tar` installed

## Installation

**Quick run:**

```shell
mkdir -p ~/wg-lite-hop && cd ~/wg-lite-hop && curl -L https://github.com/ernvk23/wg-lite-hop/archive/refs/tags/v1.0.tar.gz | tar --strip-components=1 -xz --warning=none && chmod +x ./scripts/setup.sh && sudo ./scripts/setup.sh
```

> [!NOTE]
> **That's it.** The script guides you through setup interactively, asking for your domain, email, and passwords, then handles everything else automatically (Docker installation, firewall configuration, SSL certificates, and service deployment).

## Accessing Your Services

All web interfaces require two-step authentication:

1. **Traefik Basic Auth** (first popup): Use credentials from "Web UI Authentication"
2. **Service Login** (second step):
   - **WireGuard UI** (`https://your_domain`): Use "WireGuard UI Admin" credentials
   - **AdGuard Home** (`https://adguard.your_domain`): Configure during first-time setup wizard
   - **Traefik Dashboard** (`https://traefik.your_domain`): No additional login after Basic Auth

> [!NOTE]
> Wait ~1 minute after installation before accessing the WireGuard UI.

### AdGuard Home Setup

> [!WARNING]
> Set the **Admin Web Interface Port** to **3000** during the setup wizard. Reload if the UI appears unresponsive.

> If you accidentally use port 80, edit `docker-compose.yml` (change `server.port=3000` to `server.port=80` in the `adguard` service) and run `sudo docker compose up -d`.

## Using Your VPN

Download client configuration from the WireGuard web UI. Once connected, all traffic routes through your VPN with DNS filtering via AdGuard Home.

## Maintenance

If enabled during setup, the system automatically updates packages weekly and reboots when needed. Check logs at `~/update.log`.

## Uninstall

> [!CAUTION]
> This permanently removes all components, data, and configurations. It will also offer to back up `.env` and `acme.json`.

```shell
cd ~/wg-lite-hop && chmod +x ./scripts/uninstall.sh && sudo ./scripts/uninstall.sh
```

## Advanced Configuration (Optional)

### Prevent DNS Leaks

Force all DNS queries through AdGuard Home to prevent clients with hardcoded DNS from bypassing filtering.

In the WireGuard UI **Hooks** tab, replace with:

***PostUp***

```shell
iptables -A INPUT -p udp -m udp --dport {{port}} -j ACCEPT; ip6tables -A INPUT -p udp -m udp --dport {{port}} -j ACCEPT; iptables -t nat -A PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination 10.42.42.43; iptables -t nat -A PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination 10.42.42.43; ip6tables -t nat -A PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b; ip6tables -t nat -A PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -s {{ipv4Cidr}} -o {{device}} -j MASQUERADE; ip6tables -t nat -A POSTROUTING -s {{ipv6Cidr}} -o {{device}} -j MASQUERADE;
```

***PostDown***

```shell
iptables -D INPUT -p udp -m udp --dport {{port}} -j ACCEPT || true; ip6tables -D INPUT -p udp -m udp --dport {{port}} -j ACCEPT || true; iptables -t nat -D PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination 10.42.42.43 || true; iptables -t nat -D PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination 10.42.42.43 || true; ip6tables -t nat -D PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b || true; ip6tables -t nat -D PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b || true; iptables -D FORWARD -i wg0 -j ACCEPT || true; iptables -D FORWARD -o wg0 -j ACCEPT || true; ip6tables -D FORWARD -i wg0 -j ACCEPT || true; ip6tables -D FORWARD -o wg0 -j ACCEPT || true; iptables -t nat -D POSTROUTING -s {{ipv4Cidr}} -o {{device}} -j MASQUERADE || true; ip6tables -t nat -D POSTROUTING -s {{ipv6Cidr}} -o {{device}} -j MASQUERADE || true;
```

**Save** and restart: `sudo docker restart wg-easy`

### Rate-Limit UDP Port

Prevent abuse by limiting UDP traffic on the WireGuard port. Extends the DNS leak prevention setup.

> Default rate limits **per IP**: 30,000 req/sec, burst of 60,000 (modify as needed)

***PostUp***

```shell
iptables -N WG_RATELIMIT_V4; iptables -F WG_RATELIMIT_V4; iptables -A WG_RATELIMIT_V4 -m hashlimit --hashlimit-name wg-ratelimit-v4 --hashlimit-mode srcip --hashlimit-upto 30000/second --hashlimit-burst 60000 -j ACCEPT; iptables -A WG_RATELIMIT_V4 -j DROP; ip6tables -N WG_RATELIMIT_V6; ip6tables -F WG_RATELIMIT_V6; ip6tables -A WG_RATELIMIT_V6 -m hashlimit --hashlimit-name wg-ratelimit-v6 --hashlimit-mode srcip --hashlimit-upto 30000/second --hashlimit-burst 60000 -j ACCEPT; ip6tables -A WG_RATELIMIT_V6 -j DROP; iptables -A INPUT -p udp -m udp --dport {{port}} -j WG_RATELIMIT_V4; ip6tables -A INPUT -p udp -m udp --dport {{port}} -j WG_RATELIMIT_V6; iptables -t nat -A PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination 10.42.42.43; iptables -t nat -A PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination 10.42.42.43; ip6tables -t nat -A PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b; ip6tables -t nat -A PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -s {{ipv4Cidr}} -o {{device}} -j MASQUERADE; ip6tables -t nat -A POSTROUTING -s {{ipv6Cidr}} -o {{device}} -j MASQUERADE;
```

***PostDown***

```shell
iptables -D INPUT -p udp -m udp --dport {{port}} -j WG_RATELIMIT_V4 || true; iptables -F WG_RATELIMIT_V4 || true; iptables -X WG_RATELIMIT_V4 || true; ip6tables -D INPUT -p udp -m udp --dport {{port}} -j WG_RATELIMIT_V6 || true; ip6tables -F WG_RATELIMIT_V6 || true; ip6tables -X WG_RATELIMIT_V6 || true; iptables -t nat -D PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination 10.42.42.43 || true; iptables -t nat -D PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination 10.42.42.43 || true; ip6tables -t nat -D PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b || true; ip6tables -t nat -D PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b || true; iptables -D FORWARD -i wg0 -j ACCEPT || true; iptables -D FORWARD -o wg0 -j ACCEPT || true; ip6tables -D FORWARD -i wg0 -j ACCEPT || true; ip6tables -D FORWARD -o wg0 -j ACCEPT || true; iptables -t nat -D POSTROUTING -s {{ipv4Cidr}} -o {{device}} -j MASQUERADE || true; ip6tables -t nat -D POSTROUTING -s {{ipv6Cidr}} -o {{device}} -j MASQUERADE || true;
```

**Save** and restart: `sudo docker restart wg-easy`

### AdGuard Home Configuration

Customize filtering and DNS settings via the web UI. The included [`AdGuardHome.yaml`](./assets/AdGuardHome.yaml) contains advanced configuration examples for reference.

## License

Released under the [GNU Affero General Public License v3](LICENSE)
