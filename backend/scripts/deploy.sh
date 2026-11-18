#!/usr/bin/env bash
# ==============================================================================
# Connect4People — Quick Deployment & Update Script for AWS EC2
# Run this on your EC2 instance anytime you push new commits to GitHub!
# ==============================================================================

set -e

echo "=========================================================="
echo "🚀 Updating Connect4People Backend on AWS EC2..."
echo "=========================================================="

# 1. Pull latest code from GitHub
echo "📥 Pulling latest code from GitHub..."
git pull origin main

# 2. Check deployment mode: Docker or PM2
if [ -f "docker-compose.yml" ] && command -v docker &> /dev/null && [ "$(docker ps -q -f name=c4p_api)" ]; then
    echo "🐳 Rebuilding and restarting Docker containers..."
    docker-compose down
    docker-compose up -d --build
    echo "Waiting for services to initialize..."
    sleep 5
    docker-compose ps
else
    echo "⚡ Updating native Node/PM2 deployment..."
    npm install --production
    npm run db:sync
    pm2 restart connect4people-api || pm2 start ecosystem.config.cjs --env production
    pm2 save
fi

echo ""
echo "🏥 Verifying API health status..."
sleep 2
curl -s http://localhost:5000/health || curl -s http://localhost/health

echo ""
echo "=========================================================="
echo "✅ Update complete! Connect4People is running live."
echo "=========================================================="
