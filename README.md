# Easy WireGuard VPN with Traefik and AdGuard Home

A self-hosted WireGuard VPN with a web-based management UI, ad-blocking, and automatic HTTPS via Traefik. This project is inspired by and adapted from [wg-easy](https://github.com/wg-easy/wg-easy).

## Overview

![Visual Diagram](./diagram.jpg)
*A high-level overview of the project architecture. (Image Credit: Diagram by ernvk23)*

## Features

*   **Easy WireGuard Management**: Simple web UI to add, remove, and manage VPN clients.
*   **Automatic HTTPS**: Traefik handles SSL/TLS certificates from Let's Encrypt automatically.
*   **Network-wide Ad Blocking**: Integrated AdGuard Home filters out ads and trackers for all VPN clients.
*   **Secure Access**: Web UIs are protected by Basic Authentication.
*   **Simple Setup**: Get up and running with a single setup script and `docker compose`.


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
*Note:* When accessing the web UIs, your browser will first show a pop-up asking for a username and password. This is the basic authentication layer provided by Traefik. Use the `AUTH_USER` from your `.env` file and the password you used to generate the `AUTH_PASS_HASH` value.

## Usage

1.  Connect to the WireGuard VPN using a client (see the WireGuard web UI for configuration).
2.  Your internet traffic will now be routed through the VPN, and DNS queries will be filtered by AdGuard Home.

## Uninstall

To completely remove the `wg-lite-hop` stack and all its data from your server, you can use the provided uninstall script.

> **Warning: This is a destructive operation.** This script is designed to be thorough and will permanently remove:
> *   All Docker containers, images, and networks associated with this project.
> *   All associated Docker volumes, which includes your **WireGuard client configurations** and **AdGuard Home settings**.
> *   The firewall rules that were added during setup (`80/tcp`, `443/tcp`, `443/udp`, `51820/udp`).
> *   The project directory itself (`wg-lite-hop-main`), including all configuration files.
> 
> Before proceeding, the script will ask for confirmation. It also offers a convenient option to back up your `.env` and `traefik/acme.json` files to your user's home directory (`~/.env.bak` and `~/acme.json.bak`).
> 
> To run the uninstaller, execute the following command from within the project directory. The script will ask for final confirmation before deleting anything.
```bash
chmod +x uninstall.sh && sudo ./uninstall.sh
```

## Licensing

This project is released under the [GNU Affero General Public License v3](LICENSE)
