#!/usr/bin/env bash
# ==============================================================================
# Stop Ansible Demo Environment and Clean Up Containers
# ==============================================================================

set -euo pipefail

GREEN="\033[0;32m"
BOLD="\033[1m"
RESET="\033[0m"

echo "Deteniendo contenedor Prometheus Node Exporter desplegado por Ansible..."
docker rm -f edge_node_exporter >/dev/null 2>&1 || true
rm -f /tmp/edge_watchdog.log >/dev/null 2>&1 || true

echo -e "${GREEN}${BOLD}✔ Demostración de Ansible detenida y entorno limpiado correctamente.${RESET}"
