#!/bin/bash

# Isaac Sim 4.0 Docker Environment Setup Script
# This script installs Docker, NVIDIA Container Toolkit, and sets up Isaac Sim 4.0

set -e  # Exit on any error

echo "=========================================="
echo "Isaac Sim 4.0 Docker Environment Setup"
echo "=========================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check if running on Ubuntu/Debian
if ! command -v apt-get &> /dev/null; then
    echo "This script is designed for Ubuntu/Debian systems with apt-get package manager."
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if NVIDIA GPU is available
check_nvidia_gpu() {
    if command_exists nvidia-smi; then
        echo "✓ NVIDIA GPU detected:"
        nvidia-smi --query-gpu=name --format=csv,noheader | head -1
        return 0
    else
        echo "⚠ Warning: NVIDIA GPU not detected or nvidia-smi not available."
        echo "Isaac Sim requires an NVIDIA GPU with compatible drivers."
        read -p "Do you want to continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        return 1
    fi
}

# Install Docker
install_docker() {
    if command_exists docker; then
        echo "✓ Docker is already installed"
        docker --version
    else
        echo "Installing Docker..."
        
        # Update package index
        sudo apt-get update
        
        # Install prerequisites
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        
        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Set up the stable repository
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Update package index again
        sudo apt-get update
        
        # Install Docker Engine
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Add current user to docker group
        sudo usermod -aG docker $USER
        
        echo "✓ Docker installed successfully"
        echo "Note: You may need to log out and back in for docker group changes to take effect"
    fi
}

# Install NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
    echo "Installing NVIDIA Container Toolkit..."
    
    # Add NVIDIA package repository
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
        && curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add - \
        && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    # Update package index
    sudo apt-get update
    
    # Install NVIDIA Container Toolkit
    sudo apt-get install -y nvidia-container-toolkit
    
    # Configure Docker to use NVIDIA runtime
    sudo nvidia-ctk runtime configure --runtime=docker
    
    # Restart Docker service
    sudo systemctl restart docker
    
    echo "✓ NVIDIA Container Toolkit installed successfully"
}

# Test NVIDIA Docker setup
test_nvidia_docker() {
    echo "Testing NVIDIA Docker setup..."
    
    if docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi; then
        echo "✓ NVIDIA Docker setup is working correctly"
    else
        echo "✗ NVIDIA Docker setup test failed"
        echo "Please check your NVIDIA drivers and container toolkit installation"
        return 1
    fi
}

# Pull Isaac Sim Docker image
pull_isaac_sim_image() {
    echo "Pulling Isaac Sim 4.0 Docker image..."
    echo "Note: This is a large image (~10GB) and may take a while to download"
    
    # Check if user is logged into NVIDIA NGC
    echo "You need to be logged into NVIDIA NGC to pull Isaac Sim images."
    echo "Please visit https://ngc.nvidia.com/ to create an account and get an API key."
    
    read -p "Do you have an NVIDIA NGC API key? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Please enter your NGC API key: " -s ngc_key
        echo
        
        # Login to NGC
        echo "$ngc_key" | docker login nvcr.io --username '$oauthtoken' --password-stdin
        
        # Pull Isaac Sim image
        docker pull nvcr.io/nvidia/isaac-sim:4.0.0
        
        echo "✓ Isaac Sim Docker image pulled successfully"
    else
        echo "⚠ Skipping Isaac Sim image pull. You can pull it later with:"
        echo "docker pull nvcr.io/nvidia/isaac-sim:4.0.0"
    fi
}

# Create necessary directories
create_directories() {
    echo "Creating necessary directories..."
    
    mkdir -p ~/isaac-sim-data
    mkdir -p ~/isaac-sim-cache
    
    echo "✓ Directories created:"
    echo "  - ~/isaac-sim-data (for persistent data)"
    echo "  - ~/isaac-sim-cache (for cache)"
}

# Create docker-compose file
create_docker_compose() {
    echo "Creating docker-compose.yml..."
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  isaac-sim:
    image: nvcr.io/nvidia/isaac-sim:4.0.0
    container_name: isaac-sim
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
      - DISPLAY=${DISPLAY}
      - QT_X11_NO_MITSHM=1
      - XAUTHORITY=/tmp/.docker.xauth
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - /tmp/.docker.xauth:/tmp/.docker.xauth:rw
      - ~/isaac-sim-data:/isaac-sim/data:rw
      - ~/isaac-sim-cache:/isaac-sim/cache:rw
    network_mode: host
    stdin_open: true
    tty: true
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOF
    
    echo "✓ docker-compose.yml created"
}

# Create helper scripts
create_helper_scripts() {
    echo "Creating helper scripts..."
    
    # X11 authorization setup script
    cat > setup_x11.sh << 'EOF'
#!/bin/bash
# Setup X11 forwarding for Isaac Sim GUI
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
chmod 644 $XAUTH
EOF
    
    chmod +x setup_x11.sh
    
    # Isaac Sim launcher script
    cat > run_isaac_sim.sh << 'EOF'
#!/bin/bash
# Launch Isaac Sim with proper X11 forwarding

# Setup X11 authorization
./setup_x11.sh

# Start Isaac Sim container
docker-compose up isaac-sim
EOF
    
    chmod +x run_isaac_sim.sh
    
    # Headless Isaac Sim script
    cat > run_isaac_sim_headless.sh << 'EOF'
#!/bin/bash
# Launch Isaac Sim in headless mode (no GUI)

docker run --rm -it \
    --gpus all \
    -v ~/isaac-sim-data:/isaac-sim/data:rw \
    -v ~/isaac-sim-cache:/isaac-sim/cache:rw \
    nvcr.io/nvidia/isaac-sim:4.0.0 \
    ./isaac-sim.headless.sh
EOF
    
    chmod +x run_isaac_sim_headless.sh
    
    echo "✓ Helper scripts created:"
    echo "  - setup_x11.sh (X11 forwarding setup)"
    echo "  - run_isaac_sim.sh (GUI mode launcher)"
    echo "  - run_isaac_sim_headless.sh (headless mode launcher)"
}

# Main installation process
main() {
    echo "Starting Isaac Sim 4.0 Docker environment setup..."
    
    # Check system requirements
    check_nvidia_gpu
    gpu_available=$?
    
    # Install Docker
    install_docker
    
    # Install NVIDIA Container Toolkit (only if GPU is available)
    if [ $gpu_available -eq 0 ]; then
        install_nvidia_container_toolkit
        test_nvidia_docker
    else
        echo "⚠ Skipping NVIDIA Container Toolkit installation (no GPU detected)"
    fi
    
    # Create directories and files
    create_directories
    create_docker_compose
    create_helper_scripts
    
    # Pull Isaac Sim image
    if [ $gpu_available -eq 0 ]; then
        pull_isaac_sim_image
    else
        echo "⚠ Skipping Isaac Sim image pull (no GPU detected)"
    fi
    
    echo ""
    echo "=========================================="
    echo "Installation completed successfully!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Log out and back in (or restart) to apply docker group changes"
    echo "2. Run './run_isaac_sim.sh' to start Isaac Sim with GUI"
    echo "3. Run './run_isaac_sim_headless.sh' to start Isaac Sim in headless mode"
    echo "4. Use 'docker-compose up isaac-sim' for advanced container management"
    echo ""
    echo "Data will be persisted in:"
    echo "  - ~/isaac-sim-data"
    echo "  - ~/isaac-sim-cache"
    echo ""
    echo "For more information, visit:"
    echo "  - Isaac Sim Documentation: https://docs.omniverse.nvidia.com/isaacsim/"
    echo "  - NVIDIA NGC: https://ngc.nvidia.com/"
}

# Run main function
main "$@"