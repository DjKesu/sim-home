#!/bin/bash
# Setup X11 forwarding for Isaac Sim GUI
# This script sets up the necessary X11 authentication for Docker containers

echo "Setting up X11 forwarding for Isaac Sim..."

# Create X11 authentication file
XAUTH=/tmp/.docker.xauth

# Remove existing auth file if it exists
if [ -f "$XAUTH" ]; then
    rm "$XAUTH"
fi

# Create new auth file
touch "$XAUTH"

# Generate X11 authentication entries
xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$XAUTH" nmerge -

# Set proper permissions
chmod 644 "$XAUTH"

echo "✓ X11 forwarding setup complete"
echo "Authentication file created at: $XAUTH"