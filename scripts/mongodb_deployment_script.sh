#!/bin/bash
# MongoDB Deployment Script
# Run this on vm-db (172.31.39.1)

set -e

echo "=== Starting MongoDB deployment at $(date) ==="

# Get current VM IP address
VM_IP=$(hostname -I | awk '{print $1}')
echo "Using VM IP: $VM_IP"

# Stop and remove existing container if it exists
echo "Cleaning up existing containers..."
docker stop mongodb 2>/dev/null || true
docker rm mongodb 2>/dev/null || true

# Remove existing volume if you want to start fresh
# docker volume rm mongodb_data 2>/dev/null || true

# Start MongoDB
echo "Starting MongoDB..."
docker run -d \
  --name mongodb \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=password123 \
  -v mongodb_data:/data/db \
  --restart unless-stopped \
  mongo:6.0

# Wait for MongoDB to start
echo "Waiting for MongoDB to start..."
sleep 20

# Test MongoDB connection
echo "Testing MongoDB connection..."
docker exec mongodb mongosh -u admin -p password123 --authenticationDatabase admin --eval "
use metals;
db.createCollection('prices');
db.prices.insertOne({
  'test': 'connection', 
  'timestamp': new Date(), 
  'message': 'MongoDB deployment successful'
});
db.prices.find();
"

# Show container status
echo "Container status:"
docker ps

# Show MongoDB logs (last 10 lines)
echo "MongoDB logs (last 10 lines):"
docker logs --tail 10 mongodb

echo "=== MongoDB deployment completed at $(date) ==="
echo "MongoDB is available at: $VM_IP:27017"
echo "Username: admin"
echo "Password: password123"
echo "Database: metals"
echo "Collection: prices"