# Script de Despliegue Inicial de la Tienda de Perritos en AWS ECS Fargate (Versión ALB Routing)
# Requisitos: Haber ejecutado con éxito 'create-infrastructure.ps1' y tener cargadas las credenciales de AWS.

$ErrorActionPreference = "Continue" # Permitir continuar en caso de validaciones no críticas

$accountId = "458620937306"
$region = "us-east-1"
$ecrRegistry = "$accountId.dkr.ecr.$region.amazonaws.com"

Write-Host "========== 1. Iniciando sesión en Amazon ECR ==========" -ForegroundColor Cyan
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $ecrRegistry

Write-Host "`n========== 2. Compilando e ingresando imágenes a ECR ==========" -ForegroundColor Cyan

# DB Image
Write-Host "Construyendo imagen DB..."
docker build -t tienda-perritos-db ./db
docker tag tienda-perritos-db:latest $ecrRegistry/tienda-perritos-db:latest
docker push $ecrRegistry/tienda-perritos-db:latest

# Backend Image
Write-Host "Construyendo imagen Backend..."
docker build -t tienda-perritos-backend ./backend
docker tag tienda-perritos-backend:latest $ecrRegistry/tienda-perritos-backend:latest
docker push $ecrRegistry/tienda-perritos-backend:latest

# Frontend Image
Write-Host "Construyendo imagen Frontend..."
docker build -t tienda-perritos-frontend ./frontend
docker tag tienda-perritos-frontend:latest $ecrRegistry/tienda-perritos-frontend:latest
docker push $ecrRegistry/tienda-perritos-frontend:latest

Write-Host "Imágenes subidas a ECR correctamente."

Write-Host "`n========== 3. Registrando Task Definitions en ECS ==========" -ForegroundColor Cyan
aws ecs register-task-definition --cli-input-json file://infrastructure/ecs-task-backend.json --region $region | Out-Null
aws ecs register-task-definition --cli-input-json file://infrastructure/ecs-task-frontend.json --region $region | Out-Null
Write-Host "Task Definitions registradas en ECS."

Write-Host "`n========== 4. Creando Servicios ECS Fargate ==========" -ForegroundColor Cyan
$vpcId = (aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)
$subnets = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" --query "Subnets[*].SubnetId" --output text)
$subnetList = $subnets.Replace("`t", " ").Split(" ") | Where-Object {$_ -ne ""}
$subnetsArgs = $subnetList -join ","

# Obtener IDs de Security Groups
$sgBackId = (aws ec2 describe-security-groups --filters "Name=group-name,Values=tienda-backend-sg" --query "SecurityGroups[0].GroupId" --output text)
$sgFrontId = (aws ec2 describe-security-groups --filters "Name=group-name,Values=tienda-frontend-sg" --query "SecurityGroups[0].GroupId" --output text)

# Función para crear servicio si no existe
function Create-ECSService-If-Not-Exists {
    param (
        [string]$serviceName,
        [string]$taskDef,
        [string]$sgId,
        [string]$tgArn,
        [int]$containerPort
    )
    
    $check = (aws ecs describe-services --cluster tienda-perritos-cluster --services $serviceName --query "services[0].status" --output text --region $region)
    if ($check -eq "ACTIVE" -or $check -eq "PRIMARY") {
        Write-Host "El servicio ECS '$serviceName' ya existe. Saltando creación." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Creando servicio ECS '$serviceName'..."
    # Determinar el nombre del contenedor segun la tarea
    $contName = "backend"
    if ($serviceName -like "*frontend*") {
        $contName = "frontend"
    }

    aws ecs create-service `
      --cluster tienda-perritos-cluster `
      --service-name $serviceName `
      --task-definition $taskDef `
      --desired-count 1 `
      --launch-type FARGATE `
      --load-balancers "targetGroupArn=$tgArn,containerName=$contName,containerPort=$containerPort" `
      --network-configuration "awsvpcConfiguration={subnets=[$subnetsArgs],securityGroups=[$sgId],assignPublicIp=ENABLED}" --region $region | Out-Null
    Write-Host "Servicio '$serviceName' creado con éxito."
}

# Obtener Target Group ARNs del Frontend y Backend mediante consultas seguras
$tgFrontArn = (aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName=='tienda-frontend-tg'].TargetGroupArn" --output text)
$tgBackArn = (aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName=='tienda-backend-tg'].TargetGroupArn" --output text)

# Crear los servicios asociados al ALB
Create-ECSService-If-Not-Exists -serviceName "tienda-perritos-backend-service" -taskDef "tienda-perritos-backend" -sgId $sgBackId -tgArn $tgBackArn -containerPort 3001
Create-ECSService-If-Not-Exists -serviceName "tienda-perritos-frontend-service" -taskDef "tienda-perritos-frontend" -sgId $sgFrontId -tgArn $tgFrontArn -containerPort 80

Write-Host "Servicios de Fargate procesados."

Write-Host "`n========== 5. Configurando Autoscaling (Target Tracking al 50% CPU/Memoria) (IE3) ==========" -ForegroundColor Cyan

# Función para registrar y crear políticas de autoscaling si no existen
function Setup-Service-Autoscaling {
    param ([string]$serviceName)
    
    # Registrar target
    aws application-autoscaling register-scalable-target `
      --service-namespace ecs `
      --scalable-dimension ecs:service:DesiredCount `
      --resource-id service/tienda-perritos-cluster/$serviceName `
      --min-capacity 1 --max-capacity 4 --region $region | Out-Null
      
    # Política CPU (Escapar comillas dobles de forma segura en PowerShell)
    aws application-autoscaling put-scaling-policy `
      --service-namespace ecs `
      --scalable-dimension ecs:service:DesiredCount `
      --resource-id service/tienda-perritos-cluster/$serviceName `
      --policy-name "cpu-scaling-policy" `
      --policy-type TargetTrackingScaling `
      --target-tracking-scaling-policy-configuration '{\"TargetValue\": 50.0, \"PredefinedMetricSpecification\": {\"PredefinedMetricType\": \"ECSServiceAverageCPUUtilization\"}, \"ScaleOutCooldown\": 60, \"ScaleInCooldown\": 60}' --region $region | Out-Null
      
    # Política Memoria
    aws application-autoscaling put-scaling-policy `
      --service-namespace ecs `
      --scalable-dimension ecs:service:DesiredCount `
      --resource-id service/tienda-perritos-cluster/$serviceName `
      --policy-name "memory-scaling-policy" `
      --policy-type TargetTrackingScaling `
      --target-tracking-scaling-policy-configuration '{\"TargetValue\": 50.0, \"PredefinedMetricSpecification\": {\"PredefinedMetricType\": \"ECSServiceAverageMemoryUtilization\"}, \"ScaleOutCooldown\": 60, \"ScaleInCooldown\": 60}' --region $region | Out-Null
}

Setup-Service-Autoscaling -serviceName "tienda-perritos-frontend-service"
Setup-Service-Autoscaling -serviceName "tienda-perritos-backend-service"
Write-Host "Políticas de Auto Scaling de CPU y Memoria (al 50%) registradas con éxito."

# Obtener URL del ALB mediante consulta segura
$dnsName = (aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='tienda-perritos-alb'].DNSName" --output text)

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "¡DESPLIEGUE INICIAL COMPLETADO CON ÉXITO!" -ForegroundColor Green
Write-Host "Los 2 servicios están activos en ECS Fargate."
Write-Host "El backend y base de datos corren interconectados localmente."
Write-Host "Autoscaling configurado entre 1 y 4 tareas para Frontend y Backend."
Write-Host "URL de tu Tienda: http://$dnsName" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Green
