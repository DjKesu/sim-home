#!/bin/bash

# NVIDIA Isaac Sim Docker Setup Script
# This script sets up Docker and NVIDIA Container Toolkit for running Isaac Sim containers

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user."
        exit 1
    fi
}

# Check system requirements
check_system_requirements() {
    print_info "Checking system requirements..."
    
    # Check for NVIDIA GPU
    if ! nvidia-smi &> /dev/null; then
        print_error "NVIDIA GPU driver not found. Please ensure NVIDIA drivers are installed."
        print_info "Visit: https://docs.nvidia.com/cuda/cuda-installation-guide-linux/"
        exit 1
    fi
    
    print_success "NVIDIA GPU driver found"
    nvidia-smi
}

# Install Docker
install_docker() {
    print_info "Installing Docker..."
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        print_warning "Docker is already installed"
        docker --version
        return 0
    fi
    
    # Download and run Docker installation script
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    print_success "Docker installed successfully"
}

# Configure Docker post-installation
configure_docker() {
    print_info "Configuring Docker post-installation..."
    
    # Add docker group if it doesn't exist
    if ! getent group docker > /dev/null 2>&1; then
        sudo groupadd docker
    fi
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    print_success "Docker configuration completed"
    print_warning "You may need to log out and log back in for group changes to take effect"
}

# Verify Docker installation
verify_docker() {
    print_info "Verifying Docker installation..."
    
    # Try to run hello-world container
    if docker run hello-world &> /dev/null; then
        print_success "Docker verification successful"
    else
        print_error "Docker verification failed. You may need to log out and log back in."
        print_info "Or try running: newgrp docker"
        exit 1
    fi
}

# Install NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
    print_info "Installing NVIDIA Container Toolkit..."
    
    # Configure the repository
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
        && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
        && \
        sudo apt-get update
    
    # Install the NVIDIA Container Toolkit packages
    sudo apt-get install -y nvidia-container-toolkit
    sudo systemctl restart docker
    
    # Configure the container runtime
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
    
    print_success "NVIDIA Container Toolkit installed successfully"
}

# Verify NVIDIA Container Toolkit
verify_nvidia_container_toolkit() {
    print_info "Verifying NVIDIA Container Toolkit..."
    
    if docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi &> /dev/null; then
        print_success "NVIDIA Container Toolkit verification successful"
    else
        print_error "NVIDIA Container Toolkit verification failed"
        exit 1
    fi
}

# Pull Isaac Sim container
pull_isaac_sim_container() {
    print_info "Pulling Isaac Sim container..."
    docker pull nvcr.io/nvidia/isaac-sim:5.0.0
    print_success "Isaac Sim container pulled successfully"
}

# Create cache directories
create_cache_directories() {
    print_info "Creating cache directories..."
    
    mkdir -p ~/docker/isaac-sim/cache/kit
    mkdir -p ~/docker/isaac-sim/cache/ov
    mkdir -p ~/docker/isaac-sim/cache/pip
    mkdir -p ~/docker/isaac-sim/cache/glcache
    mkdir -p ~/docker/isaac-sim/cache/computecache
    mkdir -p ~/docker/isaac-sim/logs
    mkdir -p ~/docker/isaac-sim/data
    mkdir -p ~/docker/isaac-sim/documents
    
    print_success "Cache directories created"
}

# Run Isaac Sim container
run_isaac_sim_container() {
    print_info "Starting Isaac Sim container..."
    
    docker run --name isaac-sim --entrypoint bash -it --runtime=nvidia --gpus all \
        -e "ACCEPT_EULA=Y" \
        -e "PRIVACY_CONSENT=Y" \
        --rm --network=host \
        -v ~/docker/isaac-sim/cache/kit:/isaac-sim/kit/cache:rw \
        -v ~/docker/isaac-sim/cache/ov:/root/.cache/ov:rw \
        -v ~/docker/isaac-sim/cache/pip:/root/.cache/pip:rw \
        -v ~/docker/isaac-sim/cache/glcache:/root/.cache/nvidia/GLCache:rw \
        -v ~/docker/isaac-sim/cache/computecache:/root/.nv/ComputeCache:rw \
        -v ~/docker/isaac-sim/logs:/root/.nvidia-omniverse/logs:rw \
        -v ~/docker/isaac-sim/data:/root/.local/share/ov/data:rw \
        -v ~/docker/isaac-sim/documents:/root/Documents:rw \
        nvcr.io/nvidia/isaac-sim:5.0.0
}

# Main function
main() {
    print_info "Starting NVIDIA Isaac Sim Docker setup..."
    
    case "${1:-setup}" in
        "setup")
            check_root
            check_system_requirements
            install_docker
            configure_docker
            verify_docker
            install_nvidia_container_toolkit
            verify_nvidia_container_toolkit
            pull_isaac_sim_container
            create_cache_directories
            print_success "Setup completed successfully!"
            print_info "You can now run Isaac Sim with: $0 run"
            ;;
        "run")
            run_isaac_sim_container
            ;;
        "headless")
            print_info "Starting Isaac Sim in headless mode with livestream..."
            docker run --name isaac-sim-headless --runtime=nvidia --gpus all \
                -e "ACCEPT_EULA=Y" \
                -e "PRIVACY_CONSENT=Y" \
                --rm --network=host \
                -v ~/docker/isaac-sim/cache/kit:/isaac-sim/kit/cache:rw \
                -v ~/docker/isaac-sim/cache/ov:/root/.cache/ov:rw \
                -v ~/docker/isaac-sim/cache/pip:/root/.cache/pip:rw \
                -v ~/docker/isaac-sim/cache/glcache:/root/.cache/nvidia/GLCache:rw \
                -v ~/docker/isaac-sim/cache/computecache:/root/.nv/ComputeCache:rw \
                -v ~/docker/isaac-sim/logs:/root/.nvidia-omniverse/logs:rw \
                -v ~/docker/isaac-sim/data:/root/.local/share/ov/data:rw \
                -v ~/docker/isaac-sim/documents:/root/Documents:rw \
                nvcr.io/nvidia/isaac-sim:5.0.0 \
                ./runheadless.sh -v
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  setup     Install Docker and NVIDIA Container Toolkit, pull Isaac Sim container (default)"
            echo "  run       Run Isaac Sim container with interactive bash session"
            echo "  headless  Run Isaac Sim in headless mode with livestream"
            echo "  help      Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  PRIVACY_USERID  Optional email for tagging session logs"
            ;;
        *)
            print_error "Unknown command: $1"
            print_info "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"