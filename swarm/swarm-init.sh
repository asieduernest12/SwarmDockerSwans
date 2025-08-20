#!/bin/sh
set -e

# Install diagnostic tools
apk add --no-cache netcat-openbsd bind-tools

echo "Waiting for dind daemons to be healthy..."
counter=1
while [ $counter -le 30 ]; do
  if docker --host tcp://node-a:2375 info >/dev/null 2>&1 \
  && docker --host tcp://node-b:2375 info >/dev/null 2>&1 \
  && docker --host tcp://node-c:2375 info >/dev/null 2>&1; then
    echo "All nodes healthy!"; break
  fi
  echo "Waiting for nodes... ($counter)"
  sleep 2
  counter=$((counter+1))
  if [ $counter -gt 30 ]; then
    echo "Timeout waiting for nodes to be healthy."; exit 1
  fi
done

echo "Initializing Swarm on node-a..."
NODE_A_IP=$(getent hosts node-a | awk '{ print $1 }')

# Force reset any existing swarm
docker --host tcp://node-a:2375 swarm leave --force 2>/dev/null || true
docker --host tcp://node-b:2375 swarm leave --force 2>/dev/null || true
docker --host tcp://node-c:2375 swarm leave --force 2>/dev/null || true

echo -e "node-a\nnode-b\nnode-c" | xargs -I{} sh -c "docker -H tcp://{}:2375 login -u k -p k registry:5000"

# Initialize on standard swarm port 2377 and specify --advertise-addr with custom port for API
docker --host tcp://node-a:2375 swarm init --advertise-addr $NODE_A_IP:2377

# Get the join token
TOKEN=$(docker --host tcp://node-a:2375 swarm join-token -q worker)
echo "Join token: $TOKEN"

# Make sure we have the node-a address resolved properly
ping -c 1 node-a || true

echo "Joining node-b to Swarm..."
docker --host tcp://node-b:2375 swarm join \
  --advertise-addr $(getent hosts node-b | awk '{ print $1 }'):2377 \
  --token $TOKEN node-a:2377

echo "Joining node-c to Swarm..."
docker --host tcp://node-c:2375 swarm join \
  --advertise-addr $(getent hosts node-c | awk '{ print $1 }'):2377 \
  --token $TOKEN node-a:2377

sleep 2
echo "Labeling nodes for placement..."
docker --host tcp://node-a:2375 node update --label-add role=app --label-add type=node-b node-b || true
docker --host tcp://node-a:2375 node update --label-add role=app --label-add type=node-c node-c || true

# docker exec $(docker ps -qf name=node-a) sh -l 'cd /app; dc build --push; ds deploy -c docker-compose.yml cs'

echo "Swarm setup complete."
sleep infinity
