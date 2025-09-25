#!/bin/bash
# Launch Isaac Sim in headless mode (no GUI)
# Useful for batch processing, training, or server deployments

set -e

echo "Starting Isaac Sim in headless mode..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Create data directories if they don't exist
mkdir -p data cache workspace

# Start Isaac Sim headless with docker-compose
echo "Starting Isaac Sim container in headless mode..."
docker-compose up isaac-sim-headless