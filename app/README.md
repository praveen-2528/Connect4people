# Connect4People — Mobile App (Flutter)

A cross-platform Flutter application for **Connect4People** (Rental Boyfriend/Girlfriend & Companion Platform).

## 📱 Features
- **Splash & Onboarding**: Smooth intro highlighting social companionship & safety
- **Email OTP Authentication**: Passwordless login/signup using 6-digit email OTPs
- **One-Time Registration Payment**:
  - Displays configurable fee (₹299 default)
  - Displays static UPI QR Code image & UPI ID with 1-tap copy
  - Allows user to submit UPI UTR / Transaction reference
  - Pending activation gate preventing unauthorized browsing until verified
- **Explore & Filter**:
  - Filter companions by city (Mumbai, Delhi, Bengaluru, etc.), gender, price range, rating
  - Search by name, city, or interests
- **Companion Profile**:
  - Photo gallery, rate card (hourly vs event)
  - Bio, available days, activity tags, languages
  - Safety and conduct guidelines
- **Booking Flow**:
  - Hourly or full event selection
  - Date & time picker
  - Public meeting location
  - Live cost breakdown with **20% platform commission** and **80% companion payout**
- **Booking Payments**:
  - Dedicated UPI QR code screen for booking fees
  - UTR submission & status tracking
- **My Bookings**:
  - Dual tabs: "Booked Companions" (as Client) and "Incoming Requests" (as Companion)
  - Status badges: Pending, Accepted, Ongoing, Completed, Cancelled
- **Real-Time In-App Chat**:
  - Powered by Socket.io
  - Instant messaging, typing indicators, read receipts
- **Companion Dashboard**:
  - Track total net earnings, completed meetups, and incoming requests
  - Quick Accept/Decline actions
  - Rate card updates
- **Safety & Trust**:
  - In-app reporting tool for users & bookings
  - Community rules and public meeting safety reminders

---

## 🚀 Running the App

### 1. Prerequisites
- Flutter SDK >= 3.8.1
- Android Studio / Android Emulator or a connected physical Android device

### 2. Configure Backend URL
In `lib/config/constants.dart`:
```dart
// For Android Emulator (maps to localhost on your PC):
static const String baseUrl = 'http://10.0.2.2:5000';
static const String socketUrl = 'http://10.0.2.2:5000';

// For Physical Android Device on same Wi-Fi:
// static const String baseUrl = 'http://192.168.x.x:5000';
// static const String socketUrl = 'http://192.168.x.x:5000';

// For AWS EC2 Production:
// static const String baseUrl = 'http://YOUR_EC2_PUBLIC_IP:5000';
// static const String socketUrl = 'http://YOUR_EC2_PUBLIC_IP:5000';
```

### 3. Run on Android
```bash
cd app
flutter pub get
flutter run
```
