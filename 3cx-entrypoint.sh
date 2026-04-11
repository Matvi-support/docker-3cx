#!/bin/bash
# 3CX Entrypoint - Runs on every container boot
# 3CX is pre-installed in the image, this script starts services
set -e

LOG_FILE="/var/log/3cx-entrypoint.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 3CX Startup ==="

# Ensure phonesystem user exists
if ! id -u phonesystem >/dev/null 2>&1; then
    log "Creating phonesystem user..."
    useradd -r -s /bin/false phonesystem
fi

# Start the web configuration tool
log "Starting 3CX Web Configuration Tool..."
/usr/sbin/3CXLaunchWebConfigTool || true

log "3CX startup complete. Console: http://<your-ip>:5015"
