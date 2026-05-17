# A1 Water Tech - Complete Deployment Guide
**Date:** May 2, 2026

---

## Table of Contents
1. [Website Deployment (AWS Amplify)](#website-deployment)
2. [Mobile App Deployment (Flutter)](#mobile-app-deployment)
3. [API Configuration](#api-configuration)
4. [S3 Storage Setup](#s3-storage-setup)
5. [Environment Variables](#environment-variables)
6. [Troubleshooting](#troubleshooting)

---

## Website Deployment

### Prerequisites
- Node.js installed
- npm packages installed (`npm install`)

### Step 1: Build the Project

Open CMD and run:

```cmd
cd /d "d:\Users\Desktop\The Project\A1 Water Tech\a1-water-online-shop (Web)"
npm run build
```

**Expected output:**
```
dist/index.html                   0.52 kB
dist/assets/index-xxx.js        406.23 kB
 dist/assets/index-xxx.css      61.48 kB
✓ built in 1.49s
```

### Step 2: Verify Build Output

Check that `dist` folder contains:
- `index.html` (main entry point)
- `assets/` folder with JS and CSS files
- All product images (.png files)
- `vite.svg` (favicon)

### Step 3: Create Zip File

**Option A: Using Python (Recommended)**
```cmd
cd /d "d:\Users\Desktop\The Project\A1 Water Tech\a1-water-online-shop (Web)"
python -c "import shutil; shutil.make_archive('a1-water-web-build', 'zip', 'dist')"
```

**Option B: Using PowerShell**
```cmd
cd /d "d:\Users\Desktop\The Project\A1 Water Tech\a1-water-online-shop (Web)"
powershell -Command "Compress-Archive -Path 'dist\*' -DestinationPath 'a1-water-web-build.zip' -Force"
```

**Verify zip contents:**
```cmd
tar -tf a1-water-web-build.zip | head -20
```

### Step 4: Upload to AWS Amplify

1. Open [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
2. Select app: **a1-water-tech-web**
3. App ID: `d128klivfw89ld`
4. Current URL: https://staging.d128klivfw89ld.amplifyapp.com/
5. Click **"Deploy without Git provider"**
6. Choose **"Drag and drop"** method
7. Upload file: `a1-water-web-build.zip`
8. Click **Save and deploy**

### Step 5: Configure Redirect Rules (CRITICAL)

Without this, assets will 404:

1. In Amplify Console → **App settings** → **Rewrites and redirects**
2. Click **Edit** → **Add rule**:
   - **Source address**: `</^[^.]+$|\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|ttf|map|json)$)([^.]+$)/>`
   - **Target address**: `/index.html`
   - **Type**: `200 (Rewrite)`
3. Click **Save**

### Step 6: Add Environment Variables

1. Amplify Console → **Environment variables**
2. Add variable:
   - Key: `VITE_API_BASE_URL`
   - Value: `https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod`
3. Click **Save**

---

## Mobile App Deployment

### Prerequisites
- Flutter SDK (3.x or higher)
- Android Studio / VS Code
- Java SDK 17
- Android SDK

### Development Commands

**Run in debug mode:**
```cmd
cd "d:\Users\Desktop\The Project\A1 Water Tech\a1_tech_billing (Mobile)"
flutter run
```

**Hot reload:** Press `r` in terminal
**Hot restart:** Press `R` in terminal

### Build Release APK

```cmd
cd "d:\Users\Desktop\The Project\A1 Water Tech\a1_tech_billing (Mobile)"
flutter clean
flutter pub get
flutter build apk --release
```

**Output location:**
```
build\app\outputs\flutter-apk\app-release.apk
```

### Build App Bundle (Google Play Store)

```cmd
flutter build appbundle --release
```

**Output location:**
```
build\app\outputs\bundle\release\app-release.aab
```

### Install on Device

```cmd
flutter install
```

Or manually copy APK to Android device and install.

---

## API Configuration

### Base URLs

| Environment | URL |
|-------------|-----|
| Production | `https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod` |
| Admin API | `https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod/admin` |

### Available Endpoints

**Public Endpoints (No Auth):**
- `GET /products` - List all products
- `GET /services` - List all services

**Admin Endpoints (Require Auth):**
- `GET /admin/catalog/products` - Get all products
- `GET /admin/catalog/services` - Get all services
- `POST /admin/catalog/products` - Create/update product
- `POST /admin/catalog/services` - Create/update service

### Request/Response Format

**Product Structure:**
```json
{
  "id": "aqua-shield-ro",
  "name": "Aqua Shield RO",
  "price": 23999,
  "category": "Purifiers",
  "description": "Advanced water purifier",
  "imageUrl": "https://.../Images/product-123.jpg"
}
```

**Service Structure:**
```json
{
  "id": "installation",
  "name": "Installation Service",
  "price": 500,
  "duration": "2 hours",
  "description": "Professional installation",
  "imageUrl": "https://.../Images/service-123.jpg"
}
```

---

## S3 Storage Setup

### Bucket Configuration

| Setting | Value |
|---------|-------|
| Bucket Name | `a1-water-tech` |
| Region | `ap-southeast-2` (Sydney) |
| Image Folder | `Images/` |
| Public Access | Enabled |

### Image URL Format

```
https://a1-water-tech.s3.ap-southeast-2.amazonaws.com/Images/{filename}
```

### CORS Policy (Required)

```xml
<CORSConfiguration>
  <CORSRule>
    <AllowedOrigin>*</AllowedOrigin>
    <AllowedMethod>PUT</AllowedMethod>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
  </CORSRule>
</CORSConfiguration>
```

---

## Environment Variables

### Website (.env.production)

```
VITE_API_BASE_URL=https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod
```

### Mobile App (Dart constants)

```dart
const String kApiBaseUrl = 'https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod/admin';
const String kCatalogImageBucket = 'a1-water-tech';
const String kCatalogImageRegion = 'ap-southeast-2';
const String kCatalogImagePrefix = 'Images';
```

---

## Troubleshooting

### Website Issues

| Problem | Solution |
|---------|----------|
| White screen after deploy | Check redirect rules are configured |
| 404 on JS/CSS files | Verify zip contains `assets/` folder at root |
| API not working | Check `VITE_API_BASE_URL` environment variable |
| Images not loading | Verify S3 bucket CORS policy |

### Mobile App Issues

| Problem | Solution |
|---------|----------|
| Build fails | Run `flutter clean` then `flutter pub get` |
| Images not showing | Check imageUrl is not null or empty |
| API connection error | Verify internet permission in AndroidManifest.xml |
| Photo upload fails | Check S3 bucket allows public PUT |

### Common Errors

**Error: `net::ERR_ABORTED 404`**
- Solution: Add Amplify redirect rule (see Step 5)

**Error: `Failed to fetch`**
- Solution: Check API URL and network connection

**Error: `AccessControlListNotSupported`**
- Solution: Remove `x-amz-acl` header from S3 upload, use bucket policy instead

---

## Project Structure

### Website
```
a1-water-online-shop (Web)/
├── dist/              # Build output (zip this)
├── src/
│   ├── components/
│   ├── hooks/
│   ├── pages/
│   └── utils/
├── public/
└── DEPLOYMENT.md
```

### Mobile App
```
a1_tech_billing (Mobile)/
├── lib/
│   └── main.dart      # All screens in one file
├── build/
│   └── app/outputs/   # APK output
└── DEPLOYMENT.md
```

---

## Quick Reference

**Build & Deploy Website:**
```cmd
cd "a1-water-online-shop (Web)"
npm run build
python -c "import shutil; shutil.make_archive('a1-water-web-build', 'zip', 'dist')"
# Upload a1-water-web-build.zip to AWS Amplify
```

**Build Mobile APK:**
```cmd
cd "a1_tech_billing (Mobile)"
flutter build apk --release
# APK at: build\app\outputs\flutter-apk\app-release.apk
```

---

**Last Updated:** May 2, 2026  
**Document Version:** 1.0
