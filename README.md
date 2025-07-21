# Easy WireGuard VPN with Traefik and AdGuard Home

This project, inspired by and adapted from [wg-easy](https://github.com/wg-easy/wg-easy), sets up a WireGuard VPN server with a web UI for easy configuration, protected by Traefik as a reverse proxy with automatic Let's Encrypt SSL/TLS certificates. It also includes AdGuard Home for network-wide ad/tracker blocking.

## Prerequisites

*   A Linux server with a public IP address and a RHEL-compatible distribution installed.
    *   **Tested on: AlmaLinux 9.6**
*   A domain name pointing to your server's IP address.
*   `curl` and `tar` installed.

## Setup

1. **Quick Install & Setup (AlmaLinux/RHEL):**

    ```bash
    curl -L https://github.com/ernvk23/wg-lite-hop/archive/refs/heads/main.tar.gz | tar xz && cd wg-lite-hop-main && chmod +x setup.sh && sudo ./setup.sh
    ```

2.  **Modify the `.env` file:**

    Edit the `.env` file to set your actual domain, email, and a strong password hash (as instructed by the setup script).

3.  **Start the services:**

    ```bash
    sudo docker compose up -d
    ```

## Access

*   WireGuard Web UI (to set up clients): `https://your_domain`
*   AdGuard Home UI (configure ad/trackers block lists): `https://adguard.your_domain`
*   Traefik Dashboard UI (check server's metrics, *optional*): `https://traefik.your_domain`


Use the credentials defined in your `.env` file to access the web UIs. 
*Note:* The first password requested is for logging into Traefik. This may appear as a pop-up window on an otherwise empty screen.

## Usage

1.  Connect to the WireGuard VPN using a client (see the WireGuard web UI for configuration).
2.  Your internet traffic will now be routed through the VPN, and DNS queries will be filtered by AdGuard Home.

## Uninstall

To completely remove the `wg-lite-hop` stack and all its data from your server, you can use the provided uninstall script.

> **Warning: This is a destructive operation.** The script is designed to be thorough and will permanently remove:
> *   All Docker containers, images and networks for this project.
> *   All associated Docker volumes, which includes all **WireGuard client data** and **AdGuard Home settings**.
> *   The project directory itself with all its subdirectories and files (`wg-lite-hop-main`).
> *   The script also reloads the firewall.

>
> The script will prompt for confirmation before proceeding and offers an option to back up `acme.json` and `.env` to `~/` before deletion.
>
> To run the uninstaller, execute the following command from within the project directory. The script will ask for final confirmation before deleting anything.
```bash
chmod +x uninstall.sh && sudo ./uninstall.sh
```

## TL;DR

This section provides a high-level overview of the project architecture.

![Visual Diagram](./diagram.jpg)
Image Credit: Diagram by ernvk23


## Licensing

This project is released under the [GNU Affero General Public License v3](LICENSE)
