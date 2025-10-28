# DevOps Stage 2 — Blue/Green Deployment with NGINX Failover

## 🚀 Overview
This project implements a Blue/Green deployment pattern using Docker Compose and NGINX as a reverse proxy with automatic failover. Two identical Node.js services (blue and green) run behind NGINX. Blue is the primary, Green is the backup. If Blue fails, NGINX automatically retries requests against Green with no downtime for clients.
--

## 🧱 Architecture

- **Blue App**: Primary service exposed on port 8081
- **Green App**: Backup service exposed on port 8082
- **NGINX**: Public entrypoint on port 8080, routes traffic to Blue or Green based on health

---

## 📦 Features

- Health-based failover using NGINX upstreams
- Retry logic for 5xx and timeout errors
- Manual chaos injection via `/chaos/start` and `/chaos/stop`
- Header forwarding: `X-App-Pool`, `X-Release-Id`
- Fully parameterized via `.env` file

---
Project Structure
- docker-compose.yml
- .env.example
- nginx/
  - nginx.template.conf
  - nginx.conf (generated from template)
- README.md
- DECISION.md (optional notes)

Environment Variables
Copy .env.example to .env and adjust as needed:

BLUE_IMAGE=yimikaade/wonderful:devops-stage-two
GREEN_IMAGE=yimikaade/wonderful:devops-stage-two
ACTIVE_POOL=blue
RELEASE_ID_BLUE=v1.0.0
RELEASE_ID_GREEN=v1.0.1

BLUE_IMAGE / GREEN_IMAGE: Prebuilt app images (do not rebuild).
ACTIVE_POOL: Which pool is active by default (blue or green).
RELEASE_ID_*: Passed into the apps so they return the correct X-Release-Id.

Running the Stack
1. Export environment variables and generate the NGINX config:
   export $(grep -v '^#' .env | xargs)
   envsubst < nginx/nginx.template.conf > nginx/nginx.conf

2. Start services:
   docker compose up -d --build

3. Verify containers:
   docker ps

Endpoints
- NGINX Proxy (public entrypoint): http://<PUBLIC_IP>:8080
- Blue app (direct): http://<PUBLIC_IP>:8081
- Green app (direct): http://<PUBLIC_IP>:8082

Health & Version Checks
- GET /version → returns JSON body and headers:
  X-App-Pool: blue|green
  X-Release-Id: v1.0.0|v1.0.1
- GET /healthz → liveness probe
- POST /chaos/start?mode=error|timeout → simulate failure
- POST /chaos/stop → stop failure simulation

Failover Behavior
- By default, all traffic goes to Blue.
- If Blue fails (timeout or 5xx):
  - NGINX retries the request against Green immediately.
  - Client still receives 200 OK.
- Headers are preserved and forwarded unchanged.

Example Test Flow
# Baseline: Blue active
curl -i http://localhost:8080/version
# → X-App-Pool: blue, X-Release-Id: v1.0.0

# Trigger chaos on Blue
curl -X POST http://localhost:8081/chaos/start?mode=error

# Now NGINX serves from Green
curl -i http://localhost:8080/version
# → X-App-Pool: green, X-Release-Id: v1.0.1

# Stop chaos
curl -X POST http://localhost:8081/chaos/stop

--------------------------------------------------
