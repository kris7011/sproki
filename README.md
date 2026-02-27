# sproki

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Render: URL](https://sproki-backend.onrender.com)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## To run in debug

### Web (Chrome)

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL="https://sproki-backend.onrender.com" \
  --dart-define=API_BASE_PATH="" \
  --dart-define=SUPABASE_URL="https://iurzmypymceulkymhwpy.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="sb_publishable_4QVkDQedK25E9hJskaEuWg_ecrjajXF"

```bash
  flutter run -d emulator-5554 \
  --dart-define=API_BASE_URL="https://sproki-backend.onrender.com" \
  --dart-define=API_BASE_PATH="" \
  --dart-define=SUPABASE_URL="https://iurzmypymceulkymhwpy.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="sb_publishable_4QVkDQedK25E9hJskaEuWg_ecrjajXF"
  