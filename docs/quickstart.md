# Quickstart & Verification Guide

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

## 4. Launching the Local Docker Stacks

### A. Launching the Production Hardened Stack
This stack runs the Edge Nginx reverse proxy, Telemetry Web API, and Primary MongoDB:

```bash
cd ../docker/compose
docker compose -f docker-compose.prod.yml --env-file ../.env up -d
```

Verify running containers:
```bash
docker compose -f docker-compose.prod.yml ps
```

Test healthcheck endpoint:
```bash
curl http://localhost:80/healthz
# Expected output: OK
```

### B. Launching the Kafka CDC & Historical Sink Stack
To test the real-time event streaming pipeline:

```bash
docker compose -f docker-compose.cdc.yml --env-file ../.env up -d
```

Verify that Kafka Connect is accepting connector registrations:
```bash
curl -s http://localhost:8083/connectors | jq .
```

---

## 5. Running Automated Healthchecks

Run the automated diagnostic utility from the project root:

```bash
./scripts/verify_cluster.sh
```

---

## 6. Teardown

To stop and remove all local containers and network bridges:

```bash
docker compose -f docker-compose.prod.yml down -v
docker compose -f docker-compose.cdc.yml down -v
```
