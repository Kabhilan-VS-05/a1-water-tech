# Step 2: Move Read-Only Data To AWS

Do not change login or orders yet.

In this phase we only move:
- products
- services
- announcements
- business settings
- billing settings

## First Thing To Do

Create an `Amazon RDS for PostgreSQL` database.

Use this SQL file after the database is ready:
- [aws-readonly-schema.sql](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/aws-readonly-schema.sql)

## Why We Start Here

This is the safest phase because the website mostly reads this data.

These React files will be migrated later in this phase:
- [useProducts.js](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/a1-water-online-shop/src/hooks/useProducts.js)
- [useServices.js](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/a1-water-online-shop/src/hooks/useServices.js)
- [useAnnouncements.js](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/a1-water-online-shop/src/hooks/useAnnouncements.js)
- [SiteSettingsContext.jsx](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/a1-water-online-shop/src/state/SiteSettingsContext.jsx)

## What Not To Move Yet

Not yet:
- Firebase Auth
- orders
- bookings
- addresses
- cart
- feedback

Those will come after the read-only AWS API is working.
