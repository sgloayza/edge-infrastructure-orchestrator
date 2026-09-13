#!/usr/bin/env bash
# ==============================================================================
# Start Live MongoDB Demo Environment with Real-Time CDC Replication
# Spins up Primary (27027), Historic (27028), and a background CDC Sync Worker
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}======================================================================${RESET}"
echo -e "${CYAN}${BOLD}  🍃 INICIANDO ENTORNO MONGODB + MOTOR CDC EN VIVO PARA COMPASS     ${RESET}"
echo -e "${CYAN}${BOLD}======================================================================${RESET}"
echo ""

# Cleanup any previous demo containers
docker rm -f mongo_demo_primary mongo_demo_historic >/dev/null 2>&1 || true
docker network create mongo_demo_net >/dev/null 2>&1 || true

echo -e "${BOLD}[1/5] Levantando contenedor MongoDB Primario (Puerto 27027)...${RESET}"
docker run -d --name mongo_demo_primary \
  --network mongo_demo_net \
  -p 27027:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=SuperSecurePassword2026! \
  mongo:7.0 >/dev/null

echo -e "${BOLD}[2/5] Levantando contenedor MongoDB Histórico de Auditoría (Puerto 27028)...${RESET}"
docker run -d --name mongo_demo_historic \
  --network mongo_demo_net \
  -p 27028:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=SuperSecurePassword2026! \
  mongo:7.0 >/dev/null

echo -e "${BOLD}[3/5] Esperando inicialización de motores de base de datos...${RESET}"
sleep 5

echo -e "${BOLD}[4/5] Inyectando datos de telemetría iniciales...${RESET}"

# Insert into Primary
docker exec mongo_demo_primary mongosh -u admin -p SuperSecurePassword2026! --authenticationDatabase admin --quiet --eval '
  const dbLive = db.getSiblingDB("telemetry_production");
  dbLive.telemetry_live.drop();
  dbLive.telemetry_live.insertMany([
    { sensor_id: "OrangePi-SectorNorth-01", temp_celsius: 41.5, ram_free_mb: 512, status: "ACTIVE", updated_at: new Date() },
    { sensor_id: "OrangePi-SectorSouth-02", temp_celsius: 39.8, ram_free_mb: 740, status: "ACTIVE", updated_at: new Date() }
  ]);
' >/dev/null

# Insert into Historic
docker exec mongo_demo_historic mongosh -u admin -p SuperSecurePassword2026! --authenticationDatabase admin --quiet --eval '
  const dbHist = db.getSiblingDB("telemetry_history");
  dbHist.telemetry_audit.drop();
  dbHist.telemetry_audit.insertMany([
    { sensor_id: "OrangePi-SectorNorth-01", temp_celsius: 41.5, ram_free_mb: 512, status: "ACTIVE", cdc_op: "INSERT", updated_at: new Date() },
    { sensor_id: "OrangePi-SectorSouth-02", temp_celsius: 39.8, ram_free_mb: 740, status: "ACTIVE", cdc_op: "INSERT", updated_at: new Date() },
    { 
      sensor_id: "OrangePi-Incident-03-PURGED", 
      temp_celsius: 48.2, 
      ram_free_mb: 110, 
      status: "CRITICAL_ALERT", 
      cdc_op: "INSERT", 
      audit_retention: true,
      notes: "REGISTRO PRESERVADO POR CDC: Este dato fue borrado en la base operativa por el operador, pero retenido en el histórico para auditoría legal.",
      updated_at: new Date() 
    }
  ]);
' >/dev/null

echo -e "${BOLD}[5/5] Activando Demonio de Replicación CDC en Tiempo Real...${RESET}"
docker cp "${SCRIPT_DIR}/cdc_worker.js" mongo_demo_primary:/cdc_worker.js
docker exec -d mongo_demo_primary mongosh /cdc_worker.js
echo -e "${GREEN}${BOLD}✔ ¡Motor CDC en tiempo real activo! Todo lo que insertes, edites o borres en Compass se sincronizará al instante.${RESET}"

echo ""
echo -e "${GREEN}${BOLD}✔ ¡Entorno listo! Abre MongoDB Compass en Windows.${RESET}"
echo ""
echo -e "${CYAN}======================================================================${RESET}"
echo -e "  ${BOLD}🔑 CADENAS DE CONEXIÓN PARA MONGODB COMPASS:${RESET}"
echo -e "${CYAN}======================================================================${RESET}"
echo ""
echo -e "  ${YELLOW}${BOLD}1. MongoDB Primario (Operativo / En Caliente):${RESET}"
echo -e "     Cadena (URI): ${GREEN}${BOLD}mongodb://admin:SuperSecurePassword2026!@localhost:27027/?authSource=admin${RESET}"
echo -e "     Base de datos: ${CYAN}telemetry_production${RESET} -> Colección: ${CYAN}telemetry_live${RESET}"
echo ""
echo -e "  ${YELLOW}${BOLD}2. MongoDB Histórico (Nodo de Auditoría Inmutable):${RESET}"
echo -e "     Cadena (URI): ${GREEN}${BOLD}mongodb://admin:SuperSecurePassword2026!@localhost:27028/?authSource=admin${RESET}"
echo -e "     Base de datos: ${CYAN}telemetry_history${RESET} -> Colección: ${CYAN}telemetry_audit${RESET}"
echo ""
echo -e "${CYAN}----------------------------------------------------------------------${RESET}"
echo -e "  ${BOLD}⚡ PRUEBA DE MAGIA EN VIVO EN COMPASS:${RESET}"
echo -e "  1. En el Primario (27027), haz clic en ${BOLD}'Add Data' -> 'Insert Document'${RESET} y guarda cualquier JSON."
echo -e "  2. Ve al Histórico (27028), haz clic en el botón circular de ${BOLD}Refresh${RESET} (🔄)."
echo -e "  3. ¡Verás cómo el documento apareció automáticamente con la etiqueta ${GREEN}'cdc_synced: true'${RESET}!"
echo -e "  4. Si borras el documento en el Primario, en el Histórico ${BOLD}NO se borra${RESET}: se preserva intacto para auditoría."
echo -e "${CYAN}======================================================================${RESET}"
echo "  Para apagar los contenedores al terminar: ./scripts/stop_compass_demo.sh"
echo -e "${CYAN}======================================================================${RESET}"
