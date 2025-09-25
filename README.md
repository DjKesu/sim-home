# sim-home
Simulation setup using Isaac Sim for home automation and robotics

A complete Docker-based setup for NVIDIA Isaac Sim 4.0, providing an easy way to run physics simulations, robot training, and home automation scenarios in a containerized environment.

## Prerequisites

- **Operating System**: Ubuntu 20.04+ or compatible Linux distribution
- **Hardware**: NVIDIA GPU with compute capability 7.0+ (RTX 20 series or newer recommended)
- **NVIDIA Drivers**: Version 525.60.11 or later
- **System Memory**: 16GB RAM minimum, 32GB recommended
- **Storage**: At least 50GB free space for Docker images and data

## Quick Start

### 1. One-Command Installation

Run the automated installation script that will set up Docker, NVIDIA Container Toolkit, and Isaac Sim:

```bash
./install.sh
```

This script will:
- Install Docker and Docker Compose
- Install NVIDIA Container Toolkit
- Configure GPU support for containers
- Create necessary directories and helper scripts
- Optionally pull the Isaac Sim Docker image

### 2. Manual Installation (Alternative)

If you prefer to install components manually:

#### Install Docker
```bash
# Update system
sudo apt update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### Install NVIDIA Container Toolkit
```bash
# Add NVIDIA package repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install toolkit
sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## Usage

### GUI Mode (Desktop Environment)

Launch Isaac Sim with full GUI support:

```bash
./scripts/run_isaac_sim.sh
```

This will:
- Set up X11 forwarding for GUI display
- Create necessary data directories
- Start Isaac Sim with GPU acceleration

### Headless Mode (Server Environment)

For server deployments or batch processing:

```bash
./scripts/run_isaac_sim_headless.sh
```

### Jupyter Notebook Development

Start a Jupyter notebook server for interactive development:

```bash
./scripts/jupyter_start.sh
```

Access the notebook at `http://localhost:8888`

### Docker Compose Commands

You can also use docker-compose directly for more control:

```bash
# Start Isaac Sim with GUI
docker-compose up isaac-sim

# Start Isaac Sim headless
docker-compose up isaac-sim-headless

# Start custom Isaac Sim build (with additional tools)
docker-compose up isaac-sim-custom

# Run in background
docker-compose up -d isaac-sim

# Stop containers
docker-compose down
```

## Directory Structure

```
sim-home/
├── install.sh              # Main installation script
├── docker-compose.yml      # Container orchestration
├── Dockerfile              # Custom Isaac Sim image
├── scripts/                 # Helper scripts
│   ├── setup_x11.sh        # X11 forwarding setup
│   ├── run_isaac_sim.sh    # GUI launcher
│   ├── run_isaac_sim_headless.sh # Headless launcher
│   └── jupyter_start.sh    # Jupyter server launcher
├── data/                   # Persistent simulation data
├── cache/                  # Isaac Sim cache
└── workspace/              # Development workspace
```

## Data Persistence

All simulation data, cache, and workspace files are persisted in local directories:

- `./data/` - Simulation scenes, assets, and output data
- `./cache/` - Isaac Sim cache for faster startup
- `./workspace/` - Your development files and scripts

## Troubleshooting

### GPU Not Detected
```bash
# Check NVIDIA drivers
nvidia-smi

# Test NVIDIA Docker support
docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi
```

### X11 Forwarding Issues
```bash
# Check DISPLAY variable
echo $DISPLAY

# Reset X11 authentication
./scripts/setup_x11.sh
```

### Permission Issues
```bash
# Ensure user is in docker group
sudo usermod -aG docker $USER
# Log out and back in, or restart
```

### Container Won't Start
```bash
# Check Docker logs
docker-compose logs isaac-sim

# Check system resources
docker system df
free -h
```

## Development

### Custom Extensions

Place your custom Isaac Sim extensions in the `workspace/` directory. They will be available inside the container at `/workspace/`.

### Python Scripts

Create Python scripts for automation and simulation control:

```python
# Example: workspace/my_simulation.py
import omni
from omni.isaac.kit import SimulationApp

# Initialize Isaac Sim
simulation_app = SimulationApp({"headless": True})

# Your simulation code here
# ...

simulation_app.close()
```

## NVIDIA NGC Account

To download Isaac Sim images, you'll need an NVIDIA NGC account:

1. Visit [https://ngc.nvidia.com/](https://ngc.nvidia.com/)
2. Create a free account
3. Generate an API key
4. Use the API key when prompted by the installation script

## Support and Documentation

- [Isaac Sim Documentation](https://docs.omniverse.nvidia.com/isaacsim/)
- [NVIDIA Omniverse](https://www.nvidia.com/en-us/omniverse/)
- [Docker Documentation](https://docs.docker.com/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 
