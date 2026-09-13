#!/usr/bin/env bash
# ==============================================================================
# Stop MongoDB Demo Environment
# ==============================================================================

set -euo pipefail

GREEN="\033[0;32m"
BOLD="\033[1m"
RESET="\033[0m"

echo "Deteniendo contenedores de demostración de MongoDB..."
docker rm -f mongo_demo_primary mongo_demo_historic >/dev/null 2>&1 || true
echo -e "${GREEN}${BOLD}✔ Contenedores detenidos y memoria liberada correctamente.${RESET}"
