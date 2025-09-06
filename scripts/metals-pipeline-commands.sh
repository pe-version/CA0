#!/bin/bash
# Metals Price Pipeline - Manual Docker Deployment
# No YAML files - individual container commands

# =============================================================================
# STEP 1: CREATE DOCKER NETWORK (run on any VM, but typically Kafka VM)
# =============================================================================
docker network create metals-pipeline-network

# =============================================================================
# KAFKA VM - Zookeeper and Kafka
# =============================================================================

# Start Zookeeper
docker run -d \
  --name zookeeper \
  --network metals-pipeline-network \
  -p 2181:2181 \
  -e ZOOKEEPER_CLIENT_PORT=2181 \
  -e ZOOKEEPER_TICK_TIME=2000 \
  -e ZOOKEEPER_SYNC_LIMIT=2 \
  --restart unless-stopped \
  confluentinc/cp-zookeeper:7.4.0

# Wait for Zookeeper to start (30 seconds)
sleep 30

# Start Kafka
docker run -d \
  --name kafka \
  --network metals-pipeline-network \
  -p 9092:9092 \
  -e KAFKA_BROKER_ID=1 \
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092,PLAINTEXT_HOST://YOUR_KAFKA_VM_IP:9092 \
  -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
  -e KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true \
  --restart unless-stopped \
  confluentinc/cp-kafka:7.4.0

# Create Kafka topic for metals prices
sleep 30
docker exec kafka kafka-topics --create \
  --topic metals-prices \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

# =============================================================================
# DB VM - MongoDB
# =============================================================================

# Start MongoDB
docker run -d \
  --name mongodb \
  --network metals-pipeline-network \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=password123 \
  -v mongodb_data:/data/db \
  --restart unless-stopped \
  mongo:6.0

# =============================================================================
# PROC VM - Consumer/Processor
# =============================================================================

# Build custom processor image first (create Dockerfile separately)
# docker build -t metals-processor .

# Start Processor Container
docker run -d \
  --name metals-processor \
  --network metals-pipeline-network \
  -e KAFKA_BOOTSTRAP_SERVERS=YOUR_KAFKA_VM_IP:9092 \
  -e MONGODB_URI=mongodb://admin:password123@YOUR_DB_VM_IP:27017/metals?authSource=admin \
  -e KAFKA_TOPIC=metals-prices \
  --restart unless-stopped \
  metals-processor:latest

# =============================================================================
# PRODUCER VM (or run on separate VM) - Price Producer
# =============================================================================

# Build custom producer image first (create Dockerfile separately)  
# docker build -t metals-producer .

# Start Producer Container
docker run -d \
  --name metals-producer \
  --network metals-pipeline-network \
  -e KAFKA_BOOTSTRAP_SERVERS=YOUR_KAFKA_VM_IP:9092 \
  -e KAFKA_TOPIC=metals-prices \
  -e API_KEY=your_metals_api_key \
  -e FETCH_INTERVAL=300 \
  --restart unless-stopped \
  metals-producer:latest

# =============================================================================
# VERIFICATION COMMANDS
# =============================================================================

# Check all containers are running
docker ps

# Check network connectivity
docker network inspect metals-pipeline-network

# Test Kafka topic
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Check Kafka messages
docker exec kafka kafka-console-consumer \
  --topic metals-prices \
  --from-beginning \
  --bootstrap-server localhost:9092

# Check MongoDB connection
docker exec mongodb mongosh --eval "db.adminCommand('listCollections')"

# View container logs
docker logs zookeeper
docker logs kafka  
docker logs mongodb
docker logs metals-processor
docker logs metals-producer

# =============================================================================
# CLEANUP COMMANDS (if needed)
# =============================================================================

# Stop all containers
docker stop zookeeper kafka mongodb metals-processor metals-producer

# Remove containers
docker rm zookeeper kafka mongodb metals-processor metals-producer

# Remove network
docker network rm metals-pipeline-network

# Remove volumes (WARNING: deletes data)
docker volume rm mongodb_data