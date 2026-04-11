#!/bin/bash
# 3CX Startup Script - Runs on every container boot
# Ensures services are started after a restart

LOG_FILE="/var/log/3cx-startup.log"
INSTALL_MARKER="/var/lib/3cxpbx/.installed"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 3CX Startup Check ==="

# Wait for install to complete if first boot
if [ ! -f "$INSTALL_MARKER" ]; then
    log "Waiting for first boot installation to complete..."
    for i in $(seq 1 60); do
        [ -f "$INSTALL_MARKER" ] && break
        sleep 10
    done
    if [ ! -f "$INSTALL_MARKER" ]; then
        log "ERROR: Installation did not complete in time"
        exit 1
    fi
fi

# Ensure phonesystem user exists
if ! id -u phonesystem >/dev/null 2>&1; then
    log "Recreating phonesystem user..."
    useradd -r -s /bin/false phonesystem
fi

# Remove duplicate repo file if present
rm -f /etc/apt/sources.list.d/3cxpbx.list

# Start the web configuration tool
log "Starting 3CX Web Configuration Tool..."
/usr/sbin/3CXLaunchWebConfigTool || true

log "3CX startup complete"
