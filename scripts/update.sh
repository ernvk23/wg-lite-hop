#!/bin/bash

# Main VPS Maintenance Script
# Handles system updates and Docker maintenance

# Configuration
COMPOSE_DIR="$HOME/wg-lite-hop-main"
LOGFILE="$HOME/update.log"
REBOOT_FLAG="/tmp/vps-maintenance-reboot"

# Function to log with timestamp
log() {
    # Create log file if it doesn't exist
    touch "$LOGFILE" 2>/dev/null
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

log "=== VPS MAINTENANCE SCRIPT STARTED ==="

# Try to update system and capture output
log "Running system update..."
UPDATE_OUTPUT=$(sudo /usr/bin/dnf update -y 2>&1)
log "DNF Update Output:"
log "$UPDATE_OUTPUT"

# Check if anything was actually installed/updated
if echo "$UPDATE_OUTPUT" | grep -qE "(Installed:|Upgraded:)" && ! echo "$UPDATE_OUTPUT" | grep -q "Nothing to do"; then
    log "System packages were updated. Stopping containers and rebooting..."
    
    # Stop Docker containers
    cd "$COMPOSE_DIR" || {
        log "ERROR: Cannot change to directory $COMPOSE_DIR"
        exit 1
    }
    docker compose down
    
    # Create reboot flag for post-reboot script
    echo "$(date)" > "$REBOOT_FLAG"
    
    log "Rebooting to apply updates..."
    sudo reboot
else
    log "No system updates installed. Proceeding with Docker maintenance..."
    
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