# CA0 - Precious Metal Price Tracker

**Student:** Philip Eykamp  
**Course:** CS 5287  
**Date:** September 4, 2025  
**Deadline:** September 5, 2025

---

## Project Overview

This project implements a complete IoT data pipeline for tracking precious metal prices using a cloud-native architecture. The system fetches real-time metal prices, processes them through a pub/sub messaging system, and stores the results in a NoSQL database.

**Demo Video:** See `CA0-Recording.mov` for complete pipeline demonstration showing data flow from producer through Kafka to MongoDB storage.

---

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

---

## Infrastructure Architecture

### VM Specifications
- **Instance Type**: t3.small
- **vCPUs**: 2
- **RAM**: 4 GB
- **Storage**: 20 GB gp3 EBS
- **Region**: United States (Ohio) - us-east-2c

### VM Layout and Configuration

| VM Name | Instance ID | Private IP | Public IP | Purpose | Services |
|---------|-------------|------------|-----------|---------|----------|
| **vm-kafka** | i-0d72daad0d7a2fa8a | 172.31.36.12 | 18.222.254.44 | Message Broker | Kafka, ZooKeeper |
| **vm-db** | i-051f7e1a5615ecfce | 172.31.39.1 | 18.222.152.233 | Database | MongoDB |
| **vm-proc** | i-0c9db61c1398d3e70 | 172.31.36.45 | 3.16.165.131 | Processing | Processor |
| **vm-producer** | i-0e829e20f8d5deef7 | 172.31.33.195 | 18.222.84.164 | Data Generation | Producer |

### Network Configuration

| VM | Open Ports | Security Group | Purpose |
|----|------------|----------------|---------|
| vm-kafka | 22 (SSH), 9092 (Kafka), 2181 (ZooKeeper) | kafka-sg | Message broker access |
| vm-db | 22 (SSH), 27017 (MongoDB) | db-sg | Database access |
| vm-proc | 22 (SSH), 8001 (Health) | processor-sg | Processing service |
| vm-producer | 22 (SSH), 8000 (Health) | producer-sg | Data generation |

### Network Diagram
![Network Diagram](./docs/network-diagram.png)

---

## Application Architecture

### Data Flow
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

### Application Components
- **Producer**: Generates simulated metals price data (no external API dependency)
- **Processor**: Consumes Kafka messages and stores in MongoDB with data enrichment
- **Health Checks**: Both services expose HTTP health endpoints for monitoring
- **Data Enrichment**: Adds market session info, price categorization, and processing timestamps

### Container Configuration Summary

| Component | Image/Version | Host VM | Private IP | Port(s) | Purpose |
|-----------|---------------|---------|------------|---------|---------|
| ZooKeeper | confluentinc/cp-zookeeper:7.4.0 | vm-kafka | 172.31.36.12 | 2181 | Kafka cluster coordination |
| Kafka Broker | confluentinc/cp-kafka:7.4.0 | vm-kafka | 172.31.36.12 | 9092 | Message streaming broker |
| MongoDB | mongo:6.0 | vm-db | 172.31.39.1 | 27017 | Document storage |
| Metals Producer | metals-producer:latest | vm-producer | 172.31.33.195 | 8000 | Simulated price data generation |
| Metals Processor | metals-processor:latest | vm-proc | 172.31.36.45 | 8001 | Message consumption and processing |

---

## Installation and Deployment

### Prerequisites
- AWS account with student credits activated
- SSH key pair generated and added to all VMs
- Basic familiarity with Docker and command line operations

### Deployment Scripts (Recommended Approach)

**IMPORTANT NOTE**: The actual implementation of this project was significantly more haphazard than these clean scripts suggest. The real deployment involved extensive troubleshooting, multiple failed attempts, manual debugging, and iterative problem-solving across several hours. These scripts represent a "cleaned up" version of what the deployment process *should* look like, derived from the actual commands and fixes that eventually worked.

The `/scripts` directory contains automated deployment scripts that capture the final working configuration:

```
scripts/
├── 00-master-deploy.sh     # Orchestrates entire deployment
├── 01-docker-install.sh    # Installs Docker on all VMs
├── 02-deploy-kafka.sh      # Deploys Kafka + Zookeeper
├── 03-deploy-mongodb.sh    # Deploys MongoDB with auth
├── 04-deploy-processor.sh  # Builds and runs processor
├── 05-deploy-producer.sh   # Builds and runs producer
├── 06-verify-pipeline.sh   # End-to-end testing
├── 07-security-hardening.sh # SSH and firewall security
└── setup-environment.sh    # Local environment prep
```

### Quick Start Deployment

1. **Prepare your environment:**
   ```bash
   # From the CA0 project root
   ./setup-environment.sh
   ```

2. **Update VM IP addresses:**
   Edit `scripts/00-master-deploy.sh` and update these variables with your actual VM IPs:
   ```bash
   KAFKA_VM_IP="172.31.36.12"      # Your vm-kafka IP
   DB_VM_IP="172.31.39.1"          # Your vm-db IP  
   PROC_VM_IP="172.31.36.45"       # Your vm-proc IP
   PRODUCER_VM_IP="172.31.33.195"  # Your vm-producer IP
   ```

3. **Run the master deployment:**
   ```bash
   # This will deploy everything automatically
   ./scripts/00-master-deploy.sh 2>&1 | tee logs/deployment.log
   ```

### Manual Step-by-Step Deployment

If the automated deployment fails or you prefer manual control:

1. **Install Docker on all VMs:**
   ```bash
   # Copy and run on each VM
   scp scripts/01-docker-install.sh ubuntu@VM_IP:~/
   ssh ubuntu@VM_IP "chmod +x ~/01-docker-install.sh && ~/01-docker-install.sh"
   ```

2. **Deploy infrastructure services:**
   ```bash
   # On Database VM
   ./03-deploy-mongodb.sh
   
   # On Kafka VM  
   ./02-deploy-kafka.sh
   ```

3. **Deploy application services:**
   ```bash
   # Copy code and deploy processor
   scp -r processor/* ubuntu@PROC_VM_IP:~/processor/
   ssh ubuntu@PROC_VM_IP "./04-deploy-processor.sh"
   
   # Copy code and deploy producer
   scp -r producer/* ubuntu@PRODUCER_VM_IP:~/producer/
   ssh ubuntu@PRODUCER_VM_IP "./05-deploy-producer.sh"
   ```

4. **Verify the pipeline:**
   ```bash
   ./scripts/06-verify-pipeline.sh
   ```

5. **Apply security hardening:**
   ```bash
   # Run on each VM (WARNING: Disables SSH password auth)
   ./scripts/07-security-hardening.sh
   ```

---

## Testing and Verification

### Automated Verification
The verification script tests the entire pipeline:
```bash
./scripts/06-verify-pipeline.sh
```

This script checks:
- Kafka topics exist and are accessible
- Producer is generating data
- Processor is consuming messages
- MongoDB contains processed documents
- All containers are running properly

### Manual Verification Commands
```bash
# Check Kafka topic messages
ssh ubuntu@KAFKA_VM_IP
docker exec kafka kafka-console-consumer --topic metals-prices --bootstrap-server localhost:9092 --max-messages 3

# Check MongoDB data
ssh ubuntu@DB_VM_IP  
docker exec mongodb mongosh -u admin -p password123 --authenticationDatabase admin metals --eval "db.prices.find().limit(5)"

# Check service health endpoints
curl http://PRODUCER_VM_IP:8000/health
curl http://PROCESSOR_VM_IP:8001/health

# Monitor logs
docker logs metals-producer
docker logs metals-processor
```

### Expected Results
- **Kafka**: Should show JSON messages with metal price data
- **MongoDB**: Should contain documents with processed timestamps and enriched data
- **Health endpoints**: Should return status "healthy" with processing statistics
- **Logs**: Should show regular data processing without errors

---

## Data Schema and Configuration

### MongoDB Document Schema
```json
{
  "_id": "ObjectId",
  "metal": "GOLD",
  "price": 1843.28,
  "currency": "USD",
  "timestamp": "2025-09-05T22:33:50.510621",
  "exchange": "SIMULATION",
  "volume": 1820,
  "change_24h": 5.0,
  "processed_at": "2025-09-05T22:33:50.378313",
  "timestamp_dt": "ISODate",
  "price_category": "medium",
  "market_session": "overlap_session"
}
```

### Environment Variables

**Producer Configuration:**
```bash
KAFKA_BOOTSTRAP_SERVERS=172.31.36.12:9092
KAFKA_TOPIC=metals-prices
API_KEY=""
FETCH_INTERVAL=60
LOG_LEVEL=INFO
```

**Processor Configuration:**
```bash
KAFKA_BOOTSTRAP_SERVERS=172.31.36.12:9092
KAFKA_TOPIC=metals-prices
KAFKA_GROUP_ID=metals-processor-group
MONGODB_URI=mongodb://admin:password123@172.31.39.1:27017/metals?authSource=admin
MONGODB_DATABASE=metals
MONGODB_COLLECTION=prices
LOG_LEVEL=INFO
```

---

## Security Configuration

### Authentication and Access Control
- **SSH**: Key-only access (password authentication disabled)
- **MongoDB**: Authentication enabled with admin/password123
- **Containers**: Run as non-root users (metals-user)

### Network Security
- Security groups restrict inbound traffic to essential ports only
- No public access to database ports from internet
- Inter-VM communication through private subnets

### Security Hardening Applied
- SSH password authentication disabled
- Fail2ban installed and configured
- Automatic security updates enabled
- Basic firewall rules configured
- System packages updated

### Security Note
During development, AWS Security Groups were configured with outbound "All Traffic" rules to enable Docker image downloads and package installations. In a production environment, these would be restricted to only essential outbound traffic (DNS, NTP, inter-VM communication) after deployment is complete.

---

## Troubleshooting

### Script Deployment Issues
If the automated scripts fail, try these approaches:

**Docker Installation Failures:**
```bash
# Check outbound internet access
curl -I https://download.docker.com

# Verify AWS Security Groups allow outbound traffic to 0.0.0.0/0
# Check /var/log/user-data.log if using EC2 user data

# Manual Docker installation
sudo apt update && sudo apt install -y docker.io
sudo systemctl start docker
sudo usermod -aG docker ubuntu
```

**Network Connectivity Issues:**
```bash
# Test VM-to-VM connectivity
ping [other-vm-private-ip]

# Check Security Group rules
# Kafka VM needs: 22, 9092, 2181
# DB VM needs: 22, 27017  
# Processor/Producer VMs need: 22, 8000, 8001

# Test specific ports
telnet [vm-ip] [port]
```

**Container Build Failures:**
```bash
# Check Docker daemon status
sudo systemctl status docker

# Build with verbose output
docker build --no-cache --progress=plain -t [image-name] .

# Check disk space
df -h
docker system prune -f
```

### Real-World Issues Encountered

During actual deployment, these specific problems occurred:

1. **AWS Security Groups Blocking Outbound Traffic**
   - **Problem**: Docker installation failed because VMs couldn't download packages
   - **Solution**: Added "All Traffic" outbound rule to 0.0.0.0/0

2. **Kafka Cross-VM Communication**
   - **Problem**: Producer couldn't connect to Kafka from different VM
   - **Solution**: Fixed `KAFKA_ADVERTISED_LISTENERS` with correct VM private IP

3. **MongoDB Authentication Failures**
   - **Problem**: Processor couldn't authenticate to MongoDB
   - **Solution**: Updated connection string format and credentials

4. **Producer Container Restart Loops**
   - **Problem**: Producer container kept restarting due to import issues
   - **Solution**: Added proper `if __name__ == "__main__"` block

5. **Docker Group Permissions**
   - **Problem**: Non-sudo docker commands failed
   - **Solution**: Logout/login required after adding user to docker group

### Common Issues and Solutions
- **Kafka connection refused**: Check security group allows port 9092 between VMs
- **MongoDB connection timeout**: Verify port 27017 is accessible and credentials match those set during deployment
- **Producer failing**: Check API key and rate limits (using simulation mode as fallback)
- **No data in MongoDB**: Verify processor is consuming from correct Kafka topic
- **Health checks failing**: Wait for services to fully start (can take 1-2 minutes)

### Log Locations
- **Application logs**: `docker logs [container-name]`
- **System logs**: `/var/log/syslog`
- **Docker daemon**: `journalctl -u docker.service`
- **SSH logs**: `/var/log/auth.log`
- **Deployment logs**: `logs/deployment.log` (if using scripts)

---

## Documentation and Evidence

### Screenshots
See `/docs/screenshots/` folder for:
- VM deployment verification
- Service status confirmation  
- End-to-end data flow demonstration
- Security configuration evidence

### Container Details
- **All containers**: Run as non-root users (metals-user)
- **Restart policy**: `--restart unless-stopped` on all application containers
- **Network mode**: Host networking for producer and processor, bridge networking for infrastructure services
- **Data persistence**: MongoDB uses named volume `mongodb_data`
- **Log locations**: All services log to Docker container logs accessible via `docker logs [container-name]`

### Service Dependencies
- Producer → Kafka (publishes messages)
- Kafka → ZooKeeper (cluster coordination)
- Processor → Kafka (consumes messages)
- Processor → MongoDB (stores processed data)

---

## Cost Management

### AWS Resources Used
- 4x t3.small instances (vm-kafka, vm-db, vm-proc, vm-producer)
- EBS storage (80 GB total)
- Data transfer (minimal)
- Estimated monthly cost: ~$60 (covered by student credits)

### Optimization Notes
- All instances can be stopped when not in use
- Consider spot instances for cost savings
- Monitor usage with AWS Budgets

---

## Reality Check: What Actually Happened

The actual deployment process was far messier than these scripts suggest:

- **Docker installation** initially failed due to AWS Security Group configurations blocking outbound traffic
- **Kafka networking** required multiple iterations to get the `KAFKA_ADVERTISED_LISTENERS` configuration correct for cross-VM communication
- **MongoDB authentication** caused significant debugging when the processor couldn't connect
- **Producer restart loops** required adding proper `if __name__ == "__main__"` blocks
- **Network connectivity** issues required multiple security group rule adjustments
- **Container communication** debugging took several hours to resolve IP addressing

The final working pipeline processes 200+ documents successfully, but getting there involved:
- ~6 hours of troubleshooting and iteration
- Multiple complete teardowns and rebuilds  
- Extensive log analysis and debugging
- Manual configuration adjustments
- Real-time problem solving with assistance

These scripts represent the "final working state" but don't capture the messy reality of distributed systems debugging. In a production environment, this would typically involve more automated testing, better error handling, and staged rollouts.

---

*Last updated: September 5, 2025*