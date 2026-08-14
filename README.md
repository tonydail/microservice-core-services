# Core Services (Shared Infrastructure)

> **Part of the microservices-ops authentication and user management system**

This repository provides the **shared infrastructure stack** for the microservices platform. It contains all the foundational services (Kafka, Debezium, nginx gateway, etc.) that must be running before individual microservices start.

## 🎯 Purpose

The Core Services repository provides:
- **Message Broker**: Kafka + Zookeeper for event-driven communication
- **CDC Pipeline**: Debezium Kafka Connect for transactional outbox pattern
- **API Gateway**: nginx with JWT validation and request routing
- **Management Tools**: Kafka UI for monitoring, CloudBeaver for database management
- **Network Infrastructure**: Docker bridge network connecting all services

This infrastructure is **designed to be forked and customized** — adapt the configuration to your specific deployment needs.

## 🏗️ Infrastructure Components

### Message Streaming
- **Zookeeper**: Kafka coordination service
- **Kafka**: Event streaming platform (port 29092 for host access, 9092 internal)
- **Kafka Connect**: Debezium connector runtime (port 8083)
- **Kafka UI**: Web-based Kafka management interface (port 8080)

### API Gateway
- **nginx**: Reverse proxy with JWT validation (port 80)
  - Routes `/auth/*` → `auth-service:3001`
  - Routes `/users/*` → `users-service:3002`
  - Validates JWT and injects `X-User-Id` and `X-User-Role` headers

### Management Tools
- **CloudBeaver**: Database administration tool (port 8978)
  - Connect to auth-service Postgres (port 5433)
  - Connect to users-service Postgres (port 5434)

### Network
- **microservices-net**: Docker bridge network connecting all services and Dev Containers

## 🏛️ Architecture Overview

### Network Topology
```
                     ┌─────────────────┐
                     │  Client/Browser │
                     └────────┬────────┘
                              │
                    ┌─────────▼──────────┐
                    │   nginx:80         │ ← JWT Validation
                    │   (API Gateway)    │   + Header Injection
                    └──────┬────────┬────┘
                           │        │
              /auth/*      │        │      /users/*
                           │        │
           ┌───────────────▼──┐  ┌─▼──────────────────┐
           │ auth-service:3001│  │ users-service:3002 │
           └───────┬───────┬──┘  └──┬─────────────┬───┘
                   │       │        │             │
                   │    gRPC:50051  │          gRPC call
                   │       │        │             │
                   │       └────────┴─────────────┘
                   │
         ┌─────────▼─────────┐
         │  Kafka:9092       │ ← Event Streaming
         │  (+ Zookeeper)    │
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │ Kafka Connect     │ ← Debezium CDC
         │ (Debezium)        │   (Transactional Outbox)
         └───────────────────┘
```

### Event Flow (Transactional Outbox Pattern)
1. Service writes to `outbox_events` table within database transaction
2. Debezium connector watches PostgreSQL WAL (Write-Ahead Log)
3. Events are automatically published to Kafka topics
4. Other services consume events for asynchronous integration

### API Gateway Routing
nginx performs JWT validation and routing:

| Path Pattern | Target Service | Port |
|--------------|----------------|------|
| `/auth/*` | auth-service | 3001 |
| `/users/*` | users-service | 3002 |

After validation, nginx injects headers:
- `X-User-Id`: User ID from JWT
- `X-User-Role`: User role from JWT

Services trust these headers and **do not re-validate tokens**.

## 🛠️ Tech Stack

- **Container Orchestration**: Docker Compose
- **Message Broker**: Apache Kafka + Zookeeper
- **CDC**: Debezium (PostgreSQL connector)
- **API Gateway**: nginx
- **Monitoring**: Kafka UI, CloudBeaver
- **Networking**: Docker bridge network

## 🚀 Getting Started

### Prerequisites
- Docker & Docker Compose
- Docker network: `microservices-net` (created once)

### First-Time Setup

1. **Create Docker network** (one-time):
   ```bash
   docker network create microservices-net
   ```

2. **Start infrastructure**:
   ```bash
   cd microservice-core-services
   ./start.sh
   ```

3. **Verify services are running**:
   ```bash
   docker ps --filter "network=microservices-net"
   ```

4. **Access management UIs**:
   - Kafka UI: http://localhost:8080
   - CloudBeaver: http://localhost:8978
   - Kafka Connect: http://localhost:8083

### Starting and Stopping

```bash
# Start all infrastructure services
./start.sh

# Stop all infrastructure services
./stop.sh

# Teardown (remove containers and volumes)
./teardown.sh
```

## 📝 Available Commands

```bash
# Infrastructure Management
./start.sh                     # Start all core services
./stop.sh                      # Stop all core services (preserve data)
./teardown.sh                  # Stop and remove volumes (data loss!)

# Docker Compose (manual control)
docker compose up -d           # Start in detached mode
docker compose down            # Stop services
docker compose logs -f         # View logs
docker compose ps              # List running services

# Debezium Connector Management
./config-environment.sh        # Configure environment variables
```

## 📁 Project Structure

```
microservice-core-services/
├── docker-compose.yml         # Infrastructure service definitions
├── gateway/
│   └── nginx.conf            # nginx API gateway configuration
├── start.sh                   # Start infrastructure script
├── stop.sh                    # Stop infrastructure script
├── teardown.sh               # Teardown script (removes volumes)
├── config-environment.sh     # Environment configuration
└── README.md
```

## 🔧 Configuration

### Environment Variables
Environment variables are loaded from the parent `environment/` folder:
- `container-hosts.env`: Service hostnames
- `common-service-db.env`: Shared database configuration
- `microservice-auth-service-db.env`: Auth service database config
- `microservice-users-service-db.env`: Users service database config

### nginx Gateway
Configuration: `gateway/nginx.conf`

Key features:
- JWT validation (mocked in dev, implement in production)
- Header injection (`X-User-Id`, `X-User-Role`)
- Request routing based on path
- CORS handling

### Kafka Connect (Debezium)
Each service registers its own Debezium connector on startup using `register-outbox-connector.sh`. The connector configuration:
- Watches PostgreSQL WAL using `pgoutput` plugin
- Monitors `outbox_events` table
- Publishes to Kafka topics based on `event_type` field
- Provides exactly-once delivery semantics

## 🔌 Service Ports

| Service | Port (Host) | Port (Container) | Purpose |
|---------|-------------|------------------|---------|
| nginx | 80 | 80 | API Gateway |
| Kafka | 29092 | 9092 | Message broker (external/internal) |
| Kafka Connect | 8083 | 8083 | Debezium CDC runtime |
| Kafka UI | 8080 | 8080 | Kafka management UI |
| CloudBeaver | 8978 | 8978 | Database admin tool |
| Zookeeper | — | 2181 | Kafka coordination |

## 🔍 Monitoring & Management

### Kafka UI (http://localhost:8080)
- View topics and messages
- Monitor consumer groups
- Inspect Kafka Connect connectors
- View cluster health

### CloudBeaver (http://localhost:8978)
Database administration:
- Connect to auth-service Postgres: `localhost:5433`
- Connect to users-service Postgres: `localhost:5434`
- Browse tables, run queries, view schemas

### Kafka Connect API (http://localhost:8083)
```bash
# List connectors
curl http://localhost:8083/connectors

# Get connector status
curl http://localhost:8083/connectors/{connector-name}/status

# Delete connector
curl -X DELETE http://localhost:8083/connectors/{connector-name}
```

## 🔄 Startup Order

**Critical**: Core services must start **before** individual microservices.

1. **Create network**: `docker network create microservices-net`
2. **Start core services**: `cd microservice-core-services && ./start.sh`
3. **Start microservices**: Individual services in their Dev Containers
4. **Services auto-register**: Each service registers its Debezium connector on startup

## 🧩 Integration with Microservices

### Network Connectivity
All services join the `microservices-net` Docker bridge network, enabling:
- Service-to-service communication (HTTP, gRPC)
- Access to Kafka (`kafka:9092`)
- Access to nginx gateway
- Cross-service database connections (if needed)

### Debezium CDC Integration
Each microservice:
1. Includes `outbox_events` table in Prisma schema
2. Writes events to outbox within transactions
3. Registers Debezium connector on startup (`register-outbox-connector.sh`)
4. Debezium publishes events to Kafka automatically

### Dev Container Integration
Service Dev Containers are configured to:
- Join the `microservices-net` network
- Access Kafka, nginx, and other core services
- Use dedicated Postgres instances (separate from core services)

## 🔗 Related Repositories

Part of the microservices-ops ecosystem:
- [microservices-ops](https://github.com/tonydail/microservices-ops) - Central orchestrator
- [microservice-auth-service](https://github.com/tonydail/microservice-auth-service) - Authentication service
- [microservice-users-service](https://github.com/tonydail/microservice-users-service) - User profile management

## 🐛 Issue Tracking

**Issues are tracked centrally** in the [microservices-ops repository](https://github.com/tonydail/microservices-ops/issues). This repository has issues disabled.

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch
3. Modify infrastructure configuration as needed
4. Test with all microservices running
5. Submit a pull request
6. Track the PR in the central microservices-ops issue tracker

## ⚠️ Production Considerations

This configuration is optimized for **local development**. For production:

1. **Replace single-node Kafka** with a proper cluster (3+ brokers)
2. **Implement real JWT validation** in nginx (currently mocked)
3. **Use Kubernetes** or container orchestration platform
4. **Configure proper TLS/SSL** for all services
5. **Set up monitoring** (Prometheus, Grafana)
6. **Configure backup and disaster recovery**
7. **Implement proper secrets management**
8. **Set replication factors** for Kafka topics (currently 1)
9. **Use managed PostgreSQL** instead of containerized instances
10. **Implement rate limiting** and DDoS protection

## 📄 License

[Your License Here]
