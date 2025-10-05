#!/bin/bash
# Sets up automated maintenance. Run as the target user.

set -e

PROJECT_DIR_NAME=$(basename "$PWD")

echo "--- Setting up automated maintenance for user '$USER' ---"

# Add sudoers rule
echo "Adding sudoers rule..."
echo -e "\n# Maintenance script permissions\n$USER ALL=(ALL) NOPASSWD: /usr/bin/dnf update -y, /usr/sbin/reboot" | sudo EDITOR='tee -a' visudo

# Add cron jobs
echo "Adding cron jobs..."
(echo "0 2 * * 0 \$HOME/$PROJECT_DIR_NAME/scripts/update.sh"; echo "@reboot sleep 30 && \$HOME/$PROJECT_DIR_NAME/scripts/post_reboot.sh") | crontab -

echo "--- Setup Complete ---"