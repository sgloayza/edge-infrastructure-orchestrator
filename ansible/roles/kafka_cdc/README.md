# ⚡ Rol Ansible: `kafka_cdc`

Este rol automatiza el registro, configuración y validación de los conectores de **Change Data Capture (CDC)** sobre el motor de **Kafka Connect**.

---

## 🎯 ¿Qué Problema Resuelve?

1. **Configuración manual propensa a errores:** Registrar conectores distribuidos en Kafka Connect normalmente requiere ejecutar comandos `curl` complejos contra su API REST con JSONs extensos. Este rol hace que el despliegue sea 100% declarativo e idempotente.
2. **Pérdida de datos por borrados accidentales:** Configura el pipeline para que Debezium capture los cambios del MongoDB operativo, los envíe a Apache Kafka, y el Sink histórico guarde inserciones y actualizaciones descartando eliminaciones destructivas.
3. **Resiliencia en el arranque:** Incluye sondeo activo (*polling*) esperando a que la API REST de Kafka Connect esté completamente levantada (`HTTP 200`) antes de enviar las configuraciones.

---

## ⚙️ Tareas Principales que Ejecuta

1. **Healthcheck de Kafka Connect:** Espera hasta 30 reintentos a que `http://<kafka_connect>:8083/connectors` responda exitosamente.
2. **Registro de Debezium Source (`debezium-mongodb-source`):** Configura el conector fuente para leer el `oplog` del Replica Set primario de MongoDB (`telemetry_production`).
3. **Registro de MongoDB History Sink (`mongodb-history-sink`):** Configura el conector destino hacia `telemetry_production_history`, aplicando la política de retención inmutable y descartando operaciones de eliminación (`delete`).
4. **Validación de Estado:** Realiza una consulta final para certificar que ambos conectores figuran activos en la lista de Kafka Connect.

---

## 📋 Variables por Defecto (`defaults/main.yml`)

| Variable | Valor por Defecto | Descripción |
| :--- | :--- | :--- |
| `kafka_connect_url` | `"http://127.0.0.1:8083"` | Endpoint REST de Kafka Connect |
| `source_mongo_host` | `"192.168.10.20"` | IP o hostname del MongoDB primario |
| `source_database_name`| `"telemetry_production"` | Base de datos origen de eventos |
| `sink_mongo_host` | `"192.168.10.21"` | IP o hostname del MongoDB histórico |
| `sink_database_name` | `"telemetry_production_history"`| Base de datos destino inmutable |
| `connector_source_name`| `"debezium-mongodb-source"` | Identificador del conector fuente |
| `connector_sink_name` | `"mongodb-history-sink"` | Identificador del conector destino |

---

## 🚀 Uso en Playbooks

```yaml
- hosts: cdc_brokers
  become: true
  roles:
    - role: kafka_cdc
```
