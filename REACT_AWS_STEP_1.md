# Step 1: Host The React App On AWS Amplify

This step hosts the current React website on AWS without changing its backend yet.

What stays the same in this step:
- Firebase Auth stays in use.
- Firestore stays in use.
- Existing image URLs keep working.
- The Flutter app is not touched.

What this step gives you:
- The React app is live on AWS.
- We separate hosting work from database migration work.
- We can move Firebase features to AWS one by one later.

## Files Already Prepared

The repository root now includes an [amplify.yml](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/amplify.yml) file so AWS Amplify builds only the React app folder:
- App root: `a1-water-online-shop`
- Install command: `npm ci`
- Build command: `npm run build`
- Output folder: `dist`

## Deploy In AWS Amplify

1. Push this repository to GitHub, GitLab, or Bitbucket if it is not there already.
2. Open AWS Console.
3. Go to `AWS Amplify`.
4. Choose `Create new app`.
5. Choose `Host web app`.
6. Connect your git repository.
7. Select the branch you want to deploy.
8. Select `My app is a monorepo`.
9. Enter the app root path as `a1-water-online-shop`.
10. Keep the repository root as the git repo root.
11. Confirm that Amplify detects the root `amplify.yml`.
12. Start the deployment.

## Add The SPA Rewrite Rule

Because this app uses `BrowserRouter`, direct navigation to routes such as `/shop`, `/orders`, or `/bookings` must be rewritten to `index.html`.

In Amplify:
1. Open your app.
2. Go to `App settings`.
3. Open `Rewrites and redirects`.
4. Add this rule from AWS's SPA example:

```json
[
  {
    "source": "</^[^.]+$|\\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|woff2|ttf|map|json|webp)$)([^.]+$)/>",
    "status": "200",
    "target": "/index.html",
    "condition": null
  }
]
```

## Verify After Deploy

Check these URLs after deployment:
- `/`
- `/shop`
- `/shop/a1-pureflow-rouv`
- `/login`
- `/profile`
- `/orders`
- `/bookings`
- `/contact`

If the homepage works but direct page refresh on inner routes fails, the rewrite rule is missing or incorrect.

## Important Current Limitation

Hosting on AWS does not move the data layer yet. The React app still talks directly to Firebase in these places:
- Auth state and sign-in: [a1-water-online-shop/src/state/AuthContext.jsx](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/a1-water-online-shop/src/state/AuthContext.jsx)
- Firestore setup: [a1-water-online-shop/src/firebase.js](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/a1-water-online-shop/src/firebase.js)
- Orders: [a1-water-online-shop/src/pages/Checkout.jsx](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/a1-water-online-shop/src/pages/Checkout.jsx)
- Bookings: [a1-water-online-shop/src/pages/Bookings.jsx](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/a1-water-online-shop/src/pages/Bookings.jsx)
- Addresses and cart sync: [a1-water-online-shop/src/state/CartContext.jsx](d:/Users/Desktop/The%20Project/A1%20Water%20Tech/a1-water-online-shop/src/state/CartContext.jsx)

That means:
- The site can be hosted on AWS now.
- Orders, bookings, login, cart, addresses, and feedback still depend on Firebase until we migrate them.

## Recommended Next Step

After the site is live on AWS hosting, Step 2 should be:
- Move read-only website data first:
  - `products`
  - `services`
  - `announcements`
  - `app_settings`

That will be the safest first move from Firebase to `API Gateway + Lambda + RDS`.
