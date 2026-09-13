# 🛡️ Rol Ansible: `common_hardening`

Este rol se encarga del **aseguramiento base (Hardening)** y la preparación del sistema operativo en todos los nodos del clúster (tanto microordenadores Edge como servidores de base de datos).

---

## 🎯 ¿Qué Problema Resuelve?

1. **Colapso de disco por logs infinitos:** En dispositivos con tarjetas flash (microSD / eMMC), los contenedores de Docker escriben logs sin límite hasta llenar el disco y congelar el equipo.
2. **Desincronización de eventos:** Si un nodo tiene una zona horaria diferente, los registros de telemetría y auditoría se vuelven inútiles para análisis forense.
3. **Bloqueo por límites de procesos (uLimits):** Por defecto, Linux restringe el número de archivos y procesos abiertos, causando errores de tipo `Too many open files` en servicios de alta concurrencia.

---

## ⚙️ Tareas Principales que Ejecuta

1. **Sincronización Horaria Determinista:** Enlaza `/etc/localtime` con la zona horaria definida (`system_timezone`) y escribe `/etc/timezone`.
2. **Ajuste de Límites del Sistema (`limits.conf`):** Eleva los límites de descriptores de archivos (`nofile: 65535`) y procesos concurrentes (`nproc: 32768`).
3. **Blindaje de Logs en Docker (`daemon.json`):** Configura el demonio de Docker con rotación automática mediante `json-file` (máximo 50MB por archivo y 5 copias históricas). Si se altera la configuración, notifica al handler para reiniciar el servicio Docker de forma controlada.
4. **Instalación de Paquetes de Diagnóstico:** Asegura la presencia de herramientas esenciales de monitoreo por consola (`curl`, `htop`, `iotop`, `sysstat`).

---

## 📋 Variables por Defecto (`defaults/main.yml`)

| Variable | Valor por Defecto | Descripción |
| :--- | :--- | :--- |
| `system_timezone` | `"America/Guayaquil"` | Zona horaria aplicada a nivel del sistema |
| `docker_log_driver` | `"json-file"` | Driver de almacenamiento de logs de Docker |
| `docker_log_max_size` | `"50m"` | Tamaño máximo antes de rotar el archivo de log |
| `docker_log_max_files` | `"5"` | Cantidad máxima de archivos retenidos |
| `nofile_limit` | `65535` | Límite máximo de descriptores de archivo abiertos |
| `nproc_limit` | `32768` | Límite máximo de hilos/procesos del sistema |

---

## 🚀 Uso en Playbooks

```yaml
- hosts: all
  become: true
  roles:
    - role: common_hardening
```
