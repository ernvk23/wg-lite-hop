#!/bin/bash

# Main VPS Maintenance Script
# Handles system updates and Docker maintenance

# Configuration
COMPOSE_DIR="$HOME/wg-lite-hop"
LOGFILE="$HOME/update.log"
REBOOT_FLAG="/tmp/vps-maintenance-reboot"

# Function to log with timestamp
log() {
    # Create log file if it doesn't exist
    touch "$LOGFILE" 2>/dev/null
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

log "=== VPS MAINTENANCE SCRIPT STARTED ==="

# Check for system updates without installing them
log "Checking for system updates..."
CHECK_UPDATE_OUTPUT=$(/usr/bin/dnf check-update 2>&1)
CHECK_UPDATE_EXIT_CODE=$?
log "DNF Check-Update Output:"
log "$CHECK_UPDATE_OUTPUT"

# Decision logic:
# If 'dnf check-update' found updates (exit code 100) AND
# its output, after filtering out kernel packages, is not empty,
# then proceed with a full system update and reboot.
if [ "$CHECK_UPDATE_EXIT_CODE" -eq 100 ] && echo "$CHECK_UPDATE_OUTPUT" | grep -v '^kernel-' | grep -q '^'; then
    log "Non-kernel system updates are available. Stopping containers, updating, and rebooting..."
    
    # Stop Docker containers
    cd "$COMPOSE_DIR" || {
        log "ERROR: Cannot change to directory $COMPOSE_DIR"
        exit 1
    }
    docker compose down

    # Apply system updates
    log "Applying system updates..."
    SYSTEM_UPDATE_OUTPUT=$(sudo /usr/bin/dnf update -y 2>&1)
    log "$SYSTEM_UPDATE_OUTPUT"
    
    # Create reboot flag for post-reboot script
    date > "$REBOOT_FLAG"
    
    log "Rebooting to apply updates..."
    sudo reboot
else
    log "No non-kernel system updates available. Proceeding with Docker maintenance..."
    
    # Handle Docker updates
    cd "$COMPOSE_DIR" || {
        log "ERROR: Cannot change to directory $COMPOSE_DIR"
        exit 1
    }
    
    log "Pulling latest Docker images..."
    PULL_OUTPUT=$(docker compose pull 2>&1)
    log "Docker Pull Output:"
    log "$PULL_OUTPUT"
    
    log "Updating containers..."
    UP_OUTPUT=$(docker compose up -d 2>&1)
    log "Docker Up Output:"
    log "$UP_OUTPUT"
    
    log "Removing dangling images..."
    PRUNE_OUTPUT=$(docker image prune -f 2>&1)
    log "Docker Prune Output:"
    log "$PRUNE_OUTPUT"
    
    log "Docker maintenance completed."
fi

log "=== VPS MAINTENANCE SCRIPT COMPLETED ==="