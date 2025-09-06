#!/bin/bash
# Pipeline Verification Script - After Security Lockdown
# Verify the pipeline works with restricted outbound rules

echo "=== Pipeline Verification with Locked Down Security ==="
echo "Testing at $(date)"
echo ""

# Your VM IPs
KAFKA_VM_IP="172.31.36.12"
DB_VM_IP="172.31.39.1"
PROC_VM_IP="172.31.36.45"
PRODUCER_VM_IP="172.31.33.195"

# Public IPs for health checks
PROC_PUBLIC_IP="3.16.165.131"
PRODUCER_PUBLIC_IP="18.222.84.164"

echo "Testing with restricted outbound security rules..."
echo ""

# Test 1: Health endpoints (external access)
echo "=== Test 1: Health Endpoints ==="
echo "Producer health check:"
curl -s http://$PRODUCER_PUBLIC_IP:8000/health | python3 -m json.tool 2>/dev/null || echo "❌ Producer health check failed"
echo ""

echo "Processor health check:"
curl -s http://$PROC_PUBLIC_IP:8001/health | python3 -m json.tool 2>/dev/null || echo "❌ Processor health check failed"
echo ""

# Test 2: Check if containers are still running
echo "=== Test 2: Container Status ==="
echo "Kafka VM containers:"
ssh ubuntu@$KAFKA_VM_IP "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
echo ""

echo "Database VM containers:"
ssh ubuntu@$DB_VM_IP "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
echo ""

echo "Processor VM containers:"
ssh ubuntu@$PROC_VM_IP "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
echo ""

echo "Producer VM containers:"
ssh ubuntu@$PRODUCER_VM_IP "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
echo ""

# Test 3: Check recent logs for errors
echo "=== Test 3: Recent Container Logs ==="
echo "Producer logs (last 5 lines):"
ssh ubuntu@$PRODUCER_VM_IP "docker logs --tail 5 metals-producer 2>/dev/null || echo 'No producer logs'"
echo ""

echo "Processor logs (last 5 lines):"
ssh ubuntu@$PROC_VM_IP "docker logs --tail 5 metals-processor 2>/dev/null || echo 'No processor logs'"
echo ""

# Test 4: Test Kafka connectivity
echo "=== Test 4: Kafka Connectivity ==="
echo "Checking Kafka topics:"
ssh ubuntu@$KAFKA_VM_IP "docker exec kafka kafka-topics --list --bootstrap-server localhost:9092 2>/dev/null || echo '❌ Kafka topics check failed'"
echo ""

echo "Testing Kafka message flow (will timeout after 10 seconds):"
ssh ubuntu@$KAFKA_VM_IP "timeout 10 docker exec kafka kafka-console-consumer --topic metals-prices --bootstrap-server localhost:9092 --max-messages 2 2>/dev/null || echo 'Timeout or no messages'"
echo ""

# Test 5: Test MongoDB connectivity and data
echo "=== Test 5: MongoDB Data Verification ==="
echo "MongoDB connection test:"
ssh ubuntu@$DB_VM_IP "docker exec mongodb mongosh -u admin -p password123 --authenticationDatabase admin --eval 'db.adminCommand(\"ping\")' 2>/dev/null | grep '\"ok\" : 1' && echo '✅ MongoDB connection OK' || echo '❌ MongoDB connection failed'"
echo ""

echo "Recent data count:"
ssh ubuntu@$DB_VM_IP "docker exec mongodb mongosh -u admin -p password123 --authenticationDatabase admin metals --eval 'print(\"Total documents:\", db.prices.countDocuments({}))' 2>/dev/null || echo '❌ MongoDB query failed'"
echo ""

echo "Sample recent document:"
ssh ubuntu@$DB_VM_IP "docker exec mongodb mongosh -u admin -p password123 --authenticationDatabase admin metals --eval 'printjson(db.prices.findOne({}, {metal: 1, price: 1, timestamp: 1, _id: 0}))' 2>/dev/null || echo '❌ MongoDB sample query failed'"
echo ""

# Test 6: Network connectivity between VMs
echo "=== Test 6: Inter-VM Network Connectivity ==="
echo "Processor → Kafka connectivity:"
ssh ubuntu@$PROC_VM_IP "timeout 3 bash -c '</dev/tcp/$KAFKA_VM_IP/9092' && echo '✅ Processor can reach Kafka' || echo '❌ Processor cannot reach Kafka'"

echo "Processor → MongoDB connectivity:"
ssh ubuntu@$PROC_VM_IP "timeout 3 bash -c '</dev/tcp/$DB_VM_IP/27017' && echo '✅ Processor can reach MongoDB' || echo '❌ Processor cannot reach MongoDB'"

echo "Producer → Kafka connectivity:"
ssh ubuntu@$PRODUCER_VM_IP "timeout 3 bash -c '</dev/tcp/$KAFKA_VM_IP/9092' && echo '✅ Producer can reach Kafka' || echo '❌ Producer cannot reach Kafka'"
echo ""

# Test 7: Check if outbound restrictions are working
echo "=== Test 7: Outbound Restrictions Verification ==="
echo "Testing that restricted outbound rules are working..."

echo "Producer trying to reach external site (should fail):"
ssh ubuntu@$PRODUCER_VM_IP "timeout 5 curl -s http://google.com >/dev/null 2>&1 && echo '❌ Outbound restriction FAILED - can still reach internet' || echo '✅ Outbound restriction working - cannot reach external sites'"

echo "Processor trying to reach external site (should fail):"
ssh ubuntu@$PROC_VM_IP "timeout 5 curl -s http://google.com >/dev/null 2>&1 && echo '❌ Outbound restriction FAILED - can still reach internet' || echo '✅ Outbound restriction working - cannot reach external sites'"
echo ""

# Test 8: End-to-end data flow verification
echo "=== Test 8: End-to-End Data Flow ==="
echo "Getting current document count..."
BEFORE_COUNT=$(ssh ubuntu@$DB_VM_IP "docker exec mongodb mongosh -u admin -p password123 --authenticationDatabase admin metals --eval 'db.prices.countDocuments({})' --quiet 2>/dev/null" | tail -1)
echo "Documents before: $BEFORE_COUNT"

echo "Waiting 90 seconds for new data to flow through pipeline..."
sleep 90

AFTER_COUNT=$(ssh ubuntu@$DB_VM_IP "docker exec mongodb mongosh -u admin -p password123 --authenticationDatabase admin metals --eval 'db.prices.countDocuments({})' --quiet 2>/dev/null" | tail -1)
echo "Documents after: $AFTER_COUNT"

if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
    echo "✅ END-TO-END PIPELINE IS WORKING! New data processed: $((AFTER_COUNT - BEFORE_COUNT)) documents"
else
    echo "❌ Pipeline may not be working - no new documents processed"
fi

echo ""
echo "=== Verification Complete ==="
echo "Summary:"
echo "- Health endpoints: Check above results"
echo "- Container status: Check above results"
echo "- Network connectivity: Check above results"
echo "- Security restrictions: Check above results"
echo "- Data flow: Check above results"
echo ""
echo "If all tests show ✅, your pipeline is working correctly with locked-down security!"
