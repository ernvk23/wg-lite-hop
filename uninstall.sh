#!/usr/bin/env bash

# Uninstalls the wg-lite-hop stack.

# --- Safety Check ---
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run with sudo." >&2
  exit 1
fi

# --- Confirmation ---
echo "This will stop/delete Docker containers, networks, volumes, and local config."
read -p "Are you sure you want to uninstall? (y/N) " -n 1 -r && echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

# --- Optional acme.json Backup ---
if [ -f "./traefik/acme.json" ]; then
    read -p "Save acme.json? (y/N) " -n 1 -r && echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo "Saving acme.json to ~/acme.json.bak..."
        cp ./traefik/acme.json ~/acme.json.bak
    fi
fi
echo ""

echo "--- Starting Uninstall ---"

# --- Docker Cleanup ---
echo "[1/2] Cleaning Docker resources..."
docker compose down -v --remove-orphans && docker system prune -a -f --volumes
echo "Docker cleanup complete."
echo ""

# --- Firewall Reload ---
echo "[2/2] Reloading firewall..."
firewall-cmd --reload
echo "Firewall reloaded."
echo ""

# --- Local Configuration & Project Directory Cleanup ---
echo "Deleting local configuration and project directory..."
rm -rf wg-easy adguard traefik .env ~/wg-lite-hop-main
echo "Cleanup complete."
echo ""

echo "--- Uninstall Complete ---"