# 🌐 Rol Ansible: `edge_gateway`

Este rol se encarga de desplegar y mantener el **Proxy Inverso Nginx de borde** en los nodos gateway (Orange Pi / Linux Gateways).

---

## 🎯 ¿Qué Problema Resuelve?

1. **Exposición insegura de microservicios internos:** En lugar de exponer directamente la API local de telemetría o servicios backend al puerto de red externo, Nginx actúa como puerta de enlace centralizada (Gateway).
2. **Compatibilidad Multi-Arquitectura:** Utiliza una imagen ultraligera basada en Alpine Linux (`nginx:1.27-alpine`) que pesa menos de 30MB y es 100% compatible tanto con procesadores **ARM64 (Orange Pi)** como con **x86_64**.
3. **Validación Continua de Salud (Healthchecks):** Monitorea activamente mediante un probe HTTP interno (`/healthz`) para detectar si el proxy se degrada o pierde conectividad con el backend.

---

## ⚙️ Tareas Principales que Ejecuta

1. **Estructura de Directorios:** Crea `/opt/edge-gateway/nginx` y `/opt/edge-gateway/logs` con permisos restringidos.
2. **Renderizado de Configuración (`nginx.conf.j2`):** Genera la configuración de Nginx con políticas de timeouts optimizadas para redes Edge intermitentes (`proxy_connect_timeout: 10s`), compresión Gzip y proxy pass hacia la API interna (`127.0.0.1:8080`).
3. **Despliegue del Contenedor Docker:** Levanta el contenedor `edge_proxy` en modo `network_mode: host` para mínima latencia, con rotación de logs de 20MB y healthcheck automático cada 30 segundos.

---

## 📋 Variables por Defecto (`defaults/main.yml`)

| Variable | Valor por Defecto | Descripción |
| :--- | :--- | :--- |
| `edge_gateway_dir` | `"/opt/edge-gateway"` | Ruta base en el host para configuraciones y logs |
| `nginx_container_name` | `"edge_proxy"` | Nombre del contenedor Docker |
| `nginx_image` | `"nginx:1.27-alpine"` | Imagen base ligera de Nginx |
| `edge_http_port` | `80` | Puerto HTTP público de entrada |
| `backend_api_host` | `"127.0.0.1"` | Host del backend o microservicio de telemetría |
| `backend_api_port` | `8080` | Puerto de la API interna protegida |
| `client_max_body_size` | `"20m"` | Tamaño máximo de payloads permitido |

---

## 🚀 Uso en Playbooks

```yaml
- hosts: edge_gateways
  become: true
  roles:
    - role: edge_gateway
```
