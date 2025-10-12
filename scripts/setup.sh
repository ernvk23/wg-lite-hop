#!/bin/bash

# Exit immediately if a command exits with a non-zero status or if a command in a pipeline fails.
set -e
set -o pipefail

# Get the original user's home directory and the project directory name
USER_HOME=$(eval echo "~$SUDO_USER")
PROJECT_DIR_NAME=$(basename "$PWD")
CALLER=${SUDO_USER:-$(whoami)}

# Trap Ctrl+C for graceful exit
trap 'echo -e "\nSetup cancelled by user."; exit 1' INT
trap 'if [ $? -ne 0 ]; then echo -e "\nSetup failed. Please re-run the script with:\ncd \"$USER_HOME/$PROJECT_DIR_NAME\" && sudo ./scripts/setup.sh"; fi' EXIT

# Check sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo privileges"
    exit 1
fi

# Check distribution
if ! command -v dnf &>/dev/null; then
    echo "Unsupported distribution. This script requires a RHEL-based system (AlmaLinux, CentOS, Fedora)."
    exit 1
fi

clear
echo "=== Interactive Setup ==="
echo "It is recommended to let the setup complete. Press Ctrl+C to cancel, but be aware some changes might have been applied."
echo
# --- Validation Functions ---
validate_domain() {
    local domain="$1"
    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_password() {
    local password="$1"

    # All checks are combined into one logical line using '&&'
    if [ ${#password} -ge 8 ] && [[ "$password" =~ [A-Z] ]] && [[ "$password" =~ [a-z] ]] && [[ "$password" =~ [0-9] ]]; then
        return 0 # Success
    else
        echo "Password doesn't meet policy. Please try again." >&2
        return 1 # Failure
    fi
}

# --- Prompt Functions ---
prompt_domain() {
    while true; do
        read -r -p "Enter domain (e.g., example.com): " DOMAIN
        if validate_domain "$DOMAIN"; then
            break
        else
            echo "Invalid domain format. Please enter a valid domain."
        fi
    done
}

prompt_email() {
    while true; do
        read -r -p "Enter email for Let's Encrypt certificates: " TRAEFIK_ACME_EMAIL
        if validate_email "$TRAEFIK_ACME_EMAIL"; then
            break
        else
            echo "Invalid email format. Please enter a valid email."
        fi
    done
}

prompt_auth_username() {
    while true; do
        read -r -p "Enter username for Web UI authentication: " AUTH_USER
        if [ -n "$AUTH_USER" ]; then
            break
        else
            echo "Username cannot be empty."
        fi
    done
}

prompt_wg_admin_username() {
    while true; do
        read -r -p "Enter username for WireGuard UI admin: " WG_ADMIN_USER
        if [ -n "$WG_ADMIN_USER" ]; then
            break
        else
            echo "Username cannot be empty."
        fi
    done
}

prompt_password() {
    local password1 password2
    echo "Password policy: 8+ characters, one uppercase, one lowercase, one number." >&2
    while true; do
        read -r -s -p "Password: " password1
        echo >&2
        read -r -s -p "Confirm password: " password2
        echo >&2

        if [ "$password1" != "$password2" ]; then
            echo "Passwords do not match. Please try again." >&2
            continue
        fi

        if [ -z "$password1" ]; then
            echo "Password cannot be empty." >&2
            continue
        fi

        if validate_password "$password1"; then
            echo "$password1"
            return 0
        fi
    done
}

prompt_auth_password() {
    echo "Set authentication password for Web UIs:"
    AUTH_PASS=$(prompt_password)
}

prompt_wg_admin_password() {
    echo "Set WireGuard UI admin password:"
    WG_ADMIN_PASS=$(prompt_password)
}

# Function to handle configuration editing
handle_config_edit() {
    local choice="$1"
    case $choice in
    1)
        prompt_domain
        ;;
    2)
        prompt_email
        ;;
    3)
        prompt_auth_username
        ;;
    4)
        prompt_wg_admin_username
        ;;
    5)
        prompt_auth_password
        ;;
    6)
        prompt_wg_admin_password
        ;;
    *)
        echo "Invalid choice."
        ;;
    esac
}

# Function to show configuration summary
show_config_summary() {
    echo
    echo "=== Configuration Summary ==="
    echo "Domain: $DOMAIN"
    echo "Email: $TRAEFIK_ACME_EMAIL"
    echo "Web UI Authentication Username: $AUTH_USER"
    echo "WireGuard UI Admin Username: $WG_ADMIN_USER"
    echo "Passwords: [hidden for security]"
    echo "============================="

    while true; do
        read -r -p "Does everything look correct? [y] proceed, [e] edit, [n] exit: " response
        case $response in
        [yY]*) return 0 ;;
        [nN]*)
            echo -e "\nSetup cancelled by user."
            exit 1
            ;;
        [eE]*)
            echo
            echo "Which setting would you like to edit?"
            echo "1) Domain"
            echo "2) Email"
            echo "3) Web UI Authentication Username"
            echo "4) WireGuard UI Admin Username"
            echo "5) Web UI Authentication Password"
            echo "6) WireGuard UI Admin Password"
            read -r -p "Enter choice (1-6): " choice
            handle_config_edit "$choice"
            show_config_summary
            return $?
            ;;
        *) echo "Please answer y (yes), n (no), or e (edit)." ;;
        esac
    done
}

# Function to generate htpasswd hash
generate_htpasswd_hash() {
    local username="$1"
    local password="$2"
    sudo docker run --rm httpd:2.4-alpine htpasswd -nbB "$username" "$password" | cut -d: -f2 | sed 's/\$/\$\$/g'
}

echo "--- Collecting Configuration ---"
# Main configuration collection
prompt_domain
prompt_email
prompt_auth_username
prompt_auth_password
prompt_wg_admin_username
prompt_wg_admin_password

# Show summary and get confirmation
while ! show_config_summary; do
    echo "Please re-enter the configuration."
done

echo
echo "Configuration complete! Starting system setup..."
echo

echo "--- System Setup ---"

# Install Docker if not present and start it
echo "Checking Docker installation..."
if ! command -v docker &>/dev/null; then
    echo "Docker not found. Installing and enabling..."
    sudo dnf -y install dnf-plugins-core
    sudo dnf -y config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    echo "Docker installed and enabled."
else
    echo "Docker already installed."
fi

# Docker group management (always run)
echo "Configuring Docker group permissions..."
sudo groupadd docker || true
sudo usermod -aG docker "$CALLER" || true
echo "Docker group configured."

# Check if firewalld is present, install and enable if not
echo "Checking firewalld installation..."
if ! command -v firewall-cmd &>/dev/null; then
    echo "Firewalld not found. Installing and enabling..."
    sudo dnf install -y firewalld
    sudo systemctl start firewalld
    sudo systemctl enable firewalld
    echo "Firewalld installed and enabled."
else
    echo "Firewalld already installed."
fi

# Configure firewall ports
echo "Configuring firewall ports..."
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=443/udp
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --reload
echo "Firewall ports configured."

# Configure UDP buffer sizes for AdGuard Home
echo "Configuring system UDP buffer sizes..."
SYSCTL_CONF_FILE="/etc/sysctl.d/99-system-udp-buffers.conf"
echo "net.core.rmem_max = 7500000" | sudo tee "$SYSCTL_CONF_FILE" >/dev/null
echo "net.core.wmem_max = 7500000" | sudo tee -a "$SYSCTL_CONF_FILE" >/dev/null
sudo sysctl --system >/dev/null
echo "UDP buffer sizes configured."

# Generate password hash for authentication
echo "Generating password hash for Web UI authentication..."
AUTH_PASS_HASH=$(generate_htpasswd_hash "$AUTH_USER" "$AUTH_PASS")
sudo docker rmi httpd:2.4-alpine || true
echo "Web UI authentication hash generated."

# Create .env file with actual values
echo "Creating .env file with your configuration..."
cat <<EOF >.env
DOMAIN=$DOMAIN
TRAEFIK_ACME_EMAIL=$TRAEFIK_ACME_EMAIL

# Web UI Authentication
AUTH_USER=$AUTH_USER
AUTH_PASS_HASH=$AUTH_PASS_HASH

# WireGuard UI Admin
WG_ADMIN_USER=$WG_ADMIN_USER
WG_ADMIN_PASS=$WG_ADMIN_PASS
EOF

echo ".env file created."

# Create traefik directory and acme.json for Let's Encrypt certificates
echo "Setting up Traefik for Let's Encrypt certificates..."
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
echo "Traefik acme.json created."

echo "Creating AdGuard Home volume directories..."
mkdir -p ./adguard/adguard_work ./adguard/adguard_conf
chmod -R 700 ./adguard/adguard_work ./adguard/adguard_conf
echo "AdGuard Home volume directories created."

# Prompt for automated maintenance setup
read -r -p "Do you want to set up automated weekly system updates and reboots? (y/n): " setup_maintenance_response
if [[ "$setup_maintenance_response" =~ ^[yY]$ ]]; then
    echo "Setting up automated maintenance..."
    chmod +x ./scripts/add_cron_jobs.sh && sudo -u "$CALLER" ./scripts/add_cron_jobs.sh
    echo "Automated maintenance configured."
else
    echo "Automated maintenance skipped."
fi

# Start the services automatically
echo "Starting Docker services..."
sudo docker compose up -d
echo "Docker services started."

# Create minimal instructions file
cat <<EOF >instructions.txt
Access URLs:
- https://$DOMAIN (WireGuard UI)
- https://traefik.$DOMAIN (Traefik Dashboard)
- https://adguard.$DOMAIN (AdGuard Home UI)

Credentials:
- Web UI Authentication: $AUTH_USER / [password you set]
- WireGuard UI Admin: $WG_ADMIN_USER / [password you set]

During AdGuard Home setup, set Admin Web Interface Port to 3000.
EOF

echo
echo "--- Setup complete! ---"
echo "Instructions file created. Contents:"
cat instructions.txt
