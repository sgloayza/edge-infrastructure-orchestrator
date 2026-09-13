# 🍃 Rol Ansible: `mongo_replica`

Este rol automatiza el aprovisionamiento de nodos de base de datos **MongoDB 7.0**, la inicialización de conjuntos de réplicas (**Replica Sets** con `oplog` activo) y la configuración de índices de retención de datos (**TTL Indexes**).

---

## 🎯 ¿Qué Problema Resuelve?

1. **Requisito obligatorio para CDC:** Para que herramientas como Debezium puedan capturar cambios en tiempo real, MongoDB exige obligatoriamente estar en modo Replica Set para generar el registro transaccional interno (`oplog.rs`).
2. **Crecimiento desmedido de la base operativa:** Sin políticas de retención, las colecciones de telemetría en caliente crecen indefinidamente. Este rol aplica índices TTL para purgar automáticamente datos operativos antiguos (ej. más de 60 días), dejando el histórico a largo plazo protegido en el nodo secundario de auditoría.
3. **Control de Recursos y Hardening:** Aplica límites explícitos de CPU y memoria RAM (2GB) para impedir que el motor de base de datos sature el host.

---

## ⚙️ Tareas Principales que Ejecuta

1. **Estructura de Directorios:** Crea los puntos de montaje para la persistencia de datos (`/opt/mongo-data/db`) y scripts de inicialización.
2. **Despliegue del Contenedor MongoDB:** Levanta la imagen oficial `mongo:7.0` con la directiva `--replSet rs0 --bind_ip_all`, autenticación administrativa protegida y límites de recursos estrictos.
3. **Script de Inicialización (`init_replica.js.j2`):** Renderiza el script que ejecuta `rs.initiate()` y crea los índices TTL en la colección de telemetría (`expireAfterSeconds`).
4. **Ejecución Idempotente:** Espera a que el puerto de base de datos esté accesible (`wait_for`) y ejecuta la inicialización interna mediante `mongosh` con control de cambios.

---

## 📋 Variables por Defecto (`defaults/main.yml`)

| Variable | Valor por Defecto | Descripción |
| :--- | :--- | :--- |
| `mongo_image` | `"mongo:7.0"` | Imagen de contenedor oficial de MongoDB |
| `mongo_port` | `27017` | Puerto de escucha en el host |
| `mongo_container_name` | `"mongodb_replica"` | Nombre del contenedor Docker |
| `mongo_replset_name` | `"rs0"` | Nombre del conjunto de réplica |
| `mongo_data_dir` | `"/opt/mongo-data"` | Directorio de persistencia en disco del host |
| `retention_days` | `60` | Días de retención TTL en la base operativa |
| `mongo_database_name` | `"telemetry_production"`| Base de datos principal de telemetría |
| `mongo_admin_user` | `"admin"` | Usuario administrador raíz |
| `mongo_admin_password` | `"SuperSecurePassword2026!"` | Contraseña administrativa sanitizada |

---

## 🚀 Uso en Playbooks

```yaml
- hosts: database_cluster
  become: true
  roles:
    - role: mongo_replica
```
