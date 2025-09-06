#!/bin/bash
# Master Deployment Script for Metals Price Pipeline
# This script coordinates the deployment across all VMs

set -e

echo "=== Master Deployment Script for Metals Price Pipeline ==="
echo "Starting deployment at $(date)"
echo ""

# Configuration - UPDATE THESE TO MATCH YOUR ACTUAL VM IPs
KAFKA_VM_IP="172.31.36.12"      # vm-kafka
DB_VM_IP="172.31.39.1"          # vm-db  
PROC_VM_IP="172.31.36.45"       # vm-proc
PRODUCER_VM_IP="172.31.33.195"  # vm-producer

# SSH key path (update if different)
SSH_KEY="~/.ssh/id_rsa"

echo "Using VM Configuration:"
echo "  Kafka VM:    $KAFKA_VM_IP"
echo "  Database VM: $DB_VM_IP"
echo "  Processor VM: $PROC_VM_IP"
echo "  Producer VM:  $PRODUCER_VM_IP"
echo ""

# Function to run command on remote VM
run_on_vm() {
    local vm_ip=$1
    local vm_name=$2
    local command=$3
    echo ">>> Running on $vm_name ($vm_ip): $command"
    ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$vm_ip "$command"
}

# Function to copy and run script on VM
deploy_to_vm() {
    local vm_ip=$1
    local vm_name=$2
    local script_name=$3
    echo "=== Deploying $script_name to $vm_name ==="
    
    # Copy script to VM
    scp -i $SSH_KEY scripts/$script_name ubuntu@$vm_ip:~/
    
    # Make executable and run
    run_on_vm $vm_ip $vm_name "chmod +x ~/$script_name && ~/$script_name"
    echo ""
}

# Phase 1: Install Docker on all VMs
echo "PHASE 1: Installing Docker on all VMs..."
echo "This may take several minutes per VM..."

deploy_to_vm $KAFKA_VM_IP "Kafka VM" "01-docker-install.sh"
deploy_to_vm $DB_VM_IP "Database VM" "01-docker-install.sh"  
deploy_to_vm $PROC_VM_IP "Processor VM" "01-docker-install.sh"
deploy_to_vm $PRODUCER_VM_IP "Producer VM" "01-docker-install.sh"

echo "Waiting 30 seconds for Docker services to fully start..."
sleep 30

# Phase 2: Deploy infrastructure services (Kafka + MongoDB)
echo "PHASE 2: Deploying infrastructure services..."

echo "Deploying MongoDB..."
deploy_to_vm $DB_VM_IP "Database VM" "03-deploy-mongodb.sh"

echo "Deploying Kafka + Zookeeper..."
deploy_to_vm $KAFKA_VM_IP "Kafka VM" "02-deploy-kafka.sh"

echo "Waiting 60 seconds for services to stabilize..."
sleep 60

# Phase 3: Deploy application code
echo "PHASE 3: Copying application code to VMs..."

# Copy processor code
echo "Copying processor code..."
ssh -i $SSH_KEY ubuntu@$PROC_VM_IP "mkdir -p ~/processor"
scp -i $SSH_KEY -r processor/* ubuntu@$PROC_VM_IP:~/processor/

# Copy producer code  
echo "Copying producer code..."
ssh -i $SSH_KEY ubuntu@$PRODUCER_VM_IP "mkdir -p ~/producer"
scp -i $SSH_KEY -r producer/* ubuntu@$PRODUCER_VM_IP:~/producer/

# Phase 4: Deploy applications
echo "PHASE 4: Deploying applications..."

echo "Deploying processor..."
deploy_to_vm $PROC_VM_IP "Processor VM" "04-deploy-processor.sh"

echo "Deploying producer..."
deploy_to_vm $PRODUCER_VM_IP "Producer VM" "05-deploy-producer.sh"

echo "Waiting 30 seconds for applications to start..."
sleep 30

# Phase 5: Verification
echo "PHASE 5: Running pipeline verification..."
echo "Copying verification script to local machine..."
cp scripts/06-verify-pipeline.sh ~/verify-pipeline.sh
chmod +x ~/verify-pipeline.sh

echo "Running verification (this may take a few minutes)..."
~/verify-pipeline.sh

# Phase 6: Security hardening
echo "PHASE 6: Applying security hardening to all VMs..."
echo "WARNING: This will disable SSH password authentication!"
echo "Make sure your SSH keys are working before proceeding."
read -p "Continue with security hardening? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    deploy_to_vm $KAFKA_VM_IP "Kafka VM" "07-security-hardening.sh"
    deploy_to_vm $DB_VM_IP "Database VM" "07-security-hardening.sh"
    deploy_to_vm $PROC_VM_IP "Processor VM" "07-security-hardening.sh"
    deploy_to_vm $PRODUCER_VM_IP "Producer VM" "07-security-hardening.sh"
    echo "Security hardening completed."
else
    echo "Skipping security hardening. Run 07-security-hardening.sh manually on each VM when ready."
fi

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo "Deployment finished at $(date)"
echo ""
echo "Service URLs:"
echo "  Producer Health:  http://$PRODUCER_VM_IP:8000/health"
echo "  Processor Health: http://$PROC_VM_IP:8001/health"
echo "  Kafka:            $KAFKA_VM_IP:9092"
echo "  MongoDB:          $DB_VM_IP:27017"
echo ""
echo "To monitor the pipeline:"
echo "  curl http://$PRODUCER_VM_IP:8000/metrics"
echo "  curl http://$PROC_VM_IP:8001/metrics"
echo ""
echo "To check data in MongoDB:"
echo "  ssh ubuntu@$DB_VM_IP"
echo "  docker exec mongodb mongosh -u admin -p password123 --authenticationDatabase admin metals --eval 'db.prices.find().limit(5)'"