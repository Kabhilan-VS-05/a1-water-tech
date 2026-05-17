# A1 Water Tech Website - Deployment Guide

## AWS Amplify Deployment Steps

### Step 1: Build the Project

Open CMD and run:

```cmd
cd /d "d:\Users\Desktop\The Project\A1 Water Tech\a1-water-online-shop (Web)"
npm run build
```

### Step 2: Create Zip File

After build completes, create the zip:

```cmd
cd /d "d:\Users\Desktop\The Project\A1 Water Tech\a1-water-online-shop (Web)"

powershell -Command "Remove-Item 'a1-water-web-build.zip' -ErrorAction SilentlyContinue; $source = '.\dist'; $dest = '.\a1-water-web-build.zip'; Add-Type -Assembly 'System.IO.Compression.FileSystem'; [System.IO.Compression.ZipFile]::CreateFromDirectory($source, $dest)"
```

Or use Python:

```cmd
cd /d "d:\Users\Desktop\The Project\A1 Water Tech\a1-water-online-shop (Web)"
python -c "import shutil; shutil.make_archive('a1-water-web-build', 'zip', 'dist')"
```

### Step 3: Verify Zip Contents

The zip should contain at the root:
- `index.html`
- `assets/` folder (with .js and .css files)
- `vite.svg`
- All product images (.png files)

### Step 4: Upload to AWS Amplify

1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
2. Select app: **a1-water-tech-web** (App ID: d128klivfw89ld)
3. Click **"Deploy without Git provider"**
4. Choose **"Drag and drop"** or **"Upload zip"**
5. Select file: `a1-water-web-build.zip`
6. Click **Save and deploy**

### Step 5: Add Redirect Rules (Important!)

If you get 404 errors for assets, add this rewrite rule:

1. In Amplify Console → App settings → **Rewrites and redirects**
2. Click **Edit** → **Add rule**:
   - **Source address**: `</^[^.]+$|\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|ttf)$)([^.]+$)/>`
   - **Target address**: `/index.html`
   - **Type**: `200 (Rewrite)`
3. Click **Save**

### Staging URL

After deployment, your site will be at:
```
https://staging.d128klivfw89ld.amplifyapp.com/
```

## Environment Variables

Make sure these are set in Amplify Console → Environment variables:

| Variable | Value |
|----------|-------|
| `VITE_API_BASE_URL` | `https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod` |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| White screen / 404 for assets | Check redirect rules are configured |
| API not working | Verify `VITE_API_BASE_URL` environment variable |
| Images not showing | Check S3 bucket CORS policy |

## Last Deployed

- **Date**: May 2, 2026
- **App ID**: d128klivfw89ld
- **Domain**: https://staging.d128klivfw89ld.amplifyapp.com/
