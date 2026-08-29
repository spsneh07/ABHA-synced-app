# ABHA Synced Medical Record App & Scanner OCR Module

A comprehensive, state-of-the-art Medical Record application built with **Flutter**. This project serves as a complete document scanner, OCR (Optical Character Recognition) module, and health record management app. It features seamless integration with **Firebase** and a custom **Node.js Webhook Backend** for India's Ayushman Bharat Digital Mission (ABDM) Health Information User (HIU) integration.

---

## 🌟 Features

### Frontend (Flutter App)
- **Secure Authentication**: Integrated with Firebase Auth and Google Sign-in.
- **Document Scanning**: High-quality document scanning using Google ML Kit.
- **Text Recognition (OCR)**: Extract text directly from scanned documents and images using Google ML Kit.
- **Image Capture**: Direct camera integration and image picking capabilities.
- **Cloud Storage**: Securely store and retrieve medical records using Cloud Firestore and Firebase Storage.
- **Premium UI/UX**: Designed with a modern medical teal and deep blue color palette, utilizing Google Fonts (Outfit).
- **State Management**: Robust state handling using `Provider`.

### Backend (Node.js ABDM Webhook Server)
- **ABDM HIU Integration**: Handles Phase 3 webhooks for ABDM.
- **Consent Management**: Processes patient consent requests (`/v0.5/consent-requests/on-init`) and consent notifications (`/v0.5/consents/hiu/notify`).
- **Secure Data Transfer**: Receives encrypted FHIR records (`/v0.5/health-information/hiu/on-request`) and decrypts them using Diffie-Hellman Key Exchange.

---

## 🛠️ Tech Stack

**Mobile Frontend**
- Flutter (Dart)
- Provider (State Management)
- Google ML Kit (Document Scanner & Text Recognition)
- Firebase (Core, Auth, Firestore, Storage)

**Backend Server**
- Node.js & Express.js
- Crypto (for Diffie-Hellman Key generation and AES decryption)

---

## 📁 Project Structure

```
├── abha-backend/       # Node.js ABDM HIU Webhook server
│   ├── server.js       # Express server and webhook endpoints
│   ├── crypto_utils.js # Encryption/Decryption utilities
│   └── package.json    # Backend dependencies
├── lib/                # Flutter App source code
│   ├── main.dart       # App entry point and theme setup
│   ├── screens/        # UI Screens (Login, Main Shell, etc.)
│   └── services/       # Business logic (AuthService, AbhaService)
├── android/            # Android native code
├── ios/                # iOS native code
└── pubspec.yaml        # Flutter dependencies
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>=3.16.0)
- [Node.js](https://nodejs.org/) (for the backend)
- A Firebase Project (with Auth, Firestore, and Storage enabled)
- [ngrok](https://ngrok.com/) (for exposing the local backend to ABDM sandbox)

### 1. Flutter App Setup
1. Clone the repository and navigate to the project directory:
   ```bash
   cd "ABHA synced App"
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Ensure your `firebase_options.dart` and Firebase configuration files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS) are correctly placed.
4. Run the app:
   ```bash
   flutter run
   ```

### 2. Backend (ABDM Webhook) Setup
1. Navigate to the backend directory:
   ```bash
   cd abha-backend
   ```
2. Install Node.js dependencies:
   ```bash
   npm install
   ```
3. Start the server:
   ```bash
   npm start
   ```
   *(The server runs on port 3000 by default)*
4. To test ABDM webhooks locally, use ngrok to expose your port:
   ```bash
   ngrok http 3000
   ```
   *Update your ABDM Sandbox Webhook URL with the generated ngrok URL.*

---

## 📚 Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Google ML Kit Documentation](https://developers.google.com/ml-kit)
- [ABDM Sandbox Documentation](https://sandbox.abdm.gov.in/)
