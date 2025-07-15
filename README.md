# Easy WireGuard VPN with Traefik and AdGuard Home

This project, inspired by and adapted from [wg-easy](https://github.com/wg-easy/wg-easy), sets up a WireGuard VPN server with a web UI for easy configuration, protected by Traefik as a reverse proxy with automatic Let's Encrypt SSL/TLS certificates. It also includes AdGuard Home for network-wide ad and tracker blocking.



## Prerequisites

*   A VPS (Virtual Private Server) with a public IP address and AlmaLinux installed.
*   Docker and Docker Compose installed on the VPS.
*   A domain name pointing to your VPS's IP address.

## Setup

1.  **Clone the repository:**

    ```bash
    git clone <repository_url>
    cd easy-wg-based
    ```
2.  **Run the setup script:**

    ```bash
    sudo ./setup.sh
    ```
    This script will create necessary files, prompt for configuration, and open firewall ports.

3.  **Start the services:**

    ```bash
    docker-compose up -d
    ```

## Access

*   WireGuard Web UI: `https://your_domain.com/`
*   Traefik Dashboard: `https://your_domain.com/dashboard/`
*   AdGuard Home: `https://your_domain.com/adguard/`

Use the credentials defined in your `.env` file to access the web UIs.

## Usage

1.  Connect to the WireGuard VPN using a client (see the WireGuard web UI for configuration).
2.  Your internet traffic will now be routed through the VPN, and DNS queries will be filtered by AdGuard Home.