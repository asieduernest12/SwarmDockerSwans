#!/bin/bash
set -e

echo "Checking Swarm status..."

echo -e "\n=== Node A status ==="
docker exec -it swarm-sidecar sh -c "docker --host tcp://node-a:2375 node ls"
docker exec -it swarm-sidecar sh -c "docker --host tcp://node-a:2375 info | grep -A5 'Swarm:'"

echo -e "\n=== Node B status ==="
docker exec -it swarm-sidecar sh -c "docker --host tcp://node-b:2375 info | grep -A5 'Swarm:'" || echo "Node B not in swarm"

echo -e "\n=== Node C status ==="
docker exec -it swarm-sidecar sh -c "docker --host tcp://node-c:2375 info | grep -A5 'Swarm:'" || echo "Node C not in swarm"

echo -e "\n=== Checking connectivity ==="
echo "Pinging from sidecar to node-a:"
docker exec -it swarm-sidecar sh -c "ping -c 2 node-a"
echo "Pinging from sidecar to node-b:"
docker exec -it swarm-sidecar sh -c "ping -c 2 node-b"
echo "Pinging from sidecar to node-c:"
docker exec -it swarm-sidecar sh -c "ping -c 2 node-c"

echo -e "\n=== Debug: Checking swarm ports ==="
docker exec -it swarm-sidecar sh -c "nc -zv node-a 2377" || echo "Cannot connect to node-a:2377"
docker exec -it swarm-sidecar sh -c "nc -zv node-b 2377" || echo "Cannot connect to node-b:2377" 
docker exec -it swarm-sidecar sh -c "nc -zv node-c 2377" || echo "Cannot connect to node-c:2377"

echo -e "\n=== Debug: Checking API ports ==="
docker exec -it swarm-sidecar sh -c "nc -zv node-a 2375" || echo "Cannot connect to node-a:2375"
docker exec -it swarm-sidecar sh -c "nc -zv node-b 2375" || echo "Cannot connect to node-b:2375"
docker exec -it swarm-sidecar sh -c "nc -zv node-c 2375" || echo "Cannot connect to node-c:2375"
