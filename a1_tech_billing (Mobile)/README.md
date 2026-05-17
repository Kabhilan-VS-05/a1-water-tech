# A1 Water Tech Billing App

Flutter admin and billing application for A1 Water Tech.

## What It Does

- Admin Cognito login
- Offline-first local SQLite storage
- Manual bill creation
- Automatic billing from website orders
- Customer management
- Product/service catalog management
- Order confirmation and billing
- Invoice PDF generation
- Background sync with the AWS API

## Active Structure

```text
lib/
|-- main.dart
|-- models/
|-- screens/
|   |-- billing/
|   |-- catalog/
|   |-- customers/
|   `-- orders/
`-- services/
```

Archived legacy Dart files are kept in `legacy_lib/` and excluded from active
analysis.

## Verification

```cmd
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

The debug APK is generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```
