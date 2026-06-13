# CHECKLIST PARA VIDEO - Evaluación 3
## Despliegue de tienda-perritos con Docker + ECS + CI/CD
### Duración objetivo: 10–15 minutos

---

## 🎬 Segmento 1: Arquitectura del proyecto (2 min)

- [ ] Mostrar el repositorio en GitHub
- [ ] Explicar las 3 capas:
  - **Frontend** (Nginx + HTML/JS) → puerto 80
  - **Backend** (Node.js + Express) → puerto 3001
  - **DB** (MySQL 8) → puerto 3306
- [ ] Mostrar `docker-compose.yml` y explicar la red interna
- [ ] Mostrar cada Dockerfile y explicar su función

**Guión sugerido:**
> "Este es un proyecto de 3 capas para una tienda de alimentos para perros. El frontend usa Nginx sirviendo HTML+JS, el backend es una API REST con Node.js + Express sobre MySQL. Todo orquestado con Docker Compose en 3 contenedores conectados por una red interna."

---

## 🎬 Segmento 2: Docker Compose en acción (3 min)

- [ ] Abrir terminal, ejecutar:
  ```bash
  docker compose up -d
  ```
- [ ] Mostrar `docker ps` con los 3 contenedores corriendo
- [ ] Abrir frontend en navegador (http://localhost)
- [ ] Abrir API REST (http://localhost:3001/api/productos)
- [ ] Hacer un CRUD completo:
  - [ ] **Crear** producto: llenar formulario y guardar
  - [ ] **Editar** producto: cambiar precio/stock
  - [ ] **Eliminar** producto: confirmar eliminación
- [ ] Mostrar `docker compose down` para detener

**Guión sugerido:**
> "Con un solo comando `docker compose up -d` levantamos los 3 servicios. Puedo verificar los 3 contenedores activos. La API devuelve productos y desde el frontend hago un CRUD completo: crear, editar y eliminar."

---

## 🎬 Segmento 3: Pipeline CI/CD con GitHub Actions (4 min)

- [ ] Mostrar `.github/workflows/deploy.yml` en GitHub
- [ ] Explicar el flujo:
  1. Push a main → dispara el workflow
  2. Build de las 3 imágenes Docker
  3. Push a Amazon ECR
  4. Deploy a ECS con `--force-new-deployment`
- [ ] Mostrar GitHub Secrets configurados:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- [ ] (Opcional) Hacer push a main y mostrar el action ejecutándose

**Guión sugerido:**
> "Mi pipeline de CI/CD con GitHub Actions se dispara automáticamente al hacer push a main. Build de las 3 imágenes, push a ECR y deploy automático a ECS con force new deployment. Las credenciales AWS están almacenadas como Secrets seguros en GitHub."

---

## 🎬 Segmento 4: Orquestación ECS Fargate (3 min)

- [ ] Mostrar `infrastructure/ecs-task-frontend.json` y explicar:
  - Familia, CPU (256), Memoria (512)
  - Modo Fargate (serverless)
  - Puerto mapeado (80 → 80)
- [ ] Mostrar `infrastructure/ecs-task-backend.json`:
  - Variables de entorno (DB_HOST, DB_USER, etc.)
- [ ] Mostrar `infrastructure/ecs-task-db.json`
- [ ] Explicar arquitectura final:
  ```
  Internet → ALB → Frontend (Fargate) → Backend (Fargate) → DB (Fargate)
  ```

**Guión sugerido:**
> "Para la orquestación en AWS elegí ECS Fargate por ser serverless (no pago por nodos). Tengo 3 task definitions, una por cada capa. Cada tarea pide 256 de CPU y 512 MB de RAM, suficiente para esta app. Un ALB frontend balancea el tráfico hacia los contenedores."

---

## 🎬 Segmento 5: Evaluación y mejora del pipeline (2 min)

- [ ] Identificar oportunidades de mejora:
  - **Docker layer caching**: Acelerar builds reutilizando capas
  - **Paralelización**: Construir frontend y backend en simultáneo
  - **Multi-stage builds**: Reducir tamaño de imágenes
  - **Health checks**: Agregar verificación post-deploy
  - **Rollbacks**: Estrategia para desplegar versión anterior

**Guión sugerido:**
> "El pipeline actual funciona, pero se puede optimizar: usando Docker layer cache para no reinstalar npm cada vez, paralelizando los builds de frontend y backend, y agregando multi-stage para reducir tamaño de imágenes y mejorar seguridad."

---

## 🎬 Segmento 6: Cierre (1 min)

- [ ] Resumir logros:
  - App funcional en Docker Compose
  - Pipeline CI/CD automatizado
  - Infraestructura ECS lista para desplegar
- [ ] Reflexión: importancia de DevOps en entornos productivos

**Guión sugerido:**
> "Este proyecto demuestra el ciclo completo DevOps: desarrollo local con Docker Compose, automatización del despliegue con GitHub Actions, y orquestación serverless con ECS Fargate. Todo listo para escalar a producción."

---

## 📦 Material adicional para el video

| Archivo | Link |
|---|---|
| Repositorio | https://github.com/LTassoD/tienda-perritos |
| Docker Compose | `docker-compose.yml` |
| Pipeline CI/CD | `.github/workflows/deploy.yml` |
| Task Definitions | `infrastructure/*.json` |

## ⚙️ Prerrequisitos para grabar
- [ ] Docker Desktop abierto
- [ ] Proyecto clonado en `tienda-perritos-demo`
- [ ] Navegador con http://localhost y http://localhost:3001/api/productos abiertos
- [ ] GitHub repo abierto en ventana del navegador
