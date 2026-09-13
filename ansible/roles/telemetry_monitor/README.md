# 📊 Rol Ansible: `telemetry_monitor`

Este rol implementa la **observabilidad en tiempo real** y el sistema de **autorrecuperación proactiva (Hardware Watchdog)** en los nodos de cómputo Edge.

---

## 🎯 ¿Qué Problema Resuelve?

1. **Falta de visibilidad en nodos remotos:** Los gateways en campo no tienen pantalla ni teclado. Es indispensable exponer métricas del sistema (CPU, temperatura, RAM, disco y red) hacia herramientas centrales como Prometheus o Grafana.
2. **Caídas silenciosas por fugas de memoria (OOM):** Si un servicio satura la memoria RAM de una placa Orange Pi (1GB – 2GB), el kernel de Linux congela el equipo.
3. **Mantenimiento reactivo:** En lugar de esperar a que un cliente reporte la caída del nodo, el watchdog local ejecuta alertas y limpiezas preventivas de forma autónoma.

---

## ⚙️ Tareas Principales que Ejecuta

1. **Despliegue de Prometheus Node Exporter:** Levanta el contenedor `node_exporter` en modo `network_mode: host` con acceso de solo lectura a `/proc` y `/sys`, acotado a un consumo microscópico de recursos (0.2 CPU y 128MB RAM).
2. **Instalación del Watchdog (`watchdog.sh`):** Despliega un script en Bash que inspecciona periódicamente los porcentajes reales de uso de memoria RAM y ocupación de disco.
3. **Cron Job Periódico:** Programa la ejecución del watchdog cada 5 minutos (`*/5 * * * *`) para certificar la salud del hardware y reiniciar proactivamente servicios degradados si la RAM supera el 85% o el disco el 80%.

---

## 📋 Variables por Defecto (`defaults/main.yml`)

| Variable | Valor por Defecto | Descripción |
| :--- | :--- | :--- |
| `node_exporter_port` | `9100` | Puerto de métricas para Prometheus |
| `node_exporter_image`| `"prom/node-exporter:v1.8.2"` | Imagen oficial del exportador |
| `monitor_dir` | `"/opt/telemetry-monitor"` | Directorio local del script watchdog |
| `ram_warning_threshold_percent` | `85` | Porcentaje de RAM para disparar alertas/remediación |
| `disk_warning_threshold_percent`| `80` | Porcentaje de disco para alertar saturación |
| `enable_periodic_healthcheck_cron`| `true` | Habilita o deshabilita la tarea programada en cron |

---

## 🚀 Uso en Playbooks

```yaml
- hosts: edge_gateways
  become: true
  roles:
    - role: telemetry_monitor
```
