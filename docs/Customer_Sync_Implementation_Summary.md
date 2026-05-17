# Implementation Summary: Customer Sync & Data Separation

## Context & Problem Statement
The objective was to perfectly separate **"Website App"** customers (users registered via Amazon Cognito on the website) from **"Walk-in / Manual"** customers in the A1 Water Tech mobile admin app. 

Initially, the "Website App" list was empty because the mobile app was extracting customers *only* from the orders sync (`_syncOrders`), and the AWS Lambda was failing to provide `email` or `userId` in the order payload. Furthermore, users who had registered but never placed an order were invisible to the admin app.

## Architecture Changes Implemented

### 1. Data Model & SQLite Database (Mobile App)
*   **Model Update (`Customer.dart`)**: Added a strict `source` property (`String source`) to definitively tag a customer as `'website'` or `'manual'`.
*   **Database Migration (`DatabaseService.dart`)**:
    *   Incremented database version to `4`.
    *   Added migration step in `_onUpgrade` to alter the `customers` table: `ALTER TABLE customers ADD COLUMN source TEXT DEFAULT 'manual'`.

### 2. Backend API Modifications (AWS Lambda - `admin.mjs`)
*   **Enriched Orders Payload**: Updated the `fetchAdminOrders` SQL query. The `customer` JSON object now correctly extracts and returns `email` and `userId` (Cognito sub) from the `user_addresses` and `orders` tables.
*   **New Users API Endpoint**: 
    *   Created `fetchAdminUsers(getPool)` to query the `user_addresses` table and return a distinct list of all registered users (id, name, phone, email, address, city).
    *   Added the API route `GET /admin/users` to expose this data to the mobile app.

### 3. Sync Logic Enhancements (`SyncService.dart`)
*   **Order Extraction**: Updated `_syncOrders` to look for the `userId` field. If present, the app safely knows the customer is an authenticated Cognito user and tags them as `source: 'website'`.
*   **Active Customer Sync**: Completely rewrote the `_syncCustomers` method. Instead of skipping the customer sync, the app now actively calls the new `GET /admin/users` API endpoint. It fetches all registered users from the backend and inserts/updates them in the local SQLite database with `source: 'website'`.

### 4. UI/UX Restrictions (`CustomersScreen.dart`)
*   **Strict Tab Filtering**: 
    *   Tab 0 (Website App) strictly filters for `customer.source == 'website'`.
    *   Tab 1 (Walk-in/Manual) strictly filters for `customer.source == 'manual'`.
*   **Data Integrity Protection**: The `Edit` and `Delete` action buttons in the Customer Detail Sheet are conditionally rendered. They are **hidden** for Website users (read-only) and only available for Manual users.

## Deployment Notes
*   The backend changes require a Lambda update. The deployment package (`lambda-deploy-v7.zip`) was generated containing `admin.mjs`, `index.mjs`, `package.json`, and crucially, the `node_modules` folder to prevent AWS SDK execution errors.
*   A "Pull-to-Refresh" on the mobile app triggers the updated `_syncCustomers` and `_syncOrders` logic, populating the database accurately.
