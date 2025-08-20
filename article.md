# Building a Multi-Node Docker Swarm Overnight

## Table of Contents
- [Building a Multi-Node Docker Swarm Overnight](#building-a-multi-node-docker-swarm-overnight)
  - [Table of Contents](#table-of-contents)
  - [Why This Guide](#why-this-guide)
  - [Architecture Overview](#architecture-overview)
  - [1. Bootstrapping the Swarm Manager](#1-bootstrapping-the-swarm-manager)
  - [2. Adding Worker Nodes](#2-adding-worker-nodes)
  - [3. Overlay Network \& Scoped Services](#3-overlay-network--scoped-services)
  - [4. Useful Swarm Commands](#4-useful-swarm-commands)
  - [5. Tipping Point: Caddy + Docker Proxy](#5-tipping-point-caddy--docker-proxy)
  - [Tips \& Tricks: Networking and Permissions](#tips--tricks-networking-and-permissions)
  - [Future Improvements \& Next Steps](#future-improvements--next-steps)
  - [What’s Next](#whats-next)

## Why This Guide

This guide is designed for hands-on learning: you’ll spin up an entire Docker Swarm cluster inside Docker itself, experiment with service placement, overlay networks, and reverse-proxy routing. Ideal for exploring Swarm concepts without multiple physical hosts.

## Architecture Overview
```plaintext
     +-----------------------------------------------+
     |          swarm-host (DIND Container)          |
     |      manages the cluster via docker-compose   |
     |                  `/docker-compose.yml`        |
     +---------------------------+-------------------+
       |
       ----------------------------------------------------------------------
       |                   |                       |                     |
       +-------------+   +-----------------+   +-----------------+   +----------------+
       |  registry   |   |      node-a     |   |      node-b     |   |      node-c     |
       | (registry:2)|   |    (manager)    |   |     (worker)    |   |    (worker)     |
       +-------------+   +-----------------+   +-----------------+   +----------------+
                                    |                 |                             |
                                    v                 v                             v
                                    +-------------+   +----------------------+   +-------------+
                                    | services:   |   | services:            |   | services:   |
                                    | - caddy     |   | - redis              |   | - app2      |
                                    +-------------+   | - app                |   |             |
                                            +----------------------+   +-------------+
```  
*Project overview: a Swarm host running multiple node containers and registry.*

This was a fun overnight project: I used Docker-in-Docker (DIND) containers to stand up a three-node Swarm cluster, scoping services to specific nodes, and fronting everything with Caddy as a reverse-proxy. Below is a step-by-step guide, with key snippets from the `docker-compose.yml` and useful Swarm commands.

---

## 1. Bootstrapping the Swarm Manager

In your top-level `docker-compose.yml`, define the **cluster** service using the DIND image. We expose the Docker API on TCP and then use a `post_start` hook to initialize the Swarm:

```yaml
services:
  cluster:
    image: docker:28.3.3-dind
    privileged: true
    command:
      - --host=tcp://0.0.0.0:2375
      - --host=unix:///var/run/docker.sock
      - --tls=false
    volumes:
      - cluster:/var/lib/docker
      - ./:/app
    network_mode: host
    healthcheck:
      test: ["CMD", "docker", "info"]
      interval: 5s
      timeout: 2s
      retries: 10
      start_period: 5s
    post_start:
      - command: |
            sh -c '
            # wait for DIND daemon
            until docker info >/dev/null 2>&1; do sleep 1; done
            # initialize Swarm manager
            docker -H tcp://localhost:2375 swarm init --advertise-addr 127.0.0.1
            '
``` 

> The `docker -H tcp://localhost:2375` flag targets the in-container Docker API.

---

## 2. Adding Worker Nodes

In `swarm/docker-compose.yml`, spin up three more DIND instances (`node-a`, `node-b`, `node-c`). After each container is healthy, join them to the Swarm:

```yaml
services:
  node-a:
    image: docker:28.3.3-dind
    privileged: true
    command:
      - --host=tcp://0.0.0.0:2375
      - --tls=false
    networks:
      - swarm-net
    healthcheck: { ... }
    post_start:
      - command: |
            sh -c '
            # fetch join token
            TOKEN=$(docker -H tcp://cluster:2375 swarm join-token -q worker)
            # join as worker
            docker -H tcp://localhost:2375 swarm join --token $TOKEN cluster:2375
            '
```

Repeat for **node-b** and **node-c**. Each uses the same `swarm join` command, pointing at `cluster:2375`.

---

## 3. Overlay Network & Scoped Services

Create a shared overlay network so services can communicate across nodes:

```yaml
networks:
  swarm-net:
    driver: overlay
    attachable: true
```

Scope services to specific nodes with **placement constraints**:

```yaml
services:
  app:
    image: registry:5000/exp-app
    networks: [swarm-net]
    deploy:
      replicas: 3
      placement:
        constraints:
          - node.labels.role == app
```

Use node labels (`docker node update --label-add role=app <NODE>`) to control exactly which containers run where.

---

## 4. Useful Swarm Commands

- **Check node status**: `docker node ls`  
- **List services**: `docker service ls`  
- **Scale a service**: `docker service scale app=5`  
- **Deploy a stack**: `docker stack deploy -c docker-compose.yml mystack`


---

## 5. Tipping Point: Caddy + Docker Proxy

I used the `serfriz/caddy-crowdsec-geoip-ratelimit-security-dockerproxy` Docker image to automatically route virtual hosts to the right containers via Docker labels:

```yaml
services:
  caddy:
    image: serfriz/caddy-crowdsec-geoip-ratelimit-security-dockerproxy:2.10
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    labels:
      - caddy=registry.localhost
      - caddy.reverse_proxy={{upstreams 80}}
```

With this proxy in place, any service labeled `caddy=whatever.localhost` will be reachable automatically.

---
## Tips & Tricks: Networking and Permissions
- **Bridge Networking in DIND**: Nested Docker daemons may not support the default bridge network out of the box. You may need `privileged: true`, load kernel modules (`modprobe br_netfilter`), and adjust `/etc/docker/daemon.json` to enable `bridge` and `ip_forward` settings.
- **Rootless Docker Caveats**: Running Docker daemon in rootless mode inside a container requires UID/GID mappings, `fuse-overlayfs`, and proper environment. Note that some network drivers (e.g., overlay) may not work without additional privileges.
- **Privileged Flag Caveats**: Using `privileged: true` grants full access to host capabilities. For tighter security, consider `cap_add` (e.g., `SYS_ADMIN`, `NET_ADMIN`) and explicit volume mounts instead of full privilege.
- **Restricted Images**: Minimal DIND images may lack networking tools (`iptables`, `iproute2`). Include debugging utilities or use a fuller image when troubleshooting container networking.
---

## Future Improvements & Next Steps

Consider exploring these areas to enhance and harden your swarm setup:

- **Security Enhancements**
  - Enable TLS on Docker API endpoints and use mutual TLS between nodes
  - Utilize Docker Secrets and encrypted overlay networks for sensitive data

- **Monitoring & Logging**
  - Integrate Prometheus, cAdvisor, and Grafana for real-time metrics dashboards
  - Centralize container logs with the ELK stack or Loki/Fluentd pipelines

- **Limitations & Considerations**
  - DIND containers introduce performance overhead and unique security risks
  - Overlay network simulation on a single host may not reflect real cluster latency

- **Data Persistence & Volume Sharing**
  - Implement shared volumes (NFS, GlusterFS) or named volumes for stateful services
  - Leverage Docker Configs for managing configuration files across services

- **Service Scaling & Updates**
  - Practice rolling updates with health checks for zero-downtime deploys
  - Automate scale operations using `docker service scale` or stack re-deploys

---

## What’s Next

For your next iteration, consider infrastructure-as-code and orchestration tools for more automated deployments:

- Pulumi or Terraform for declarative provisioning of cloud resources
- Chef or Ansible for configuration management across hosts
- Jenkins or GitHub Actions for CI/CD pipelines to automate builds, tests, and deployments

These tools can help transition from a manual DIND-based lab to a production-grade deployment workflow.

