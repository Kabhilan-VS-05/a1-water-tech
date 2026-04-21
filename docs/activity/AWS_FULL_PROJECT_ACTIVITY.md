# AWS Full Project Activity Log

Date updated: 2026-04-18  
Workspace root: `d:\Users\Desktop\The Project\A1 Water Tech`

## Purpose

This file is the full handoff and activity record for the AWS migration and follow-up fixes done across:

- React website: `a1-water-online-shop`
- Flutter admin / billing app: `a1_tech_billing`
- Shared AWS backend:
  - API Gateway
  - Lambda
  - RDS PostgreSQL
  - Cognito
  - Amplify hosting
  - CloudShell VPC environment

This file is meant for future continuation with no major skipped context.

---

## AWS Resources In Use

### API Gateway

- API name: `a1-readonly-api`
- API ID: `k713nuvb74`
- Base URL: `https://k713nuvb74.execute-api.ap-south-1.amazonaws.com`

### Lambda

- Function name: `a1-products-api`
- Shared source:
  - `aws-lambdas/products-api/index.mjs`
  - `aws-lambdas/products-api/admin.mjs`
- Latest deploy zip:
  - `aws-lambdas/products-api-lambda.zip`

### RDS PostgreSQL

- Host: `a1-water-tech-db.chk0gamumn4n.ap-south-1.rds.amazonaws.com`
- Port: `5432`
- Database: `postgres`
- Username: `a1admin`

### Cognito

- User pool ID: `ap-south-1_frjBbY5H9`
- App client ID: `7ipnh0krocrne8a98n5kecdtg0`
- Client secret: none

### Amplify Hosting

- React staging URL:
  - `https://staging.d128klivfw89ld.amplifyapp.com`

### CloudShell

- VPC environment:
  - `a1-db-shell`

---

## SQL / Schema Files Created

- `aws-readonly-schema.sql`
- `aws-readonly-seed.sql`
- `aws-feedback-schema.sql`
- `aws-bookings-schema.sql`
- `aws-addresses-schema.sql`
- `aws-orders-schema.sql`
- `aws-cart-schema.sql`
- `aws-flutter-admin-schema.sql`
- `aws-flutter-admin-seed.sql`

---

## React Website Migration Activity

Project path:

- `a1-water-online-shop`

### Hosting Migration

- React website hosting moved to AWS Amplify
- Flutter app was not part of the website hosting migration
- Manual zip deploy flow was prepared for Amplify
- Working production env file created:
  - `a1-water-online-shop/.env.production`

### React AWS Environment Values

Current values used:

```env
VITE_API_BASE_URL=https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod
VITE_COGNITO_USER_POOL_ID=ap-south-1_frjBbY5H9
VITE_COGNITO_CLIENT_ID=7ipnh0krocrne8a98n5kecdtg0
```

### React Data Migration Completed

The following were moved from Firebase to AWS:

#### Read-only data

- Products
- Services
- Announcements
- Business settings
- Billing settings

#### Write flows

- Feedback / contact form
- Bookings
- Addresses / profile
- Orders / checkout
- Order tracking / order history
- Cart

#### Authentication

- Firebase Auth replaced with Cognito
- Signup
- Login
- Email verification code flow
- Resend verification code flow

### PostgreSQL Tables Used For React

- `products`
- `services`
- `announcements`
- `business_settings`
- `billing_settings`
- `feedback`
- `bookings`
- `user_addresses`
- `orders`
- `cart_items`

### React API Routes Added

#### Read routes

- `GET /products`
- `GET /services`
- `GET /announcements`
- `GET /settings/business`
- `GET /settings/billing`
- `GET /bookings`
- `GET /addresses`
- `GET /orders`
- `GET /orders/track`
- `GET /cart`

#### Write routes

- `POST /feedback`
- `POST /bookings`
- `POST /addresses`
- `PUT /addresses/{id}`
- `DELETE /addresses/{id}`
- `POST /orders`
- `PUT /cart/{id}`
- `DELETE /cart/{id}`
- `DELETE /cart`

### Main React Files Changed

#### Auth / startup / compatibility

- `a1-water-online-shop/src/cognito.js`
- `a1-water-online-shop/src/polyfills.js`
- `a1-water-online-shop/src/state/AuthContext.jsx`
- `a1-water-online-shop/src/pages/Login.jsx`
- `a1-water-online-shop/src/main.jsx`
- `a1-water-online-shop/vite.config.js`

#### Data hooks and providers

- `a1-water-online-shop/src/hooks/useProducts.js`
- `a1-water-online-shop/src/hooks/useServices.js`
- `a1-water-online-shop/src/hooks/useAnnouncements.js`
- `a1-water-online-shop/src/hooks/useBookings.js`
- `a1-water-online-shop/src/hooks/useOrders.js`
- `a1-water-online-shop/src/hooks/useAddresses.js`
- `a1-water-online-shop/src/state/SiteSettingsContext.jsx`
- `a1-water-online-shop/src/state/CartContext.jsx`

#### Pages migrated to AWS backend

- `a1-water-online-shop/src/pages/Contact.jsx`
- `a1-water-online-shop/src/pages/Bookings.jsx`
- `a1-water-online-shop/src/pages/Profile.jsx`
- `a1-water-online-shop/src/pages/Checkout.jsx`
- `a1-water-online-shop/src/pages/TrackOrder.jsx`
- `a1-water-online-shop/src/pages/Login.jsx`

#### Product/cart related

- `a1-water-online-shop/src/components/ProductCard.jsx`
- `a1-water-online-shop/src/pages/ProductDetail.jsx`

### Important React Fixes Applied

#### 1. White screen from Cognito/browser globals

Fixes:

- added `src/polyfills.js`
- added browser-safe globals
- adjusted `cognito.js`
- updated `vite.config.js`

#### 2. Amplify asset 404 / white screen from zip packaging

Fix:

- frontend deploy zip is rebuilt using `tar.exe -a -cf ...`
- this avoided the earlier bad asset packaging issue

#### 3. Cart `400 Bad Request` on `/prod/cart/{id}`

Cause:

- Lambda path parsing failed when API Gateway sent `/prod/...` paths

Fix:

- Lambda route id parsing updated in `aws-lambdas/products-api/index.mjs`

#### 4. Cart UI showed success too early

Fix:

- cart add flow now waits for API success before showing success feedback

#### 5. Cognito sign-in identity timing issue

Fix:

- `uid` / session handling improved so cart and user flows do not fire with empty identity

### React Deploy Artifacts

- Latest frontend deploy zip:
  - `a1-water-online-shop/aws-react-upload-final.zip`
- Shared Lambda zip:
  - `aws-lambdas/products-api-lambda.zip`

### React Remaining Cleanup

- remove old Firebase leftovers:
  - `a1-water-online-shop/src/firebase.js`
  - Firebase deps in `a1-water-online-shop/package.json`
- fix Amplify SPA refresh rule for paths like `/shop/`
- later make RDS private again
- later move DB password from Lambda env vars to Secrets Manager

---

## Flutter Admin / Billing Migration Activity

Project path:

- `a1_tech_billing`

### Goal

Replace Firebase-backed admin/billing functionality with AWS-backed APIs and Cognito.

### Flutter AWS Data Migration Completed

The Flutter admin app was migrated from Firebase data access to AWS-backed repository access for:

- Orders listing and status updates
- Bills listing
- Bill fetch
- Bill edit
- Bill generation
- Service bookings listing and status updates
- Feedback listing
- Feedback status update
- Feedback response save
- Manual feedback create
- Business settings
- Billing settings
- Announcements
- Catalog items
- Admin dashboard metrics

### Flutter Auth Migration Completed

- Firebase auth removed from Flutter admin app
- Cognito login added
- Admin access is now approved through:
  - Cognito user authentication
  - `admins` table lookup in RDS

This means:

- Cognito user alone is not enough
- email must also exist in `admins` table

### Flutter Files Changed

- `a1_tech_billing/lib/main.dart`
- `a1_tech_billing/lib/admin_auth_cognito.dart`
- `a1_tech_billing/lib/billing_repository_aws.dart`
- `a1_tech_billing/pubspec.yaml`

### Backend Files Changed For Flutter Admin

- `aws-lambdas/products-api/index.mjs`
- `aws-lambdas/products-api/admin.mjs`
- `aws-flutter-admin-schema.sql`
- `aws-flutter-admin-seed.sql`

### Flutter Backend Routes Added / Used

- `/admin/session`
- `/admin/orders`
- `/admin/bookings`
- `/admin/feedback`
- `/admin/settings/business`
- `/admin/settings/billing`
- `/admin/announcements`
- `/admin/catalog/{collection}`
- `/admin/bills`
- `/admin/metrics`

### Database Tables / Extensions For Flutter Admin

- `admins`
- `bills`
- extra admin tracking fields added for:
  - `orders`
  - `bookings`
  - `feedback`

### Flutter Admin Seeding

- `aws-flutter-admin-seed.sql` used to insert or update admin access row
- Example admin email used:
  - `techawater@gmail.com`

### Firebase Removal In Flutter

- Firebase packages removed from `pubspec.yaml`
- `firebase_options.dart` removed

### Flutter Verification Already Done

- `flutter analyze`
- `flutter build web --no-wasm-dry-run`
- `flutter build apk --debug`

APK output path:

- `a1_tech_billing/build/app/outputs/flutter-apk/app-debug.apk`

---

## Flutter Admin UX / Functionality Improvements Done

These were added after the AWS migration:

### Order Confirmation Improvements

In `a1_tech_billing/lib/main.dart`:

- polling interval improved from 15s to 5s
- order confirmation page now supports:
  - better live refresh feel
  - full order review dialog before confirmation
  - customer details view before confirming
  - service booking review dialog
  - reject button for orders
  - reject button for bookings
  - reject confirmation dialog
  - faster optimistic status updates in UI

### Notifications

Added notifications for:

- new product orders
- new service bookings

Notification message quality improved to show:

- customer name
- amount or booking summary
- service / item preview

### Admin Data Model Improvements

Flutter booking model expanded to include:

- phone
- email
- city
- address

Lambda booking response was updated to return those fields.

---

## Flutter Admin Fixes Done For Reported Runtime Problems

### 1. API `Not Found` on all admin screens

Cause:

- `/admin/...` routes were missing in API Gateway or not deployed

Fix:

- `/admin/{proxy+}` route and corresponding Lambda handling were added / used

### 2. `Failed to fetch data` on metrics/orders after route fix

Cause:

- admin schema changes had not been applied in RDS

Fix:

- ran `aws-flutter-admin-schema.sql`

### 3. Cognito `New Password Required`

Cause:

- admin user was created with temporary password

Resolution path discussed:

- either set permanent password in Cognito
- or use website signup/verification and then approve same email through `admins` table

### 4. Manage Bills runtime errors

Reported issues:

- `Bad state: Stream has already been listened to`
- `_dependents.isEmpty is not true`

Fix direction implemented:

- repository polling streams converted to broadcast-safe usage
- stream-backed pages updated to reuse cached data instead of repeatedly resetting

### 5. Dashboard overview and Sales Analytics showing incorrect / mostly zero data

Root cause found:

- metrics API was calculating revenue only from the `bills` table
- confirmed orders without generated bills were not included

Fix applied:

- admin metrics backend now counts confirmed unbilled orders as current sales inputs
- dashboard overview was updated to show more current operational KPIs
- sales analytics now uses live sales count in selected range

### 6. Recent bills looking broken when bills table is empty

Fix applied:

- dashboard recent bills section now falls back to showing confirmed orders ready for billing when there are no bills yet

### 7. Page open/close causing repeated heavy loading UI

Fix applied:

- repository now caches latest metrics and list data for key screens
- stream pages now use `initialData` and avoid unnecessary full-screen loaders after first load

---

## Most Recent Flutter Admin Code Changes

Recent fixes were applied in:

- `a1_tech_billing/lib/billing_repository_aws.dart`
- `a1_tech_billing/lib/main.dart`
- `aws-lambdas/products-api/admin.mjs`

### What changed in repository

- broadcast-safe polling streams used for repeated listeners
- cache fields added for:
  - metrics
  - orders
  - recent bills
  - all bills
  - bookings

### What changed in UI

- dashboard overview now shows more current operational counts:
  - revenue
  - orders
  - pending orders
  - bookings
  - products
  - services
  - open feedback
- recent bills block now has fallback pending-billing panel
- sales analytics now uses range-aware sales count
- major pages now reuse cached stream data where possible instead of flashing full loading spinners

### What changed in metrics Lambda

- pending order count narrowed to real pending orders
- added:
  - `salesCount`
  - `salesCountInRange`
- revenue now combines:
  - bills
  - confirmed unbilled orders
- top items and daily revenue now use current sales rows instead of only bills

---

## Current Deploy Artifacts

### Lambda

- `aws-lambdas/products-api-lambda.zip`

### Flutter APK

- `a1_tech_billing/build/app/outputs/flutter-apk/app-debug.apk`

### React Frontend Zip

- `a1-water-online-shop/aws-react-upload-final.zip`

---

## Current Recommended Deploy Steps

### For backend changes

1. Upload `aws-lambdas/products-api-lambda.zip` to Lambda `a1-products-api`

### For Flutter admin changes

1. Install latest APK:
   - `a1_tech_billing/build/app/outputs/flutter-apk/app-debug.apk`

### For React frontend changes

1. Upload:
   - `a1-water-online-shop/aws-react-upload-final.zip`
2. Redeploy in Amplify

---

## Current Known Follow-up Items

### React

- remove old Firebase leftovers
- finalize SPA rewrite behavior
- tighten AWS secret / DB security

### Flutter Admin

- test dashboard overview after latest Lambda upload
- test sales analytics after latest Lambda upload
- test manage bills page after latest APK install
- test automatic billing flow
- optionally harden admin API with proper Cognito JWT verification server-side

### AWS / Security

- move DB credentials to Secrets Manager
- reduce public DB access after migration fully stabilizes

---

## Quick Resume Summary

If continuing later, the important current state is:

- React app is migrated to AWS for hosting, data, and Cognito auth
- Flutter admin app is migrated to AWS for data and Cognito auth
- Shared backend is `a1-products-api`
- API Gateway is `a1-readonly-api`
- RDS is PostgreSQL
- Cognito is active for both web and admin use
- latest cross-project backend zip is:
  - `aws-lambdas/products-api-lambda.zip`
- latest Flutter APK is:
  - `a1_tech_billing/build/app/outputs/flutter-apk/app-debug.apk`
- latest React deploy zip is:
  - `a1-water-online-shop/aws-react-upload-final.zip`

---

## Related Existing Notes

Older / narrower notes that still exist:

- `AWS_REACT_MIGRATION_ACTIVITY.md`
- `AWS_FLUTTER_ADMIN_MIGRATION_ACTIVITY.md`
- `REACT_AWS_STEP_1.md`
- `AWS_STEP_2_READONLY.md`

This file is the broadest combined handoff and should be preferred for future continuation.
