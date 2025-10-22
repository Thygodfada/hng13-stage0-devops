#!/bin/bash

timestamp=$(date +"%Y%m%d_%H%M%S")
log_file="deploy_${timestamp}.log"
exec > >(tee -i "$log_file") 2>&1

trap 'echo "❌ Unexpected error on line $LINENO"; exit 1' ERR

echo "🚀 Starting deployment..."

# 1. Collect Parameters
read -p "GitHub repository URL: " repo_url
read -p "GitHub Personal Access Token (PAT): " pat
read -p "Branch name [default: main]: " branch
branch=${branch:-main}

read -p "SSH username: " ssh_user
read -p "Server IP address: " server_ip
read -p "SSH key path: " ssh_key
read -p "Internal app port (e.g., 3000): " app_port

repo_name=$(basename "$repo_url" .git)

# 2. Clone or Pull Repo
if [ -d "$repo_name" ]; then
    echo "📁 Repo exists. Pulling latest changes..."
    cd "$repo_name"
    git pull https://${pat}@${repo_url#https://}
    cd ..
else
    echo "📁 Cloning repo..."
    git clone --branch "$branch" https://${pat}@${repo_url#https://}
fi

# 3. Verify Dockerfile
if [ ! -f "$repo_name/Dockerfile" ]; then
    echo "❌ No Dockerfile found. Exiting."
    exit 1
fi
echo "✅ Docker configuration found"

# 4. SSH into Remote Server
echo "🔐 Connecting to remote server..."
ssh -t -i "$ssh_key" "$ssh_user@$server_ip" << EOF
    echo "🔧 Updating system..."
    sudo apt update -y
    sudo apt install -y docker.io docker-compose nginx git

    echo "🔄 Enabling services..."
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $ssh_user

    sudo systemctl enable nginx
    sudo systemctl start nginx

    echo "📁 Cloning repo on server..."
    if [ ! -d "$repo_name" ]; then
        git clone --branch "$branch" https://${pat}@${repo_url#https://}
    fi
    cd "$repo_name"

    echo "🐳 Building Docker image..."
    sudo docker build -t hng13-app .

    echo "🚀 Running Docker container..."
    sudo docker rm -f hng13-app || true
    sudo docker run -d --name hng13-app -p $app_port:$app_port hng13-app

    echo "🛠️ Configuring NGINX..."
    sudo tee /etc/nginx/sites-available/hng13.conf > /dev/null <<EOL
server {
    listen 80;
    location / {
        proxy_pass http://localhost:$app_port;
    }
}
EOL

    sudo ln -sf /etc/nginx/sites-available/hng13.conf /etc/nginx/sites-enabled/hng13.conf
    sudo nginx -t && sudo systemctl restart nginx

    echo "🔍 Validating deployment..."
    curl -I http://localhost || echo "⚠️ App not responding locally"
EOF

echo "✅ Deployment complete. Visit: http://$server_ip"