# A1 Water Tech Project Full Overview

Date updated: 2026-04-18  
Workspace root: `d:\Users\Desktop\The Project\A1 Water Tech`

## 1. Project Summary

This project is a complete digital system for the **A1 Water Tech** business.

It is not just one app. It is a connected setup with:

- a **customer-facing React website**
- an **admin / billing Flutter app**
- a **shared AWS backend**

The system supports:

- product browsing and sales
- service booking
- customer accounts
- address management
- cart and checkout
- order tracking
- feedback collection
- announcements
- billing and invoice management
- admin order confirmation
- analytics and business settings

So in simple terms, this project is a **water purifier ecommerce + service booking + billing + admin operations platform**.

---

## 2. Main Parts Of The Project

There are 3 major parts.

### 2.1 Customer Website

Path:

- `a1-water-online-shop`

Technology:

- React
- Vite
- React Router

Purpose:

- customers use this app to browse products and services
- customers can sign up and log in
- customers can maintain profile/address data
- customers can place orders
- customers can book service visits
- customers can track their orders

### 2.2 Admin / Billing App

Path:

- `a1_tech_billing`

Technology:

- Flutter

Purpose:

- admins use this app to manage the business side
- confirm or reject product orders
- confirm or reject service bookings
- generate and edit bills
- manage products and services
- view analytics
- respond to feedback
- manage announcements and settings

### 2.3 Shared AWS Backend

Path:

- `aws-lambdas`

Purpose:

- serves both the React website and the Flutter admin app
- provides API endpoints
- reads and writes to PostgreSQL in Supabase
- works with Cognito for authentication flow

---

## 3. Project Folder Structure

Top-level project folders/files:

- `.vscode`
- `a1-water-online-shop`
- `a1_tech_billing`
- `aws-lambdas`
- `Project Deatils`
- `amplify.yml`
- SQL schema files for AWS migration
- markdown handoff / migration notes

Important directories:

### React app

- `a1-water-online-shop/src`
- `a1-water-online-shop/public`
- `a1-water-online-shop/scripts`
- `a1-water-online-shop/dist`

### Flutter app

- `a1_tech_billing/lib`
- `a1_tech_billing/android`
- `a1_tech_billing/ios`
- `a1_tech_billing/web`
- `a1_tech_billing/windows`
- `a1_tech_billing/build`

### Shared backend

- `aws-lambdas/products-api`

---

## 4. Customer Website Details

Project path:

- `a1-water-online-shop`

### 4.1 What The Website Does

The website is the customer portal for A1 Water Tech.

Customers can:

- open the home page
- view featured products
- view service plans
- read announcements
- sign up / log in
- add products to cart
- checkout and place orders
- add and edit saved addresses
- book services
- view order history
- track orders
- contact the business

### 4.2 Important Website Pages

Main routing is in:

- `a1-water-online-shop/src/App.jsx`

Important routes/pages include:

- `/` -> home
- `/shop` -> product listing
- `/shop/:id` -> product detail
- `/cart` -> shopping cart
- `/checkout` -> order checkout
- `/orders` -> order history
- `/track-order` -> tracking
- `/services` -> service plans
- `/bookings` -> customer service bookings
- `/profile` -> user profile and addresses
- `/login` -> login/signup/verification
- `/contact` -> feedback/contact form
- `/faq`
- `/terms`
- `/privacy`

### 4.3 Main Website State / Providers

Application setup is in:

- `a1-water-online-shop/src/main.jsx`

Main providers used:

- `AuthProvider`
- `CartProvider`
- `SiteSettingsProvider`

Important files:

- `a1-water-online-shop/src/state/AuthContext.jsx`
- `a1-water-online-shop/src/state/CartContext.jsx`
- `a1-water-online-shop/src/state/SiteSettingsContext.jsx`

### 4.4 Main Website Data Hooks

Data hooks fetch AWS-backed data for the customer app:

- `a1-water-online-shop/src/hooks/useProducts.js`
- `a1-water-online-shop/src/hooks/useServices.js`
- `a1-water-online-shop/src/hooks/useAnnouncements.js`
- `a1-water-online-shop/src/hooks/useAddresses.js`
- `a1-water-online-shop/src/hooks/useBookings.js`
- `a1-water-online-shop/src/hooks/useOrders.js`
- `a1-water-online-shop/src/hooks/useRecommendations.js`

### 4.5 Main Website User Flows

#### Product flow

- customer opens shop
- product list comes from AWS API
- product detail page shows single item details
- customer adds to cart

#### Cart / checkout flow

- cart is linked to signed-in user
- address is selected
- checkout sends order data to AWS API
- order is stored in Supabase

#### Service booking flow

- customer selects service
- customer selects date/time
- address snapshot is included
- booking is stored in Supabase

#### Feedback flow

- customer sends feedback or contact message
- message is stored in Supabase
- admin later sees it in Flutter admin app

#### Auth flow

- user signs up with Cognito
- verifies email
- signs in
- customer-specific data then loads by Cognito user identity

---

## 5. Flutter Admin / Billing App Details

Project path:

- `a1_tech_billing`

### 5.1 What The Flutter App Does

This app is the internal admin/business tool.

It is used to:

- log in as admin
- view dashboard overview
- confirm/reject product orders
- confirm/reject service bookings
- generate bills automatically from orders
- create manual bills
- edit existing bills
- manage feedback
- manage catalog
- manage announcements
- change business settings
- change billing settings
- view sales analytics

### 5.2 Important Flutter Screens

Most of the app is implemented in:

- `a1_tech_billing/lib/main.dart`

Important screens inside it:

- app entry / login gate
- dashboard page
- order confirmation page
- automatic billing page
- manual billing page
- bill editor / manage bills page
- feedback center
- sales analytics page
- catalog management page
- announcements management page
- business settings page

### 5.3 Flutter Data Layer

AWS repository file:

- `a1_tech_billing/lib/billing_repository_aws.dart`

This repository handles:

- orders
- bookings
- bills
- feedback
- announcements
- settings
- metrics
- catalog items

It uses:

- HTTP requests to API Gateway / Lambda
- polling streams for live-ish updates
- local caches for smoother UI and less loading flicker

### 5.4 Flutter Auth Layer

Auth file:

- `a1_tech_billing/lib/admin_auth_cognito.dart`

Admin login works like this:

1. user signs in with Cognito
2. app calls admin session API
3. backend checks whether that email/user is approved in the `admins` table
4. only approved admins are allowed into the app

So the Flutter app is not using hardcoded admin access.

### 5.5 Flutter Admin Flows

#### Dashboard

Shows:

- overview metrics
- recent bills or pending billing items
- quick actions

#### Order confirmation

Admin can:

- review order details
- see customer details
- confirm
- reject with confirmation dialog

#### Booking confirmation

Admin can:

- review booking details
- see customer/contact details
- confirm
- reject

#### Billing flow

Two modes:

- automatic billing from website orders
- manual billing for direct/walk-in billing

Bills can also be edited and PDF/shared.

#### Analytics flow

Admin sees:

- revenue
- sales count
- trend chart
- top-selling items

#### Feedback flow

Admin can:

- view customer feedback
- mark status
- send admin responses

#### Catalog flow

Admin can:

- manage products
- manage services

#### Announcement flow

Admin can:

- create or update announcement banners/messages

---

## 6. Shared AWS Backend Details

Backend path:

- `aws-lambdas/products-api`

### 6.1 Backend Files

Main backend files:

- `aws-lambdas/products-api/index.mjs`
- `aws-lambdas/products-api/admin.mjs`

### 6.2 Backend Purpose

This backend acts as the API layer between frontend apps and the database.

It handles:

- product reads
- service reads
- settings reads
- announcements
- feedback create/read/update
- bookings create/read/update
- addresses CRUD
- orders create/read/track
- cart CRUD
- admin routes
- billing routes
- metrics routes

### 6.3 Why This Backend Is Shared

Both apps use the same business data:

- website creates orders/bookings/feedback
- admin app reviews and manages them

So it makes sense that both apps talk to one common backend and database.

---

## 7. AWS Services Used

### 7.1 Amplify

Used for:

- hosting the React website

Current staging URL:

- `https://staging.d128klivfw89ld.amplifyapp.com`

### 7.2 API Gateway

Used for:

- public HTTP API routing
- sending API requests to Lambda

Current API:

- `a1-readonly-api`
- API ID: `k713nuvb74`

Base URL:

- `https://k713nuvb74.execute-api.ap-south-1.amazonaws.com`

### 7.3 Lambda

Used for:

- all business API logic
- request routing
- validation and DB access

Current function:

- `a1-products-api`

### 7.4 Supabase PostgreSQL

Used for:

- main business relational data storage

Stores:

- products
- services
- orders
- bookings
- addresses
- feedback
- bills
- admins
- settings
- announcements
- cart data

### 7.5 Cognito

Used for:

- website customer authentication
- Flutter admin authentication

Current Cognito config:

- pool ID: `ap-south-1_frjBbY5H9`
- client ID: `7ipnh0krocrne8a98n5kecdtg0`

### 7.6 S3

Used for:

- image storage

The user had already mentioned images were stored in S3.

### 7.7 CloudShell

Used for:

- running PostgreSQL commands inside AWS environment
- schema setup and seed execution

Current VPC shell:

- `a1-db-shell`

---

## 8. Database Overview

### 8.1 Website / customer tables

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

### 8.2 Admin / billing tables and extensions

- `admins`
- `bills`
- extra admin tracking fields on:
  - `orders`
  - `bookings`
  - `feedback`

### 8.3 SQL Files In Project

- `aws-readonly-schema.sql`
- `aws-readonly-seed.sql`
- `aws-feedback-schema.sql`
- `aws-bookings-schema.sql`
- `aws-addresses-schema.sql`
- `aws-orders-schema.sql`
- `aws-cart-schema.sql`
- `aws-flutter-admin-schema.sql`
- `aws-flutter-admin-seed.sql`

These files were used during migration/setup and are important for future environment recreation.

---

## 9. Authentication Model

### 9.1 Website users

- authenticate through Cognito
- email verification supported
- used for customer-facing login/signup

### 9.2 Flutter admin users

- authenticate through Cognito
- must also exist in `admins` table
- this creates an approval layer beyond just password login

This means the admin app follows:

- Cognito auth
- then admin authorization

---

## 10. Cross-App Data Relationship

The customer website and admin app are connected.

### Example

- customer places order on website
- order goes to Supabase through AWS API
- admin app reads that order from AWS
- admin confirms order
- admin generates bill
- bill becomes part of analytics and billing management

Another example:

- customer books a service
- booking is stored in Supabase
- admin sees booking in Flutter app
- admin confirms or rejects it

So the project is one connected business workflow, not two separate unrelated apps.

---

## 11. General Business Modules Inside The Project

These are the main business modules present in the project:

### Customer Commerce

- product listing
- cart
- checkout
- order history

### Service Management

- service plans
- customer service booking
- booking review in admin

### Customer Account Management

- signup/login
- address storage
- profile management

### Business Operations

- order confirmation
- booking confirmation
- billing
- announcements
- feedback handling

### Management / Reporting

- dashboard overview
- sales analytics
- recent billing activity

---

## 12. Current Documentation Files

The most useful project docs currently are:

- `AWS_FULL_PROJECT_ACTIVITY.md`
- `AWS_REACT_MIGRATION_ACTIVITY.md`
- `AWS_FLUTTER_ADMIN_MIGRATION_ACTIVITY.md`
- `REACT_AWS_STEP_1.md`
- `AWS_STEP_2_READONLY.md`

Suggested main references:

- `AWS_FULL_PROJECT_ACTIVITY.md` for history and migration activity
- `PROJECT_FULL_OVERVIEW.md` for general project understanding

---

## 13. Current Deploy Artifacts

### React frontend zip

- `a1-water-online-shop/aws-react-upload-final.zip`

### Lambda zip

- `aws-lambdas/products-api-lambda.zip`

### Flutter APK

- `a1_tech_billing/build/app/outputs/flutter-apk/app-debug.apk`

---

## 14. Current Known Follow-Up Areas

### React

- remove old Firebase leftovers
- improve Amplify SPA rewrite behavior
- tighten DB secret handling
- final cleanup and hardening

### Flutter Admin

- continue validating overview and sales analytics with live deployed Lambda
- keep smoothing loading behavior
- continue testing manage bills / automatic billing / metrics

### AWS Security

- move DB password to Secrets Manager
- reduce public DB exposure after system is stable
- optionally add stronger server-side JWT verification for admin routes

---

## 15. Simple One-Line Description

If someone asks what this project is, the simplest correct answer is:

**A1 Water Tech is a cloud-based customer sales, service booking, admin billing, and business operations platform built with a React website, a Flutter admin app, and a shared AWS backend using Lambda, API Gateway, Supabase PostgreSQL, Cognito, Amplify, and S3.**
