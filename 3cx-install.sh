#!/bin/bash
# 3CX Installation Script - Runs on first container boot
set -e

LOG_FILE="/var/log/3cx-install.log"
INSTALL_MARKER="/var/lib/3cxpbx/.installed"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 3CX Docker Installation Starting ==="

# Check if already installed
if [ -f "$INSTALL_MARKER" ]; then
    log "3CX already installed. Checking for updates..."
    apt-get update
    apt-get upgrade -y 3cxpbx || true
    log "Update check complete."

    # Ensure web config tool is running
    log "Starting 3CX Web Configuration Tool..."
    /usr/sbin/3CXLaunchWebConfigTool || true

    exit 0
fi

log "First boot detected. Installing 3CX..."

# Update package lists
log "Updating package lists..."
apt-get update

# Install 3CX PBX
log "Installing 3cxpbx package..."
apt-get install -y 3cxpbx

# Wait for services to settle
log "Waiting for services to initialize..."
sleep 10

# Mark as installed
mkdir -p /var/lib/3cxpbx
touch "$INSTALL_MARKER"
echo "$(date)" > "$INSTALL_MARKER"

log "=== 3CX Installation Complete ==="

# Start the web configuration tool
log "Starting 3CX Web Configuration Tool..."
/usr/sbin/3CXLaunchWebConfigTool || true
sleep 5

log "Access the management console at: http://<your-ip>:5015"
log "Run the 3CX configuration wizard to complete setup."

# Create update script for convenience
cat > /usr/local/bin/3cx-update.sh << 'UPDATEEOF'
#!/bin/bash
echo "Updating 3CX..."
apt-get update
apt-get upgrade -y 3cxpbx
echo "Update complete. You may need to restart 3CX services."
systemctl restart 3cxpbx || true
UPDATEEOF
chmod +x /usr/local/bin/3cx-update.sh

log "Created /usr/local/bin/3cx-update.sh for manual updates"
