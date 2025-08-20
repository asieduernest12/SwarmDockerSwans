#!/bin/bash
set -e

# Stop and remove all containers, networks, and volumes for this project
COMPOSE_FILE=compose-swarm-sidecar.yml

echo "Bringing down all containers and removing volumes..."
docker compose -f $COMPOSE_FILE down -v || true

echo "Pruning all unused Docker volumes..."
docker volume prune -f

# Remove any dind volumes that may persist
for v in $(docker volume ls -q | grep -E 'node-(a|b|c)'); do
  echo "Removing volume $v..."
  docker volume rm $v || true
done

echo "Rebuilding and starting the stack..."
docker compose -f $COMPOSE_FILE up --build -d

echo "Waiting for dind daemons to be ready..."
sleep 10

# Verify each node is accessible with retry logic
for n in node-a node-b node-c; do
  echo "Checking $n..."
  counter=1
  ready=0
  while [ $counter -le 30 ]; do
    if docker exec swarm-sidecar sh -c "docker --host tcp://$n:2375 info" >/dev/null 2>&1; then
      echo "$n is ready."
      ready=1
      break
    else
      echo "Waiting for $n to be ready... ($counter/30)"
      sleep 2
    fi
    counter=$((counter+1))
  done
  
  if [ $ready -eq 0 ]; then
    echo "$n is not ready after waiting. Exiting."
    exit 1
  fi
done

echo "All dind nodes are up and accessible."
echo "You can now run your Swarm setup script."
