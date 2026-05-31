#!/bin/bash

echo "WARNING: Do you wish to prune all docker images first (you really dont want to do this on every run)?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo "Pruning docker images" 
              docker rm -f $(docker ps -aq) 2>/dev/null 
              docker volume rm -f $(docker volume ls -q) 2>/dev/null
              docker system prune -a --volumes -f
              break;;
        No ) echo "Not pruning docker images" ; break;;
    esac
done

rm -rf ./target/delta-v-smoke
mkdir -p ./target/delta-v-smoke 

#GIT_REF=v1.2.0-rc2.2
#IMG_TAG=1.2.0-rc2.2
#GIT_REF=v1.2.0-rc3
#IMG_TAG=1.2.0-rc3
#GIT_REF=v1.2.0-rc4
#IMG_TAG=1.2.0-rc4
#GIT_REF=v1.2.0-rc4.1
#IMG_TAG=1.2.0-rc4.1
#GIT_REF=v1.2.0
#IMG_TAG=1.2.0
GIT_REF=v1.3.0-rc3
IMG_TAG=1.3.0-rc3

BASE=https://raw.githubusercontent.com/pbrane/delta-v/$GIT_REF/opennms-container/delta-v

curl -OL --output-dir "./target/delta-v-smoke/" $BASE/docker-compose.yml
curl -OL --output-dir "./target/delta-v-smoke/" $BASE/docker-compose.dev.yml

cat > ./target/delta-v-smoke/.env <<EOF
IMAGE_PREFIX=ghcr.io/pbrane
VERSION=$IMG_TAG
EOF

docker compose -f ./target/delta-v-smoke/docker-compose.yml -f ./target/delta-v-smoke/docker-compose.dev.yml -f docker-compose-nginx-proxy.yml --profile full --profile metrics pull

docker compose -f ./target/delta-v-smoke/docker-compose.yml -f ./target/delta-v-smoke/docker-compose.dev.yml -f docker-compose-nginx-proxy.yml --profile full --profile metrics up -d

# --- Print all browser-accessible URLs ---
HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
HOST_IP="${HOST_IP:-localhost}"

cat <<EOF

==============================================================
 Delta-V $IMG_TAG is starting on $HOST_IP
==============================================================

 Nginx ingress controller   http://$HOST_IP:80
 (this provides a welcome page with links to all observability UI services through a reverse proxy)
 
 Admin tools
   pgAdmin                http://$HOST_IP:15432           (admin/admin)
   kafkaUI                http://$HOST_IP:19092/ui        (admin/admin)
   
 Observability
   Grafana                http://$HOST_IP:13000           (admin/admin)
   VictoriaMetrics UI     http://$HOST_IP:18428
   Alertmanager           http://$HOST_IP:9093
   Prometheus Writer      http://$HOST_IP:18080/actuator/health

 Data plane
   ClickHouse HTTP        http://$HOST_IP:8123/play
   L8opensim REST/UI      http://$HOST_IP:19081

 Daemon actuators
   Minion                 http://$HOST_IP:8301/actuator/health
   Bsmd                   http://$HOST_IP:8180/actuator/health

 Ingress (not browser URLs, FYI)
   Minion gateway (gRPC)  $HOST_IP:8443
   Kafka bootstrap        $HOST_IP:19092
   SNMP test agent        $HOST_IP:19161/udp
   Trapd / Syslog / Flow  $HOST_IP:11162/udp, 1514/udp, 4729/udp

 Tip: 'docker compose ps' to watch health; Grafana takes ~30-60s to come up.
 
 To shutdown in this directory, use:
 docker compose -f ./target/delta-v-smoke/docker-compose.yml -f ./target/delta-v-smoke/docker-compose.dev.yml -f docker-compose-nginx-proxy.yml --profile full --profile metrics down

==============================================================
EOF