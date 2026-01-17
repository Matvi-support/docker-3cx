# 3CX on Debian Docker Container
# Uses jrei/systemd-debian for proper systemd support

FROM jrei/systemd-debian:bookworm

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

# Add 3CX repository - but DO NOT install yet (requires running systemd)
# Using repo.3cx.com for Debian 12 (bookworm)
RUN wget -qO- https://repo.3cx.com/key.pub | gpg --dearmor -o /usr/share/keyrings/3cx-archive-keyring.gpg \
    && echo "deb [arch=amd64 by-hash=yes signed-by=/usr/share/keyrings/3cx-archive-keyring.gpg] http://repo.3cx.com/3cx bookworm main" > /etc/apt/sources.list.d/3cx.list

# Copy initialization script (runs on first boot via systemd)
COPY 3cx-install.sh /usr/local/bin/3cx-install.sh
RUN chmod +x /usr/local/bin/3cx-install.sh

# Create systemd service for first-boot 3CX installation
RUN printf '[Unit]\n\
Description=3CX First Boot Installation\n\
After=network.target\n\
ConditionPathExists=!/var/lib/3cxpbx/.installed\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/local/bin/3cx-install.sh\n\
RemainAfterExit=yes\n\
StandardOutput=journal+console\n\
StandardError=journal+console\n\
TimeoutStartSec=600\n\
\n\
[Install]\n\
WantedBy=multi-user.target\n' > /etc/systemd/system/3cx-install.service \
    && systemctl enable 3cx-install.service

# Volumes for persistent data
VOLUME ["/var/lib/3cxpbx", "/etc/3cxpbx", "/var/lib/postgresql", "/var/log"]

# 3CX Ports
EXPOSE 5015 5000 5001 5060/udp 5060/tcp 5090/udp 5090/tcp 9000-10999/udp
