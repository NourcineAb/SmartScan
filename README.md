# SmartScan

SmartScan is a Flutter OCR and document scanning application. It captures images via camera or gallery, extracts text using Google ML Kit, detects document types and entities, translates content on-device, and exports results to PDF, TXT, or DOCX. The app supports English, French, and Arabic (including RTL layout) and persists data locally via SQLite with an optional Firebase-backed cloud sync layer.

## Key Features

- **OCR Text Extraction** — Google ML Kit text recognition returning structured output (blocks, lines, elements) with normalized bounding boxes for text region highlighting.
- **Smart Crop** — Auto-detected text region with a draggable crop widget that re-runs OCR on the selected area.
- **Entity Extraction** — Combined ML Kit entity annotation and regex-based extraction of emails, phone numbers, URLs, prices, dates, and addresses.
- **Document Type Classification** — Rule-based classifier that scores text against keyword sets for invoice, receipt, ticket, contract, official document, and note types.
- **On-Device Translation** — ML Kit on-device translation with model pre-downloading for offline language pairs covering 9 languages.
- **AI Summarization** — Optional Google Gemini integration that generates 3-bullet summaries and category suggestions from OCR text.
- **Reminder Suggestions** — Document-type-aware reminder generation (payment due dates, event dates, contract renewals, follow-ups).
- **Multi-Format Export** — Export scans as PDF, TXT, or DOCX with system share sheet integration.
- **Local Persistence** — SQLite database with in-memory web fallback plus file-based image storage.
- **Cloud Sync** — Optional Firebase Firestore sync for authenticated users via Google Sign-In.
- **Localization & RTL** — English, French, and Arabic localizations with automatic RTL directionality for Arabic.
- **Dark Mode** — Material Design 3 light/dark themes with a charcoal-and-coral dark palette.
- **Haptic & Audio Feedback** — Configurable shutter, success, error, and tap sounds with haptic patterns.

## Architecture Notes

### State Management

The application uses [flutter_bloc](https://pub.dev/packages/flutter_bloc) with events and states defined in separate files joined via Dart's `part` directive. Each feature contains its own `Bloc` (e.g., `ScanBloc`, `SettingsBloc`, `DashboardBloc`, `CategoryBloc`) that consumes repositories and services through constructor injection. Theme and language settings flow from `SettingsBloc` to `MaterialApp` via `BlocBuilder`.

### Dependency Injection

No DI framework is used. All services and repositories are implemented as singletons using the factory constructor pattern. BLoCs receive dependencies through constructor parameters, wired manually in `lib/main.dart`'s `MultiBlocProvider`.

### Navigation and Routing

Navigation is imperative using `Navigator.of(context).push(MaterialPageRoute(...))` and `Navigator.pushReplacement`. There are no named routes or generated routing. Transitions use custom `PageRouteBuilder` with fade animations.

### Feature Organization

Code is organized by feature under `lib/features/`, each following an internal `data/` → `presentation/` structure:

- `data/repositories/` — Repository implementations
- `data/services/` — Feature-specific services (e.g., OCR)
- `presentation/bloc/` — BLoC, events, and states
- `presentation/pages/` — Screen widgets
- `presentation/widgets/` — Feature-specific widgets
- `presentation/dialogs/` — Dialog widgets

Shared code lives in `lib/core/` (constants, services, theme, utils) and `lib/shared/` (models, widgets).

### Repository Pattern

Each data domain has a repository (`ScanRepository`, `CategoryRepository`, `ActionHistoryRepository`) that abstracts over `DatabaseService` and `FileStorageService`. BLoCs depend only on repositories.

### Service Layer

Core services in `lib/core/services/` are stateless singletons that encapsulate platform APIs:

- `DatabaseService` — SQLite operations with web fallback
- `ExportService` — PDF/TXT/DOCX generation and sharing
- `LanguageService` — Text language detection and on-device translation
- `EntityExtractionService` — Entity annotation via ML Kit and regex
- `CloudSyncService` — Firestore read/write for authenticated users
- `AnalyticsService` — Firebase Analytics event logging
- `NotificationService` — Local notifications for exports and reminders
- `FeedbackService` / `SoundManager` / `VibrationManager` — Audio and haptic feedback

### Offline Support

The app is fully offline-capable. Translation models can be pre-downloaded via `ModelDownloadService`. OCR and entity extraction run on-device through ML Kit. All scans are stored locally in SQLite. Cloud sync is opt-in and non-blocking.

### Caching Strategies

- **Image cache**: `PaintingBinding.instance.imageCache` is configured to 20 images / 15 MB at startup, aggressively cleared in the lifecycle service and fullscreen viewer disposal.
- **Multi-resolution images**: The `FullscreenImageViewer` loads a low-res (1000 px) image by default and upgrades to 2500 px only when the user zooms past 1.5×, using `ResizeImage`.
- **Translation models**: Downloaded once via `ModelDownloadService`; subsequent translations use the cached on-device model.

### Error Handling

Errors are caught at the BLoC level with try/catch blocks that emit `ScanError` states. Platform-level errors (Firebase init, file I/O, ML Kit failures) are caught locally per service with graceful fallbacks: mock OCR on web, default language detection, fallback fonts in PDF export.

### Platform-Specific Integrations

- **Web**: Conditional paths for OCR (mock data), analytics (console fallback), database (in-memory maps) via `kIsWeb` checks.
- **Android**: `AudioContextAndroid` for background audio, public Downloads folder for exports, notification channels.
- **iOS/MacOS/Linux/Windows**: Standard platform support via generated projects.

## Technologies and Packages

| Package | Purpose |
|---|---|
| [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) | BLoC state management |
| [`equatable`](https://pub.dev/packages/equatable) | Value equality for states/events |
| [`google_mlkit_text_recognition`](https://pub.dev/packages/google_mlkit_text_recognition) | On-device OCR |
| [`google_mlkit_language_id`](https://pub.dev/packages/google_mlkit_language_id) | Language identification |
| [`google_mlkit_translation`](https://pub.dev/packages/google_mlkit_translation) | On-device translation |
| [`google_mlkit_entity_extraction`](https://pub.dev/packages/google_mlkit_entity_extraction) | Entity annotation |
| [`google_generative_ai`](https://pub.dev/packages/google_generative_ai) | Gemini summarization |
| [`firebase_core`](https://pub.dev/packages/firebase_core) | Firebase initialization |
| [`firebase_analytics`](https://pub.dev/packages/firebase_analytics) | Usage analytics |
| [`cloud_firestore`](https://pub.dev/packages/cloud_firestore) | Cloud document sync |
| [`firebase_auth`](https://pub.dev/packages/firebase_auth) | Authentication |
| [`google_sign_in`](https://pub.dev/packages/google_sign_in) | Google sign-in |
| [`sqflite`](https://pub.dev/packages/sqflite) | Local SQLite database |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Key-value settings |
| [`image_picker`](https://pub.dev/packages/image_picker) | Camera/gallery capture |
| [`image`](https://pub.dev/packages/image) | Server-side image cropping |
| [`pdf`](https://pub.dev/packages/pdf) | PDF generation |
| [`printing`](https://pub.dev/packages/printing) | PDF printing |
| [`share_plus`](https://pub.dev/packages/share_plus) | System share sheet |
| [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) | Local notifications |
| [`audioplayers`](https://pub.dev/packages/audioplayers) | Sound effect playback |
| [`haptic_feedback`](https://pub.dev/packages/haptic_feedback) | Haptic feedback |
| [`flutter_animate`](https://pub.dev/packages/flutter_animate) | Declarative animations |
| [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) | Network connectivity |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | Typography |
| [`intl`](https://pub.dev/packages/intl) | Date formatting / localization |
| [`uuid`](https://pub.dev/packages/uuid) | v4 UUID generation |
| [`archive`](https://pub.dev/packages/archive) | DOCX archive creation |
| [`open_filex`](https://pub.dev/packages/open_filex) | Open files from notifications |
| [`file_picker`](https://pub.dev/packages/file_picker) | File selection dialogs |
| [`speech_to_text`](https://pub.dev/packages/speech_to_text) | Speech recognition |
| [`timezone`](https://pub.dev/packages/timezone) | Timezone-aware scheduling |

## Notable Implementation Techniques

- **BLoC with `part` directives** — Each feature's bloc, events, and state live in separate files joined via `part 'file.dart'`, keeping the event/state hierarchy co-located with the bloc without excessive imports.

- **Singleton services** — All core services use the Dart singleton pattern (`factory` constructor + private `_internal` constructor), eliminating the need for a DI container.

- **Smart Crop with CustomPainter** — `SmartCropWidget` uses a `CropOverlayPainter` that darkens the area outside the crop region and renders rule-of-thirds grid lines, with draggable corner handles for manual adjustment.

- **Hierarchical OCR output** — `OCRService` returns `StructuredOCRResult` with three bounding-box levels (blocks, lines, elements), each normalized to 0–1 coordinates, enabling both coarse region detection and element-level highlighting.

- **Multi-resolution image viewer** — `FullscreenImageViewer` uses `ResizeImage` with two resolution tiers (1000 px / 2500 px), switching to the higher-res provider only when zoom exceeds 1.5×, trading memory for sharpness on demand.

- **Lifecycle-aware memory management** — `AppLifecycleService` observes app lifecycle and clears image caches and resets native ML Kit services when the app background, with a throttled cleanup interval and a guard that disables cleanup during active scanning.

## Project Structure

```
smart_scan/
├── android/
├── assets/
│   ├── images/
│   └── sounds/
├── ios/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── services/
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       ├── notification_manager.dart
│   │       ├── page_transition_utils.dart
│   │       ├── sound_manager.dart
│   │       └── vibration_manager.dart
│   ├── features/
│   │   ├── categorization/
│   │   ├── dashboard/
│   │   ├── history/
│   │   ├── main/
│   │   ├── scan/
│   │   ├── settings/
│   │   └── translation/
│   ├── l10n/
│   ├── shared/
│   │   ├── models/
│   │   └── widgets/
│   ├── app.dart
│   ├── app_barrel.dart
│   ├── firebase_options.dart
│   └── main.dart
├── linux/
├── macos/
├── test/
│   └── widget_test.dart
├── web/
├── windows/
├── analysis_options.yaml
├── flutter_launcher_icons.yaml
├── l10n.yaml
└── pubspec.yaml
```

## Development Notes

- **SDK constraint**: Dart `>=3.3.0 <4.0.0`, Flutter `>=3.19.0`.
- **Firebase**: Requires `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) for authentication, analytics, and Firestore.
- **Google ML Kit**: OCR, language ID, translation, and entity extraction run on-device; no network required after translation model download.
- **Gemini**: Optional — provide an API key through the in-app settings. Without it, AI summarization and parsing are skipped.
- **Localization**: ARB-based via `flutter gen-l10n`. Run `flutter gen-l10n` after editing `.arb` files to regenerate `app_localizations.dart`.
- **Code generation**: `build_runner` is listed as a dev dependency; no generated code (freezed, json_serializable) is currently in use — all models are hand-written with `toMap`/`fromMap`.
- **Image cache**: Configured to 20 images / 15 MB to avoid OOM on lower-end devices. The lifecycle service performs aggressive cleanup on app backgrounding.
