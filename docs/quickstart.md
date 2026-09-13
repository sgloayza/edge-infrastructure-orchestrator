# 🚀 Guía Rápida de Inicio y Verificación

🌐 **Idioma / Language:** **Español 🇪🇸** | [Switch to English 🇺🇸](quickstart.en.md)

Esta guía proporciona instrucciones paso a paso para ejecutar, probar y validar el **Edge Infrastructure Orchestrator** en un entorno de desarrollo local (Linux / WSL 2) o en servidores de pruebas.

---

## 1. Requisitos Previos

Asegúrate de contar con las siguientes herramientas instaladas:
* **Linux / WSL 2** (Ubuntu 22.04 o 24.04 recomendado)
* **Python 3.10+**
* **Ansible 2.15+** (`pip install ansible-core`)
* **Motor Docker & Docker Compose v2**

---

## 2. Configuración del Entorno

Clona el repositorio y copia la plantilla de configuración de variables de entorno:

```bash
# Navegar a la raíz del proyecto
cd edge-infrastructure-orchestrator

# Crear archivo .env a partir de la plantilla
cp docker/env.example docker/.env
```

Puedes revisar y personalizar las variables en `docker/.env` si deseas cambiar puertos o credenciales de prueba.

---

## 3. Validación del Motor de Orquestación de Ansible

Verifica que todos los playbooks pasen la comprobación de sintaxis sin errores:

```bash
cd ansible

# 1. Validar playbook maestro
ansible-playbook playbooks/site.yml --syntax-check -i inventory/hosts.example.yml

# 2. Validar aprovisionamiento de gateways Edge
ansible-playbook playbooks/setup_edge_nodes.yml --syntax-check -i inventory/hosts.example.yml

# 3. Validar despliegue de base de datos distribuida y Kafka CDC
ansible-playbook playbooks/setup_mongo_cdc.yml --syntax-check -i inventory/hosts.example.yml

# 4. Validar playbook de remediación y autorrecuperación
ansible-playbook playbooks/remediate_services.yml --syntax-check -i inventory/hosts.example.yml
```

Probar la ejecución del plugin de inventario dinámico:

```bash
python3 inventory/dynamic/issue_inventory.py --list
```

---

## 4. Ejecución de Demostraciones Visuales en Vivo

### A. Diagnóstico Integral del Clúster (`verify_cluster.sh`)
Verifica la salud y compatibilidad de Docker, Compose, Ansible, Python y el plugin de inventario:

```bash
./scripts/verify_cluster.sh
```

### B. Ejecución en Vivo de Ansible + Prometheus (`demo_ansible_live.sh`)
Ejecuta en tiempo real el playbook `playbooks/demo_local.yml`, despliega el exportador Prometheus Node Exporter en el puerto 9100 y corre el watchdog guardián:

```bash
# 1. Ejecutar demostración interactiva de Ansible
./scripts/demo_ansible_live.sh

# 2. Abrir métricas en vivo en tu navegador: http://localhost:9100/metrics

# 3. Detener la demostración y limpiar el entorno cuando termines
./scripts/stop_ansible_demo.sh
```

### C. Simulación Interactiva del Pipeline CDC (`demo_cdc.sh`)
Muestra paso a paso en consola cómo Debezium y Kafka capturan eventos en caliente y cómo la base histórica preserva el 100% de los datos ante un borrado accidental en el nodo primario:

```bash
./scripts/demo_cdc.sh
```

### C. Demostración Gráfica Interactiva en MongoDB Compass
Permite conectarte desde tu entorno gráfico de Windows y ver la replicación en vivo entre dos bases de datos:

```bash
# 1. Levantar instancias de MongoDB y el demonio CDC en tiempo real
./scripts/start_compass_demo.sh
```

Abre **MongoDB Compass** y crea dos conexiones:
* **MongoDB Primario (Operativo):**  
  `mongodb://admin:SuperSecurePassword2026!@localhost:27027/?authSource=admin`  
  *(Base: `telemetry_production` ➡️ Colección: `telemetry_live`)*
* **MongoDB Histórico (Auditoría Inmutable):**  
  `mongodb://admin:SuperSecurePassword2026!@localhost:27028/?authSource=admin`  
  *(Base: `telemetry_history` ➡️ Colección: `telemetry_audit`)*

> 💡 **Prueba interactiva:** Si agregas cualquier documento en `telemetry_live` (27027), haz clic en **Refresh** (🔄) en `telemetry_audit` (27028) y verás cómo el demonio CDC lo replica al instante. Si lo borras en el primario, en el histórico se conserva intacto con la marca de auditoría legal.

```bash
# 2. Destruir el entorno y liberar memoria al finalizar
./scripts/stop_compass_demo.sh
```

---

## 5. Limpieza de Stacks Completos de Docker

Si levantaste los stacks completos de producción o CDC con Docker Compose, puedes detenerlos y limpiar volúmenes con:

```bash
docker compose -f docker/compose/docker-compose.prod.yml down -v
docker compose -f docker/compose/docker-compose.cdc.yml down -v
```
