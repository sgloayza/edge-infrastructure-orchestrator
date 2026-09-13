#!/usr/bin/env bash
# ==============================================================================
# Resilient CDC Pipeline & Historical Audit Sink - Interactive Live Demo
# Simulates: Primary Mongo -> Debezium CDC -> Apache Kafka -> Historical Audit Sink
# ==============================================================================

set -euo pipefail

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

clear 2>/dev/null || true

echo -e "${CYAN}${BOLD}======================================================================${RESET}"
echo -e "${CYAN}${BOLD}  🚀 RESILIENT CDC PIPELINE & HISTORICAL AUDIT DEMO                  ${RESET}"
echo -e "${CYAN}${BOLD}  Kafka + Debezium + MongoDB Dual-Replica Zero-Data-Loss Architecture  ${RESET}"
echo -e "${CYAN}${BOLD}======================================================================${RESET}"
echo ""
sleep 1

echo -e "${BOLD}[1/5] Initializing Topology & Health Status...${RESET}"
echo -e "  • Primary Database:     ${GREEN}mongodb://database_primary:27017/telemetry_production (rs0)${RESET}"
echo -e "  • Streaming Broker:     ${GREEN}kafka://cdc_kafka_broker:9092 (Topic: cdc.telemetry.events)${RESET}"
echo -e "  • Historical Audit Sink:${GREEN}mongodb://database_historic:27019/telemetry_history (rs_historic)${RESET}"
echo -e "  • CDC Policy:           ${YELLOW}Persist INSERT & UPDATE / Discard DELETE (Audit Rule 365d)${RESET}"
echo ""
sleep 1.2

echo -e "${BOLD}[2/5] Simulating Sensor Telemetry Ingestion into Primary Database...${RESET}"
EVENT_PAYLOAD='{"event_id": "EVT-9041", "sensor_node": "OrangePi-Alpha-01", "temp_celsius": 42.1, "ram_usage_pct": 58.4, "status": "ACTIVE"}'
echo -e "  ${CYAN}>> db.telemetry_live.insertOne(${EVENT_PAYLOAD})${RESET}"
echo -e "  ${GREEN}✔ Document written to Primary MongoDB (Oplog entry generated at t=0ms)${RESET}"
echo ""
sleep 1.2

echo -e "${BOLD}[3/5] Debezium Change Data Capture (CDC) Event Streaming...${RESET}"
echo -e "  ${CYAN}>> Debezium MongoConnector captured oplog timestamp: ts_ms=$(date +%s%3N)${RESET}"
echo -e "  ${CYAN}>> Emitted structured event into Apache Kafka Topic [cdc.telemetry.events]${RESET}"
echo -e "  ${CYAN}>> Kafka Connect MongoDB History Sink received and deserialized event${RESET}"
echo -e "  ${GREEN}✔ Document automatically synchronized to database_historic (Latency: ~120ms)${RESET}"
echo ""
sleep 1.2

echo -e "${BOLD}[4/5] Testing Hot-Storage Incident: Simulating ACCIDENTAL DELETE...${RESET}"
echo -e "  ${YELLOW}⚠️  Simulating operator error or uncoordinated purge on hot operational node:${RESET}"
echo -e "  ${RED}>> db.telemetry_live.deleteMany({\"sensor_node\": \"OrangePi-Alpha-01\"})${RESET}"
echo -e "  ${RED}✖ Records in Primary Database: 0 (HOT DATA HAS BEEN WIPED!)${RESET}"
echo ""
sleep 1.5

echo -e "${BOLD}[5/5] Auditing Historical Retention Sink (Verification)...${RESET}"
echo -e "  ${CYAN}>> Querying database_historic.telemetry_history.countDocuments({\"sensor_node\": \"OrangePi-Alpha-01\"})${RESET}"
echo -e "  ${GREEN}${BOLD}✔ Records in Historical Database: 1 (PRESERVED INTACT!)${RESET}"
echo ""
echo -e "${CYAN}----------------------------------------------------------------------${RESET}"
echo -e "  ${BOLD}AUDIT SUMMARY:${RESET}"
echo -e "  • Primary Operational Node (Hot):     ${RED}0 documents (Empty / Purged)${RESET}"
echo -e "  • Historical Audit Sink (Immutable):   ${GREEN}1 document (100% Retained)${RESET}"
echo -e "  • Data Loss:                          ${GREEN}${BOLD}0% (Zero Data Loss Enforced)${RESET}"
echo -e "  • Compliance Result:                  ${GREEN}${BOLD}PASSED - Statutory Audit Ready${RESET}"
echo -e "${CYAN}----------------------------------------------------------------------${RESET}"
echo ""
echo -e "${GREEN}Demonstration completed successfully!${RESET}"
