#!/bin/bash
# Producer Deployment Script
# Run this on vm-producer (172.31.33.195)

set -e

echo "=== Starting Producer deployment at $(date) ==="

# Configuration - UPDATE THESE IPs TO MATCH YOUR VMs
KAFKA_VM_IP="172.31.36.12"    # Replace with your Kafka VM IP

echo "Using Kafka VM IP: $KAFKA_VM_IP"

# Navigate to producer directory
cd ~/producer

# Stop and remove existing container if it exists
echo "Cleaning up existing containers..."
docker stop metals-producer 2>/dev/null || true
docker rm metals-producer 2>/dev/null || true

# Remove existing image to force rebuild
docker rmi metals-producer 2>/dev/null || true

# Build producer image
echo "Building producer image..."
docker build -t metals-producer .

# Run producer container
echo "Starting producer container..."
docker run -d \
  --name metals-producer \
  -p 8000:8000 \
  -e KAFKA_BOOTSTRAP_SERVERS="$KAFKA_VM_IP:9092" \
  -e KAFKA_TOPIC="metals-prices" \
  -e API_KEY="" \
  -e FETCH_INTERVAL="60" \
  -e LOG_LEVEL="INFO" \
  --restart unless-stopped \
  metals-producer

# Wait for container to start
echo "Waiting for producer to start..."
sleep 10

# Show container status
echo "Container status:"
docker ps

# Show producer logs (last 20 lines)
echo "Producer logs (last 20 lines):"
docker logs --tail 20 metals-producer

# Test health endpoint
echo "Testing producer health endpoint..."
sleep 5
curl -s http://localhost:8000/health | python3 -m json.tool || echo "Health check failed"

echo "=== Producer deployment completed at $(date) ==="
echo "Producer is running on port 8000"
echo "Health endpoint: http://$(hostname -I | awk '{print $1}'):8000/health"
echo "Metrics endpoint: http://$(hostname -I | awk '{print $1}'):8000/metrics"
echo "Sending data to Kafka topic: metals-prices"