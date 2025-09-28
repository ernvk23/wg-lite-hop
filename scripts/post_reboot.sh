#!/bin/bash

# Post-Reboot Script
# Handles Docker operations after system reboot

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

# Only run if the reboot flag exists (meaning it was a maintenance reboot)
if [[ ! -f "$REBOOT_FLAG" ]]; then
    exit 0
fi

log "=== POST-REBOOT OPERATIONS STARTED ==="

# Wait for system to fully initialize
sleep 60

cd "$COMPOSE_DIR" || {
    log "ERROR: Cannot change to directory $COMPOSE_DIR"
    exit 1
}

log "Pulling latest Docker images..."
PULL_OUTPUT=$(docker compose pull 2>&1)
log "Docker Pull Output:"
log "$PULL_OUTPUT"

log "Starting containers..."
UP_OUTPUT=$(docker compose up -d 2>&1)
log "Docker Up Output:"
log "$UP_OUTPUT"

log "Removing dangling images..."
PRUNE_OUTPUT=$(docker image prune -f 2>&1)
log "Docker Prune Output:"
log "$PRUNE_OUTPUT"

# Remove reboot flag
rm -f "$REBOOT_FLAG"

log "=== POST-REBOOT OPERATIONS COMPLETED ==="