#!/usr/bin/env bash
# ==============================================================================
# Connect4People — Automated AWS EC2 Server Setup Script
# Supported OS: Ubuntu 22.04 LTS / Ubuntu 24.04 LTS (x86_64 / arm64)
# ==============================================================================

set -e

echo "=========================================================="
echo "🚀 Starting Connect4People EC2 Setup..."
echo "=========================================================="

# 1. Update and Upgrade System Packages
echo "📦 Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git build-essential ufw unattended-upgrades ca-certificates gnupg lsb-release

# 2. Install Node.js 20 LTS
echo "📦 Installing Node.js 20 LTS..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
echo "Node version: $(node -v)"
echo "NPM version:  $(npm -v)"

# 3. Install PM2 Globally (for production process management)
echo "📦 Installing PM2 globally..."
sudo npm install -g pm2

# 4. Install Docker & Docker Compose
echo "🐳 Installing Docker & Docker Compose..."
if ! command -v docker &> /dev/null; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
    sudo usermod -aG docker "$USER"
fi

# 5. Configure Firewall (UFW)
echo "🛡️ Configuring firewall rules..."
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (Nginx)
sudo ufw allow 443/tcp   # HTTPS (SSL)
sudo ufw allow 5000/tcp  # Direct API / WebSocket
sudo ufw --force enable

echo "=========================================================="
echo "✅ EC2 Environment Setup Complete!"
echo "=========================================================="
echo ""
echo "🚀 To run the backend with Docker Compose (Recommended):"
echo "   cd Connect4people/backend"
echo "   cp .env.example .env   # (Edit your secrets)"
echo "   docker-compose up -d --build"
echo ""
echo "🚀 To run with PM2 natively:"
echo "   cd Connect4people/backend"
echo "   npm install"
echo "   cp .env.example .env   # (Edit your secrets)"
echo "   npm run db:sync"
echo "   pm2 start ecosystem.config.cjs --env production"
echo "   pm2 save"
echo "   pm2 startup"
echo "=========================================================="
