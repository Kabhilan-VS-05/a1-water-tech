# AWS Flutter Admin Migration Activity

## Scope
- Project: `a1_tech_billing`
- Goal: replace Firebase with AWS-backed APIs, RDS, and Cognito for the Flutter billing/admin app
- Current status: data layer and admin authentication are migrated to AWS

## AWS resources in use
- API Gateway HTTP API: `a1-readonly-api`
- API base URL for Flutter admin: `https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod/admin`
- Lambda: `a1-products-api`
- Lambda source:
  - `aws-lambdas/products-api/index.mjs`
  - `aws-lambdas/products-api/admin.mjs`
- Lambda deploy zip:
  - `aws-lambdas/products-api-lambda.zip`
- RDS PostgreSQL:
  - host: `a1-water-tech-db.chk0gamumn4n.ap-south-1.rds.amazonaws.com`
  - port: `5432`
  - database: `postgres`

## Flutter files changed
- `a1_tech_billing/lib/main.dart`
- `a1_tech_billing/lib/admin_auth_cognito.dart`
- `a1_tech_billing/lib/billing_repository_aws.dart`
- `a1_tech_billing/pubspec.yaml`

## Backend files changed
- `aws-lambdas/products-api/index.mjs`
- `aws-lambdas/products-api/admin.mjs`
- `aws-flutter-admin-schema.sql`
- `aws-flutter-admin-seed.sql`

## What was migrated from Firestore to AWS
- Orders dashboard and status updates
- Bills listing, bill fetch, bill edit, and bill generation
- Service bookings listing and status updates
- Feedback listing, status updates, admin responses, and manual feedback
- Business settings
- Billing settings
- Announcements
- Catalog items for products and services
- Admin metrics dashboard
- New-order notification listener now reads from the AWS repository stream

## Flutter implementation notes
- `BillingRepository` now lives in `lib/billing_repository_aws.dart`
- The repository uses polling HTTP requests to the admin API instead of Firestore snapshots
- `main.dart` now includes:
  - `part 'admin_auth_cognito.dart';`
  - `part 'billing_repository_aws.dart';`
  - `kAdminApiBaseUrl`
  - Cognito pool/client configuration
  - AWS-backed repository construction via `BillingRepository()`
- Direct Firestore data access for bills and order notifications was removed from UI code and routed through repository methods
- Admin login/session restore now uses Cognito plus the `admins` table instead of Firebase Auth + Firestore

## Lambda implementation notes
- `index.mjs` now imports `handleAdminRoute` from `admin.mjs`
- `admin.mjs` handles these route groups:
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

## Database changes
- Run `aws-flutter-admin-schema.sql` in PostgreSQL before using the admin APIs
- Run `aws-flutter-admin-seed.sql` to insert the approved admin email into the `admins` table
- It creates or updates:
  - `admins`
  - `bills`
  - extra admin fields on `orders`
  - extra admin fields on `bookings`
  - extra admin fields on `feedback`

## Verification completed
- `flutter analyze` passed with no issues
- `flutter build web` succeeded
- `node --check` passed for:
  - `aws-lambdas/products-api/index.mjs`
  - `aws-lambdas/products-api/admin.mjs`
- New Lambda zip was rebuilt:
  - `aws-lambdas/products-api-lambda.zip`

## Firebase removal status
- Firebase packages were removed from `a1_tech_billing/pubspec.yaml`
- `firebase_options.dart` was removed
- No Firebase references remain in the Flutter admin app code

## Next AWS console steps
1. Run `aws-flutter-admin-schema.sql` against RDS.
2. Run `aws-flutter-admin-seed.sql` against RDS.
3. Upload `aws-lambdas/products-api-lambda.zip` to Lambda `a1-products-api`.
4. Make sure API Gateway routes include the `/admin/...` catch-all or equivalent methods.
5. Create or confirm the admin user in Cognito with the email that exists in the `admins` table.
6. Rebuild and install the Flutter app.

## Admin auth note
- Flutter login now uses Cognito for password authentication.
- Access to the admin app is granted only if the Cognito account also exists in the `admins` table.
- This avoids hardcoding the admin email inside the app while still allowing only approved admins.
