#!/bin/bash
# Docker Installation Script for Ubuntu 22.04
# Run this on all VMs (vm-kafka, vm-db, vm-proc, vm-producer)

set -e  # Exit on any error

echo "=== Starting Docker Installation at $(date) ==="

# Update package index
echo "Updating package index..."
sudo apt update

# Install prerequisite packages
echo "Installing prerequisite packages..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo "Setting up Docker repository..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
echo "Updating package index with Docker repository..."
sudo apt update

# Install Docker Engine
echo "Installing Docker Engine..."
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
echo "Adding user to docker group..."
sudo usermod -aG docker $USER
sudo usermod -aG docker ubuntu

# Start and enable Docker service
echo "Starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Install Docker Compose manually
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
echo "Verifying Docker installation..."
docker --version
docker-compose --version

echo "=== Docker installation completed at $(date) ==="
echo "NOTE: You must logout and back in for docker group changes to take effect"
echo "Then test with: docker ps"