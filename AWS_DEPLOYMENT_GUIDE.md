# 🚀 AWS EC2 Deployment Guide — Connect4People

This guide provides a step-by-step walkthrough to deploy the **Connect4People** backend, admin portal, and database on an **AWS EC2** instance.

Unlike free cloud container platforms (which block outbound email ports), AWS EC2 allows direct outbound connections on **ports 587 and 465**, enabling real Gmail SMTP OTP delivery directly to user inboxes.

---

## 📋 Step 1: Launch your AWS EC2 Instance

1. Open the [AWS EC2 Console](https://console.aws.amazon.com/ec2/).
2. Click **Launch Instance**:
   - **Name**: `connect4people-backend`
   - **AMI (Operating System)**: `Ubuntu Server 24.04 LTS` (or `22.04 LTS`), 64-bit (x86_64).
   - **Instance Type**:
     - `t3.small` (2 vCPU, 2 GB RAM — Recommended for production)
     - or `t2.micro` / `t3.micro` (AWS Free Tier eligible; our setup script automatically configures 2GB swap space so it won't run out of memory).
   - **Key pair (login)**: Create a new key pair or choose an existing `.pem` key (e.g. `connect4people-key.pem`).
3. **Network Settings (Security Group)**:
   Add the following **Inbound Rules**:

   | Type | Port | Protocol | Source | Purpose |
   | :--- | :--- | :--- | :--- | :--- |
   | **SSH** | `22` | TCP | `0.0.0.0/0` (or My IP) | Terminal remote login |
   | **HTTP** | `80` | TCP | `0.0.0.0/0` | Web & Nginx reverse proxy |
   | **HTTPS** | `443` | TCP | `0.0.0.0/0` | Encrypted SSL traffic |
   | **Custom TCP** | `5000` | TCP | `0.0.0.0/0` | Express API & Socket.io WebSockets |

4. Click **Launch Instance**.
5. Once running, copy your **Public IPv4 Address** (e.g. `13.233.xxx.xxx`).

---

## 💻 Step 2: Connect to your EC2 Instance via SSH

Open PowerShell or Terminal on your computer:

```bash
# If on Linux/Mac, set permissions on your key:
chmod 400 connect4people-key.pem

# Connect to your instance (replace with your key path and EC2 IP):
ssh -i "path/to/connect4people-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

---

## 📥 Step 3: Clone the Repository & Run Setup

Once connected to your EC2 instance:

```bash
# 1. Clone your GitHub repository
git clone https://github.com/praveen-2528/Connect4people.git

# 2. Enter backend directory
cd Connect4people/backend

# 3. Make scripts executable
chmod +x scripts/setup-ec2.sh scripts/deploy.sh

# 4. Run the automated EC2 setup script
./scripts/setup-ec2.sh
```

> **What `setup-ec2.sh` does automatically:**
> - Configures **2GB Swap space** (prevents memory crashes on micro instances during builds).
> - Updates all system packages.
> - Installs **Node.js 20 LTS** & npm.
> - Installs **PM2** process manager globally.
> - Installs **Docker** & **Docker Compose**.
> - Configures internal firewall rules for ports 22, 80, 443, and 5000.

---

## ⚙️ Step 4: Configure Environment Variables

```bash
# Copy the template to .env
cp .env.example .env

# Edit the environment variables
nano .env
```

Set your values in `.env`:
1. **Database**: Keep the pre-filled `DATABASE_URL` to connect to your existing Neon PostgreSQL database (which already has your 90 seeded companions, bookings, and payments intact).
2. **Gmail SMTP (for Real OTP Delivery)**:
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your_email@gmail.com
   SMTP_PASS=your_16_char_gmail_app_password
   ```
3. Press `CTRL + O`, then `Enter` to save, and `CTRL + X` to exit `nano`.

---

## 🐳 Step 5: Launch the Server

### Option A: Using Docker Compose (Recommended)

Run the full stack (Node.js API + Socket.io + Nginx reverse proxy):
```bash
docker-compose up -d --build
```

Check running containers:
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

## 🧪 Step 6: Verify Live Backend & Admin Portal

1. **Verify API Health**:
   ```bash
   curl http://localhost:5000/health
   # Expected output: {"status":"healthy",...}
   ```
2. **Access Admin Portal in Browser**:
   Open in your browser:
   `http://YOUR_EC2_PUBLIC_IP:5000/admin` (or `http://YOUR_EC2_PUBLIC_IP/admin`)
   - **Email**: `admin@connect4people.com`
   - **Password**: `Admin@2026!`
3. **Verify Gmail SMTP & Send Test OTP**:
   - Go to the **Email & OTP Diagnostics** tab in the Admin Portal.
   - You will see your Gmail SMTP connection verified!
   - Enter your email and click **Send Test OTP** to receive an instant verification code in your inbox.

---

## 📱 Step 7: Connect the Flutter Mobile App to EC2

1. Open `app/lib/config/constants.dart` in your local Flutter project:
   ```dart
   class AppConstants {
     // Replace with your EC2 Public IP:
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

## 🔄 Updating Your EC2 Server in the Future

Whenever you push new code to GitHub, simply SSH into your EC2 instance and run:

```bash
cd Connect4people/backend
./scripts/deploy.sh
```

This single command automatically pulls the latest commit, rebuilds/restarts containers, and checks health.
