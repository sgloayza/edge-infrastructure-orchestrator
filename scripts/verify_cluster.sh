#!/usr/bin/env bash
# ==============================================================================
# Cluster Verification & Healthcheck Diagnostic Utility
# Edge Infrastructure Orchestrator
# ==============================================================================

set -euo pipefail

COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

echo -e "${COLOR_GREEN}====================================================${COLOR_RESET}"
echo -e "${COLOR_GREEN}  Edge Infrastructure Orchestrator Health Diagnostic ${COLOR_RESET}"
echo -e "${COLOR_GREEN}====================================================${COLOR_RESET}"

# Check Docker availability
echo -n "Checking Docker engine... "
if command -v docker >/dev/null 2>&1; then
    echo -e "${COLOR_GREEN}[OK]$(docker --version)${COLOR_RESET}"
else
    echo -e "${COLOR_RED}[FAILED] Docker is not installed or not in PATH${COLOR_RESET}"
    exit 1
fi

# Check Docker Compose availability
echo -n "Checking Docker Compose... "
if docker compose version >/dev/null 2>&1; then
    echo -e "${COLOR_GREEN}[OK] $(docker compose version)${COLOR_RESET}"
else
    echo -e "${COLOR_RED}[FAILED] Docker Compose plugin missing${COLOR_RESET}"
    exit 1
fi

# Check Ansible availability
echo -n "Checking Ansible installation... "
if command -v ansible >/dev/null 2>&1; then
    echo -e "${COLOR_GREEN}[OK] $(ansible --version | head -n 1)${COLOR_RESET}"
else
    echo -e "${COLOR_YELLOW}[WARNING] Ansible CLI not found in current PATH${COLOR_RESET}"
fi

# Check Python environment
echo -n "Checking Python 3 environment... "
if command -v python3 >/dev/null 2>&1; then
    echo -e "${COLOR_GREEN}[OK] $(python3 --version)${COLOR_RESET}"
else
    echo -e "${COLOR_RED}[FAILED] Python 3 required${COLOR_RESET}"
    exit 1
fi

# Validate Dynamic Inventory execution
echo -n "Validating Dynamic Inventory Plugin... "
if python3 ansible/inventory/dynamic/issue_inventory.py --list >/dev/null 2>&1; then
    echo -e "${COLOR_GREEN}[OK] issue_inventory.py executed successfully${COLOR_RESET}"
else
    echo -e "${COLOR_RED}[FAILED] Dynamic inventory script returned an error${COLOR_RESET}"
    exit 1
fi

echo -e "\n${COLOR_GREEN}All diagnostic checks completed successfully!${COLOR_RESET}"
