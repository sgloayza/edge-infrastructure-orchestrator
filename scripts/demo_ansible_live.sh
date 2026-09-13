#!/usr/bin/env bash
# ==============================================================================
# Ansible Edge Orchestration & Self-Healing - Live Interactive Demonstration
# Executes real tasks on localhost: Hardening check, Prometheus Exporter, Watchdog
# ==============================================================================

set -euo pipefail

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="${SCRIPT_DIR}/../ansible"

clear 2>/dev/null || true

echo -e "${CYAN}${BOLD}======================================================================${RESET}"
echo -e "${CYAN}${BOLD}  🤖 DEMOSTRACIÓN EN VIVO DE ANSIBLE: APROVISIONAMIENTO Y SELF-HEALING ${RESET}"
echo -e "${CYAN}${BOLD}  Orquestación de Nodos Edge + Prometheus Exporter + Watchdog Guardián ${RESET}"
echo -e "${CYAN}${BOLD}======================================================================${RESET}"
echo ""

echo -e "${BOLD}[1/3] Ejecutando Playbook de Ansible con conexión local (Simulación Edge)...${RESET}"
echo ""

cd "${ANSIBLE_DIR}"
ansible-playbook playbooks/demo_local.yml

echo ""
echo -e "${GREEN}${BOLD}✔ ¡Ejecución de Ansible completada exitosamente con código 0!${RESET}"
echo ""

echo -e "${CYAN}======================================================================${RESET}"
echo -e "  ${BOLD}📊 EVIDENCIAS VISUALES GENERADAS POR ANSIBLE:${RESET}"
echo -e "${CYAN}======================================================================${RESET}"
echo ""
echo -e "  ${YELLOW}${BOLD}1. Métricas de Prometheus en Vivo (Navegador Web):${RESET}"
echo -e "     Abre este enlace en tu navegador (Chrome, Edge):"
echo -e "     👉 ${GREEN}${BOLD}http://localhost:9100/metrics${RESET}"
echo -e "     ${CYAN}(Verás cientos de métricas en tiempo real de CPU, RAM y red del host).${RESET}"
echo ""
echo -e "  ${YELLOW}${BOLD}2. Registro de Auditoría del Watchdog de Hardware:${RESET}"
if [ -f /tmp/edge_watchdog.log ]; then
    echo -e "     Última línea registrada por Ansible:"
    echo -e "     ${BOLD}$(tail -n 1 /tmp/edge_watchdog.log)${RESET}"
fi
echo ""
echo -e "  ${YELLOW}${BOLD}3. Contenedor de Monitoreo Desplegado por Ansible:${RESET}"
docker ps --filter "name=edge_node_exporter" --format "     Nombre: {{.Names}} | Estado: {{.Status}} | Puertos: {{.Ports}}"
echo ""
echo -e "${CYAN}======================================================================${RESET}"
echo -e "  Para apagar el exportador y limpiar el entorno cuando termines:"
echo -e "  ${BOLD}./scripts/stop_ansible_demo.sh${RESET}"
echo -e "${CYAN}======================================================================${RESET}"
