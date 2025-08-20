# Project Plan & Status 🚦

## Overview
This document tracks the setup and status of the distributed Docker Compose learning project, using status emojis for each step.

---

## Steps & Status

| Step | Description | Status |
|------|-------------|--------|
| 1 | Scaffold base Compose files for all nodes | ✅ |
| 2 | Split Compose files by node (proxy, redis, services) | ✅ |
| 3 | Mount each Compose file into its node container at `/app/node-x/docker-compose.yml` | ✅ |
| 4 | Create dummy Dockerfile for node containers | ✅ |
| 5 | Start all node containers using `nodes-compose.yml` | ⏳ |
| 6 | Inside each node container, run `docker compose -f /app/node-x/docker-compose.yml up -d` | ⏳ |
| 7 | Configure Caddy with custom host labels for Express apps | ⏳ |
| 8 | Exec into a container on one node and ping another node using the custom host (Caddy-proxied) | ⏳ |
| 9 | Verify inter-node connectivity and service discovery | ⏳ |
| 10 | Document and clean up | ⏳ |

---

## Example: Caddy Docker Proxy Label

Add a label to your Express app service in `services-node-c-compose.yml`:
```yaml
labels:
  - caddy=cat1.localhost
  - caddy.reverse_proxy={{upstreams 3001}}
```

This will expose the app at `http://cat1.localhost` via Caddy.

---

## Final Test
- [ ] Start all nodes
- [ ] Exec into one node's container (e.g., `services-node-c`)
- [ ] Ping another node's service using the custom host (e.g., `ping cat1.localhost` or `curl http://cat1.localhost`)
- [ ] Confirm successful response

---

## Emoji Legend
- ✅ = Complete
- ⏳ = In Progress
- ❌ = Blocked/Failed

---

Update this plan as you progress! 🎯
