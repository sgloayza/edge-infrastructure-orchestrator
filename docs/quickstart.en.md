# Quickstart & Verification Guide

🌐 **Language / Idioma:** [Cambiar a Español 🇪🇸](quickstart.md) | **English 🇺🇸**

This guide provides step-by-step instructions to run and validate the **Edge Infrastructure Orchestrator** in a local development environment (Linux / WSL 2) or on dedicated staging servers.

---

## 1. Prerequisites

Ensure your environment has the following tools installed:
* **Linux / WSL 2** (Ubuntu 22.04 or 24.04 recommended)
* **Python 3.10+**
* **Ansible 2.15+** (`pip install ansible-core`)
* **Docker Engine & Docker Compose v2**

---

## 2. Environment Setup

Clone the repository and copy the environment configuration:

```bash
# Navigate to the project root
cd edge-infrastructure-orchestrator

# Create local environment configuration from template
cp docker/env.example docker/.env
```

Review and adjust variables in `docker/.env` if you want to customize port allocations or database credentials.

---

## 3. Validating the Ansible Orchestration Engine

Verify that all playbooks pass syntax validation:

```bash
cd ansible

# Check master orchestration playbook
ansible-playbook playbooks/site.yml --syntax-check -i inventory/hosts.example.yml

# Check edge gateway provisioning playbook
ansible-playbook playbooks/setup_edge_nodes.yml --syntax-check -i inventory/hosts.example.yml

# Check distributed MongoDB & Kafka CDC playbook
ansible-playbook playbooks/setup_mongo_cdc.yml --syntax-check -i inventory/hosts.example.yml
```

Test the dynamic inventory script:

```bash
python3 inventory/dynamic/issue_inventory.py --list
```

---

## 4. Running Visual Demonstrations

### A. Health Diagnostic Utility
```bash
./scripts/verify_cluster.sh
```

### B. Interactive Change Data Capture (CDC) CLI Simulation
```bash
./scripts/demo_cdc.sh
```

### C. Live Graphical Demonstration in MongoDB Compass
```bash
# 1. Start dual MongoDB instances and real-time CDC daemon
./scripts/start_compass_demo.sh

# 2. Connect MongoDB Compass to:
#    Primary:  mongodb://admin:SuperSecurePassword2026!@localhost:27027/?authSource=admin
#    Historic: mongodb://admin:SuperSecurePassword2026!@localhost:27028/?authSource=admin

# 3. Stop and clean up containers when finished
./scripts/stop_compass_demo.sh
```

---

## 5. Teardown

To stop and remove all local Docker stacks:

```bash
docker compose -f docker/compose/docker-compose.prod.yml down -v
docker compose -f docker/compose/docker-compose.cdc.yml down -v
```
