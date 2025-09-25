#!/bin/bash
# Launch Isaac Sim with GUI support
# This script sets up X11 forwarding and starts Isaac Sim in GUI mode

set -e

echo "Starting Isaac Sim with GUI..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Setup X11 forwarding
echo "Setting up X11 forwarding..."
./scripts/setup_x11.sh

# Create data directories if they don't exist
mkdir -p data cache workspace

# Start Isaac Sim with docker-compose
echo "Starting Isaac Sim container..."
docker-compose up isaac-sim