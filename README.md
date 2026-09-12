# 🚀 Edge Infrastructure Orchestrator

[![Ansible Core](https://img.shields.io/badge/Ansible-2.16%2B-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Docker Compose](https://img.shields.io/badge/Docker-28.0%2B-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Apache Kafka](https://img.shields.io/badge/Apache_Kafka-CDC_Streaming-231F20?style=for-the-badge&logo=apachekafka&logoColor=white)](https://kafka.apache.org/)
[![MongoDB](https://img.shields.io/badge/MongoDB-7.0_Replica_Sets-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

An enterprise-ready **Infrastructure as Code (IaC)**, **Event-Driven Orchestration**, and **Resilient Data Streaming (CDC)** framework designed for distributed Edge computing nodes (Orange Pi / NanoPi / Linux Gateways) and high-availability database clusters.

---

## 📌 Executive Summary

Maintaining fleets of remote IoT gateways and continuous data synchronization poses severe engineering challenges: network instability, limited flash memory and RAM, uncoordinated concurrent deployments, and accidental data losses.

This repository demonstrates a battle-tested infrastructure architecture that provides:
1. **Automated Provisioning & Self-Healing:** Event-driven playbooks managing gateway configurations, reverse proxies (ARM64), and proactive memory/disk health watchdogs.
2. **Dual-State Dynamic Inventory:** An intelligent Python inventory plugin that decouples live node status (`actual_*`) from requested actions (`target_*`), enforcing mutual exclusion (mutex) locks to eliminate deployment race conditions.
3. **Resilient Data Pipeline (CDC):** Real-time event streaming via **Apache Kafka** and **Debezium**, continuously replicating telemetry from operational databases to a permanent historical audit sink (preserving inserts and updates while dropping deletions).
4. **Production Hardening:** Docker Compose stacks configured with JSON log rotation, strictly bounded CPU/RAM resource limits, and read-only host timezone synchronization.

---

## 🏗️ System Architecture

```mermaid
flowchart TB
    subgraph ORCH["1. Orchestration & Event-Driven Engine"]
        API[External CMDB / Issue Tracker API] --> DYN_INV["Dynamic Inventory: issue_inventory.py"]
        DYN_INV --> MUTEX{"Concurrency Check<br/>(Stage != In-Progress)"}
        MUTEX -- Lock Acquired --> ANSIBLE[Ansible Core Engine]
        MUTEX -- Busy --> ABORT[Enforce Mutual Exclusion / Abort]
    end

    subgraph EDGE["2. Edge Gateways Fleet (ARM64 / Orange Pi)"]
        ANSIBLE -->|SSH & Python| GW1["Edge Gateway 01<br/>(192.168.10.11)"]
        ANSIBLE -->|SSH & Python| GW2["Edge Gateway 02<br/>(192.168.10.12)"]

        subgraph NODE_SERVICES["Node Microservices & Hardening"]
            PROXY[Nginx Reverse Proxy:80/443] --> API_SVC[Telemetry Local API]
            WATCHDOG[Hardware RAM/Disk Watchdog] -.-> PROMETHEUS[Node Exporter:9100]
        end
        GW1 --- NODE_SERVICES
    end

    subgraph DATA_STREAM["3. Resilient CDC & Data Pipeline"]
        ANSIBLE -->|Playbooks| MONGO_PRI[MongoDB Primary<br/>Replica Set rs0]
        ANSIBLE -->|Connect API| KAFKA_CONN[Kafka Connect<br/>Debezium Mongo Plugin]
        
        MONGO_PRI -- "Oplog / Change Streams" --> KAFKA_CONN
        KAFKA_CONN --> KAFKA_BROKER[Apache Kafka Cluster]
        KAFKA_BROKER -- "CDC Topics" --> MONGO_SINK[MongoDB History Sink<br/>Retention 365 Days]
    end

    classDef orchStyle fill:#1e293b,stroke:#0284c7,stroke-width:2px,color:#f8fafc;
    classDef edgeStyle fill:#0f172a,stroke:#10b981,stroke-width:2px,color:#f8fafc;
    classDef dataStyle fill:#18181b,stroke:#8b5cf6,stroke-width:2px,color:#f8fafc;

    class API,DYN_INV,MUTEX,ANSIBLE,ABORT orchStyle;
    class GW1,GW2,PROXY,API_SVC,WATCHDOG,PROMETHEUS edgeStyle;
    class MONGO_PRI,KAFKA_CONN,KAFKA_BROKER,MONGO_SINK dataStyle;
```

---

## 📂 Repository Structure

```text
edge-infrastructure-orchestrator/
├── .github/
│   └── workflows/
│       ├── lint.yml                # Quality gate: ansible-lint, yaml-lint, flake8
│       └── validate-docker.yml     # Validation of Docker Compose stacks
│
├── ansible/
│   ├── ansible.cfg                 # Performance tuning (pipelining, profile_tasks)
│   ├── inventory/
│   │   ├── dynamic/
│   │   │   └── issue_inventory.py  # Dual-State dynamic inventory with mutex lock
│   │   └── hosts.example.yml       # Production-like topology inventory
│   ├── playbooks/
│   │   ├── site.yml                # Master orchestrator playbook
│   │   ├── setup_edge_nodes.yml    # Provisioning & hardening of gateways
│   │   ├── setup_mongo_cdc.yml     # Cluster deployment & Kafka CDC connectors
│   │   └── remediate_services.yml  # Automated remediation & self-healing
│   └── roles/
│       ├── common_hardening/       # Timezones, Docker log-rotation, sys limits
│       ├── edge_gateway/           # Nginx reverse proxy (multi-arch ARM64/x86_64)
│       ├── telemetry_monitor/      # Prometheus node_exporter & RAM watchdog
│       ├── mongo_replica/          # Replica sets, credentials, and TTL index policies
│       └── kafka_cdc/              # Debezium Source & MongoDB History Sink
│
├── docker/
│   ├── compose/
│   │   ├── docker-compose.prod.yml # Hardened production stack with quotas
│   │   └── docker-compose.cdc.yml  # Distributed streaming: Kafka, Zookeeper, Debezium
│   └── env.example                 # Sanitized configuration template
│
├── docs/
│   ├── architecture.md             # Complete architectural specifications
│   └── quickstart.md               # Step-by-step local testing instructions
│
├── scripts/
│   └── verify_cluster.sh           # Automated healthcheck and diagnostic utility
│
├── .gitignore
├── LICENSE
└── README.md
```

---

## ⚡ Key Highlights & Engineering Decisions

### 1. Dual-State Dynamic Inventory & Mutex Locking
* Avoids dangerous blind overrides by querying the target platform API and splitting parameters into `actual_*` (observed running state) and `target_*` (desired state from ticket/event).
* Implements a **Mutual Exclusion (Mutex)** lock: if any ticket is in `In-Progress`, new automation runs return an empty set, guaranteeing zero concurrent collisions.

### 2. Zero-Data-Loss Historical CDC Pipeline
* Employs **Debezium** to ingest Change Streams directly from MongoDB replica set oplogs.
* Transmits change events across Kafka topics to a dedicated **historical replica set** (`database_historic`).
* Configured specifically to **persist inserts and updates** while dropping destructive deletions, providing full audit compliance without polluting the high-speed operational node.

### 3. Production Docker Hardening
* **Storage Protection:** Enforces JSON log rotation (`max-size: 50m`, `max-file: 5`) to prevent disk exhaustion on Edge devices.
* **OOM Prevention:** Explicit `deploy.resources.limits` bounds CPU and RAM usage on every container.
* **Deterministic Time:** Maps `/etc/localtime:ro` and injects `TZ` parameters across all microservices.

---

## 🛠️ Quickstart

### Prerequisites
* Linux / WSL 2 (Ubuntu recommended)
* Docker & Docker Compose v2
* Python 3.10+ & Ansible 2.15+

### Run Automated Healthcheck & Lint Validation
```bash
# 1. Clone repository
git clone https://github.com/sgloayza/edge-infrastructure-orchestrator.git
cd edge-infrastructure-orchestrator

# 2. Run diagnostic script
./scripts/verify_cluster.sh

# 3. Test Ansible playbooks syntax
cd ansible
ansible-playbook playbooks/site.yml --syntax-check -i inventory/hosts.example.yml

# 4. Test Dynamic Inventory execution
python3 inventory/dynamic/issue_inventory.py --list
```

For full setup instructions, see the **[Quickstart Guide](docs/quickstart.md)** and **[Architecture Specifications](docs/architecture.md)**.

---

## 👤 Author & Contact

**Sandra Loayza**  
*Computer Science Engineer (ESPOL)*  
*DevOps, Backend & IoT Architecture Specialist*

* 🌐 **Portfolio:** [https://sgloayza.github.io/portfolio-web/](https://sgloayza.github.io/portfolio-web/)
* 🐙 **GitHub:** [@sgloayza](https://github.com/sgloayza)
* 💼 **LinkedIn:** [Sandra Loayza](https://linkedin.com/in/sgloayza)
* 📧 **Email:** [sgloayza94@gmail.com](mailto:sgloayza94@gmail.com)
