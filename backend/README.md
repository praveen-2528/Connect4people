# Connect4People — Backend API

Node.js + Express + PostgreSQL + Socket.io backend for **Connect4People** (Rental Boyfriend/Girlfriend & Companion Platform).

## 🚀 Features
- **Authentication**: Email OTP sent via Gmail SMTP + JWT tokens
- **Registration Payment**: Configurable one-time fee with UPI QR code verification
- **Companions**: Rate cards (hourly/event), availability, tags, interests, gallery
- **Bookings**: Request, accept/decline, ongoing, completion, reviews & ratings
- **20% Platform Commission**: Auto-calculated on every booking
- **Real-Time Chat**: Socket.io real-time messaging with typing indicators & read receipts
- **Safety**: User reporting system and admin review
- **Admin Panel API**: Payment claim verification, user management, and platform analytics

---

## 🛠️ Prerequisites
- Node.js >= 18
- PostgreSQL >= 13
- Gmail account with App Password (for OTPs)
- AWS S3 bucket (optional for photo storage)

---

## ⚙️ Environment Configuration

Create or modify `.env` in the `backend/` directory:

```env
PORT=5000
NODE_ENV=development

# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=connect4people
DB_USER=postgres
DB_PASSWORD=your_postgres_password
DB_AUTO_SYNC=true

# JWT Auth
JWT_SECRET=your_long_random_jwt_secret_key
JWT_EXPIRES_IN=30d

# Gmail SMTP for OTPs
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_gmail_app_password

# AWS S3 (Media uploads)
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=ap-south-1
AWS_S3_BUCKET=connect4people-bucket
```

---

## 📦 Installation & Database Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create database and sync tables:
   ```bash
   npm run db:sync
   ```

3. Run in development:
   ```bash
   npm run dev
   ```

4. Run in production:
   ```bash
   npm start
   ```

---

## 🌐 API Overview

| Route | Description |
|---|---|
| `POST /api/auth/send-otp` | Send 6-digit OTP to email |
| `POST /api/auth/verify-otp` | Verify OTP & receive JWT token |
| `GET /api/users/me` | Current user profile |
| `PUT /api/users/me` | Update profile |
| `POST /api/users/me/companion` | Enable companion mode & rates |
| `GET /api/companions` | Explore companions with filters |
| `POST /api/bookings` | Create companion booking |
| `GET /api/bookings` | List user bookings |
| `PUT /api/bookings/:id/accept` | Companion accepts booking |
| `POST /api/bookings/:id/review` | Leave review & rating |
| `GET /api/payments/registration-info` | Get UPI QR & registration fee |
| `POST /api/payments/registration/claim` | User claims payment made |
| `GET /api/conversations` | List chat conversations |
| `GET /api/conversations/:id/messages` | Fetch messages |
| `POST /api/reports` | Report user |
| `GET /api/admin/payments/pending` | Admin view pending payment claims |
| `PUT /api/admin/payments/:id/verify` | Admin approves payment claim |
