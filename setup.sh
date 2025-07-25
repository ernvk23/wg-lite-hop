#!/bin/bash

# Exit immediately if a command exits with a non-zero status or if a command in a pipeline fails.
set -e
set -o pipefail

echo "Setting up WireGuard with Traefik..."

if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo privileges"
    exit 1
fi
# Check if dnf is present, indicating an RHEL-based system
if command -v dnf &> /dev/null; then
    echo "Detected RHEL-based system. Proceeding..."
else
    echo "Unsupported distribution. This script requires a RHEL-based system (AlmaLinux, CentOS, Fedora)."
    exit 1
fi

# Install Docker if not present and start it
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing and starting..."
    sudo dnf -y install dnf-plugins-core
    sudo dnf -y config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    echo "Docker installed and started."
fi

# Check if firewalld is present, install and enable if not
if ! command -v firewall-cmd &> /dev/null; then
  echo "firewalld not found. Installing and enabling..."
  sudo dnf install -y firewalld
  sudo systemctl start firewalld
  sudo systemctl enable firewalld
  echo "firewalld installed and enabled."
fi

# Configure firewall ports
echo "Configuring firewall ports..."
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=443/udp
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --reload
echo "Firewall configured. Ports 80, 443, 443/udp, and 51820/udp are now open."

# Create .env file from template if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat << EOF > .env
DOMAIN=your-domain (e.g. example.com)
TRAEFIK_ACME_EMAIL=your-email (e.g. example@hotmail.com)

# Web UI Authentication
AUTH_USER=your_username

# Generate a new password hash with: docker run --rm httpd:2.4-alpine htpasswd -nbB user password | sed 's/\$/\$\$/g'

AUTH_PASS_HASH=your_generated_hash

# Password in here is used for creating the fist user,
# though after install is advisable to remove it
WG_ADMIN_USER=your_username 
# This password should not be a hashed password
# can generat with openssl rand -base64 16
WG_ADMIN_PASS=your_password_not_hashed

EOF
fi

# Create traefik directory and acme.json for Let's Encrypt certificates
echo "Creating Traefik acme.json file..."
if [ -f ./traefik/acme.json ]; then
  echo "Backing up existing acme.json to ~/acme.json.bak ..."
  cp ./traefik/acme.json ~/acme.json.bak
  echo "Backup created."
else
  echo "No existing acme.json found, nothing to back up."
fi
mkdir -p ./traefik
touch ./traefik/acme.json
chmod 600 ./traefik/acme.json
echo "acme.json created with secure permissions."


echo "Creating Adguard volume dirs..."
mkdir -p ./adguard/adguard_work ./adguard/adguard_conf
chmod -R 700 ./adguard/adguard_work ./adguard/adguard_conf
echo "Adguard volume dirs created with secure permissions."


# Create instructions file
cat << EOF > instructions.txt
Pending Tasks:
1. Edit the .env file with your actual domain, email, and a new password hash.
2. Start the services: sudo docker compose up -d

Troubleshooting:
If the services fail to start or do not work as expected, consider the following:
The specific Docker image versions used during testing (v0.9) were:
- adguard/adguardhome:latest
- ghcr.io/wg-easy/wg-easy:15
- traefik:3.3

To resolve potential compatibility issues, you may need to update the image tags in your \`docker-compose.yml\` file. For example:

For Traefik:
services -> traefik -> image (replace the whole line with the one below, ensuring correct indentation)
image: traefik@sha256:2cd5cc75530c8d07ae0587c743d23eb30cae2436d07017a5ff78498b1a43d09f

For AdGuard:
services -> adguard -> image (replace the whole line with the one below, ensuring correct indentation)
image: adguard/adguardhome@sha256:320ab49bd5f55091c7da7d1232ed3875f687769d6bb5e55eb891471528e2e18f

For wg-easy:
services -> wg-easy -> image (replace the whole line with the one below, ensuring correct indentation)
image: ghcr.io/wg-easy/wg-easy@sha256:bb8152762c36f824eb42bb2f3c5ab8ad952818fbef677d584bc69ec513b251b0

After making these changes, run: sudo docker compose up -d
EOF

echo -e "\nInstructions file created. Contents:"
cat instructions.txt
