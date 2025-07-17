#!/usr/bin/env bash

#
# Uninstalls the wg-lite-hop stack completely.
#
# WARNING: This script is destructive and will permanently remove:
#   - All Docker containers and networks for this project.
#   - All associated Docker volumes (including WireGuard client data).
#   - All local configuration directories (wg-easy, adguard, traefik).
#

# --- Safety Check ---
# Check if the script is run with sudo privileges, as it's required for Docker and file removal.
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run with sudo."
  echo "Usage: sudo ./uninstall.sh"
  exit 1
fi

# --- Confirmation Prompt ---
echo "This script will stop and delete all containers, networks, and volumes."
echo "It will also permanently delete local data in: 'wg-easy/', 'adguard/', 'traefik/', and '.env'."
echo ""
read -p "Are you absolutely sure you want to uninstall? (y/N) " -n 1 -r
echo # Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 1
fi

echo ""
echo "--- Starting Full Uninstall ---"

echo "[1/2] Stopping and removing Docker containers, volumes, and networks..."
docker compose down -v --remove-orphans
echo ""
echo "[2/2] Deleting all containers/volumes/networks/interfaces/files"
docker system prune -a -f --volumes
firewall-cmd --reload

cd && rm -rf wg-lite-hop-main
echo ""
echo "--- Uninstall Complete ---"