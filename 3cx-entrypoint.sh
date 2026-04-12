#!/bin/bash
# 3CX Entrypoint - Runs on every container boot
# Installs 3CX if binaries are missing, then starts services
set -e

LOG_FILE="/var/log/3cx-entrypoint.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 3CX Entrypoint ==="

# Ensure phonesystem system user exists
if ! id -u phonesystem >/dev/null 2>&1; then
    log "Creating phonesystem system user..."
    useradd -r -s /bin/false phonesystem
fi

# Install 3CX if not present (first boot or container recreated)
if ! dpkg -s 3cxpbx >/dev/null 2>&1; then
    log "3CX not installed. Installing..."

    # Keep downloaded .deb files in the cache volume (fast reinstall)
    rm -f /etc/apt/apt.conf.d/docker-clean

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

# Ensure PostgreSQL cluster is registered
# Cluster config lives in /etc/postgresql (persisted via volume), data in /var/lib/postgresql (persisted)
if ! pg_lsclusters -h 2>/dev/null | grep -q '^15 *main'; then
    if [ -f /var/lib/postgresql/15/main/PG_VERSION ]; then
        log "PostgreSQL data found but cluster config missing. Regenerating config while preserving data..."
        # Move existing data aside
        mv /var/lib/postgresql/15/main /var/lib/postgresql/15/main.preserved
        # Create fresh cluster (generates /etc/postgresql/15/main/* config files + empty data)
        pg_createcluster 15 main --locale=C.UTF-8 --encoding=UTF8
        # Replace fresh data with preserved data
        rm -rf /var/lib/postgresql/15/main
        mv /var/lib/postgresql/15/main.preserved /var/lib/postgresql/15/main
        chown -R postgres:postgres /var/lib/postgresql/15/main
    else
        log "Creating new PostgreSQL cluster with UTF-8 encoding..."
        rm -rf /var/lib/postgresql/15/main
        pg_createcluster 15 main --locale=C.UTF-8 --encoding=UTF8
    fi
fi

# Ensure TimescaleDB is preloaded (required by 3CX)
PG_CONF="/etc/postgresql/15/main/postgresql.conf"
if [ -f "$PG_CONF" ] && ! grep -q "^shared_preload_libraries.*timescaledb" "$PG_CONF"; then
    log "Enabling TimescaleDB preload in PostgreSQL..."
    # Remove any existing shared_preload_libraries line and add ours
    sed -i "/^shared_preload_libraries/d" "$PG_CONF"
    echo "shared_preload_libraries = 'timescaledb'" >> "$PG_CONF"
    # Restart if already running
    if pg_lsclusters -h 2>/dev/null | grep '^15 *main' | grep -q online; then
        pg_ctlcluster 15 main restart || true
    fi
fi

# Ensure PostgreSQL is running
if ! pg_lsclusters -h 2>/dev/null | grep '^15 *main' | grep -q online; then
    log "Starting PostgreSQL cluster..."
    pg_ctlcluster 15 main start || true
    sleep 3
fi

# Ensure phonesystem PostgreSQL role exists
if ! su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='phonesystem'\"" 2>/dev/null | grep -q 1; then
    log "Creating phonesystem PostgreSQL role..."
    su - postgres -c "psql -c \"CREATE ROLE phonesystem WITH LOGIN SUPERUSER;\"" || true
fi

# Start the web configuration tool
log "Starting 3CX Web Configuration Tool..."
/usr/sbin/3CXLaunchWebConfigTool || true

log "3CX startup complete. Console: http://<your-ip>:5015"
