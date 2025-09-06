#!/bin/bash
# Processor Deployment Script
# Run this on vm-proc (172.31.36.45)

set -e

echo "=== Starting Processor deployment at $(date) ==="

# Configuration - UPDATE THESE IPs TO MATCH YOUR VMs
KAFKA_VM_IP="172.31.36.12"    # Replace with your Kafka VM IP
DB_VM_IP="172.31.39.1"        # Replace with your Database VM IP

echo "Using Kafka VM IP: $KAFKA_VM_IP"
echo "Using Database VM IP: $DB_VM_IP"

# Navigate to processor directory
cd ~/processor

# Stop and remove existing container if it exists
echo "Cleaning up existing containers..."
docker stop metals-processor 2>/dev/null || true
docker rm metals-processor 2>/dev/null || true

# Remove existing image to force rebuild
docker rmi metals-processor 2>/dev/null || true

# Build processor image
echo "Building processor image..."
docker build -t metals-processor .

# Run processor container
echo "Starting processor container..."
docker run -d \
  --name metals-processor \
  -p 8001:8001 \
  -e KAFKA_BOOTSTRAP_SERVERS="$KAFKA_VM_IP:9092" \
  -e KAFKA_TOPIC="metals-prices" \
  -e KAFKA_GROUP_ID="metals-processor-group" \
  -e MONGODB_URI="mongodb://admin:password123@$DB_VM_IP:27017/metals?authSource=admin" \
  -e MONGODB_DATABASE="metals" \
  -e MONGODB_COLLECTION="prices" \
  -e LOG_LEVEL="INFO" \
  --restart unless-stopped \
  metals-processor

# Wait for container to start
echo "Waiting for processor to start..."
sleep 10

# Show container status
echo "Container status:"
docker ps

# Show processor logs (last 20 lines)
echo "Processor logs (last 20 lines):"
docker logs --tail 20 metals-processor

# Test health endpoint
echo "Testing processor health endpoint..."
sleep 5
curl -s http://localhost:8001/health | python3 -m json.tool || echo "Health check failed"

echo "=== Processor deployment completed at $(date) ==="
echo "Processor is running on port 8001"
echo "Health endpoint: http://$(hostname -I | awk '{print $1}'):8001/health"
echo "Metrics endpoint: http://$(hostname -I | awk '{print $1}'):8001/metrics"