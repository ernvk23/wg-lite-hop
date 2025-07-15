# Easy WireGuard VPN with Traefik and AdGuard Home

This project, inspired by and adapted from [wg-easy](https://github.com/wg-easy/wg-easy), sets up a WireGuard VPN server with a web UI for easy configuration, protected by Traefik as a reverse proxy with automatic Let's Encrypt SSL/TLS certificates. It also includes AdGuard Home for network-wide ad and tracker blocking.



## Prerequisites

*   A Linux server with a public IP address and a RHEL-compatible distribution installed.
    *   **Tested on: AlmaLinux 9.6**
*   A domain name pointing to your server's IP address.
*   `curl` and `tar` must be installed to download the repository.

## Setup

1. **Quick Install & Setup (AlmaLinux/RHEL):**

   ```bash
   sudo yum install -y curl tar && \
   curl -L https://github.com/ernvk23/wg-lite-hop/archive/refs/heads/main.tar.gz | tar xz && \
   cd wg-lite-hop-main && \
   sudo ./setup.sh
   ```

2.  **Modify the `.env` file:**

    Edit the `.env` file to set your actual domain, email, and a strong password hash (as instructed by the setup script).

3.  **Start the services:**

    ```bash
    sudo docker compose up -d
    ```

## Access

*   WireGuard Web UI: `https://your_domain.com`
*   Traefik Dashboard: `https://your_domain.com/dashboard`
*   AdGuard Home: `https://your_domain.com/adguard`

Use the credentials defined in your `.env` file to access the web UIs.

## Usage

1.  Connect to the WireGuard VPN using a client (see the WireGuard web UI for configuration).
2.  Your internet traffic will now be routed through the VPN, and DNS queries will be filtered by AdGuard Home.


## Licensing

This project is released under the [GNU Affero General Public License v3](LICENSE)
