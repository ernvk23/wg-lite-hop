# Self-Hosted WireGuard VPN with Traefik and AdGuard Home

A self-hosted WireGuard VPN with a web UI, ad-blocking, and automatic HTTPS via Traefik. Adapted and inspired by [wg-easy](https://github.com/wg-easy/wg-easy).

## Overview

![Visual Diagram](./assets/diagram.jpg)
_A high-level overview of the project architecture. (Image Credit: Diagram by ernvk23)_

## Features

- **Simple Management**: Web UI for adding, removing, and managing VPN clients.
- **Automatic HTTPS**: Traefik provides SSL certificates from Let's Encrypt.
- **Ad Blocking**: AdGuard Home filters ads and trackers for all connected clients.
- **Secure Access**: Web UIs are protected by Basic Authentication.
- **Automated Maintenance**: Optional weekly system updates.
- **Simple Setup**: Get running with a single setup script.

## Prerequisites

- A Linux server (**RHEL-based**, **_tested on AlmaLinux 9.6_**) with a public IP.
- A domain name pointing to your server's IP.
- `curl` and `tar` installed.

## Setup

1. **Quick Install & Setup (AlmaLinux/RHEL):**

    ```shell
    mkdir -p ~/wg-lite-hop && cd ~/wg-lite-hop && curl -L https://github.com/ernvk23/wg-lite-hop/archive/refs/heads/main.tar.gz | tar --strip-components=1 -xz && chmod +x ./scripts/setup.sh && sudo ./scripts/setup.sh
    ```

> [!NOTE]
> This script installs Docker and `firewalld`, configures firewall rules, optimizes system settings, and prepares necessary configuration files.

2. **Modify the `.env` file:**

    Edit the `.env` file to set your actual domain, email, and a strong password hash.

3. **Start the services:**

    ```shell
    sudo docker compose up -d
    ```

4. **Set up automated maintenance (optional but recommended):**

    ```shell
    chmod +x ./scripts/add_update_cron.sh && ./scripts/add_update_cron.sh
    ```

> [!NOTE]
> This sets up weekly system updates and automatic reboots when required.

## Access

**Access to the web UIs is protected by a two-step process:**

- **Traefik Basic Auth**: For `https://traefik.your_domain` (Traefik Dashboard) and the initial popup for all UIs, use the `AUTH_USER` and `AUTH_PASS_HASH` variables from your `.env` file.
- **WireGuard UI**: For `https://your_domain` (Manage VPN clients), use the `WG_ADMIN_USER` and `WG_ADMIN_PASSWORD` variables from your `.env` file.
- **AdGuard Home UI**: For `https://adguard.your_domain` (Configure ad-blocking), access is configured via the AdGuard Home setup wizard.

> [!WARNING]
> During AdGuard Home setup, set the **Admin Web Interface Port** to **3000**. Reload the page if the UI appears unresponsive.

> If you accidentally use port 80, manually edit `docker-compose.yml` (change `server.port=3000` to `server.port=80` for `adguard` service) and restart with `sudo docker compose up -d`.

## Usage

Connect to the WireGuard VPN using a client (refer to the WireGuard web UI for configuration). Once connected, your internet traffic will be routed through the VPN, and DNS queries will be filtered by AdGuard Home.

## Maintenance

The automated maintenance system (if enabled) runs weekly, updates system packages, and reboots if necessary. Logs are in `~/update.log`.

## Uninstall

The uninstall script removes the entire stack and its data from your server.

> [!CAUTION]
> This script permanently removes all components, data, firewall rules, and maintenance setups. It will ask for confirmation and offers to back up `.env` and `acme.json`.

To run the uninstaller, execute the following command from the project directory:

```shell
chmod +x ./scripts/uninstall.sh && sudo ./scripts/uninstall.sh
```

## Optional

### Force DNS Resolution to Prevent Leaks

To prevent DNS leaks from devices with fixed IPs (which can bypass the VPN's DNS and ad-blocking), force all DNS queries through AdGuard.

1. In the WireGuard Web UI, go to the **Hooks** tab and replace the content with:

    **_PostUp_**

    ```shell
    iptables -A INPUT -p udp -m udp --dport {{port}} -j ACCEPT; ip6tables -A INPUT -p udp -m udp --dport {{port}} -j ACCEPT; iptables -t nat -A PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination 10.42.42.43; iptables -t nat -A PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination 10.42.42.43; ip6tables -t nat -A PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b; ip6tables -t nat -A PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -s {{ipv4Cidr}} -o {{device}} -j MASQUERADE; ip6tables -t nat -A POSTROUTING -s {{ipv6Cidr}} -o {{device}} -j MASQUERADE;
    ```

    **_PostDown_**

    ```shell
    iptables -D INPUT -p udp -m udp --dport {{port}} -j ACCEPT || true; ip6tables -D INPUT -p udp -m udp --dport {{port}} -j ACCEPT || true; iptables -t nat -D PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination 10.42.42.43 || true; iptables -t nat -D PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination 10.42.42.43 || true; ip6tables -t nat -D PREROUTING -i wg0 -p udp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b || true; ip6tables -t nat -D PREROUTING -i wg0 -p tcp --dport 53 -j DNAT --to-destination fdcc:ad94:bacf:61a3::2b || true; iptables -D FORWARD -i wg0 -j ACCEPT || true; iptables -D FORWARD -o wg0 -j ACCEPT || true; ip6tables -D FORWARD -i wg0 -j ACCEPT || true; ip6tables -D FORWARD -o wg0 -j ACCEPT || true; iptables -t nat -D POSTROUTING -s {{ipv4Cidr}} -o {{device}} -j MASQUERADE || true; ip6tables -t nat -D POSTROUTING -s {{ipv6Cidr}} -o {{device}} -j MASQUERADE || true;
    ```

2. **Save** and then restart the container with `sudo docker restart wg-easy`:

### AdGuard Home Configuration Notes

AdGuard Home is managed via its web UI. While it has basic filters, these are customizable. The provided [`AdGuardHome.yaml`](./assets/AdGuardHome.yaml) offers advanced DNS settings and filters for reference, but cannot replace the active configuration.

## Licensing

This project is released under the [GNU Affero General Public License v3](LICENSE)
