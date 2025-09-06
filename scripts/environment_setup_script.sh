#!/bin/bash
# Environment Setup Script
# Run this on your local machine to prepare for deployment

set -e

echo "=== Environment Setup for Metals Price Pipeline ==="
echo "This script prepares your local environment for deployment"
echo ""

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "processor" ] || [ ! -d "producer" ]; then
    echo "ERROR: Please run this script from the CA0 project root directory"
    echo "Expected structure:"
    echo "  CA0/"
    echo "    ├── README.md"
    echo "    ├── processor/"
    echo "    ├── producer/"
    echo "    └── scripts/"
    exit 1
fi

# Create scripts directory if it doesn't exist
echo "Creating scripts directory..."
mkdir -p scripts

# Make all scripts executable
echo "Making scripts executable..."
chmod +x scripts/*.sh 2>/dev/null || echo "No scripts found in scripts/ directory yet"

# Check SSH key exists
echo "Checking SSH key configuration..."
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "WARNING: SSH private key not found at ~/.ssh/id_rsa"
    echo "You may need to:"
    echo "  1. Generate a new key: ssh-keygen -t rsa -b 4096"
    echo "  2. Update the SSH_KEY variable in 00-master-deploy.sh"
    echo ""
else
    echo "✓ SSH private key found"
fi

# Check if we can SSH to VMs (if IPs are configured)
echo "Checking VM connectivity..."
KAFKA_VM_IP="172.31.36.12"      # Update these with your actual IPs
DB_VM_IP="172.31.39.1"
PROC_VM_IP="172.31.36.45"
PRODUCER_VM_IP="172.31.33.195"

echo "Attempting to connect to VMs..."
echo "NOTE: Update the IP addresses in this script and 00-master-deploy.sh"

for vm_ip in $KAFKA_VM_IP $DB_VM_IP $PROC_VM_IP $PRODUCER_VM_IP; do
    echo -n "Testing $vm_ip... "
    if timeout 5 ssh -i ~/.ssh/id_rsa -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$vm_ip "echo 'connected'" 2>/dev/null; then
        echo "✓ Connected"
    else
        echo "✗ Failed to connect"
    fi
done

# Check required tools
echo ""
echo "Checking required tools..."

command -v ssh >/dev/null 2>&1 && echo "✓ ssh available" || echo "✗ ssh not found"
command -v scp >/dev/null 2>&1 && echo "✓ scp available" || echo "✗ scp not found"
command -v curl >/dev/null 2>&1 && echo "✓ curl available" || echo "✗ curl not found"

# Validate project structure
echo ""
echo "Validating project structure..."

check_file() {
    if [ -f "$1" ]; then
        echo "✓ $1"
    else
        echo "✗ $1 (missing)"
    fi
}

check_file "processor/Dockerfile"
check_file "processor/processor.py"
check_file "processor/requirements.txt"
check_file "producer/Dockerfile"
check_file "producer/producer.py"
check_file "producer/requirements.txt"

# Create deployment log directory
echo ""
echo "Creating deployment logs directory..."
mkdir -p logs

# Display next steps
echo ""
echo "=== Environment Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Update VM IP addresses in scripts/00-master-deploy.sh"
echo "2. Ensure all VMs are running and accessible via SSH"
echo "3. Run the master deployment script:"
echo "   ./scripts/00-master-deploy.sh 2>&1 | tee logs/deployment.log"
echo ""
echo "Alternative deployment (manual step-by-step):"
echo "1. Copy individual scripts to each VM"
echo "2. Run them in order: 01 -> 02,03 -> 04,05 -> 06 -> 07"
echo ""
echo "Troubleshooting:"
echo "- If SSH connections fail, check AWS Security Groups"
echo "- If deployment fails, check individual script logs"
echo "- Each script creates detailed output for debugging"