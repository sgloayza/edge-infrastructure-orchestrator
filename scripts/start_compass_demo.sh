#!/usr/bin/env bash
# ==============================================================================
# Start Live MongoDB Demo Environment for MongoDB Compass
# Spins up Primary (27017) and Historic (27019) MongoDB instances with sample data
# ==============================================================================

set -euo pipefail

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}======================================================================${RESET}"
echo -e "${CYAN}${BOLD}  🍃 INICIANDO ENTORNO MONGODB PARA COMPASS (DEMO EN VIVO)          ${RESET}"
echo -e "${CYAN}${BOLD}======================================================================${RESET}"
echo ""

# Cleanup any previous demo containers
docker rm -f mongo_demo_primary mongo_demo_historic >/dev/null 2>&1 || true

echo -e "${BOLD}[1/4] Levantando contenedor MongoDB Primario (Puerto 27017)...${RESET}"
docker run -d --name mongo_demo_primary \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=SuperSecurePassword2026! \
  mongo:7.0 >/dev/null

echo -e "${BOLD}[2/4] Levantando contenedor MongoDB Histórico de Auditoría (Puerto 27019)...${RESET}"
docker run -d --name mongo_demo_historic \
  -p 27019:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=SuperSecurePassword2026! \
  mongo:7.0 >/dev/null

echo -e "${BOLD}[3/4] Esperando inicialización de motores de base de datos...${RESET}"
sleep 5

echo -e "${BOLD}[4/4] Inyectando datos de prueba y simulando replicación CDC...${RESET}"

# Insert into Primary
docker exec mongo_demo_primary mongosh -u admin -p SuperSecurePassword2026! --authenticationDatabase admin --quiet --eval '
  use telemetry_production;
  db.telemetry_live.insertMany([
    { sensor_id: "OrangePi-SectorNorth-01", temp_celsius: 41.5, ram_free_mb: 512, status: "ACTIVE", updated_at: new Date() },
    { sensor_id: "OrangePi-SectorSouth-02", temp_celsius: 39.8, ram_free_mb: 740, status: "ACTIVE", updated_at: new Date() }
  ]);
' >/dev/null

# Insert into Historic (including the audit-preserved record that was wiped from primary)
docker exec mongo_demo_historic mongosh -u admin -p SuperSecurePassword2026! --authenticationDatabase admin --quiet --eval '
  use telemetry_history;
  db.telemetry_audit.insertMany([
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

echo ""
echo -e "${GREEN}${BOLD}✔ ¡Entorno listo! Ya puedes abrir MongoDB Compass en Windows.${RESET}"
echo ""
echo -e "${CYAN}======================================================================${RESET}"
echo -e "  ${BOLD}🔑 CADENAS DE CONEXIÓN PARA MONGODB COMPASS:${RESET}"
echo -e "${CYAN}======================================================================${RESET}"
echo ""
echo -e "  ${YELLOW}${BOLD}1. MongoDB Primario (Operativo / En Caliente):${RESET}"
echo -e "     Cadena (URI): ${GREEN}${BOLD}mongodb://admin:SuperSecurePassword2026!@localhost:27017/?authSource=admin${RESET}"
echo -e "     Base de datos a revisar: ${CYAN}telemetry_production${RESET} -> Colección: ${CYAN}telemetry_live${RESET}"
echo -e "     (Verás 2 documentos activos)."
echo ""
echo -e "  ${YELLOW}${BOLD}2. MongoDB Histórico (Nodo de Auditoría Inmutable):${RESET}"
echo -e "     Cadena (URI): ${GREEN}${BOLD}mongodb://admin:SuperSecurePassword2026!@localhost:27019/?authSource=admin${RESET}"
echo -e "     Base de datos a revisar: ${CYAN}telemetry_history${RESET} -> Colección: ${CYAN}telemetry_audit${RESET}"
echo -e "     (Verás los 2 documentos activos + el ${BOLD}3er documento de AUDITORÍA${RESET} que fue borrado en la original)."
echo ""
echo -e "${CYAN}======================================================================${RESET}"
echo -e "  Cuando termines de verlos en Compass, puedes apagarlos con:"
echo -e "  ${BOLD}./scripts/stop_compass_demo.sh${RESET}"
echo -e "${CYAN}======================================================================${RESET}"
