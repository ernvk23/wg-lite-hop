#!/bin/bash
# Sets up automated maintenance. Run as the target user.

set -e

echo "--- Setting up automated maintenance for user '$USER' ---"

# Add sudoers rule
echo "Adding sudoers rule..."
echo -e "\n# Maintenance script permissions\n$USER ALL=(ALL) NOPASSWD: /usr/bin/dnf update -y, /usr/sbin/reboot" | sudo EDITOR='tee -a' visudo

# Add cron jobs
echo "Adding cron jobs..."
(echo "0 2 * * 1 \$HOME/wg-lite-hop-main/scripts/update.sh"; echo "@reboot sleep 60 && \$HOME/wg-lite-hop-main/scripts/post-reboot.sh") | crontab -

echo "--- Setup Complete ---"