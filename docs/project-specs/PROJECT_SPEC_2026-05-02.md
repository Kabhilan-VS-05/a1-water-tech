# A1 Water Tech – Admin Billing & Business Management Mobile Application

**Project Specification Document**  
**Date:** May 2, 2026  
**Version:** 2.0 - Production Ready Redesign

---

## 1. Project Overview

### Context
Complete business system consisting of:
- **Customer Website:** React-based frontend for customers to browse products/services and place orders
- **Admin Mobile App:** Flutter-based app for shop management (this project)
- **Shared Backend:** AWS (API Gateway + Lambda + Supabase PostgreSQL + Cognito + S3)

### Objective
Redesign and rebuild the admin mobile application to be:
- **Fast:** Minimal steps for core operations
- **Practical:** Designed for real shop environment
- **Offline-First:** Works without internet, syncs when online
- **GST Compliant:** Proper tax calculations and invoice generation

---

## 2. Core Modules

### 2.1 Billing System (PRIMARY MODULE)

#### 2.1.1 Manual Billing
- Select products/services from local catalog
- Search existing customers or create new customer
- Store customer details (name, phone, address) for reuse
- **GST Calculation:**
  - CGST + SGST for intra-state (default 9% each = 18% total)
  - IGST for inter-state (default 18%)
  - Configurable GST rates per product category
- Generate invoice with unique bill number
- **Editable Bills:** Allow modification after creation (before payment)
- **Payment Modes:** Cash / Online / Pending
- **Bill Status:** Draft → Confirmed → Paid

#### 2.1.2 Automatic Billing
- Fetch confirmed orders from website via API
- Auto-populate bill with order data (customer, items, amounts)
- Allow admin to review and edit before finalizing
- Maintain link: Order ID → Bill ID
- Mark order as "Billed" after invoice generation

#### 2.1.3 Common Features
- **PDF Invoice Generation** with company branding
- **Invoice Storage:** Local + Cloud backup
- **Print Support:** Bluetooth thermal printer integration (future)
- **Bill History:** Search, filter, view all bills

---

### 2.2 Account Management (Customer Database)

- **Customer Profiles:**
  - Name (required)
  - Phone (required, unique)
  - Address (optional)
  - Email (optional)
  - Created date, last visit
- **Smart Search:**
  - Autocomplete during billing
  - Search by name or phone
  - Recent customers list
- **Duplicate Prevention:**
  - Phone number validation
  - Suggest existing customer if phone matches
- **Customer History:**
  - View all bills for a customer
  - Total lifetime value
  - Last purchase date

---

### 2.3 Product & Service Management

- **Catalog Management:**
  - Add, edit, delete products/services
  - Fields: Name, Price, GST %, Category, Description
  - **Image Upload:** AWS S3 with public access
- **Categories:**
  - Products: Purifiers, Filters, Accessories, Commercial
  - Services: Installation, Maintenance, Repair, Testing
- **GST Configuration:**
  - Default: 18% (9% CGST + 9% SGST)
  - Per-item override possible
- **Sync:**
  - Local SQLite storage
  - Sync with website catalog via API
  - Image caching for offline viewing

---

### 2.4 Order Management

- **Fetch Orders:** From website backend via API
- **Order Categories:**
  - **Pending:** New orders awaiting confirmation
  - **Confirmed:** Admin approved, ready for billing
  - **Completed:** Billed and delivered
  - **Expired:** Auto-moved if service date exceeded
  - **Rejected:** Cancelled by admin
- **Filters:**
  - Date range (today, this week, this month, custom)
  - Product/Service type
  - Order status
  - Customer name/phone
- **Actions:**
  - View full order details
  - Confirm/Reject orders
  - Convert to bill (automatic billing)
  - Contact customer (call/WhatsApp)

---

### 2.5 Notification System

- **Notification Types:**
  - New order received
  - New service booking
  - Payment received
  - Order status changes
- **Display:**
  - In-app notification center
  - Badge counts on menu icons
  - Summary view (customer name, items, amount)
- **Delivery:**
  - Polling-based (every 5 minutes when online)
  - Push notifications (Phase 2 - Firebase)

---

### 2.6 Offline-First Architecture (CRITICAL)

- **Local Database:** SQLite
  - Bills table
  - Customers table
  - Products/Services table
  - Orders table (cached)
  - Settings table
- **Sync Strategy:**
  - **When Online:**
    - Sync local changes to cloud
    - Fetch latest data from cloud
    - Resolve conflicts (last-write-wins)
  - **When Offline:**
    - Continue normal operations
    - Queue changes for sync
    - Show offline indicator
- **Data Persistence:**
  - No data loss on app close
  - Auto-save drafts
  - Background sync when connection restored

---

### 2.7 Dashboard & Analytics

- **Real-time Metrics:**
  - Today's revenue
  - Today's order count
  - Pending orders count
  - Pending bills count
- **Charts:**
  - Weekly revenue trend
  - Top-selling products/services
  - Payment mode distribution
- **Recent Activity:**
  - Last 5 bills
  - Last 5 orders
  - Quick actions

---

### 2.8 Additional Features

- **Search & Filter:** Global search across bills, customers, orders
- **Announcements:** Admin can view company announcements
- **Feedback:** View customer feedback from website
- **Settings:**
  - Business info (name, GSTIN, address)
  - GST rates configuration
  - Invoice numbering format
  - App preferences
- **Reports:**
  - Daily sales report
  - Monthly GST report
  - Customer statement

---

## 3. Technical Architecture

### 3.1 Frontend (Flutter)

```
lib/
├── main.dart                 # App entry, routing
├── screens/                  # UI Screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart      # Dashboard
│   ├── billing/
│   │   ├── manual_billing_screen.dart
│   │   ├── auto_billing_screen.dart
│   │   ├── bill_editor_screen.dart
│   │   └── bill_history_screen.dart
│   ├── customers/
│   │   ├── customer_list_screen.dart
│   │   ├── customer_detail_screen.dart
│   │   └── customer_search_dialog.dart
│   ├── catalog/
│   │   ├── product_list_screen.dart
│   │   ├── product_editor_screen.dart
│   │   └── image_upload_dialog.dart
│   ├── orders/
│   │   ├── order_list_screen.dart
│   │   └── order_detail_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── widgets/                  # Reusable UI components
├── models/                   # Data models
├── services/                 # Business logic
│   ├── database_service.dart     # SQLite
│   ├── api_service.dart          # AWS API
│   ├── auth_service.dart         # Cognito
│   ├── sync_service.dart         # Offline sync
│   └── pdf_service.dart          # Invoice generation
└── utils/                    # Helpers, constants
```

### 3.2 Backend (AWS)

| Service | Purpose |
|---------|---------|
| API Gateway | REST API endpoints |
| Lambda | Business logic handlers |
| Supabase PostgreSQL | Cloud database |
| Cognito | User authentication |
| S3 | Image and PDF storage |

### 3.3 Database Schema

#### SQLite (Local)

```sql
-- Bills
CREATE TABLE bills (
  id TEXT PRIMARY KEY,
  bill_number TEXT UNIQUE,
  customer_id TEXT,
  customer_name TEXT,
  customer_phone TEXT,
  customer_address TEXT,
  items TEXT, -- JSON array
  subtotal REAL,
  gst_amount REAL,
  total REAL,
  payment_mode TEXT, -- cash/online/pending
  status TEXT, -- draft/confirmed/paid
  is_synced INTEGER DEFAULT 0,
  created_at TEXT,
  updated_at TEXT
);

-- Customers
CREATE TABLE customers (
  id TEXT PRIMARY KEY,
  name TEXT,
  phone TEXT UNIQUE,
  address TEXT,
  email TEXT,
  total_visits INTEGER DEFAULT 0,
  total_spent REAL DEFAULT 0,
  is_synced INTEGER DEFAULT 0,
  created_at TEXT
);

-- Products/Services
CREATE TABLE catalog (
  id TEXT PRIMARY KEY,
  type TEXT, -- product/service
  name TEXT,
  price REAL,
  gst_percent REAL DEFAULT 18,
  category TEXT,
  description TEXT,
  image_url TEXT,
  is_active INTEGER DEFAULT 1,
  is_synced INTEGER DEFAULT 0,
  updated_at TEXT
);

-- Orders (cached from web)
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  customer_name TEXT,
  customer_phone TEXT,
  customer_address TEXT,
  items TEXT, -- JSON
  total REAL,
  status TEXT, -- pending/confirmed/completed/rejected
  order_date TEXT,
  synced_at TEXT
);

-- Sync Queue
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT,
  record_id TEXT,
  operation TEXT, -- insert/update/delete
  payload TEXT,
  created_at TEXT
);
```

---

## 4. User Experience (UX) Requirements

### 4.1 Core Principles

- **Minimal Steps:** Complete billing in 3-4 taps
- **Speed:** No loading screens > 2 seconds
- **Reliability:** Works even with poor internet
- **Clarity:** Large fonts, high contrast for shop lighting
- **Efficiency:** Smart defaults, remember preferences

### 4.2 Navigation Structure

```
Home (Dashboard)
├── Billing
│   ├── New Bill (Manual)
│   ├── From Order (Automatic)
│   └── Bill History
├── Customers
│   ├── Customer List
│   └── Add Customer
├── Orders
│   ├── Pending Orders
│   ├── Confirmed Orders
│   └── All Orders
├── Catalog
│   ├── Products
│   ├── Services
│   └── Add/Edit Items
└── Settings
    ├── Business Info
    ├── GST Settings
    └── Sync Status
```

### 4.3 Billing Flow

**Manual Billing (Fastest Path):**
1. Tap "New Bill"
2. Select customer (search or add new)
3. Add items (quick tap catalog)
4. Review & confirm (auto-calculated GST)
5. Generate invoice

**Automatic Billing:**
1. Notification: "New Order #1234"
2. Tap notification
3. Review order details
4. Tap "Generate Bill"
5. Edit if needed → Confirm

---

## 5. Business Flow Integration

```
Website                    Mobile App
─────────────────────────────────────────
Customer                    Admin
   │                           │
   │ Browse products           │
   │ Place order ─────────────►│ Notification
   │ Pay online                │ View order
   │                           │ Confirm order
   │                           │ Generate bill
   │                           │ Create invoice
   │◄─────────────────────────│ (SMS/WhatsApp)
   │                           │
   │ Service delivered         │ Mark complete
   │                           │
```

---

## 6. Implementation Phases

### Phase 1: Core Foundation (Week 1-2)
- [ ] Project setup, SQLite database
- [ ] Offline-first architecture
- [ ] Basic UI structure

### Phase 2: Billing System (Week 3-4)
- [ ] Manual billing with GST
- [ ] Customer management
- [ ] PDF invoice generation
- [ ] Bill history & editing

### Phase 3: Integration (Week 5-6)
- [ ] AWS API integration
- [ ] Automatic billing from orders
- [ ] Order management
- [ ] Sync mechanism

### Phase 4: Polish & Features (Week 7-8)
- [ ] Dashboard & analytics
- [ ] Notifications
- [ ] Settings & configuration
- [ ] Testing & optimization

---

## 7. Success Criteria

| Metric | Target |
|--------|--------|
| Bill creation time | < 30 seconds |
| App launch time | < 3 seconds |
| Offline functionality | 100% core features |
| Sync reliability | > 99% success rate |
| User satisfaction | No manual workarounds needed |

---

## 8. File Locations

| Document | Path |
|----------|------|
| This Spec | `docs/project-specs/PROJECT_SPEC_2026-05-02.md` |
| Deployment Guide | `docs/guides/DEPLOYMENT_2026-05-02.md` |
| Mobile App | `a1_tech_billing (Mobile)/` |
| Website | `a1-water-online-shop (Web)/` |

---

**Prepared for:** A1 Water Tech  
**Prepared by:** AI Development Assistant  
**Status:** Ready for Implementation
