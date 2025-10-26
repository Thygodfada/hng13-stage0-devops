# DevOps Stage 2 — Blue/Green Deployment with NGINX Failover

## 🚀 Overview

This project implements a Blue/Green deployment architecture using Docker Compose and NGINX. Two identical Node.js services (Blue and Green) are deployed as pre-built containers. NGINX routes traffic to the active pool (Blue by default) and automatically fails over to the backup (Green) if the primary becomes unhealthy.

---

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

## 📄 Setup Instructions
1. Clone the Repository
-----------------------
git clone https://github.com/Thygodfada/hng13-stage0-devops.git
cd hng13-stage0-devops

2. Create a .env File
---------------------
Create a file named `.env` in the root directory with the following content:

BLUE_PORT=8081
GREEN_PORT=8082
NGINX_PORT=8080

3. Start the Application
------------------------
Run the stack using Docker Compose:

docker compose --env-file .env up

This starts:
- Blue app on port 8081
- Green app on port 8082
- NGINX proxy on port 8080

4. Test Routing
---------------
Use these endpoints:

http://localhost:8080/version   → Routed via NGINX
http://localhost:8081/version   → Direct to Blue
http://localhost:8082/version   → Direct to Green

Expected headers:
- X-App-Pool: blue or green
- X-Release-Id: v1.0.0 or v1.0.1

5. Simulate Failover
--------------------
Chaos endpoint is present but non-functional.

The /chaos/start?mode=error endpoint is present but does not simulate failure. To validate NGINX failover, the Blue container was manually stopped. 
NGINX correctly rerouted traffic to Green, confirming the expected behavior.

To test failover manually:
- Stop Blue container:
  docker stop comfy-bluegreen-app_blue-1

- Test NGINX routing:
  curl http://localhost:8080/version
  → Should now route to Green

- Restart Blue:
  docker start comfy-bluegreen-app_blue-1

--------------------------------------------------
