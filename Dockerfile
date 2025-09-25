# Isaac Sim 4.0 Custom Docker Environment
# Based on NVIDIA Isaac Sim official image with additional tools and configurations

FROM nvcr.io/nvidia/isaac-sim:4.0.0

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONPATH=/isaac-sim/python_packages:${PYTHONPATH}
ENV ISAAC_SIM=/isaac-sim

# Update system and install additional packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    tmux \
    python3-pip \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install additional Python packages for development
RUN pip3 install --no-cache-dir \
    jupyter \
    matplotlib \
    seaborn \
    opencv-python \
    pillow \
    scipy \
    scikit-learn \
    pandas \
    tqdm

# Create workspace directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Copy any local scripts or configurations
COPY scripts/ /workspace/scripts/ 2>/dev/null || true

# Set up proper permissions
RUN chmod -R 755 /workspace

# Create directories for data persistence
RUN mkdir -p /isaac-sim/data /isaac-sim/cache

# Expose common ports for web interfaces and debugging
EXPOSE 8080 8888 6006

# Default command - can be overridden
CMD ["/isaac-sim/isaac-sim.sh"]