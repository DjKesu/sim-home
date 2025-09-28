#!/bin/bash

# Cross-platform installation script for Genesis simulation
# Supports Linux, macOS, and Windows (WSL)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
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

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    print_status "Detected OS: $OS"
}

# Check for required dependencies
check_dependencies() {
    print_status "Checking system dependencies..."
    
    # Check for Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        print_error "git is required but not installed"
        exit 1
    fi
    
    print_success "All required dependencies found"
}

# Install uv if not already installed
install_uv() {
    if ! command -v uv &> /dev/null; then
        print_status "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        
        # Add uv to PATH for this session
        export PATH="$HOME/.local/bin:$PATH"
        
        # Verify installation
        if command -v uv &> /dev/null; then
            print_success "uv installed successfully"
        else
            print_error "Failed to install uv"
            exit 1
        fi
    else
        print_success "uv already installed"
    fi
}

# Create and setup virtual environment
setup_environment() {
    print_status "Creating virtual environment with uv..."
    
    # Remove existing environment if it exists
    if [ -d "genesis_sim_home" ]; then
        print_warning "Removing existing virtual environment..."
        rm -rf genesis_sim_home
    fi
    
    # Create new environment
    uv venv genesis_sim_home --python 3.11
    
    # Activate the virtual environment
    print_status "Activating virtual environment..."
    source genesis_sim_home/bin/activate
    
    print_success "Virtual environment created and activated"
}

# Install Genesis and dependencies
install_packages() {
    print_status "Installing Genesis..."
    uv pip install git+https://github.com/Genesis-Embodied-AI/Genesis.git
    
    print_status "Installing dependencies..."
    if [ -f "requirements.txt" ]; then
        uv pip install -r requirements.txt
    else
        print_warning "requirements.txt not found, installing basic dependencies..."
        uv pip install torch torchvision torchaudio trimesh numpy
    fi
    
    print_success "All packages installed successfully"
}

# Setup openpi submodule
setup_openpi() {
    print_status "Setting up openpi submodule..."
    
    if [ -f ".gitmodules" ]; then
        print_status "Initializing and updating submodules..."
        git submodule update --init --recursive
        
        # Check if openpi directory exists and has content
        if [ -d "openpi" ] && [ "$(ls -A openpi)" ]; then
            print_success "OpenPI submodule initialized successfully. Check readme to setup complete environment."
        else
            print_warning "OpenPI submodule may not be properly initialized"
        fi
    else
        print_warning "No .gitmodules file found - skipping submodule setup"
    fi
}

# Create output directory
create_directories() {
    print_status "Creating output directories..."
    mkdir -p output
    mkdir -p assets
    print_success "Directories created"
}

# Main installation function
main() {
    print_status "Starting Genesis simulation setup..."
    
    detect_os
    check_dependencies
    install_uv
    setup_environment
    install_packages
    setup_openpi
    create_directories
    
    print_success "Setup complete!"
    echo ""
    print_status "To activate the environment in future sessions, run:"
    echo "source genesis_sim_home/bin/activate"
    echo ""
    print_status "To run the simulation:"
    echo "python simulation.py"
}

# Run main function
main "$@"
