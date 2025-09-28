#!/usr/bin/env bash

# Uninstalls the wg-lite-hop stack.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Safety Check ---
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run with sudo." >&2
  exit 1
fi

USER_HOME=$(eval echo "~$SUDO_USER")
PROJECT_DIR_NAME=$(basename "$PWD")

# --- Confirmation ---
echo "This will permanently remove the wg-lite-hop stack, including all its Docker containers, networks, images, volumes (WireGuard client data, AdGuard settings), firewall rules, automated maintenance setup, and the project directory itself."
read -p "Are you sure you want to uninstall? (y/N) " -n 1 -r && echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

# --- Optional Backups ---
if [ -f "./traefik/acme.json" ]; then
    read -p "Backup acme.json to your home directory? (Y/n) " -n 1 -r && echo
    if [[ -z "$REPLY" || "$REPLY" =~ ^[Yy]$ ]]; then
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        BACKUP_FILE=$USER_HOME/acme.json.bak."$TIMESTAMP"
        cp ./traefik/acme.json "$BACKUP_FILE"
        echo "Saved acme.json to $BACKUP_FILE"
    fi
fi
# --- Optional .env Backup ---
if [ -f "./.env" ]; then
    read -p "Backup .env file to your home directory? (Y/n) " -n 1 -r && echo
    if [[ -z "$REPLY" || "$REPLY" =~ ^[Yy]$ ]]; then
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        BACKUP_FILE=$USER_HOME/env.bak."$TIMESTAMP"
        cp ./.env "$BACKUP_FILE"
        echo "Saved .env to $BACKUP_FILE"
    fi
fi
echo ""

echo "--- Starting Uninstall ---"
# --- Docker Cleanup ---
echo "[1/5] Cleaning Docker resources..."
if command -v docker &> /dev/null && [ -f "docker-compose.yml" ]; then
    docker compose down -v --rmi local --remove-orphans
    echo "Docker cleanup complete."
else
    echo "Docker or docker-compose.yml not found, skipping Docker cleanup."
fi
echo ""

# --- Firewall Cleanup ---
echo "[2/5] Removing firewall rules..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --remove-port=80/tcp || true
    firewall-cmd --permanent --remove-port=443/tcp || true
    firewall-cmd --permanent --remove-port=443/udp || true
    firewall-cmd --permanent --remove-port=51820/udp || true
    firewall-cmd --reload
    echo "Firewall rules removed and firewall reloaded."
else
    echo "firewall-cmd not found, skipping firewall cleanup."
fi
echo ""

# --- Sysctl Cleanup ---
echo "[3/5] Removing sysctl configuration..."
SYSCTL_CONF_FILE="/etc/sysctl.d/99-system-udp-buffers.conf"
if [ -f "$SYSCTL_CONF_FILE" ]; then
    rm -f "$SYSCTL_CONF_FILE"
    sudo sysctl --system > /dev/null
    echo "Removed sysctl configuration for UDP buffers."
else
    echo "Sysctl configuration file not found, skipping cleanup."
fi
echo ""

# --- Maintenance Cleanup ---
echo "[4/5] Removing automated maintenance setup..."
CALLER=${SUDO_USER:-$(whoami)}
# Remove cron jobs from the original user's crontab
if sudo crontab -u "$CALLER" -l 2>/dev/null | grep -q "$PROJECT_DIR_NAME/scripts/"; then
    sudo crontab -u "$CALLER" -l 2>/dev/null | grep -v "$PROJECT_DIR_NAME/scripts/" | sudo crontab -u "$CALLER" -
    sudo sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' /etc/sudoers
    echo "Removed cron jobs for user $CALLER."
else
    echo "No cron jobs found for user $CALLER."
fi


# Remove sudoers rule
if grep -q "# Maintenance script permissions" /etc/sudoers 2>/dev/null; then
    sed -i '/# Maintenance script permissions/,+1d' /etc/sudoers
    echo "Removed sudoers rule."
else
    echo "No sudoers rule found."
fi
echo ""

# --- Local Configuration & Project Directory Cleanup ---
echo "[5/5] Deleting project directory..."
cd "$USER_HOME"
rm -rf "${USER_HOME:?}/$PROJECT_DIR_NAME"
echo "Project directory '$PROJECT_DIR_NAME' removed."
echo ""

echo "--- Uninstall Complete ---"