# PowerShell script to deploy and start Delta-V Docker containers

Write-Host "WARNING: Do you wish to prune all docker images first (you really dont want to do this on every run)?"
$choice = Read-Host "Enter choice (Yes/No)"

if ($choice -eq "Yes") {
    Write-Host "Pruning docker images"
    
    # Remove all containers
    $containers = docker ps -aq 2>$null
    if ($containers) {
        docker rm -f $containers | Out-Null
    }
    
    # Remove all volumes
    $volumes = docker volume ls -q 2>$null
    if ($volumes) {
        docker volume rm -f $volumes | Out-Null
    }
    
    # Prune system
    docker system prune -a --volumes -f | Out-Null
}
else {
    Write-Host "Not pruning docker images"
}

#Set-Location ./target

# Clean up and create delta-v-smoke directory
if (Test-Path .\target\delta-v-smoke) {
    Remove-Item -Path .\target\delta-v-smoke -Recurse -Force
}
New-Item -ItemType Directory -Path .\target\delta-v-smoke | Out-Null
#Set-Location .\target\delta-v-smoke

# Configure version variables
$GIT_REF = "v1.3.0"
$IMG_TAG = "1.3.0"

$BASE = "https://raw.githubusercontent.com/pbrane/delta-v/$GIT_REF/deploy"

# Download docker-compose files
Write-Host "Downloading docker-compose files from $BASE..."
Invoke-WebRequest -Uri "$BASE/compose.yml" -OutFile ".\target\delta-v-smoke\compose.yml"
Invoke-WebRequest -Uri "$BASE/compose.override.dev.yml" -OutFile ".\target\delta-v-smoke\compose.override.dev.yml"

# Create .env file
$envContent = @"
IMAGE_PREFIX=ghcr.io/pbrane
VERSION=$IMG_TAG
"@
Set-Content -Path ".\target\delta-v-smoke\.env" -Value $envContent

# Pull and start containers
Write-Host "Pulling containers..."
docker compose -f ./target/delta-v-smoke/compose.yml -f ./target/delta-v-smoke/compose.override.dev.yml -f docker-compose-nginx-proxy.yml --profile full --profile metrics pull

Write-Host "Starting containers..."
docker compose -f ./target/delta-v-smoke/compose.yml -f ./target/delta-v-smoke/compose.override.dev.yml -f docker-compose-nginx-proxy.yml --profile full --profile metrics up -d

# Determine host IP (IPv4)
$HOST_IP = $null
try {
    $hostIPs = [System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName())
    if ($hostIPs -and $hostIPs.Count -gt 0) {
        # Filter for IPv4 addresses only (InterNetwork)
        $ipv4 = $hostIPs | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
        if ($ipv4) {
            $HOST_IP = $ipv4.IPAddressToString
        }
    }
}
catch {
    $HOST_IP = "localhost"
}

if (-not $HOST_IP) {
    $HOST_IP = "localhost"
}

# Print all browser-accessible URLs
$output = @"

==============================================================
 Delta-V $IMG_TAG is starting on $HOST_IP
==============================================================

 Nginx ingress controller   http://$($HOST_IP):80
 (this provides a welcome page with links to all observability UI services through a reverse proxy)
 
 Admin tools
   pgAdmin                http://$($HOST_IP):15432           (admin/admin)
   kafkaUI                http://$($HOST_IP):19092/ui        (admin/admin)

 Observability
   Grafana                http://$($HOST_IP):13000           (admin/admin)
   VictoriaMetrics UI     http://$($HOST_IP):18428
   Alertmanager           http://$($HOST_IP):9093
   Prometheus Writer      http://$($HOST_IP):18080/actuator/health

 Data plane
   ClickHouse HTTP        http://$($HOST_IP):8123/play
   L8opensim REST/UI      http://$($HOST_IP):19081

 Daemon actuators
   Minion                 http://$($HOST_IP):8301/actuator/health
   Bsmd                   http://$($HOST_IP):8180/actuator/health

 Ingress (not browser URLs, FYI)
   Minion gateway (gRPC)  $($HOST_IP):8443
   Kafka bootstrap        $($HOST_IP):19092
   SNMP test agent        $($HOST_IP):19161/udp
   Trapd / Syslog / Flow  $($HOST_IP):11162/udp, 1514/udp, 4729/udp

 Tip: 'docker compose ps' to watch health; Grafana takes ~30-60s to come up.
 
 Track 3 (alarms-materializer): no host port — check health with
   'docker compose ps alarms-materializer'; its metrics appear in Grafana/VM
   (deltav_alarms_materializer_*). Default persistence.mode is 'dual-write'.

 To shutdown in this directory, use:
 docker compose -f ./target/delta-v-smoke/compose.yml -f ./target/delta-v-smoke/compose.override.dev.yml -f docker-compose-nginx-proxy.yml --profile full --profile metrics down

==============================================================
"@

Write-Host $output