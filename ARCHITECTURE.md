# SmartScan - Complete Architecture Guide

## Project Overview

`SmartScan` is a production-ready Flutter application for intelligent OCR, document scanning, text extraction, translation, and categorization. This document outlines the complete architecture, setup, and development guidelines.

## ✅ Completed Setup

### 1. **Dependencies (pubspec.yaml)**

All required packages have been added and resolved:

- Firebase (Firebase Core, Firestore, Storage, Messaging)
- ML Kit (Text Recognition, Language ID, Translation, Entity Extraction)
- State Management (Flutter BLoC)
- Local Storage (SQLite, Shared Preferences)
- UI/Animations (Flutter Animate, Lottie, Animations, Shimmer)
- Media (Camera, Image Picker, Image Cropper)
- Notifications (Flutter Local Notifications)
- Audio/Haptics (AudioPlayers, Vibration)
- Utilities (Permission Handler, Connectivity Plus, UUID)

### 2. **Localization System**

✅ ARB files created for 3 languages:

- `lib/l10n/app_en.arb` - English (100+ strings)
- `lib/l10n/app_fr.arb` - French (100+ strings)
- `lib/l10n/app_ar.arb` - Arabic with RTL support (100+ strings)

Run to generate localization:

```bash
flutter gen-l10n
```

### 3. **Theme System**

✅ Complete theme setup in `lib/core/theme/`:

- `app_colors.dart` - Comprehensive color palette with entity colors
- `app_theme.dart` - Light and Dark themes with Material Design 3
- Support for theme switching at runtime

### 4. **Core Services**

✅ Implemented services in `lib/core/services/` and `lib/core/utils/`:

- **DatabaseService** - SQLite wrapper with full CRUD operations
- **CloudSyncService** - Firebase Firestore + Storage integration
- **SoundManager** - Audio playback for UI feedback (singleton)
- **VibrationManager** - Haptic feedback system (singleton)
- **NotificationManager** - Local and scheduled notifications
- **AppConstants** - Configuration and constants

### 5. **Project Structure**

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp configuration
├── firebase_options.dart        # Firebase configuration
├── l10n/                        # Localization files
│   ├── app_en.arb
│   ├── app_fr.arb
│   └── app_ar.arb
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── sound_manager.dart
│   │   ├── vibration_manager.dart
│   │   └── notification_manager.dart
│   └── services/
│       ├── database_service.dart
│       └── cloud_sync_service.dart
├── features/
│   ├── scan/
│   ├── ocr/
│   ├── translation/
│   ├── categorization/
│   ├── history/
│   ├── export/
│   ├── settings/
│   └── dashboard/
├── shared/
│   ├── widgets/
│   └── animations/
└── flutter_gen/                 # Generated localization files
    └── gen_l10n/
        └── app_localizations.dart
```

## 📋 Next Steps to Complete

### Phase 1: Core Features

1. **Create BLoCs for State Management**
   - `ScanBloc` - Manages scan workflow
   - `HistoryBloc` - Manages scan list and search
   - `SettingsBloc/Cubit` - Manages app preferences
   - `DashboardBloc` - Computes statistics

2. **Create Model Classes**
   - `Scan` model with OCR, translation, entities, category
   - `Category` model
   - `Entity` model for extracted data

3. **Create Repository Pattern**
   - `ScanRepository` - Abstracts local/remote scan data
   - `CategoryRepository` - Abstracts category data

### Phase 2: Screens (15 screens total)

Create presentation layers for each feature:

```
features/[feature]/presentation/
├── pages/
│   └── [feature]_screen.dart
├── widgets/
│   ├── [custom_widget_1].dart
│   └── [custom_widget_2].dart
└── bloc/
    ├── [feature]_bloc.dart
    ├── [feature]_event.dart
    └── [feature]_state.dart
```

**Screen List:**

1. SplashScreen - Lottie animation
2. OnboardingScreen - 3-slide walkthrough
3. HomeScreen - Dashboard with quick actions
4. ScanScreen - Camera integration
5. PreviewScreen - Image adjustment
6. ProcessingScreen - Progress indicators
7. ResultScreen - OCR results with entities
8. CategoryPickerScreen - Assign category
9. HistoryScreen - Paginated scan list
10. ScanDetailScreen - Edit/view scan
11. SearchScreen - Full-text search with filters
12. DashboardScreen - Statistics and charts
13. CategoryMgmtScreen - CRUD categories
14. ExportScreen - PDF export/share
15. SettingsScreen - All preferences

### Phase 3: Animations

- [ ] Splash screen entrance animations
- [ ] Home screen staggered list animation
- [ ] Floating action button pulse
- [ ] Camera shutter animation
- [ ] Scanning line laser effect
- [ ] OCR progress ring animation
- [ ] Result text typewriter animation
- [ ] Category bounce animation
- [ ] Page transitions with SharedAxisTransition

### Phase 4: Advanced Features

- [ ] Full-text search implementation
- [ ] PDF export with formatting
- [ ] Push notifications (Firebase Cloud Messaging)
- [ ] Date-based reminders
- [ ] Cloud sync with conflict resolution
- [ ] Statistics computation
- [ ] Charts (pie chart, bar chart)

### Phase 5: Platform Configuration

- [ ] Android: Update AndroidManifest.xml with permissions
- [ ] iOS: Update Info.plist with permissions
- [ ] App icons and splash screens
- [ ] Firebase setup with keys

## 🛠 Development Guidelines

### Adding a New Feature

1. Create feature folder: `lib/features/[feature_name]/`
2. Create folder structure:

   ```
   [feature_name]/
   ├── data/
   │   ├── datasources/
   │   ├── models/
   │   └── repositories/
   ├── domain/
   │   ├── entities/
   │   ├── repositories/
   │   └── usecases/
   └── presentation/
       ├── bloc/
       ├── pages/
       └── widgets/
   ```

3. Implement using BLoC pattern:
   - Define events
   - Define states
   - Create BLoC
   - Create UI

### Using Services

```dart
// Sound
SoundManager().playSuccessSound();

// Vibration
VibrationManager().successVibration();

// Notifications
NotificationManager().showNotification(
  title: 'Title',
  body: 'Body',
);

// Database
DatabaseService().insertScan(scanData);
```

### Localization Usage

```dart
import 'flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)?.appName ?? 'SmartScan')
```

### Theme Usage

```dart
// Access colors
AppColors.primary

// Access theme
Theme.of(context).colorScheme.primary
```

## 🔐 Security Considerations

1. **Firebase Configuration**: Update `firebase_options.dart` with real Firebase project credentials
2. **API Keys**: Store sensitive keys in environment variables
3. **Data Encryption**: Implement encryption for stored scan data
4. **Permissions**: Request permissions only when needed
5. **Error Handling**: Never expose stack traces in production

## 📱 Platform-Specific Setup

### Android (`android/app/build.gradle`)

```gradle
android {
    compileSdkVersion 34
    ndkVersion "26.1.10909125"

    defaultConfig {
        targetSdkVersion 34
        minSdkVersion 21
    }
}
```

### iOS (`ios/Podfile`)

Ensure minimum deployment target is 11.0

## 🧪 Testing

Create test files:

```
test/
├── features/
│   ├── scan/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   └── [other_features]/
├── core/
│   ├── theme/
│   ├── utils/
│   └── services/
└── shared/
```

## 📦 Building for Production

```bash
# Android
flutter build apk --split-per-abi -v
flutter build app bundle -v

# iOS
flutter build ios --release -v

# Web
flutter build web --release -v
```

## 🚀 Performance Optimization

1. **Image Optimization**: Use cached_network_image for remote images
2. **Database Indexing**: Index frequently searched columns
3. **Lazy Loading**: Implement pagination for scan lists
4. **Memory Management**: Proper disposal of resources in BLoCs
5. **Code Splitting**: Use conditional imports for large modules

## 📚 Documentation Standards

Every public function should have dartdoc comments:

```dart
/// Saves a scan to the local database.
///
/// Returns the scan ID if successful, null otherwise.
/// Throws [DatabaseException] if write fails.
Future<String?> saveScan(ScanModel scan) async {
  // Implementation
}
```

## 🤝 Contributing

1. Follow the feature-based architecture
2. Use BLoC pattern for state management
3. Add localization strings for all user-visible text
4. Write unit tests for business logic
5. Use meaningful commit messages

## 📞 Support

For issues or feature requests, refer to the documentation or create an issue in the repository.

---

**Version**: 1.0.0  
**Last Updated**: April 2026  
**Maintainer**: SmartScan Development Team
