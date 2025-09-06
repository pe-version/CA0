#!/bin/bash
# Pipeline Verification Script
# Run this after all services are deployed

set -e

echo "=== Starting Pipeline Verification at $(date) ==="

# Configuration - UPDATE THESE IPs TO MATCH YOUR VMs
KAFKA_VM_IP="172.31.36.12"
DB_VM_IP="172.31.39.1"
PROC_VM_IP="172.31.36.45"
PRODUCER_VM_IP="172.31.33.195"

echo "Checking all services..."

# Test 1: Check Kafka topics
echo "1. Checking Kafka topics..."
ssh ubuntu@$KAFKA_VM_IP "docker exec kafka kafka-topics --list --bootstrap-server localhost:9092"

# Test 2: Check producer is sending messages
echo "2. Checking producer health..."
curl -s http://$PRODUCER_VM_IP:8000/health | python3 -m json.tool

# Test 3: Check processor is running
echo "3. Checking processor health..."
curl -s http://$PROC_VM_IP:8001/health | python3 -m json.tool

# Test 4: Check messages in Kafka
echo "4. Checking messages in Kafka topic..."
ssh ubuntu@$KAFKA_VM_IP "timeout 10 docker exec kafka kafka-console-consumer --topic metals-prices --bootstrap-server localhost:9092 --max-messages 3"

# Test 5: Check MongoDB data
echo "5. Checking MongoDB data..."
ssh ubuntu@$DB_VM_IP "docker exec mongodb mongosh -u admin -p password123 --authenticationDatabase admin metals --eval 'db.prices.find().limit(3)'"

# Test 6: Count total documents
echo "6. Counting total documents in MongoDB..."
ssh ubuntu@$DB_VM_IP "docker exec mongodb mongosh -u admin -p password123 --authenticationDatabase admin metals --eval 'db.prices.countDocuments({})'"

# Test 7: Check all containers are running
echo "7. Checking all containers status..."
echo "Kafka VM:"
ssh ubuntu@$KAFKA_VM_IP "docker ps"
echo ""
echo "Database VM:"
ssh ubuntu@$DB_VM_IP "docker ps"
echo ""
echo "Processor VM:"
ssh ubuntu@$PROC_VM_IP "docker ps"
echo ""
echo "Producer VM:"
ssh ubuntu@$PRODUCER_VM_IP "docker ps"

echo "=== Pipeline Verification completed at $(date) ==="
echo ""
echo "If all tests passed, your pipeline is working correctly!"
echo "Data flow: Producer -> Kafka -> Processor -> MongoDB"