# A1 Water Tech – Digital Service Ordering, GST Billing & Recommendation System

## Project Overview
A1 Water Tech – Digital Service Ordering, GST Billing & Recommendation System is a real-time consultancy-based project developed to digitize the operations of a service-based business.  
The system replaces manual service ordering and billing with a modern web and mobile solution supported by cloud storage and intelligent service recommendations.

The project integrates:
- A customer-facing website
- An admin mobile application for billing
- A backend system using Firebase
- A recommendation engine based on the Apriori algorithm

---

## Objectives
- Digitize manual service and product ordering
- Automate GST-based billing and invoice generation
- Maintain centralized and secure cloud records
- Support both online and offline billing scenarios
- Improve customer experience using intelligent service recommendations

---

## Existing System
The existing system relied on:
- Manual service booking
- Handwritten bills
- Offline record maintenance
- Manual GST calculation

### Limitations
- Time-consuming processes
- Higher chances of GST errors
- No centralized data storage
- No analytics or recommendation support
- Poor scalability

---

## Proposed System
The proposed system is a **web and mobile-based digital platform** that automates:
- Service and product ordering
- Billing and GST calculation
- Invoice generation
- Data storage using cloud services
- Recommendation of frequently selected services

---

## System Architecture (High Level)
- **Customer Website** – Service & product browsing and order placement
- **Admin Mobile Application** – Billing and invoice handling
- **Backend & Cloud** – Firebase for data storage, billing logic, and recommendations

---

## Project Modules

---

## 1️⃣ Customer Website (Frontend – Integration Ready)

### Description
A customer-facing website developed using React JS.  
The website focuses on UI and frontend logic and uses static JSON data while keeping the structure ready for seamless backend and Firebase integration.

### Features
- Home page with business overview
- Service and product listing
- Product/service detail pages
- Order placement interface (UI level)
- Static display of recommended services
- Responsive design for mobile and desktop

### Data Handling
- Static JSON used as the current data source
- Centralized data layer
- JSON structure aligned with future database schema
- Easy replacement with Firebase or APIs

---

## 2️⃣ Admin Mobile Application – Billing System (Frontend – Integration Ready)

### Description
A Flutter-based admin mobile application designed for billing services and products.  
The app supports **two billing modes** and provides fully editable billing interfaces.

---

### Billing Modes

#### a) Automatic Billing (From Website Orders)
- Bills generated automatically using order data from the website
- Order details pre-filled into the billing form
- All bill fields remain editable before finalization
- Designed to receive real-time data from backend/Firebase

#### b) Manual Billing (Empty Bill Form)
- Bills created manually from scratch
- Service and product selection by admin
- Quantity and price entry
- Suitable for walk-in or offline customers
- Fully editable billing form

---

### Mobile App Features
- Admin login interface (UI level)
- Dashboard with billing navigation
- Automatic billing screen
- Manual billing screen
- Bill summary and preview screen
- Clean and simple UI for quick billing

---

## 3️⃣ Backend System & Cloud Services

### Firebase Data Architecture
- Firestore collections for:
  - Customers
  - Orders
  - Services and products
  - Bills and invoices
- Real-time data synchronization
- Scalable and secure data design

---

### Order Processing
- Receive orders from the customer website
- Validate and normalize order details
- Store confirmed orders in Firebase
- Provide order data for automatic billing in the admin app

---

### Billing Logic
- Centralized billing data model
- Supports:
  - Automatic billing from website orders
  - Manual billing created by admin
- Editable billing records
- Prepares billing data for GST and invoice generation

---

### GST Calculation
- GST logic implemented centrally
- Supports:
  - CGST
  - SGST
  - IGST
- Dynamic tax calculation based on bill details
- Reduces manual calculation errors

---

### Invoice Generation
- PDF invoice generation
- Secure storage using Firebase Storage
- Invoice linked with billing records
- Easy retrieval for admin use

---

## 4️⃣ Service Recommendation System (Apriori Algorithm)

### Description
An intelligent recommendation system built using the **Apriori association rule mining algorithm**.

### Functionality
- Analyzes historical order data
- Identifies frequently selected service and product combinations
- Detects seasonal demand patterns
- Generates recommendation rules

### Usage
- Recommendations displayed on the website
- Helps admin suggest relevant services during billing

### Update Strategy
- Recommendations generated periodically
- Monthly refresh based on accumulated order history

---

## Technologies Used

### Frontend
- React JS (Website)
- HTML, CSS, Bootstrap

### Mobile Application
- Flutter

### Backend & Cloud
- Firebase Firestore
- Firebase Functions
- Firebase Authentication
- Firebase Storage

### Recommendation Engine
- Apriori Algorithm
- JavaScript / Python (as required)

---

## System Workflow
1. Customer browses services/products on the website  
2. Customer places an order  
3. Order data is processed and stored in Firebase  
4. Admin chooses:
   - Automatic billing from website order, or  
   - Manual billing for walk-in customers  
5. GST is calculated automatically  
6. Invoice is generated and stored  
7. Recommendation system updates periodically  

---

## Key Features
- Dual billing modes (online & offline)
- Editable billing records
- GST-compliant automated billing
- Cloud-based real-time storage
- Intelligent service recommendations
- Modular and scalable system design

---

## One-Line Project Summary
This project digitizes service ordering and GST billing for A1 Water Tech using a web and mobile platform, supported by Firebase and an Apriori-based recommendation system to handle both online and offline business operations efficiently.