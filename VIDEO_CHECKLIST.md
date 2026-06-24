# CHECKLIST PARA VIDEO - Evaluacion 3
## Despliegue de tienda-perritos con Docker + ECS Fargate + CI/CD
### Duracion objetivo: 10 a 15 minutos

---

## Segmento 1: Arquitectura del proyecto (2 min)

- [ ] Mostrar el repositorio en GitHub.
- [ ] Explicar la arquitectura de 3 capas local:
  - Frontend (Nginx + HTML/JS) sirviendo en puerto 80.
  - Backend (Node.js + Express) expuesto en puerto 3001.
  - DB (MySQL 8) expuesto en puerto 3306.
- [ ] Mostrar docker-compose.yml y explicar la red interna y la dependencia con condition: service_healthy para el backend.
- [ ] Mostrar cada Dockerfile local y explicar su funcion (Alpine, Nginx y MySQL).

**Guion sugerido:**
> "Este es un proyecto de 3 capas para una tienda de alimentos para mascotas. Contamos con un frontend en Nginx sirviendo estáticos, una API backend en Node.js + Express y una base de datos MySQL 8. En desarrollo local, docker-compose.yml orquesta los tres contenedores conectados por una red interna bridge."

---

## Segmento 2: Docker Compose en accion (2 min)

- [ ] Abrir la terminal de VS Code y ejecutar:
  ```bash
  docker compose up -d
  ```
- [ ] Mostrar docker ps para comprobar los 3 contenedores corriendo localmente.
- [ ] Abrir el navegador en http://localhost y en http://localhost:3001/api/productos.
- [ ] Realizar un CRUD completo localmente (crear, editar y eliminar un producto) para verificar la persistencia de datos.
- [ ] Mostrar docker compose down para detener y limpiar el entorno.

**Guion sugerido:**
> "Con el comando docker compose up -d levantamos los 3 contenedores. Podemos ver el frontend y la API respondiendo en localhost. El CRUD funciona perfectamente persistiendo los datos en el contenedor de MySQL. Ahora detenemos los servicios locales con docker compose down."

---

## Segmento 3: Arquitectura y Orquestacion en AWS ECS Fargate (3 min)

- [ ] Explicar el rediseño de arquitectura en AWS para superar restricciones de red:
  - **Enrutamiento por Capa 7 en ALB**: Un único Application Load Balancer (ALB) recibe el tráfico. La ruta /api/* es redirigida al backend (puerto 3001) y el resto del tráfico al frontend (puerto 80). Esto soluciona CORS de raíz.
  - **Tarea Multicontenedor (Sidecar)**: El backend y la base de datos MySQL corren dentro de la misma definicion de tarea Fargate. Se comunican localmente vía 127.0.0.1:3306. Esto aisla el puerto de MySQL de la red externa para máxima seguridad.
- [ ] Mostrar ecs-task-backend.json y ecs-task-frontend.json en VS Code.
- [ ] Mostrar los dos servicios activos en la Consola Web de AWS ECS (tienda-perritos-backend-service y tienda-perritos-frontend-service) y el estado de sus tareas.
- [ ] Mostrar los Security Groups creados en capas (tienda-alb-sg, tienda-frontend-sg, tienda-backend-sg).
- [ ] Mostrar las politicas de Auto Scaling configuradas por seguimiento de objetivos al 50% de CPU y memoria.

**Guion sugerido:**
> "Para desplegar en producción en AWS ECS, seleccionamos Fargate por ser serverless. Diseñamos una arquitectura segura y optimizada: el backend y la base de datos corren en una sola tarea multicontenedor, conectándose vía localhost sin exponer puertos de base de datos a la red. El balanceador ALB gestiona el tráfico público redirigiendo la API al backend. La escalabilidad está asegurada mediante políticas de Auto Scaling al 50% de uso de CPU y memoria para duplicar tareas de forma automática."

---

## Segmento 4: Pipeline CI/CD con GitHub Actions (3 min)

- [ ] Mostrar .github/workflows/deploy.yml en GitHub.
- [ ] Explicar el flujo del pipeline automatizado:
  1. Push a main como disparador del workflow.
  2. Autenticación segura mediante credenciales de AWS (inyectando AWS_SESSION_TOKEN por ser credenciales temporales de AWS Academy).
  3. Construcción (Build) de las 3 imágenes Docker.
  4. Push de las imágenes a Amazon ECR.
  5. Despliegue (Deploy) en ECS forzando un nuevo despliegue (--force-new-deployment) de forma progresiva en los servicios Frontend y Backend.
- [ ] Mostrar los Secrets configurados de forma segura en GitHub Settings.

**Guion sugerido:**
> "El pipeline de CI/CD se dispara con cada push a la rama main. Utiliza secretos de GitHub para autenticarse temporalmente de forma segura en AWS, construye y sube las imágenes a ECR y realiza un despliegue progresivo en ECS para evitar tiempos de inactividad."

---

## Segmento 5: Evaluacion, Mejora y Cierre (2 min)

- [ ] Mostrar la URL publica de la tienda corriendo sobre el ALB en vivo y realizar un CRUD rapido sobre AWS.
- [ ] Mostrar los logs en la consola de ECS (o CloudWatch Logs) demostrando monitoreo activo.
- [ ] Mencionar oportunidades de optimización y mejoras técnicas:
  - **Uso de Amazon RDS**: Migrar la base de datos desde Fargate hacia Amazon RDS en producción real de Innovatech Chile para asegurar almacenamiento persistente persistido de datos (no efímero).
  - **Docker Layer Caching**: Optimizar los tiempos del pipeline guardando cache de npm en los builds.
  - **Rollbacks**: Implementar políticas de reversión de versiones basadas en tags de git.
- [ ] Reflexion final de lo aprendido.

**Guion sugerido:**
> "La tienda funciona perfectamente en producción sobre la URL del ALB en AWS. Vemos los logs de consultas SQL en CloudWatch. Como mejoras críticas para llevar esto a un entorno de producción real, sugerimos migrar la base de datos relacional a Amazon RDS y optimizar el caché de compilación en el pipeline. Este proyecto demuestra el valor de la automatización y la infraestructura ágil en la nube."
