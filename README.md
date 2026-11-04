# Sproki

Sproki is a **Flutter/Dart prototype for Danish word-practice activities**. It contains word categories, text-to-speech, speech recognition, local exercise progress, progress views and PDF reporting. It is not a clinically validated speech-therapy tool.

The app is designed to run locally. **It does not require paid hosting.** Speech-recognition and speech-synthesis availability depends on the device, operating system, installed language services and permissions; these capabilities have not been verified on every platform.

## Features

- Browse Danish words and phonetic categories, with progressively unlocked activities.
- Tap a word illustration to hear it spoken using the device's text-to-speech service.
- Practice speaking using the device's speech-recognition integration.
- Store exercise attempts and per-word progress locally with Hive.
- Inspect progress and generate a local PDF report using the existing reporting tools.
- **New: Exercise history** (clock icon on the home screen) lists the 50 most recent locally stored attempts, newest first, with the practiced word, time and result. Refresh, empty, loading and error states are supported. No remote service is used.
- **New: Practice suggestions** (light-bulb icon on the home screen) shows transparent, local progress insights and up to five suggested words for another practice session. Selecting a word opens the existing practice screen; returning refreshes the summary. Suggestions use existing per-word attempts, exclude locked/unknown words and never claim to provide clinical advice.

## Run locally

Install Flutter and platform-specific tooling appropriate for your device. Then:

```bash
git clone https://github.com/kris7011/sproki.git
cd sproki
flutter pub get
flutter run
```

Run the static analyzer and tests:

```bash
flutter analyze
flutter test
```

Automated checks run in GitHub Actions on pull requests and pushes to `main`.

## Architecture of the new history feature

The history feature uses a small **feature-first, layered design** rather than expanding global mutable services:

```text
lib/features/practice_history/
  domain/
    practice_attempt.dart                 # Immutable domain snapshot
    practice_history_repository.dart      # Storage-agnostic contract
  data/
    hive_practice_history_repository.dart # Adapter for existing local Hive data
  application/
    practice_history_cubit.dart           # Immutable states, loading, retry and errors
  presentation/
    practice_history_screen.dart          # Flutter widgets
```

The composition root (`main.dart`) injects the repository into `HomeScreen`. The history screen provides a feature-scoped `PracticeHistoryCubit` with `BlocProvider` and renders immutable loading, empty, loaded and failure states with `BlocBuilder`. Neither the Cubit nor the widgets import Hive. The Hive adapter maps existing `WordAttempt` data into immutable snapshots; **the stored schema and adapters are unchanged**. This keeps the feature isolated and testable with fake repositories.

The tests cover Cubit state transitions, retries and cancellation safety, local Hive mapping and sorting, and widget empty/populated states. Cubit states are asserted through its public stream using `flutter_test`; this avoids a dependency conflict between the current `bloc_test` and the legacy Hive code generator. The existing Flutter template counter test has been replaced with tests of real app functionality.

## Practice suggestions architecture

The `lib/features/progress_insights/` feature follows the same separation as the history feature: pure-Dart ranking rules and immutable snapshots in `domain/`, a read-only adapter for the existing Hive progress box in `data/`, a `ProgressInsightsCubit` for initial/loading/empty/loaded/error states in `application/`, and a Flutter screen in `presentation/`. The existing per-word Hive schema is unchanged. Tests cover ranking rules, invalid data, database snapshots, refresh/error behavior and the screen.

**Important:** the numbers describe previous attempts on this device; they are not an assessment of pronunciation or a substitute for professional guidance. This data is not currently separated by child profile.

## Privacy and limitations

- Exercise history stays in local application storage. **Do not put personal information about children or their speech recordings in this public repository.**
- A result shown as “Godkendt” reflects the existing attempt's stored success flag; it is **not** a medical evaluation or diagnostic result.
- There is no user-account synchronisation or cloud database in this prototype. It does not add audio upload, advertising, analytics or remote telemetry.
- Earlier screens use existing static services and predate the new layered history feature. They have **not** all been migrated to this architecture.
- Microphone permissions, speech providers and PDF printing vary by device. Physical-device verification is still needed before claiming reliable operation on Android or iOS.

This repository demonstrates Flutter UI, plugin integrations, local persistence, bounded data access and a progressively testable architecture. It is not a production-ready medical or educational product.
