#!/bin/bash

echo "=== Limpando ambiente antigo ==="
podman pod rm -f nextcloud-pod 2>/dev/null
podman volume rm nextcloud-data nextcloud-db-data 2>/dev/null

echo "=== Criando volumes ==="
podman volume create nextcloud-data
podman volume create nextcloud-db-data

echo "=== Criando diretórios externos ==="
sudo mkdir -p /var/lib/nextcloud_data

echo "=== Ajustando permissões (Podman rootless) ==="
podman unshare chown -R 33:33 /var/lib/nextcloud_data
podman unshare chown -R 33:33 /run/media/ariel_/Database_Rocky_G

echo "=== Criando POD ==="
podman pod create --name nextcloud-pod -p 8080:80

echo "=== Subindo PostgreSQL ==="
podman run -d \
  --name postgres-nextcloud \
  --pod nextcloud-pod \
  -e POSTGRES_USER=nextcloud \
  -e POSTGRES_PASSWORD=nextcloud \
  -e POSTGRES_DB=nextcloud \
  -v nextcloud-db-data:/var/lib/postgresql/data
  docker.io/library/postgres:16

echo "=== Aguardando banco iniciar ==="
sleep 5

echo "=== Subindo Nextcloud ==="
podman run -d \
  --name nextcloud \
  --pod nextcloud-pod \
  -v nextcloud-data:/var/www/html \
  docker.io/library/nextcloud:32

echo "=== Aguarde 30-60s e acesse ==="
echo "👉 http://localhost:8080"

podman exec -u www-data nextcloud php occ config:system:set trusted_domains 1 --value=(IPDOVPN):8080
