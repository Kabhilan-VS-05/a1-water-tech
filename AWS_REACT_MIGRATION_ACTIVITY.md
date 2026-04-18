# AWS React Migration Activity

Date: 2026-04-11  
Workspace root: `d:\Users\Desktop\The Project\A1 Water Tech`

## Goal

Migrate the **React website only** from Firebase-based hosting/auth/data to AWS.

Flutter admin app is **not** part of the hosting migration.

## Project Paths

- React app: `d:\Users\Desktop\The Project\A1 Water Tech\a1-water-online-shop`
- Lambda source: `d:\Users\Desktop\The Project\A1 Water Tech\aws-lambdas\products-api`
- Current frontend deploy zip: `d:\Users\Desktop\The Project\A1 Water Tech\a1-water-online-shop\aws-react-upload-final.zip`
- Current Lambda deploy zip: `d:\Users\Desktop\The Project\A1 Water Tech\aws-lambdas\products-api-lambda.zip`

## Current AWS Resources

### Frontend

- AWS Amplify manual deploy
- Staging URL: `https://staging.d128klivfw89ld.amplifyapp.com`

### API Gateway

- API name: `a1-readonly-api`
- API ID: `k713nuvb74`
- Base URL: `https://k713nuvb74.execute-api.ap-south-1.amazonaws.com`
- React env currently points to: `https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod`

### Lambda

- Function name: `a1-products-api`
- Runtime is Node.js
- Lambda is manually connected to the VPC for RDS access

### RDS PostgreSQL

- Endpoint: `a1-water-tech-db.chk0gamumn4n.ap-south-1.rds.amazonaws.com`
- Port: `5432`
- Database: `postgres`
- Username: `a1admin`

### Cognito

- User pool ID: `ap-south-1_frjBbY5H9`
- App client ID: `7ipnh0krocrne8a98n5kecdtg0`
- Client secret: none

### AWS CloudShell

- VPC environment name: `a1-db-shell`

## What Was Migrated

The React website has been moved feature-by-feature from Firebase to AWS.

### Read-only data moved to AWS

- Products
- Services
- Announcements
- Business settings
- Billing settings

### Write flows moved to AWS

- Feedback / contact form
- Bookings
- Addresses / profile
- Orders / checkout
- Order tracking / order history
- Cart

### Auth moved to AWS

- Firebase Auth replaced with Cognito in the React app
- Sign up
- Login
- Email verification code flow
- Resend verification code

## Database Tables Created

The following tables were created in PostgreSQL during migration:

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

## API Routes Added

These routes are handled by the Lambda backend:

### Read routes

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

### Write routes

- `POST /feedback`
- `POST /bookings`
- `POST /addresses`
- `PUT /addresses/{id}`
- `DELETE /addresses/{id}`
- `POST /orders`
- `PUT /cart/{id}`
- `DELETE /cart/{id}`
- `DELETE /cart`

## Main React Files Changed

### Auth and app startup

- `a1-water-online-shop/src/cognito.js`
- `a1-water-online-shop/src/polyfills.js`
- `a1-water-online-shop/src/state/AuthContext.jsx`
- `a1-water-online-shop/src/pages/Login.jsx`
- `a1-water-online-shop/src/main.jsx`
- `a1-water-online-shop/vite.config.js`

### Data hooks and providers

- `a1-water-online-shop/src/hooks/useProducts.js`
- `a1-water-online-shop/src/hooks/useServices.js`
- `a1-water-online-shop/src/hooks/useAnnouncements.js`
- `a1-water-online-shop/src/hooks/useBookings.js`
- `a1-water-online-shop/src/hooks/useOrders.js`
- `a1-water-online-shop/src/hooks/useAddresses.js`
- `a1-water-online-shop/src/state/SiteSettingsContext.jsx`
- `a1-water-online-shop/src/state/CartContext.jsx`

### Pages changed to AWS backend

- `a1-water-online-shop/src/pages/Contact.jsx`
- `a1-water-online-shop/src/pages/Bookings.jsx`
- `a1-water-online-shop/src/pages/Profile.jsx`
- `a1-water-online-shop/src/pages/Checkout.jsx`
- `a1-water-online-shop/src/pages/TrackOrder.jsx`
- `a1-water-online-shop/src/pages/Login.jsx`

### Product/cart behavior

- `a1-water-online-shop/src/components/ProductCard.jsx`
- `a1-water-online-shop/src/pages/ProductDetail.jsx`

### Backend source

- `aws-lambdas/products-api/index.mjs`

## Environment Configuration

Current production env file:

`a1-water-online-shop/.env.production`

Current values:

```env
VITE_API_BASE_URL=https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod
VITE_COGNITO_USER_POOL_ID=ap-south-1_frjBbY5H9
VITE_COGNITO_CLIENT_ID=7ipnh0krocrne8a98n5kecdtg0
```

## Important Fixes Applied

### 1. White screen due to Cognito/browser globals

Problem:

- Build loaded but app could blank due to browser-incompatible globals from Cognito bundle

Fixes:

- Added `src/polyfills.js`
- Added browser-safe globals for:
  - `global`
  - `process.env`
  - `Buffer`
- Moved Cognito loading to dynamic import in `src/cognito.js`
- Added `global` define in `vite.config.js`

### 2. White screen due to bad Amplify zip structure

Problem:

- `index.html` deployed, but `assets/` files returned `404`

Cause:

- Windows zip packaging created entries in a way Amplify manual deploy did not serve correctly

Fix:

- Final frontend zip is now rebuilt using `tar.exe -a -cf ...` from inside `dist`
- This preserves `assets/...` correctly

### 3. Cart failed with `400 Bad Request`

Problem:

- Add-to-cart failed on:
  - `PUT /prod/cart/{productId}`

Cause:

- Lambda path parsing only worked when the path started with `/cart/`
- API Gateway prod stage sends paths like `/prod/cart/...`

Fix:

- Updated `getPathId()` in:
  - `aws-lambdas/products-api/index.mjs`
- It now finds route ids even when the path contains a stage prefix like `/prod`

### 4. Cart UX was too optimistic

Problem:

- UI showed success even if cart API failed

Fix:

- `ProductCard.jsx` now awaits the cart request
- `ProductDetail.jsx` now awaits the cart request
- Failure now shows a friendly error toast instead of fake success

### 5. Cognito sign-in user id issue

Problem:

- `uid` could become empty during sign-in flow

Fix:

- `signInWithCognito()` now reads the session payload directly
- `CartContext.jsx` now safely falls back to local cart unless `user.uid` is present

## Current Build Information

Latest verified frontend build:

- JS asset: `/assets/index-Ctt8YT3g.js`
- CSS asset: `/assets/index-10OojLtX.css`

Latest frontend zip:

- `d:\Users\Desktop\The Project\A1 Water Tech\a1-water-online-shop\aws-react-upload-final.zip`

Latest Lambda zip:

- `d:\Users\Desktop\The Project\A1 Water Tech\aws-lambdas\products-api-lambda.zip`

## Manual Deploy Notes

### Frontend deploy

1. Build React app
2. Recreate zip from `dist`
3. Upload zip manually in Amplify

### Current packaging method that works

From inside `a1-water-online-shop/dist`, package using:

```powershell
tar.exe -a -cf ..\aws-react-upload-final.zip *
```

This is preferred over `Compress-Archive` for this Amplify setup.

### Lambda deploy

Upload:

- `aws-lambdas/products-api-lambda.zip`

to Lambda:

- `a1-products-api`

## What Was Still Pending For Final Verification

At this stage, the migration is mostly complete, but the live site should still be manually tested end-to-end.

Recommended verification checklist:

1. Sign up in Cognito
2. Verify email with code
3. Login
4. Add a product to cart
5. Open cart
6. Increase quantity
7. Remove item
8. Sign out and sign in again, verify cart still loads
9. Add or edit address
10. Submit booking
11. Submit contact form
12. Place order
13. Check order history
14. Track order

## Remaining Cleanup Work

These are the main cleanup tasks left after functional verification:

### Remove Firebase leftovers

Still present:

- `a1-water-online-shop/src/firebase.js`
- Firebase packages still present in `a1-water-online-shop/package.json`

Likely removable later:

- `firebase`
- `firebase-admin`

Only remove after confirming nothing still imports them.

### Fix Amplify SPA refresh behavior

Issue seen:

- direct path refresh on URLs like `/shop/` can show `404`

Needs:

- correct Amplify rewrite/redirect rule for SPA routing

### Lock down database access

Current setup was opened for easier migration.

Later improvements:

- set RDS `Publicly accessible` back to `No`
- remove temporary laptop IP access if still present

### Move secrets out of Lambda env vars

Current DB password is in Lambda environment variables.

Better later:

- move DB credentials to AWS Secrets Manager

## Quick Handoff Text

Use this summary when continuing in another chat:

- React app only migrated to AWS
- Amplify hosts frontend
- API Gateway + Lambda + RDS handle data
- Cognito handles auth
- most functional work is done
- latest frontend zip is `a1-water-online-shop/aws-react-upload-final.zip`
- latest Lambda zip is `aws-lambdas/products-api-lambda.zip`
- latest frontend asset is `/assets/index-Ctt8YT3g.js`
- most recent backend bug fixed was `/prod/cart/{id}` path parsing in Lambda

## Notes

- Flutter admin app was intentionally left out of hosting migration
- If Flutter still expects Firebase data, that should be reviewed separately
- Existing Firebase users are not automatically migrated into Cognito unless a dedicated migration flow is built
