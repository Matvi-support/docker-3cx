# docker-3cx

Run 3CX Phone System in Docker using official Debian packages.

> **Disclaimer:** 3CX does not officially support Docker. This is a community project. Use at your own risk.

## Features

- Debian 12 (Bookworm) base with systemd
- Automatic installation on first boot
- Auto-updates on container restart
- Persistent data via host volumes
- Web configuration tool auto-starts

## Requirements

- Docker 20.10+
- Linux host with cgroups v2
- ~2GB RAM minimum
- ~10GB disk space

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/docker-3cx.git
cd docker-3cx
make run
```

Then open `http://localhost:5015` to complete the 3CX setup wizard.

## Usage

```bash
make help          # Show all commands
make run           # Build and run (first time)
make logs          # View logs
make shell         # Open container shell
make status        # Check status
make stop          # Stop container
make start         # Start container
make update        # Update 3CX packages
make reset         # Full reset (deletes data!)
```

## Manual Run

If you prefer not to use make:

```bash
./run.sh           # Build and start container
```

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 5015 | TCP | Web Config / Management |
| 5000-5001 | TCP | HTTPS |
| 5060 | UDP/TCP | SIP |
| 5090 | UDP/TCP | Tunnel |
| 9000-9500 | UDP | RTP Media |

## Data Persistence

All data stored in `./data/`:

```
data/
├── 3cxpbx/      # Application data
├── config/      # Configuration
├── postgresql/  # Database
├── logs/        # Logs
└── backups/     # Backups
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | `America/New_York` | Timezone |

### Host Networking (Production)

For better VoIP performance, edit `run.sh` and replace port mappings with:

```bash
--network host \
```

## Updating

Updates are checked automatically on container restart. Manual update:

```bash
make update
# or
docker exec 3cx-pbx /usr/local/bin/3cx-update.sh
```

## Troubleshooting

### Web config not accessible

```bash
docker exec 3cx-pbx /usr/sbin/3CXLaunchWebConfigTool
docker exec 3cx-pbx ss -tlnp | grep 5015
```

### Check logs

```bash
docker exec 3cx-pbx cat /var/log/3cx-install.log
docker exec 3cx-pbx journalctl -xe
```

### Full reset

```bash
make reset
# or
docker stop 3cx-pbx && docker rm 3cx-pbx
rm -rf ./data/*
./run.sh
```

## How It Works

1. Container starts with systemd as PID 1
2. On first boot, systemd service installs 3CX from official repos
3. Web config tool starts automatically
4. User completes setup via web browser
5. On subsequent boots, checks for updates

## Project Structure

```
docker-3cx/
├── Dockerfile         # Image definition
├── docker-compose.yml # Alternative launcher
├── run.sh             # Main launcher (recommended)
├── 3cx-install.sh     # Installation script
├── Makefile           # Build commands
├── data/              # Persistent data (gitignored)
├── LICENSE
└── README.md
```

## License

MIT License - See [LICENSE](LICENSE)

**Note:** 3CX is a trademark of 3CX Ltd. This project is not affiliated with 3CX.

## Contributing

Issues and PRs welcome. Please test changes before submitting.
