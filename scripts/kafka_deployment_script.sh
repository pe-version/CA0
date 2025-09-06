#!/bin/bash
# Kafka + Zookeeper Deployment Script
# Run this on vm-kafka (172.31.36.12)

set -e

echo "=== Starting Kafka deployment at $(date) ==="

# Get current VM IP address
VM_IP=$(hostname -I | awk '{print $1}')
echo "Using VM IP: $VM_IP"

# Stop and remove existing containers if they exist
echo "Cleaning up existing containers..."
docker stop zookeeper kafka 2>/dev/null || true
docker rm zookeeper kafka 2>/dev/null || true

# Start Zookeeper
echo "Starting Zookeeper..."
docker run -d \
  --name zookeeper \
  -p 2181:2181 \
  -e ZOOKEEPER_CLIENT_PORT=2181 \
  -e ZOOKEEPER_TICK_TIME=2000 \
  -e ZOOKEEPER_SYNC_LIMIT=2 \
  --restart unless-stopped \
  confluentinc/cp-zookeeper:7.4.0

# Wait for Zookeeper to start
echo "Waiting for Zookeeper to start..."
sleep 30

# Start Kafka
echo "Starting Kafka..."
docker run -d \
  --name kafka \
  -p 9092:9092 \
  -e KAFKA_BROKER_ID=1 \
  -e KAFKA_ZOOKEEPER_CONNECT=localhost:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092,PLAINTEXT_HOST://$VM_IP:9092 \
  -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
  -e KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true \
  --restart unless-stopped \
  confluentinc/cp-kafka:7.4.0

# Wait for Kafka to start
echo "Waiting for Kafka to start..."
sleep 45

# Create metals-prices topic
echo "Creating metals-prices topic..."
docker exec kafka kafka-topics --create \
  --topic metals-prices \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

# Verify topic creation
echo "Verifying topic creation..."
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Show container status
echo "Container status:"
docker ps

echo "=== Kafka deployment completed at $(date) ==="
echo "Kafka is available at: $VM_IP:9092"
echo "Zookeeper is available at: $VM_IP:2181"