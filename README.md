# A1 Water Tech — Full Stack Admin & Customer Platform

A monorepo for the A1 Water Tech business platform, consisting of:

- **Customer-facing web shop** (React + Vite)
- **Admin billing & management app** (Flutter / Android)
- **AWS Lambda backend APIs**
- **Database schemas & seeds**

---

## Repository Structure

```text
A1 Water Tech/
├── a1-water-online-shop (Web)/   # React customer storefront
├── a1_tech_billing (Mobile)/     # Flutter admin billing app
├── aws-lambdas/                  # AWS Lambda backend functions
├── database/
│   ├── schemas/                  # SQL schema files (AWS RDS)
│   └── seeds/                    # SQL seed data
├── docs/
│   ├── activity/                 # Migration & implementation logs
│   ├── guides/                   # Setup & deployment guides
│   ├── overviews/                # High-level project overviews
│   └── project-details/          # Reference materials & assets
├── amplify.yml                   # AWS Amplify CI/CD config
└── README.md
```

---

## Sub-projects

### 🌐 Web — Customer Online Shop
**Path:** `a1-water-online-shop (Web)/`  
**Stack:** React, Vite, TailwindCSS  
**Hosted on:** AWS Amplify / S3 + CloudFront  
**URL:** https://a1watertech.in

```bash
cd "a1-water-online-shop (Web)"
npm install
npm run dev        # Development
npm run build      # Production build → dist/
```

---

### 📱 Mobile — Admin Billing App
**Path:** `a1_tech_billing (Mobile)/`  
**Stack:** Flutter (Dart), SQLite (offline-first), AWS RDS (sync)  
**Platform:** Android (release APK)

```bash
cd "a1_tech_billing (Mobile)"
flutter pub get
flutter run                    # Debug on device/emulator
flutter build apk --release    # Production APK
```

The release APK is output to:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

### ⚙️ Backend — AWS Lambda APIs
**Path:** `aws-lambdas/`  
Node.js Lambda functions for:
- Product & catalog CRUD
- Order management
- Customer records
- Presigned S3 URL generation

---

## Environment Setup

### Web
Copy `.env.example` to `.env.development` / `.env.production` and fill in your values.  
**Never commit `.env.production` or `.env.development` to git.**

### Mobile
The app connects to AWS API Gateway automatically. No `.env` file needed — endpoints are configured in `lib/utils/image_helper.dart` and `lib/services/`.

---

## Security Notes

- Firebase Admin SDK JSON files (`*-firebase-adminsdk-*.json`) are excluded from git via `.gitignore`
- Android keystore files (`*.keystore`, `*.jks`, `key.properties`) must never be committed
- Real environment variable files (`.env.production`, `.env.development`) are excluded
- Build artefacts (`*.apk`, `*.zip`, `*.tar`, `build/`, `dist/`, `node_modules/`) are excluded

---

## Tech Stack Overview

| Layer | Technology |
|---|---|
| Customer Web | React 18, Vite, TailwindCSS |
| Admin Mobile | Flutter 3, Dart, SQLite |
| Backend APIs | AWS Lambda (Node.js) |
| Database | AWS RDS (MySQL) + local SQLite |
| Storage | AWS S3 |
| Hosting | AWS Amplify + CloudFront |
| Auth | AWS Cognito |
