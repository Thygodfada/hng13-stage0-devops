#!/bin/bash

# === Setup Logging ===
timestamp=$(date +"%Y%m%d_%H%M%S")
log_file="deploy_${timestamp}.log"
exec > >(tee -i "$log_file") 2>&1
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

echo "🚀 Starting deployment..."

# === Input Collection ===
read -p "GitHub repository URL: " repo_url
[[ -z "$repo_url" ]] && { echo "❌ Repo URL is required"; exit 1; }

read -p "GitHub Personal Access Token (PAT): " pat
[[ -z "$pat" ]] && { echo "❌ PAT is required"; exit 1; }

read -p "Branch name [default: main]: " branch
branch=${branch:-main}

read -p "SSH username: " ssh_user
[[ -z "$ssh_user" ]] && { echo "❌ SSH username is required"; exit 1; }

read -p "Server IP address: " server_ip
[[ -z "$server_ip" ]] && { echo "❌ Server IP is required"; exit 1; }

read -p "SSH key path: " ssh_key
[[ ! -f "$ssh_key" ]] && { echo "❌ SSH key not found"; exit 1; }

read -p "Internal app port (e.g., 3000): " app_port
[[ -z "$app_port" ]] && { echo "❌ App port is required"; exit 1; }

read -p "Use --cleanup mode? [y/N]: " cleanup
repo_name=$(basename "$repo_url" .git)

# === Git Operations ===
if [ -d "$repo_name" ]; then
    echo "📁 Repo exists. Pulling latest changes..."
    cd "$repo_name"
    git checkout "$branch"
    git pull https://${pat}@${repo_url#https://}
    cd ..
else
    echo "📁 Cloning repo..."
    git clone --branch "$branch" https://${pat}@${repo_url#https://}
fi

# === Dockerfile Check ===
if [ ! -f "$repo_name/Dockerfile" ]; then
    echo "❌ No Dockerfile found. Exiting."
    exit 1
fi
echo "✅ Dockerfile found"

# === SSH Connectivity Check ===
ping -c 2 "$server_ip" > /dev/null || { echo "❌ Server unreachable"; exit 1; }

# === File Transfer ===
echo "📦 Transferring files to remote server..."
scp -i "$ssh_key" -r "$repo_name" "$ssh_user@$server_ip:~"

# === Remote Deployment ===
ssh -t -i "$ssh_key" "$ssh_user@$server_ip" << EOF
    set -e
    echo "🔧 Updating system..."
    sudo apt update -y
    sudo apt install -y docker.io docker-compose nginx git curl

    echo "🔄 Enabling services..."
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $ssh_user

    sudo systemctl enable nginx
    sudo systemctl start nginx

    cd "$repo_name"

    if [ "$cleanup" == "y" ] || [ "$cleanup" == "Y" ]; then
        echo "🧹 Cleaning up old containers..."
        sudo docker rm -f hng13-app || true
        sudo docker image rm hng13-app || true
        sudo rm -f /etc/nginx/sites-enabled/hng13.conf
    fi

    echo "🐳 Building Docker image..."
    sudo docker build -t hng13-app .

    echo "🚀 Running Docker container..."
    sudo docker run -d --name hng13-app -p $app_port:$app_port hng13-app

    echo "🔍 Checking container health..."
    sleep 3
    sudo docker inspect --format='{{.State.Health.Status}}' hng13-app || echo "⚠️ Health check not configured"

    echo "🛠️ Configuring NGINX..."
    sudo tee /etc/nginx/sites-available/hng13.conf > /dev/null <<EOL
server {
    listen 80;
    location / {
        proxy_pass http://localhost:$app_port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

    sudo ln -sf /etc/nginx/sites-available/hng13.conf /etc/nginx/sites-enabled/hng13.conf
    sudo nginx -t && sudo systemctl restart nginx

    echo "✅ Deployment complete. App should be live at http://$server_ip"
EOF