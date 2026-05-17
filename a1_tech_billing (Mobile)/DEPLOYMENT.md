# A1 Water Tech Mobile Build Guide

## Android Debug Build

```cmd
flutter clean
flutter pub get
flutter build apk --debug --no-pub
```

Output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Android Release Build

```cmd
flutter clean
flutter pub get
flutter build apk --release --no-pub
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Current App Notes

- The active app is modular, with code split across `models`, `screens`, and
  `services`.
- `legacy_lib/` stores old monolithic reference files and is excluded from
  analyzer checks.
- AWS API URL and Cognito pool/client values are currently hardcoded in the
  Flutter services. Move them to build-time configuration before public release.
- `flutter pub get` may print pub.dev advisory decode warnings with the current
  local Flutter/pub toolchain. The app can still analyze, test, and build.
