# xpenzes-app

Flutter mobile app for Xpenzes — a smart expense tracking application. This is a **thin client** that fetches all data from the backend (`xpenzes-svc`) via REST API. No local database or client-side business logic.

## Architecture

- **State management**: Riverpod
- **Authentication**: Supabase passwordless OTP (email magic link)
- **Backend integration**: All providers call `xpenzes-svc` API endpoints
- **No local storage**: Every transaction, budget, and analytics query goes to the server

See the full product architecture in `../xpenzes-svc/docs/PROJECT.md`.

## Setup

```bash
flutter pub get
flutter analyze      # must be clean
flutter run
```

**Requirements:**
- Flutter SDK 3.12.2+
- Dart SDK (bundled with Flutter)
- Running `xpenzes-svc` backend (see `../xpenzes-svc/README.md`)

## Configuration

Create a Supabase project and update the auth config in `lib/core/config/env.dart` with:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Also configure the backend API base URL in the same file (`API_BASE_URL`).

## Verification

After making changes, always run:
```bash
flutter analyze
```

Must complete with no errors before committing.

## Project Structure

```
lib/
├── app.dart
├── main.dart
├── core/
│   ├── config/        # Environment config, Supabase setup
│   ├── constants/     # App-wide constants (currencies, categories, etc.)
│   ├── network/       # API client (Dio-based, auto-attaches Supabase token)
│   ├── theme/         # App theme
│   ├── utils/         # Date formatting, validators
│   └── widgets/       # Shared UI components
└── features/          # Feature-based architecture
    ├── account/       # User profile, settings
    ├── analytics/     # Analytics dashboard
    ├── auth/          # Supabase OTP auth
    ├── budgets/       # Budget CRUD
    ├── home/          # Transaction list, main hub
    ├── navigation/    # Root shell, bottom nav
    ├── onboarding/    # First-run flow
    ├── spend_radar/   # Recurring spend aggregation
    ├── subscription/  # Pro features, billing
    └── transactions/  # Transaction models, providers
```

Each feature typically contains: `models/`, `providers/`, `screens/`, `widgets/` subdirectories.

## Development Notes

- This app was originally fully local (using `sqflite`), but was rewired as a thin client in the current architecture.
- All business logic lives in `xpenzes-svc` — the app just renders data and sends user actions to the API.
- For billing flow: app calls `POST /checkout/handoff` → redirects to `xpenzes-web/upgrade` → returns to app after payment.
