# CA0 - Precious Metal Price Tracker

**Student:** [Your Name]  
**Course:** [Course Code]  
**Date:** September 4, 2025  
**Deadline:** [Your specific deadline]

## Project Overview

This project implements a complete IoT data pipeline for tracking precious metal prices using a cloud-native architecture. The system fetches real-time metal prices, processes them through a pub/sub messaging system, and stores the results in a NoSQL database.

## Reference Software Stack

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Cloud Provider** | AWS | - | Infrastructure hosting |
| **Operating System** | Ubuntu | 22.04 LTS (x86_64) | VM base OS |
| **Compute** | EC2 | t3.small | VM instances (~2 vCPU, 4GB RAM) |
| **Container Runtime** | Docker | 24.x | Application containerization |
| **Message Broker** | Apache Kafka | 3.7 | Pub/Sub messaging |
| **Coordination** | Apache ZooKeeper | 3.8 | Kafka cluster management |
| **Database** | MongoDB | 7.x | Document storage |
| **Application Framework** | Python FastAPI | Latest | Processor service |
| **HTTP Client** | Python requests/aiohttp | Latest | API data fetching |
| **Kafka Client** | confluent-kafka-python | Latest | Kafka integration |

## Infrastructure Architecture

### VM Layout
- **vm-kafka**: Kafka broker + ZooKeeper coordination service
- **vm-db**: MongoDB database server
- **vm-proc**: Data processor + producer containers

### Network Configuration
| VM | Purpose | Open Ports | Services |
|----|---------|------------|----------|
| vm-kafka | Message Broker | 22 (SSH), 9092 (Kafka), 2181 (ZooKeeper) | Kafka, ZooKeeper |
| vm-db | Database | 22 (SSH), 27017 (MongoDB) | MongoDB |
| vm-proc | Processing | 22 (SSH), 8000 (FastAPI - optional) | Processor, Producers |

### VM Specifications
- **Instance Type**: t3.small
- **vCPUs**: 2
- **RAM**: 4 GB
- **Storage**: 20 GB gp3 EBS
- **Region**: [Your chosen AWS region]
- **Availability Zone**: [Your chosen AZ]

## Data Flow Architecture

```
[Metal Price APIs] 
    ↓ (HTTP requests)
[Producer Containers] 
    ↓ (publish messages)
[Kafka Topic: metal-prices] 
    ↓ (consume messages)
[Processor Container] 
    ↓ (write documents)
[MongoDB Database]
```

### Data Flow Steps
1. **Producer**: Fetches metal prices from external APIs (Metals-API)
2. **Kafka**: Receives and queues price messages in `metal-prices` topic
3. **Processor**: Consumes messages, normalizes data, calculates deltas
4. **MongoDB**: Stores processed documents with timestamps and metadata

## MongoDB Document Schema

```json
{
  "_id": "ObjectId",
  "symbol": "XAU",
  "metal_name": "Gold",
  "price": {
    "value": 2345.67,
    "currency": "USD"
  },
  "source": "Metals-API",
  "timestamp_utc": "2025-09-01T14:30:00Z",
  "meta": {
    "change_pct_24h": 0.45,
    "unit": "troy_ounce"
  }
}
```

## External Dependencies

### APIs
- **Metals-API**: Primary source for precious metal prices
  - Endpoint: `https://metals-api.com/api/latest`
  - Authentication: API key required
  - Rate limits: [Based on your plan]

### Container Images
- **Kafka**: `confluentinc/cp-kafka:7.4.0`
- **ZooKeeper**: `confluentinc/cp-zookeeper:7.4.0`
- **MongoDB**: `mongo:7.0`
- **Python**: `python:3.11-slim` (for custom applications)

## Security Configuration

### Authentication
- SSH key-only access (password authentication disabled)
- MongoDB authentication enabled
- Kafka SASL/PLAIN authentication (if applicable)

### Network Security
- Security groups restrict inbound traffic to essential ports only
- No public access to database ports from internet
- Inter-VM communication through private subnets

### Container Security
- Containers run as non-root users where supported
- Minimal base images to reduce attack surface
- Regular security updates applied

## Environment Variables

### Producer Configuration
```bash
KAFKA_BOOTSTRAP=vm-kafka-ip:9092
KAFKA_TOPIC=metal-prices
METALS_API_URL=https://metals-api.com/api/latest
METALS_API_KEY=your_api_key_here
```

### Processor Configuration
```bash
KAFKA_BOOTSTRAP=vm-kafka-ip:9092
KAFKA_TOPIC=metal-prices
MONGODB_URL=mongodb://vm-db-ip:27017/metals
```

## Installation Steps

### Prerequisites
- AWS account with student credits activated
- SSH key pair generated
- Metals-API account and API key

### High-Level Deployment Process
1. **Infrastructure Setup**
   - Create 3 EC2 instances with Ubuntu 22.04
   - Configure security groups and networking
   - Set up SSH access

2. **Software Installation**
   - Install Docker on all VMs
   - Deploy Kafka + ZooKeeper on vm-kafka
   - Deploy MongoDB on vm-db
   - Deploy processor and producers on vm-proc

3. **Configuration**
   - Create Kafka topics
   - Configure MongoDB collections
   - Set up environment variables
   - Test connectivity between services

4. **Verification**
   - Run end-to-end data flow test
   - Verify data appears in MongoDB
   - Check all services are running and auto-restart

## Testing and Verification

### Verification Commands
```bash
# Check Kafka topic
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Check MongoDB data
docker exec mongodb mongo metals --eval "db.prices.find().limit(5)"

# Check producer logs
docker logs producer-container

# Check processor logs
docker logs processor-container
```

## VM Details

### vm-kafka
- **Instance ID**: [To be filled]
- **Private IP**: [To be filled]
- **Public IP**: [To be filled]
- **Security Group**: kafka-sg

### vm-db
- **Instance ID**: [To be filled]
- **Private IP**: [To be filled]
- **Public IP**: [To be filled]
- **Security Group**: db-sg

### vm-proc
- **Instance ID**: [To be filled]
- **Private IP**: [To be filled]
- **Public IP**: [To be filled]
- **Security Group**: processor-sg

## Troubleshooting

### Common Issues
- **Kafka connection refused**: Check security group allows port 9092
- **MongoDB connection timeout**: Verify port 27017 is accessible
- **Producer failing**: Check API key and rate limits
- **No data in MongoDB**: Verify processor is consuming from correct topic

### Log Locations
- Kafka logs: `/var/lib/docker/containers/[kafka-container-id]/`
- MongoDB logs: `/var/log/mongodb/`
- Application logs: `docker logs [container-name]`

## Cost Management

### AWS Resources Used
- 3x t3.small instances
- EBS storage (60 GB total)
- Data transfer (minimal)
- Estimated monthly cost: ~$45 (covered by student credits)

### Optimization Notes
- All instances can be stopped when not in use
- Consider spot instances for cost savings
- Monitor usage with AWS Budgets

---

## Status Log

### Completed Tasks
- [ ] GitHub repository created
- [ ] Stack documented
- [ ] AWS VMs provisioned
- [ ] Security groups configured
- [ ] Docker installed
- [ ] Kafka deployed
- [ ] MongoDB deployed
- [ ] Producer implemented
- [ ] Processor implemented
- [ ] End-to-end testing completed
- [ ] Documentation finalized

### Issues Encountered
[Document any problems and solutions here]

### Deviations from Reference Stack
[Document any changes made and why]

---

*Last updated: [Date/Time]*