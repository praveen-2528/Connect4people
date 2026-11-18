#!/usr/bin/env bash
# ==============================================================================
# Connect4People — Automated AWS EC2 Server Setup Script
# Supported OS: Ubuntu 22.04 LTS / Ubuntu 24.04 LTS (x86_64 / arm64)
# ==============================================================================

set -e

echo "=========================================================="
echo "🚀 Starting Connect4People AWS EC2 Setup..."
echo "=========================================================="

# 1. Setup 2GB Swap Space (Critical for t2.micro / t3.micro with 1GB RAM)
if [ ! -f /swapfile ]; then
    echo "💾 Setting up 2GB swap file to prevent memory exhaustion during builds..."
    sudo fallocate -l 2G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo "✓ Swap space configured."
else
    echo "✓ Swap file already exists."
fi

# 2. Update and Upgrade System Packages
echo "📦 Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y curl wget git build-essential ufw unattended-upgrades ca-certificates gnupg lsb-release htop

# 3. Install Node.js 20 LTS
echo "📦 Installing Node.js 20 LTS..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
echo "✓ Node version: $(node -v)"
echo "✓ NPM version:  $(npm -v)"

# 4. Install PM2 Globally (for production process management)
echo "📦 Installing PM2 globally..."
sudo npm install -g pm2

# 5. Install Docker & Docker Compose Plugin
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
echo "✓ Docker installed."

# 6. Configure UFW Firewall (AWS Security Group also applies)
echo "🛡️ Configuring internal firewall rules..."
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (Nginx)
sudo ufw allow 443/tcp   # HTTPS (SSL)
sudo ufw allow 5000/tcp  # Direct Express API & Socket.io
sudo ufw --force enable
echo "✓ Firewall rules applied."

echo ""
echo "=========================================================="
echo "✅ AWS EC2 Server Setup Finished Successfully!"
echo "=========================================================="
echo ""
echo "🚀 Option A: Run Stack with Docker Compose (Recommended):"
echo "   cd Connect4people/backend"
echo "   cp .env.example .env    # (Add your secrets & Neon DATABASE_URL)"
echo "   docker-compose up -d --build"
echo ""
echo "🚀 Option B: Run Stack with PM2 (Native):"
echo "   cd Connect4people/backend"
echo "   npm install"
echo "   cp .env.example .env    # (Add your secrets & Neon DATABASE_URL)"
echo "   npm run db:sync"
echo "   pm2 start ecosystem.config.cjs --env production"
echo "   pm2 save"
echo "   pm2 startup"
echo "=========================================================="
