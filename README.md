# Distributed Docker Compose Practice Project: Multi-Node Cat Profiles

This project demonstrates how to use Docker Compose with Docker-in-Docker (dind) to simulate a multi-node environment using overlay networking. The setup includes:

- **Node A**: Runs a Redis instance.
- **Node B**: Runs two simple Express.js applications ("Cat Service 1" and "Cat Service 2") that connect to Redis to display and like cat profiles.

## Architecture

```
[Node A: dind] -- Redis (container)
   |  \
   |   \
   |    \
[Overlay Network]
   |    /
   |   /
[Node B: dind] -- Express App 1 (container)
             \
              -- Express App 2 (container)
```

## Architecture Diagrams

1) Swarm Host View: Top-level DIND container runs the Swarm host orchestration (in `/docker-compose.yml`)

```
           +-----------------------------------------------+
           |          swarm-host (DIND Container)          |
           |      manages the cluster via docker-compose   |
           |                  `/docker-compose.yml`        |
           +---------------------------+-------------------+
                                   |
   ----------------------------------------------------------------------
   |                   |                       |                     |
+-------------+   +-----------------+   +-----------------+   +----------------+
|  registry   |   |      node-a     |   |      node-b     |   |     node-c     |
| (registry:2)|   |    (manager)    |   |     (worker)    |   |    (worker)    |
+-------------+   +-----------------+   +-----------------+   +----------------+
```

2) Node-Level View: Services scoped to each node on the `swarm-net` overlay network

```
         +-------------------+       +-------------------+       +-------------------+
         |      node-a       |       |      node-b       |       |      node-c       |
         |     (manager)     |       |     (worker)      |       |     (worker)      |
         +---------+---------+       +---------+---------+       +---------+---------+
                   |                         |                         |
    +--------------------------------+  +--------------------------------+  +--------------------------------+
    |           services            |  |          services             |  |          services             |
    |         - caddy               |  | - redis                       |  | - app2                        |
    |                                |  | - app                         |  |                                |
    +--------------------------------+  +--------------------------------+  +--------------------------------+
                    \                             \                             \
                     +---------------------------------------------------------+
                     |                         swarm-net                       |
                     +---------------------------------------------------------+
```

## Prerequisites
- Docker and Docker Compose installed on your machine
- Linux recommended (for overlay networking)

## How It Works
- Each dind service simulates a Docker host (node) in a real cluster.
- Overlay network allows containers on different dind nodes to communicate.
- Express apps on Node B connect to Redis on Node A to fetch and update cat profiles.

## Project Structure
- `docker-compose.yml`: Main Compose file orchestrating dind nodes and app containers
- `express-app/`: Simple Express.js app with inline Dockerfile

## Usage

1. **Clone this repository**

2. **Start the environment**

   ```bash
   docker compose up --build
   ```

3. **Access the Express Apps**
   - Visit [http://localhost:3001](http://localhost:3001) and [http://localhost:3002](http://localhost:3002)

4. **Try liking cats and see the like count update (shared via Redis)**

5. **Stop the environment**
   ```bash
   docker compose down
   ```

## How to Explore Further
- Add more services or nodes
- Try scaling the Express apps
- Experiment with Redis data

---

### Notes
- This setup is for local learning and practice. For production, use real Docker Swarm or Kubernetes.
- Overlay networking with dind is for simulation only.
