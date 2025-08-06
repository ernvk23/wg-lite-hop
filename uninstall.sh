#!/usr/bin/env bash

# Uninstalls the wg-lite-hop stack.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Safety Check ---
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run with sudo." >&2
  exit 1
fi

# --- Confirmation ---
echo "This will permanently remove the wg-lite-hop stack, including all Docker containers, networks, volumes (WireGuard client data, AdGuard settings), firewall rules, and the project directory itself."
read -p "Are you sure you want to uninstall? (y/N) " -n 1 -r && echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

# --- Optional Backups ---
if [ -f "./traefik/acme.json" ]; then
    read -p "Backup acme.json to your home directory? (Y/n) " -n 1 -r && echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        BACKUP_FILE=~/acme.json.bak."$TIMESTAMP"
        cp ./traefik/acme.json "$BACKUP_FILE"
        echo "Saved acme.json to $BACKUP_FILE"
    fi
fi
# --- Optional .env Backup ---
if [ -f "./.env" ]; then
    read -p "Backup .env file to your home directory? (Y/n) " -n 1 -r && echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        BACKUP_FILE=~/.env.bak."$TIMESTAMP"
        cp ./.env "$BACKUP_FILE"
        echo "Saved .env to $BACKUP_FILE"
    fi
fi
echo ""

echo "--- Starting Uninstall ---"
# --- Docker Cleanup ---
echo "[1/3] Cleaning Docker resources..."
if command -v docker &> /dev/null && [ -f "docker-compose.yml" ]; then
    docker compose down -v --rmi all --remove-orphans
    echo "Docker cleanup complete."
else
    echo "Docker or docker-compose.yml not found, skipping Docker cleanup."
fi
echo ""

# --- Firewall Cleanup ---
echo "[2/3] Removing firewall rules..."
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

# --- Local Configuration & Project Directory Cleanup ---
echo "[3/3] Deleting project directory..."
PROJECT_DIR_NAME=$(basename "$PWD")
cd ..
rm -rf "./$PROJECT_DIR_NAME"
echo "Project directory '$PROJECT_DIR_NAME' removed."
echo ""

echo "--- Uninstall Complete ---"
