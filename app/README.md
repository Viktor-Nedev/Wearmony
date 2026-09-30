# Wearmony app

Flutter client for web (organizers, iPhone users) and Android (participants).

```bash
flutter pub get
flutter run -d chrome                                          # backend on http://localhost:8787
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8787
flutter test
```

- `API_BASE_URL` (dart-define) points to the backend; the app never calls YouCam directly.
- Translations live in `lib/l10n/app_en.arb` and `lib/l10n/app_bg.arb`; run `flutter gen-l10n` after editing them.
- In debug builds the landing page links to a try-on pipeline check that exercises the backend's mock mode.
