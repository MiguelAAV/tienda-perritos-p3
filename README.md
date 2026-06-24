# Tienda de Alimentos para Perritos

Este proyecto es una aplicación web de tres capas diseñada para la gestión de productos de una tienda de alimentos para mascotas. Se encuentra dockerizado y desplegado en un entorno serverless en AWS ECS Fargate, automatizado mediante un pipeline de CI/CD con GitHub Actions.

---

## Arquitectura del Proyecto

El sistema está diseñado bajo buenas prácticas de ingeniería en la nube y seguridad de la información, estructurado en tres capas:

1.  **Frontend**: Servidor web con Nginx Alpine que sirve los archivos estáticos (HTML5 y JavaScript Vanilla).
2.  **Backend**: API REST en Node.js + Express que procesa la lógica de negocio y expone los endpoints CRUD en el puerto 3001.
3.  **Base de Datos (DB)**: Motor relacional MySQL 8 que persiste la información de los productos y se inicializa mediante scripts SQL.

```
                   [ Navegador del Cliente ]
                               │ (HTTP / Puerto 80)
                               ▼
               [ Application Load Balancer (ALB) ]
                               │
               ┌───────────────┴───────────────┐
               │ Ruta: /api/*                  │ Ruta: / (Por defecto)
               ▼                               ▼
     ┌───────────────────┐           ┌───────────────────┐
     │ Task Backend (3001)│           │ Task Frontend (80)│
     │   ┌───────────┐   │           │   ┌───────────┐   │
     │   │  Node.js  │   │           │   │   Nginx   │   │
     │   └─────┬─────┘   │           │   └───────────┘   │
     │         │ (localhost / 3306)  └───────────────────┘
     │   ┌─────▼─────┐   │
     │   │  MySQL 8  │   │
     │   └───────────┘   │
     └───────────────────┘
```

---

## Diseño de Seguridad y Redes

Para cumplir con las restricciones de entornos educativos (como AWS Academy) y garantizar la máxima seguridad informática, implementamos las siguientes estrategias:

*   **Enrutamiento Layer 7 en ALB**: Un único balanceador de carga público recibe todo el tráfico. Las peticiones a la API (/api/*) se redirigen al Target Group del Backend. El resto del tráfico va al Frontend. Esto mitiga problemas de CORS nativamente y centraliza el acceso.
*   **Tarea Multicontenedor (Sidecar)**: El Backend y la Base de Datos corren dentro de la misma definición de tarea en Fargate. Comparten el espacio de red local (127.0.0.1). MySQL no expone su puerto 3306 a la red de la VPC, aislándolo por completo de accesos no autorizados externos.
*   **Security Groups en Cascada**:
    *   tienda-alb-sg: Permite tráfico HTTP público (puerto 80) desde cualquier origen.
    *   tienda-frontend-sg: Permite puerto 80 únicamente desde el Security Group del ALB.
    *   tienda-backend-sg: Permite puerto 3001 únicamente desde el Security Group del ALB.

---

## Despliegue Local (Entorno de Desarrollo)

Para levantar el entorno completo localmente usando Docker Compose:

```bash
# Iniciar servicios en segundo plano
docker compose up -d

# Detener y limpiar contenedores
docker compose down
```
*   **Frontend**: Acceso en http://localhost
*   **API Backend**: Acceso en http://localhost:3001/api/productos

---

## Autorización del Aprovisionamiento (AWS CLI)

El proyecto cuenta con scripts de PowerShell para automatizar la creación de la infraestructura base y los despliegues en AWS:

1.  **create-infrastructure.ps1**:
    *   Detecta la VPC y subredes públicas por defecto.
    *   Crea los registros de imágenes en Amazon ECR.
    *   Crea el clúster ECS Fargate.
    *   Configura los Security Groups y el Application Load Balancer (ALB) con reglas HTTP en el puerto 80.
2.  **deploy-first-time.ps1**:
    *   Construye las imágenes locales y las sube a sus repositorios en ECR.
    *   Registra las Task Definitions multicontenedor.
    *   Crea los servicios ECS y configura políticas de Auto Scaling (IE3) para CPU y Memoria al 50% de umbral.

---

## Pipeline de CI/CD (GitHub Actions)

El archivo .github/workflows/deploy.yml gestiona el despliegue automático en cada push a la rama main:

1.  **Autenticación**: Configura credenciales usando secretos seguros (AWS_SESSION_TOKEN incluido).
2.  **Build & Push**: Compila las imágenes usando tags dinámicos basados en el SHA del commit y los sube a ECR.
3.  **Deployment**: Lanza una actualización forzada (--force-new-deployment) en los servicios de ECS para realizar despliegues tipo Rolling Update (cero tiempo de inactividad).

### Secrets Requeridos en GitHub:
*   AWS_ACCESS_KEY_ID
*   AWS_SECRET_ACCESS_KEY
*   AWS_SESSION_TOKEN (Requerido para credenciales temporales de AWS Academy)
