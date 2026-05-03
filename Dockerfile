# 3CX on Debian Docker Container
# Uses geerlingguy/docker-debian12-ansible for proper systemd support (multi-arch)

FROM --platform=linux/amd64 geerlingguy/docker-debian12-ansible:latest

LABEL maintainer="docker-3cx"
LABEL description="3CX Phone System on Debian 12 with systemd"

ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    gnupg2 \
    wget \
    sudo \
    net-tools \
    iputils-ping \
    procps \
    dphys-swapfile \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add 3CX repository
RUN wget -qO- https://repo.3cx.com/key.pub | gpg --dearmor -o /usr/share/keyrings/3cx-archive-keyring.gpg \
    && echo "deb [arch=amd64 by-hash=yes signed-by=/usr/share/keyrings/3cx-archive-keyring.gpg] http://repo.3cx.com/3cx bookworm main" > /etc/apt/sources.list.d/3cx.list

# Create phonesystem user (required by 3CX, persisted in image)
RUN useradd -r -s /bin/false phonesystem

# Copy entrypoint script
COPY 3cx-entrypoint.sh /usr/local/bin/3cx-entrypoint.sh
RUN chmod +x /usr/local/bin/3cx-entrypoint.sh

# Create systemd service - runs on every boot
RUN printf '[Unit]\n\
Description=3CX Install and Startup\n\
After=network.target\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/local/bin/3cx-entrypoint.sh\n\
RemainAfterExit=yes\n\
StandardOutput=journal+console\n\
StandardError=journal+console\n\
TimeoutStartSec=600\n\
\n\
[Install]\n\
WantedBy=multi-user.target\n' > /etc/systemd/system/3cx-entrypoint.service \
    && systemctl enable 3cx-entrypoint.service

# Volumes for persistent data
# /var/cache/apt/archives: keeps downloaded .deb so reinstall is fast (no re-download)
# /etc/postgresql: keeps PostgreSQL cluster config alive across container recreations
VOLUME ["/var/lib/3cxpbx", "/etc/3cxpbx", "/var/lib/postgresql", "/etc/postgresql", "/var/log", "/var/cache/apt/archives"]

# 3CX Ports
EXPOSE 5015 5000 5001 5060/udp 5060/tcp 5090/udp 5090/tcp 9000-10999/udp
