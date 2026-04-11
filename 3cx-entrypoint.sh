#!/bin/bash
# 3CX Entrypoint - Runs on every container boot
# Installs 3CX if binaries are missing, then starts services
set -e

LOG_FILE="/var/log/3cx-entrypoint.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 3CX Entrypoint ==="

# Ensure phonesystem user exists
if ! id -u phonesystem >/dev/null 2>&1; then
    log "Creating phonesystem user..."
    useradd -r -s /bin/false phonesystem
fi

# Install 3CX if not present (first boot or container recreated)
if ! dpkg -s 3cxpbx >/dev/null 2>&1; then
    log "3CX not installed. Installing..."

    apt-get update
    apt-get install -y 3cxpbx

    # Remove duplicate repo file created by the package
    rm -f /etc/apt/sources.list.d/3cxpbx.list

    log "Waiting for services to initialize..."
    sleep 10

    log "=== 3CX Installation Complete ==="
else
    log "3CX already installed."
fi

# Start the web configuration tool
log "Starting 3CX Web Configuration Tool..."
/usr/sbin/3CXLaunchWebConfigTool || true

log "3CX startup complete. Console: http://<your-ip>:5015"
