#!/bin/bash

# Example usage script for Isaac Sim Docker container
# This script demonstrates how to use the Isaac Sim container after setup

set -e

echo "=== Isaac Sim Docker Container Example Usage ==="
echo ""

# Check if setup has been completed
if ! docker images | grep -q "isaac-sim"; then
    echo "Error: Isaac Sim container not found. Please run './setup_isaac_sim.sh setup' first."
    exit 1
fi

echo "1. Running Isaac Sim container in interactive mode..."
echo "   Command: ./setup_isaac_sim.sh run"
echo ""

echo "2. Inside the container, you can run:"
echo "   - Isaac Sim GUI: ./isaac-sim.sh"
echo "   - Headless with livestream: ./runheadless.sh -v"
echo "   - Python API: ./python.sh"
echo ""

echo "3. To run headless mode directly:"
echo "   Command: ./setup_isaac_sim.sh headless"
echo ""

echo "4. Example Python script inside container:"
echo "   ./python.sh -c \"import omni.isaac.core; print('Isaac Sim Python API loaded')\""
echo ""

echo "5. For development, mount your code directory:"
echo "   Add: -v /path/to/your/code:/workspace:rw"
echo "   to the docker run command in setup_isaac_sim.sh"
echo ""

echo "=== Quick Test (if container is available) ==="
if docker images | grep -q "nvcr.io/nvidia/isaac-sim:5.0.0"; then
    echo "✓ Isaac Sim 5.0.0 container is available"
else
    echo "✗ Isaac Sim 5.0.0 container not found - run setup first"
fi

echo ""
echo "For more information, see README.md or run './setup_isaac_sim.sh help'"