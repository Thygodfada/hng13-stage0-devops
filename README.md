# HNG DevOps Stage 1 — Automated Deployment Script

## 🚀 Overview

This repository contains a production-grade Bash script (`deploy.sh`) that automates the setup, deployment, and configuration of a Dockerized application on a remote Ubuntu server. It is designed to reflect real-world DevOps workflows including provisioning, containerization, reverse proxy setup, and validation.

---

## 🛠️ Features

- Collects deployment parameters interactively
- Authenticates and clones a GitHub repository using a Personal Access Token (PAT)
- SSH into a remote Ubuntu server using a `.pem` key
- Installs Docker, Docker Compose, NGINX, and Git
- Builds and runs the Docker container
- Configures NGINX as a reverse proxy to the container
- Validates deployment and logs all actions to a timestamped file

---

## 📦 Prerequisites

- A remote Ubuntu server (e.g., EC2 instance)
- SSH access via a `.pem` key
- A GitHub repository with a valid `Dockerfile`
- A GitHub Personal Access Token (PAT) with repo access

---

## 📄 Usage

Make the script executable:
```bash
chmod +x deploy.sh
