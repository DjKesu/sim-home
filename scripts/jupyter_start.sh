#!/bin/bash
# Start Jupyter notebook server inside Isaac Sim container
# Useful for interactive development and experimentation

set -e

echo "Starting Jupyter notebook server in Isaac Sim container..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Create workspace directory if it doesn't exist
mkdir -p workspace

# Run Jupyter in the custom Isaac Sim container
docker-compose run --rm -p 8888:8888 isaac-sim-custom \
    jupyter notebook \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --notebook-dir=/workspace

echo "Jupyter server will be available at http://localhost:8888"