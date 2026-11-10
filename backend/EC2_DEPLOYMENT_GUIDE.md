# 🚀 AWS EC2 Deployment Guide — Connect4People Backend

This guide walks you through deploying the **Connect4People** backend server onto an **AWS EC2** instance so the mobile app can connect live from any phone or device worldwide.

---

## 📋 Step 1: Launch an AWS EC2 Instance

1. Log into your **AWS Management Console** and navigate to **EC2**.
2. Click **Launch Instance**:
   - **Name**: `connect4people-backend`
   - **AMI (OS)**: `Ubuntu Server 24.04 LTS` (or `Ubuntu 22.04 LTS`) - 64-bit (x86)
   - **Instance Type**: `t3.small` (recommended, 2 vCPU, 2 GB RAM) or `t2.micro` (free tier)
   - **Key Pair**: Select or create a new key pair (`.pem` file, e.g. `c4p-key.pem`)
3. **Network / Security Group Rules** (Important!):
   Add the following inbound rules:
   | Type | Port | Protocol | Source | Purpose |
   |---|---|---|---|---|
   | **SSH** | `22` | TCP | `0.0.0.0/0` (or My IP) | Terminal access |
   | **HTTP** | `80` | TCP | `0.0.0.0/0` | Web & API traffic |
   | **HTTPS** | `443` | TCP | `0.0.0.0/0` | Encrypted SSL traffic |
   | **Custom TCP** | `5000` | TCP | `0.0.0.0/0` | Express API & Socket.io |
4. Click **Launch Instance** and note your **Public IPv4 Address** (e.g. `13.233.xxx.xxx`).

---

## 💻 Step 2: Connect to your EC2 Instance via SSH

From your computer terminal (PowerShell or Terminal):
```bash
ssh -i "path/to/c4p-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

---

## 📥 Step 3: Clone the GitHub Repository

Once logged into your EC2 instance:
```bash
git clone https://github.com/praveen-2528/Connect4people.git
cd Connect4people/backend
```

---

## ⚡ Step 4: Run the Automated EC2 Setup Script

Make the setup script executable and run it:
```bash
chmod +x scripts/setup-ec2.sh
./scripts/setup-ec2.sh
```
*(This installs Node.js 20 LTS, Docker, Docker Compose, PM2, and configures the firewall automatically.)*

---

## 🐳 Step 5: Start the Server (Docker Compose — Recommended)

1. Create your production environment file from `.env.example`:
   ```bash
   cp .env.example .env
   nano .env
   ```
2. Configure your credentials in `.env`:
   - `JWT_SECRET`: Generate a random secret string
   - `SMTP_USER`: Your Gmail address (for email OTPs)
   - `SMTP_PASS`: Your Gmail App Password
3. Start the entire stack (PostgreSQL + Express API + Socket.io + Nginx):
   ```bash
   docker-compose up -d --build
   ```
4. Verify all containers are running:
   ```bash
   docker-compose ps
   ```
5. Test the health endpoint:
   ```bash
   curl http://localhost:5000/health
   ```
   *(You should see `{"status":"healthy",...}`)*

---

## 📱 Step 6: Connect your Flutter Mobile App to EC2

1. Open `app/lib/config/constants.dart` in your project on your local machine:
   ```dart
   class AppConstants {
     // Replace with your EC2 Public IPv4 address:
     static const String baseUrl = 'http://YOUR_EC2_PUBLIC_IP:5000';
     static const String socketUrl = 'http://YOUR_EC2_PUBLIC_IP:5000';

     static const String tokenKey = 'c4p_auth_token';
     static const String userKey = 'c4p_user_data';
   }
   ```
2. Run or build the app:
   ```powershell
   cd app
   flutter run
   ```
3. Your mobile app is now connected live to your AWS EC2 cloud backend! Any device anywhere in the world running the app will communicate with your live server.

---

## 🛠️ Handy Server Management Commands

- **View Live Server Logs**:
  ```bash
  docker-compose logs -f api
  ```
- **Restart the Server**:
  ```bash
  docker-compose restart
  ```
- **Reset / Clean Database to Fresh State**:
  ```bash
  docker-compose exec api npm run db:clean
  ```
- **Stop Server**:
  ```bash
  docker-compose down
  ```
