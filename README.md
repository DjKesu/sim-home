# sim-home
Simulation setup using Isaac Sim for home

## Overview
This repository provides a Docker setup script for running NVIDIA Isaac Sim containers in a home environment. The script automates the installation of Docker, NVIDIA Container Toolkit, and provides convenient commands to run Isaac Sim.

## Prerequisites
- Ubuntu Linux system
- NVIDIA GPU with proper drivers installed
- Internet connection for downloading packages and containers

## System Requirements
- NVIDIA GPU with CUDA support
- NVIDIA GPU drivers (compatible with Isaac Sim 5.0.0)
- At least 8GB of GPU memory recommended
- 32GB+ system RAM recommended
- 50GB+ available disk space

## Quick Start

### 1. Setup (One-time installation)
```bash
./setup_isaac_sim.sh setup
```

This command will:
- Install Docker using the official convenience script
- Configure Docker for non-root usage
- Install NVIDIA Container Toolkit
- Pull the Isaac Sim 5.0.0 container
- Create necessary cache directories
- Verify all installations

### 2. Run Isaac Sim (Interactive)
```bash
./setup_isaac_sim.sh run
```

This starts an interactive bash session inside the Isaac Sim container where you can run Isaac Sim commands.

### 3. Run Isaac Sim (Headless with Livestream)
```bash
./setup_isaac_sim.sh headless
```

This runs Isaac Sim in headless mode with native livestream enabled.

## Usage

### Available Commands
- `setup` - Install and configure all prerequisites (default)
- `run` - Start Isaac Sim container with interactive bash
- `headless` - Start Isaac Sim in headless mode with livestream
- `help` - Show usage information

### Examples
```bash
# Full setup
./setup_isaac_sim.sh setup

# Quick run (after setup)
./setup_isaac_sim.sh run

# Headless mode
./setup_isaac_sim.sh headless

# Show help
./setup_isaac_sim.sh help
```

### Inside the Container
Once you're inside the Isaac Sim container, you can:
- Start Isaac Sim GUI: `./isaac-sim.sh`
- Run headless with livestream: `./runheadless.sh -v`
- Access Python API: `./python.sh`

## Environment Variables
- `PRIVACY_USERID` - Optional email for tagging session logs

Example:
```bash
PRIVACY_USERID="user@example.com" ./setup_isaac_sim.sh run
```

## Cache and Data Persistence
The script creates persistent directories in `~/docker/isaac-sim/` for:
- Kit cache
- Omniverse cache
- Pip cache
- GL cache
- Compute cache
- Logs
- Data
- Documents

## Troubleshooting

### Docker Permission Issues
If you get permission errors with Docker:
```bash
# Log out and log back in, or run:
newgrp docker
```

### NVIDIA Container Toolkit Issues
Verify your setup:
```bash
docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
```

### GPU Driver Issues
Check your NVIDIA drivers:
```bash
nvidia-smi
```

## License Agreement
By using this script with the Isaac Sim container, you accept:
- [NVIDIA Omniverse License Agreement](https://docs.omniverse.nvidia.com/platform/latest/common/NVIDIA_Omniverse_License_Agreement.html)
- Data collection agreement (opt-in via PRIVACY_CONSENT=Y)

## Support
For issues related to:
- Isaac Sim: Check [NVIDIA Isaac Sim Documentation](https://docs.omniverse.nvidia.com/isaacsim/latest/)
- Docker: Check [Docker Documentation](https://docs.docker.com/)
- NVIDIA Container Toolkit: Check [NVIDIA Container Toolkit Documentation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
