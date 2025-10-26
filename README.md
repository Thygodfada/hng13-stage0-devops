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

### 1. Clone the Repository
```bash
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>