# A1 Water Tech - Project Overhaul Summary
**Date:** May 2026
**Target Projects:** a1-water-online-shop (Web), a1_tech_billing (Flutter Mobile), aws-lambdas (Backend)

This document serves as a persistent record of the architectural changes, bug fixes, and feature implementations completed during the major UI/UX refactoring and production-deployment phase.

## 1. Web Application (`a1-water-online-shop`)
### UI/UX & Responsive Fixes
* **Tailwind CSS Specificity:** Moved custom component classes (`.btn-primary`, `.card`, etc.) into the `@layer components` directive inside `index.css`. This fixed a critical issue where Tailwind utilities (like `hidden` for mobile responsiveness) were being ignored.
* **Aggressive Color Overrides:** Added `!important` to `.text-white` and `.btn-primary` color attributes in `index.css` to prevent `a` tags from inheriting the default dark text color.
* **Scrollbar Artifact:** Removed global `::-webkit-scrollbar` rules from `index.css`. The transparent track was bleeding through to the body background, causing a persistent 5px white vertical line on the right edge of dark themes.
* **Header & Shop Mobile Views:** Adjusted flex breakpoints in `Header.jsx` to prevent the logo and hamburger menu from squishing on mobile. Completely refactored the `Shop.jsx` filter sidebar to use an intuitive mobile toggle system with a "Clear All" button.

### Logic & Data Migration
* **AWS Dynamic Data:** Removed hardcoded mock data (`src/data/services.js`). Created a `faqs` table in the AWS Postgres database, built a `fetchFaqs()` API endpoint in the Lambda, and implemented a `useFaqs.js` React hook to render FAQs dynamically with a loading spinner.
* **Image Fallback Fix:** Refactored `src/utils/imageUtils.js`. Removed dangerously loose word-matching logic that assigned wrong images to products. The system now strictly prioritizes the AWS `imageUrl` first, exact catalog matches second, and category placeholders third.

### AWS Amplify Deployment Toolkit
* Created `zip_dist.ps1` to streamline AWS manual deployments. Since Amplify drag-and-drop deployments do not run build scripts, this script safely executes `npm run build` and uses `tar` to package ONLY the compiled `dist` folder into `a1-water-production-deploy.zip` with correct Unix `/` path separators.

---

## 2. Mobile Application (`a1_tech_billing` -> `A1 FlowSyn`)
### Rebranding
* Completely renamed the Flutter application to **A1 FlowSyn**.
* Updated OS-level identifiers:
  * Android: `android:label="A1 FlowSyn"` in `AndroidManifest.xml`.
  * iOS: `CFBundleDisplayName` and `CFBundleName` in `Info.plist`.
  * Web: `apple-mobile-web-app-title` in `index.html` and `name`/`short_name` in `manifest.json`.
  * Flutter: `MaterialApp(title: 'A1 FlowSyn')` in `lib/main.dart`.

### Production Crash Fix (Release Mode Blank Screen)
* **The Bug:** The app showed a blank black screen when compiled via `flutter build apk --release`. This occurs when unhandled exceptions halt the UI thread before `runApp()` can render.
* **The Fix:** Wrapped aggressive initialization calls (`NotificationService`, `Workmanager`) in `lib/main.dart` inside a robust `try-catch` block. 
* **Provider Safety:** Wrapped `AppProvider.initialize()` in a `try-catch-finally` block to guarantee `_setLoading(false)` is always executed, preventing infinite unrendered loading states if background syncs or database reads fail on physical devices.

---

## 3. AWS Lambdas & Database (`aws-lambdas`)
* **Schema Updates:** Added `CREATE TABLE faqs` to `aws-readonly-schema.sql` and wrote an `INSERT` statement to seed the database with initial questions.
* **Lambda Endpoints:** Added `fetchFaqs` logic to `products-api/index.mjs` and wired it up to intercept `GET /faqs` requests.
