# Connect4People — Rental Companion Platform

Connect4People is a full-stack platform enabling individuals to connect as rental boyfriends and girlfriends for social events, dinners, gatherings, or outings.

The platform is designed around strict community boundaries, transparent pricing, a **20% platform commission**, and a **one-time registration payment** verified via UPI QR code.

---

## 🏗️ Architecture

```
Connect4people/
├── backend/                  # Node.js + Express + PostgreSQL + Socket.io
│   ├── src/
│   │   ├── config/           # Database, Gmail SMTP, S3, Socket.io
│   │   ├── controllers/      # Auth, Users, Companions, Bookings, Payments, Chat, Admin
│   │   ├── middleware/       # JWT Auth, Validators, Error Handler, Multer
│   │   ├── models/           # 11 Sequelize models (Users, Bookings, Payments, etc.)
│   │   ├── routes/           # REST endpoints
│   │   ├── utils/            # Fee calculator (20%), OTP generator, Response helpers
│   │   ├── app.js            # Express application setup
│   │   └── server.js         # HTTP + Socket.io server entry
│   ├── .env.example
│   └── package.json
│
└── app/                      # Flutter Mobile Application (Android / iOS)
    ├── lib/
    │   ├── config/           # Theme, Colors, API constants
    │   ├── models/           # User, Companion, Booking, Message, Payment
    │   ├── providers/        # Riverpod State Management (Auth, Companion, Booking, Chat)
    │   ├── services/         # ApiService (REST), SocketService (Real-time), Storage
    │   ├── screens/          # 20+ screens (Onboarding, Explore, Booking, Chat, Dashboard)
    │   └── main.dart         # Flutter entry point
    └── pubspec.yaml
```

---

## ⚡ Quick Start

### 1. Backend Setup (Node.js & PostgreSQL on EC2 or Local)
```bash
cd backend
npm install

# Configure your .env (PostgreSQL credentials, Gmail App password for OTP)
# Sync database tables:
npm run db:sync

# Start server:
npm run dev
```

### 2. Mobile App Setup (Flutter)
```bash
cd app
flutter pub get
flutter run
```

---

## 💰 Platform Business Logic

1. **One-Time Registration Payment**:
   - Every user (client & companion) pays a one-time onboarding fee (configurable, default ₹299).
   - The user scans the admin UPI QR code in the app and enters the UTR number.
   - Admin approves the claim to activate the user's account.

2. **20% Commission Model**:
   - For every booking, the total amount is paid by the client.
   - **80%** is credited to the companion.
   - **20%** is retained by the platform as commission fee.
