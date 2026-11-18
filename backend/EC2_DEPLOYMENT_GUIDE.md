# 🚀 AWS EC2 Deployment Guide — Connect4People Backend

This guide walks you through deploying the **Connect4People** backend, admin portal, and database onto an **AWS EC2** instance.

Unlike free cloud container platforms (which block outbound email ports), AWS EC2 allows direct outbound connections on **ports 587 and 465**, enabling real Gmail SMTP OTP delivery directly to user inboxes.

---

## 📋 Step 1: Launch an AWS EC2 Instance

1. Log into your **AWS Management Console** and navigate to **EC2**.
2. Click **Launch Instance**:
   - **Name**: `connect4people-backend`
   - **AMI (OS)**: `Ubuntu Server 24.04 LTS` (or `Ubuntu 22.04 LTS`) - 64-bit (x86_64)
   - **Instance Type**: `t3.small` (recommended) or `t2.micro` / `t3.micro` (free tier)
   - **Key Pair**: Select or create a new key pair (`.pem` file, e.g. `connect4people-key.pem`)
3. **Network / Security Group Inbound Rules**:
   | Type | Port | Protocol | Source | Purpose |
   |---|---|---|---|---|
   | **SSH** | `22` | TCP | `0.0.0.0/0` (or My IP) | Terminal access |
   | **HTTP** | `80` | TCP | `0.0.0.0/0` | Web & Nginx reverse proxy |
   | **HTTPS** | `443` | TCP | `0.0.0.0/0` | Encrypted SSL traffic |
   | **Custom TCP** | `5000` | TCP | `0.0.0.0/0` | Express API & Socket.io WebSockets |
4. Click **Launch Instance** and copy your **Public IPv4 Address** (e.g. `13.233.xxx.xxx`).

---

## 💻 Step 2: Connect to your EC2 Instance via SSH

From your computer terminal (PowerShell or Terminal):
```bash
ssh -i "path/to/connect4people-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

---

## 📥 Step 3: Clone the GitHub Repository & Run Setup

Once logged into your EC2 instance:
```bash
# Clone the repository
git clone https://github.com/praveen-2528/Connect4people.git

# Enter backend directory
cd Connect4people/backend

# Make scripts executable
chmod +x scripts/setup-ec2.sh scripts/deploy.sh

# Run the automated setup script
./scripts/setup-ec2.sh
```

*(This configures 2GB swap, installs Node.js 20 LTS, Docker, Docker Compose, PM2, and configures UFW firewall automatically).*

---

## ⚙️ Step 4: Configure Environment Variables

```bash
cp .env.example .env
nano .env
```
Fill in your credentials:
- `DATABASE_URL`: Pre-configured to point to your existing Neon database (preserving 90 seeded companions, bookings, and payments).
- `SMTP_USER`: Your Gmail address.
- `SMTP_PASS`: Your 16-character Gmail App Password.
- `ADMIN_PASSWORD`: Your custom admin password (default: `Admin@2026!`).

Save with `CTRL + O`, `Enter`, and exit with `CTRL + X`.

---

## 🐳 Step 5: Start the Server

### Option A: Using Docker Compose (Recommended)
```bash
docker-compose up -d --build
```

Verify containers:
```bash
docker-compose ps
```

### Option B: Using PM2 (Native Node.js)
```bash
npm install
npm run db:sync
pm2 start ecosystem.config.cjs --env production
pm2 save
pm2 startup
```

---

## 🧪 Step 6: Verify Backend & Admin Dashboard

1. Test the health endpoint:
   ```bash
   curl http://localhost:5000/health
   ```
2. Open the Admin Portal in your browser:
   `http://YOUR_EC2_PUBLIC_IP:5000/admin` (or `http://YOUR_EC2_PUBLIC_IP/admin`)
   - **Email**: `admin@connect4people.com`
   - **Password**: `Admin@2026!`
3. Check the **Email & OTP Diagnostics** tab and test sending a real verification OTP to your email inbox!

---

## 📱 Step 7: Connect your Flutter Mobile App to EC2

1. Open `app/lib/config/constants.dart` in your local project:
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
   ```bash
   cd app
   flutter run -d <your-device-id>
   ```

---

## 🔄 Future Updates
Run this script anytime you push code to GitHub:
```bash
cd Connect4people/backend
./scripts/deploy.sh
```
