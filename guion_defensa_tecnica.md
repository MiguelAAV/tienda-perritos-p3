# Guion y Estructura de la Defensa Tecnica - Prueba 3 DevOps
## Proyecto: Tienda de Alimentos para Perritos
## Estudiante: Miguel Arredondo
## Duracion Objetivo: 10 a 15 minutos

Este documento sirve como guia paso a paso y guion para la grabacion de tu video individual. Puedes copiar y pegar todo este texto en Microsoft Word para imprimirlo o tenerlo de apoyo en una segunda pantalla durante la grabacion.

---

## Estructura General y Tiempos Sugeridos

| Segmento | Duracion | Que mostrar en pantalla | Temas clave a explicar |
| :--- | :--- | :--- | :--- |
| **1. Introduccion y Pitch** | 1.5 min | Tu camara encendida y el repositorio de GitHub de fondo. | Presentacion, contexto de Innovatech Chile y eleccion de ECS Fargate. |
| **2. Demo y Codigo Local** | 2.5 min | VS Code (docker-compose, Dockerfiles) y navegador en localhost. | Docker Compose, healthchecks locales y demo CRUD local. |
| **3. Arquitectura y Red AWS** | 3.0 min | Consola de AWS (ECS, ALB, Security Groups) y diagramas. | Tarea multicontenedor, enrutamiento ALB Layer 7 y seguridad. |
| **4. Pipeline CI/CD** | 2.5 min | Pestaña Actions en GitHub, deploy.yml y GitHub Secrets. | Integracion continua, resguardo de secrets y AWS Session Token. |
| **5. Demo AWS en Vivo** | 3.0 min | Tienda en la URL publica del ALB y Logs en ECS/CloudWatch. | CRUD funcional en produccion, persistencia y monitoreo de logs. |
| **6. Analisis Critico y Cierre**| 1.5 min | Tu camara o la tienda web. | Resolucion de problemas y propuesta de mejora (RDS). |

---

## Guion Detallado Paso a Paso

### Segmento 1: Introduccion y Pitch del Proyecto (Tiempo: 0:00 - 1:30)

*   **Que mostrar en pantalla**: Tu camara encendida en una esquina o pantalla completa, y el navegador mostrando tu repositorio de GitHub `https://github.com/MiguelAAV/tienda-perritos-p3`.
*   **Guion sugerido**:
    > "Estimado docente, mi nombre es Miguel Arredondo y en esta presentación técnica individual abordaré el diseño, implementación y automatización del entorno productivo para la empresa Innovatech Chile. El objetivo es llevar la aplicación de tres capas 'tienda-perritos' a un clúster serverless de AWS altamente disponible, escalable y automatizado mediante un pipeline de CI/CD.
    > 
    > Para este despliegue, la decisión de arquitectura principal fue utilizar **AWS ECS Fargate**. Al ser una tecnología serverless de contenedores, nos permite delegar la administración de servidores físicos a AWS, reduciendo costos operativos y permitiendo una rápida escalabilidad por seguimiento de objetivos de CPU y memoria, ideal para una tienda de alimentos de mascotas con tráfico dinámico."

---

### Segmento 2: Entorno de Desarrollo y Dockerizacion Local (Tiempo: 1:30 - 4:00)

*   **Que mostrar en pantalla**: Tu IDE (VS Code o Antigravity) mostrando el archivo `docker-compose.yml` y los Dockerfiles de las subcarpetas. Abre la terminal e inicia los servicios locales.
*   **Acciones en pantalla**:
    1.  Muestra el `docker-compose.yml` destacando la red `tienda-net` y la dependencia `condition: service_healthy` del backend.
    2.  Ejecuta `docker compose up -d` en tu terminal.
    3.  Abre `http://localhost` y realiza un CRUD rápido (crear un producto, editarle el precio y luego cancelarlo o eliminarlo).
    4.  Ejecuta `docker compose down` al finalizar.
*   **Guion sugerido**:
    > "Comenzamos en nuestro entorno de desarrollo local. Para garantizar la portabilidad de las tres capas (frontend, backend y base de datos), creamos contenedores dockerizados basados en imágenes livianas Alpine.
    > 
    > En nuestro archivo `docker-compose.yml`, estructuramos los servicios conectados a una red local aislada. Implementamos un healthcheck en la base de datos MySQL para que el backend de Node.js espere a que la base de datos esté lista antes de inicializar el servidor de Express, previniendo fallas de conexión al arrancar. Levanto los servicios locales con un solo comando, y como pueden observar, el frontend en el puerto 80 responde, permitiéndonos realizar un CRUD completo sobre nuestra base de datos local MySQL."

---

### Segmento 3: Arquitectura y Redes en la Nube de AWS (Tiempo: 4:00 - 7:00)

*   **Que mostrar en pantalla**: La consola de AWS web. Ve al servicio de **ECS** y muestra el clúster `tienda-perritos-cluster` y las dos Task Definitions. Luego ve a **EC2 / Security Groups** y **Load Balancers** para mostrar la red.
*   **Acciones en pantalla**:
    1.  Muestra los 2 servicios activos en ECS: `tienda-perritos-frontend-service` y `tienda-perritos-backend-service`.
    2.  Muestra los Security Groups y sus reglas asociadas.
    3.  Muestra el Application Load Balancer `tienda-perritos-alb` y sus reglas de Listener (redirigir `/api/*` al backend y `/` al frontend).
*   **Guion sugerido**:
    > "Al migrar a la nube de AWS, nos adaptamos a las restricciones de la API de Cloud Map en cuentas de estudiantes de AWS Academy. Para superar el bloqueo de DNS internos, implementamos una arquitectura altamente eficiente basada en dos soluciones de diseño:
    > 
    > Primero, a nivel del **Application Load Balancer (ALB)**, configuramos enrutamiento nativo de Capa 7. El ALB recibe el tráfico público de internet y evalúa las rutas HTTP: si el cliente consulta `/api/*`, el balanceador redirige la petición al backend en el puerto 3001; para cualquier otra ruta, redirige al frontend. Esto elimina la necesidad de proxies internos en Nginx y mitiga problemas de CORS de raíz.
    > 
    > Segundo, implementamos el **patrón multicontenedor** en ECS Fargate, agrupando el Backend de Node y la base de datos MySQL 8 dentro de la misma definición de tarea. Ambos comparten la interfaz de red local `127.0.0.1`, permitiendo al backend conectarse a la base de datos de forma privada. Esto es sumamente seguro, ya que el puerto 3306 de MySQL queda completamente aislado, con una superficie de ataque externa de cero.
    > 
    > A nivel de seguridad de red, los Security Groups se estructuraron en cascada: el ALB es el único expuesto al público, el Frontend solo acepta tráfico proveniente del ALB en el puerto 80, y el Backend solo acepta tráfico del ALB en el puerto 3001."

---

### Segmento 4: Pipeline de CI/CD con GitHub Actions (Tiempo: 7:00 - 9:30)

*   **Que mostrar en pantalla**: Tu repositorio en GitHub, ve a la pestaña **Actions** para mostrar los flujos de ejecución exitosos (en verde). Luego abre el archivo `.github/workflows/deploy.yml` y muestra los GitHub Secrets de tu configuración.
*   **Acciones en pantalla**:
    1.  Navega por las ejecuciones exitosas de Actions.
    2.  Muestra el archivo `deploy.yml`.
    3.  Muestra la sección de Settings -> Secrets -> Actions sin revelar los valores.
*   **Guion sugerido**:
    > "La automatización es el núcleo del flujo de trabajo de desarrollo (DevOps). Diseñamos un pipeline de CI/CD utilizando **GitHub Actions**. El archivo `deploy.yml` se dispara automáticamente con cada `push` a la rama `main`.
    > 
    > El pipeline realiza los siguientes pasos secuenciales: primero, configura las credenciales de AWS utilizando secretos seguros de GitHub, inyectando el `AWS_SESSION_TOKEN` obligatorio por ser credenciales de estudiante. Segundo, realiza el build de las tres imágenes usando el SHA del commit como tag para garantizar trazabilidad. Tercero, empuja las imágenes a Amazon ECR. Y cuarto, actualiza los servicios en ECS Fargate forzando un nuevo despliegue. ECS realiza un despliegue progresivo de tipo *Rolling Update*, levantando los nuevos contenedores y verificando su salud antes de apagar las versiones antiguas, garantizando cero tiempo de inactividad para los usuarios finales."

---

### Segmento 5: Demostracion Funcional y Monitoreo (Tiempo: 9:30 - 12:30)

*   **Que mostrar en pantalla**: El navegador abierto en la URL de tu balanceador de carga público de AWS. Realiza un CRUD en vivo. Luego ve a la consola de AWS ECS -> Servicios -> Logs para mostrar el monitoreo en vivo.
*   **Acciones en pantalla**:
    1.  Abre `http://tienda-perritos-alb-115946312.us-east-1.elb.amazonaws.com`.
    2.  Agrega un producto (ej. "Alimento Fargate Premium", Precio: "24990", Stock: "30"), haz clic en Guardar y muestra que aparece en la tabla.
    3.  Edita el producto (ej. cambia el precio a "25990") y guárdalo.
    4.  Muestra los logs del contenedor del Backend en la consola de ECS, destacando las peticiones POST y PUT registradas en consola.
*   **Guion sugerido**:
    > "A continuación, vemos la demostración de la aplicación en vivo en la nube de AWS, utilizando la URL pública provista por el Application Load Balancer. Como podemos observar, el sitio carga rápidamente y nos presenta el inventario inicial. 
    > 
    > Si realizamos una operación de creación agregando un nuevo producto, el formulario valida los datos y los envía al backend, el cual inserta el registro en MySQL. Podemos verificar que la tabla se actualiza. Asimismo, si editamos o eliminamos el producto, el cambio persiste de inmediato.
    > 
    > Para el monitoreo y auditoría, configuramos los logs de ejecución. En la pestaña de Logs de ECS podemos ver en tiempo real cómo el servidor Express registra las peticiones HTTP y las conexiones exitosas del pool de MySQL, lo que facilita el análisis de logs y resolución de incidentes ante cualquier fallo."

---

### Segmento 6: Analisis Critico de Resolucion de Problemas y Cierre (Tiempo: 12:30 - 14:00)

*   **Que mostrar en pantalla**: Vuelve a tu camara a pantalla completa o mantén la tienda web activa de fondo.
*   **Guion sugerido**:
    > "Como balance final y análisis crítico de la implementación, tuvimos que resolver desafíos importantes:
    > 
    > El principal problema fue la restricción de privilegios en la API de Cloud Map de AWS Academy, la cual resolvimos adaptando la arquitectura de red mediante reglas de enrutamiento a nivel de ALB y aplicando la tarea multicontenedor. Adicionalmente, detectamos e implementamos un Health Check path explícito hacia `/api/health` en el Target Group del backend, evitando que el balanceador marcara al backend como no saludable por el retorno 404 por defecto y previniendo los reinicios cíclicos de la tarea.
    > 
    > Como propuesta de mejora continua para llevar la aplicación a un entorno productivo real de Innovatech Chile, sugerimos dos puntos: primero, migrar la base de datos MySQL desde Fargate hacia **Amazon RDS MySQL** para independizar el ciclo de vida de los datos del contenedor, garantizando alta disponibilidad con Multi-AZ y respaldos automatizados. Y segundo, implementar Docker Layer Caching en el pipeline de GitHub Actions para reducir los tiempos de compilación de las dependencias de Node.js.
    > 
    > En conclusión, esta entrega cumple con todos los objetivos técnicos evaluados de forma robusta, segura y automatizada. Muchas gracias."
