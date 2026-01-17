#!/bin/bash
# Run script for 3CX Docker container with proper cgroups v2 support

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"

# Create data directories
mkdir -p "$DATA_DIR"/{3cxpbx,config,postgresql,logs,backups}

# Build the image
echo "Building 3CX Docker image..."
docker build -t 3cx-pbx "$SCRIPT_DIR"

# Stop and remove existing container if running
docker stop 3cx-pbx 2>/dev/null || true
docker rm 3cx-pbx 2>/dev/null || true

# Run with proper cgroup settings for systemd
echo "Starting 3CX container..."
docker run -d \
    --name 3cx-pbx \
    --hostname 3cx-pbx \
    --privileged \
    --cgroupns=host \
    -e TZ="${TZ:-America/New_York}" \
    -v "$DATA_DIR/3cxpbx:/var/lib/3cxpbx" \
    -v "$DATA_DIR/config:/etc/3cxpbx" \
    -v "$DATA_DIR/postgresql:/var/lib/postgresql" \
    -v "$DATA_DIR/logs:/var/log" \
    -v "$DATA_DIR/backups:/var/lib/3cxpbx/Data/Backups" \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    --tmpfs /run \
    --tmpfs /run/lock \
    -p 5015:5015 \
    -p 5000:5000 \
    -p 5001:5001 \
    -p 5060:5060/udp \
    -p 5060:5060/tcp \
    -p 5090:5090/udp \
    -p 5090:5090/tcp \
    -p 9000-9500:9000-9500/udp \
    --restart unless-stopped \
    3cx-pbx

echo ""
echo "Container started. Checking status..."
sleep 3
docker ps --filter name=3cx-pbx

echo ""
echo "Testing exec..."
docker exec 3cx-pbx ps aux

echo ""
echo "To view logs: docker logs -f 3cx-pbx"
echo "To check install: docker exec 3cx-pbx systemctl status 3cx-install.service"
echo "To enter shell: docker exec -it 3cx-pbx bash"
