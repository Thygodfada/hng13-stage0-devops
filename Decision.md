- Project: Blue/Green deployment with NGINX failover
- Stack: Docker Compose, Node.js apps (Blue & Green), NGINX reverse proxy
- How to run:
    docker compose --env-file .env up
- Endpoints:
- http://localhost:8080/version → Routed via NGINX
- http://localhost:8081/version → Direct to Blue
- http://localhost:8082/version → Direct to Green
- Chaos testing:
- Chaos endpoint (/chaos/start?mode=error) included but non-functional
- Manual failover tested by stopping Blue container:
    docker stop comfy-bluegreen-app_blue-1
- NGINX correctly rerouted traffic to Green
- Expected headers:
- X-App-Pool: blue or green
- X-Release-Id: v1.0.0 or v1.0.1
- Validation: Manual failover confirmed NGINX routing logic works as expected

