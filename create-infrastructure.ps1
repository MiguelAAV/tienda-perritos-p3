# Script de Automatización de Infraestructura AWS - Tienda de Perritos (Versión ALB Routing Defensiva)
# Requisitos: Tener instalado AWS CLI y configuradas las variables de entorno de AWS Academy.

$ErrorActionPreference = "Stop"

Write-Host "========== 1. Detectando VPC y Subredes por defecto ==========" -ForegroundColor Cyan
$vpcId = (aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)
if ($vpcId -eq "None" -or -not $vpcId) {
    Write-Error "No se encontró una VPC por defecto. Asegúrate de tener configurado el AWS CLI correctamente."
}
Write-Host "VPC por defecto detectada: $vpcId"

$subnets = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" --query "Subnets[*].SubnetId" --output text)
$subnetList = $subnets.Replace("`t", " ").Split(" ") | Where-Object {$_ -ne ""}
$subnetsArgs = $subnetList -join " "
Write-Host "Subredes detectadas: $subnetsArgs"

Write-Host "`n========== 2. Creando Repositorios en Amazon ECR ==========" -ForegroundColor Cyan
# Función para crear repositorio si no existe
function Create-ECR-If-Not-Exists {
    param ([string]$repoName)
    $check = (aws ecr describe-repositories --query "repositories[?repositoryName=='$repoName'].repositoryName" --output text 2>$null)
    if ($check -eq $repoName) {
        Write-Host "El repositorio ECR '$repoName' ya existe. Saltando creación." -ForegroundColor Yellow
    } else {
        aws ecr create-repository --repository-name $repoName --region us-east-1 | Out-Null
        Write-Host "Repositorio ECR '$repoName' creado con éxito."
    }
}
Create-ECR-If-Not-Exists -repoName "tienda-perritos-db"
Create-ECR-If-Not-Exists -repoName "tienda-perritos-backend"
Create-ECR-If-Not-Exists -repoName "tienda-perritos-frontend"

Write-Host "`n========== 3. Creando Clúster ECS Fargate ==========" -ForegroundColor Cyan
$clusterCheck = (aws ecs describe-clusters --query "clusters[?clusterName=='tienda-perritos-cluster'].clusterName" --output text --region us-east-1 2>$null)
if ($clusterCheck -eq "tienda-perritos-cluster") {
    Write-Host "El clúster ECS 'tienda-perritos-cluster' ya existe. Saltando creación." -ForegroundColor Yellow
} else {
    aws ecs create-cluster --cluster-name tienda-perritos-cluster --region us-east-1 | Out-Null
    Write-Host "Clúster 'tienda-perritos-cluster' creado con éxito."
}

Write-Host "`n========== 4. Creando Security Groups y Reglas de Entrada ==========" -ForegroundColor Cyan

# SG ALB
$sgAlbId = (aws ec2 describe-security-groups --filters "Name=group-name,Values=tienda-alb-sg" --query "SecurityGroups[0].GroupId" --output text 2>$null)
if (-not $sgAlbId -or $sgAlbId -eq "None" -or $sgAlbId -eq "") {
    $sgAlbId = (aws ec2 create-security-group --group-name "tienda-alb-sg" --description "SG para balanceador de carga" --vpc-id $vpcId --query "GroupId" --output text)
    Write-Host "Security Group ALB creado: $sgAlbId"
} else {
    Write-Host "Security Group ALB ya existe: $sgAlbId" -ForegroundColor Yellow
}

# SG Frontend Service
$sgFrontId = (aws ec2 describe-security-groups --filters "Name=group-name,Values=tienda-frontend-sg" --query "SecurityGroups[0].GroupId" --output text 2>$null)
if (-not $sgFrontId -or $sgFrontId -eq "None" -or $sgFrontId -eq "") {
    $sgFrontId = (aws ec2 create-security-group --group-name "tienda-frontend-sg" --description "SG para servicio Frontend" --vpc-id $vpcId --query "GroupId" --output text)
    Write-Host "Security Group Frontend creado: $sgFrontId"
} else {
    Write-Host "Security Group Frontend ya existe: $sgFrontId" -ForegroundColor Yellow
}

# SG Backend Service
$sgBackId = (aws ec2 describe-security-groups --filters "Name=group-name,Values=tienda-backend-sg" --query "SecurityGroups[0].GroupId" --output text 2>$null)
if (-not $sgBackId -or $sgBackId -eq "None" -or $sgBackId -eq "") {
    $sgBackId = (aws ec2 create-security-group --group-name "tienda-backend-sg" --description "SG para servicio Backend" --vpc-id $vpcId --query "GroupId" --output text)
    Write-Host "Security Group Backend creado: $sgBackId"
} else {
    Write-Host "Security Group Backend ya existe: $sgBackId" -ForegroundColor Yellow
}

# Configurar reglas de forma tolerante a errores duplicados
$previousPreference = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"

aws ec2 authorize-security-group-ingress --group-id $sgAlbId --protocol tcp --port 80 --cidr 0.0.0.0/0 2>$null
aws ec2 authorize-security-group-ingress --group-id $sgFrontId --protocol tcp --port 80 --source-group $sgAlbId 2>$null
aws ec2 authorize-security-group-ingress --group-id $sgBackId --protocol tcp --port 3001 --source-group $sgAlbId 2>$null

$ErrorActionPreference = $previousPreference
Write-Host "Reglas de Security Groups validadas (se agregaron reglas nuevas si aplicaba)."

Write-Host "`n========== 5. Creando Target Groups y Application Load Balancer ==========" -ForegroundColor Cyan

# Target Group Frontend
$tgFrontArn = (aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName=='tienda-frontend-tg'].TargetGroupArn" --output text 2>$null)
if (-not $tgFrontArn -or $tgFrontArn -eq "None" -or $tgFrontArn -eq "") {
    $tgFrontArn = (aws elbv2 create-target-group --name "tienda-frontend-tg" --protocol HTTP --port 80 --vpc-id $vpcId --target-type ip --query "TargetGroups[0].TargetGroupArn" --output text)
    Write-Host "Target Group Frontend creado: $tgFrontArn"
} else {
    Write-Host "Target Group Frontend ya existe: $tgFrontArn" -ForegroundColor Yellow
}

# Target Group Backend
$tgBackArn = (aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName=='tienda-backend-tg'].TargetGroupArn" --output text 2>$null)
if (-not $tgBackArn -or $tgBackArn -eq "None" -or $tgBackArn -eq "") {
    $tgBackArn = (aws elbv2 create-target-group --name "tienda-backend-tg" --protocol HTTP --port 3001 --vpc-id $vpcId --target-type ip --query "TargetGroups[0].TargetGroupArn" --output text)
    Write-Host "Target Group Backend creado: $tgBackArn"
} else {
    Write-Host "Target Group Backend ya existe: $tgBackArn" -ForegroundColor Yellow
}

# Load Balancer
$albArn = (aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='tienda-perritos-alb'].LoadBalancerArn" --output text 2>$null)
if (-not $albArn -or $albArn -eq "None" -or $albArn -eq "") {
    $albArn = (aws elbv2 create-load-balancer --name "tienda-perritos-alb" --subnets $subnetList --security-groups $sgAlbId --query "LoadBalancers[0].LoadBalancerArn" --output text)
    Write-Host "Application Load Balancer creado con éxito."
} else {
    Write-Host "Application Load Balancer ya existe: $albArn" -ForegroundColor Yellow
}

# Listener para redirigir tráfico al Target Group
$listenerArn = (aws elbv2 describe-listeners --load-balancer-arn $albArn --query "Listeners[0].ListenerArn" --output text 2>$null)
if (-not $listenerArn -or $listenerArn -eq "None" -or $listenerArn -eq "") {
    $listenerArn = (aws elbv2 create-listener --load-balancer-arn $albArn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$tgFrontArn --query "Listeners[0].ListenerArn" --output text)
    Write-Host "Listener HTTP asociado al puerto 80."
} else {
    Write-Host "Listener HTTP ya existe: $listenerArn" -ForegroundColor Yellow
}

# Agregar o validar regla de enrutamiento para redirigir /api/* al Backend Target Group
$rulesCheck = (aws elbv2 describe-rules --listener-arn $listenerArn --query "Rules[?Actions[0].TargetGroupArn=='$tgBackArn'].Priority" --output text 2>$null)
if (-not $rulesCheck -or $rulesCheck -eq "None" -or $rulesCheck -eq "") {
    aws elbv2 create-rule --listener-arn $listenerArn --priority 10 --conditions Field=path-pattern,Values='/api/*' --actions Type=forward,TargetGroupArn=$tgBackArn | Out-Null
    Write-Host "Regla de enrutamiento para '/api/*' creada con éxito (apunta al Backend)."
} else {
    Write-Host "La regla de enrutamiento para '/api/*' ya existe." -ForegroundColor Yellow
}

# Obtener URL pública del ALB
$dnsName = (aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='tienda-perritos-alb'].DNSName" --output text)

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "¡INFRAESTRUCTURA DE RED Y CONTENEDORES REGISTRADA CON ÉXITO!" -ForegroundColor Green
Write-Host "URL Pública del Frontend (ALB): http://$dnsName" -ForegroundColor Yellow
Write-Host "Enrutamiento de la API (/api/*) gestionado a nivel de ALB." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
