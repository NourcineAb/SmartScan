# SmartScan - Project Structure Guide

## Overview

This project follows a **Clean Architecture + BLoC** pattern with feature-based organization.

```
lib/
├── main.dart                           # App entry point
├── app.dart                            # MaterialApp & routing setup
├── firebase_options.dart               # Firebase configuration
│
├── core/                               # App-wide services & utilities
│   ├── constants/
│   │   └── app_constants.dart          # Global constants & configs
│   ├── services/                       # Singleton services
│   │   ├── database_service.dart       # SQLite wrapper
│   │   ├── cloud_sync_service.dart     # Firebase Firestore sync
│   │   └── auth_service.dart           # Authentication
│   ├── theme/                          # Design system
│   │   ├── app_colors.dart             # Color palette
│   │   ├── app_theme.dart              # Theme definitions
│   │   └── app_typography.dart         # Text styles
│   └── utils/                          # Utilities & helpers
│       ├── sound_manager.dart          # Audio playback (singleton)
│       ├── vibration_manager.dart      # Haptic feedback (singleton)
│       ├── notification_manager.dart   # Local notifications
│       └── validators.dart             # Input validation
│
├── features/                           # Feature modules
│   │
│   ├── main/                           # Main launcher/home navigation
│   │   ├── data/
│   │   │   ├── repositories/           # Data access abstraction
│   │   │   └── services/               # Business logic services
│   │   └── presentation/
│   │       ├── bloc/                   # State management
│   │       ├── pages/                  # Full-screen pages
│   │       └── widgets/                # Reusable UI components
│   │
│   ├── scan/                           # Document scanning feature
│   │   ├── data/
│   │   │   ├── repositories/           # Repository pattern
│   │   │   └── services/               # Scan services
│   │   └── presentation/
│   │       ├── bloc/                   # Scan BLoC
│   │       ├── pages/                  # Scan screens
│   │       └── widgets/                # Scan UI widgets
│   │
│   ├── ocr/                            # Optical Character Recognition
│   │   ├── data/
│   │   │   ├── repositories/           # OCR data layer
│   │   │   └── services/               # OCR service integration
│   │   ├── presentation/
│   │   │   ├── bloc/                   # OCR state management
│   │   │   ├── pages/                  # OCR result screens
│   │   │   └── widgets/                # OCR UI components
│   │   └── domain/
│   │       └── models/                 # Domain models
│   │
│   ├── translation/                    # Translation feature
│   │   ├── data/
│   │   │   ├── repositories/           # Translation data access
│   │   │   └── services/               # Translation API service
│   │   └── presentation/
│   │       ├── bloc/                   # Translation BLoC
│   │       ├── pages/                  # Translation screens
│   │       └── widgets/                # Translation widgets
│   │
│   ├── categorization/                 # Document categorization
│   │   ├── data/
│   │   │   ├── repositories/           # Category data
│   │   │   └── services/               # Categorization logic
│   │   └── presentation/
│   │       ├── bloc/                   # Category BLoC
│   │       ├── pages/                  # Category screens
│   │       └── widgets/                # Category widgets
│   │
│   ├── history/                        # Scan history & archive
│   │   ├── data/
│   │   │   ├── repositories/           # History data access
│   │   │   └── services/               # History services
│   │   └── presentation/
│   │       ├── bloc/                   # History BLoC
│   │       ├── pages/                  # History screens
│   │       └── widgets/                # History widgets
│   │
│   ├── export/                         # Export to PDF/Share
│   │   ├── data/
│   │   │   ├── repositories/           # Export data
│   │   │   └── services/               # PDF/export services
│   │   └── presentation/
│   │       ├── bloc/                   # Export BLoC
│   │       ├── pages/                  # Export screens
│   │       └── widgets/                # Export widgets
│   │
│   ├── settings/                       # App settings & preferences
│   │   ├── data/
│   │   │   ├── repositories/           # Settings persistence
│   │   │   └── services/               # Settings services
│   │   └── presentation/
│   │       ├── bloc/                   # Settings BLoC (if complex)
│   │       ├── pages/                  # Settings screens
│   │       └── widgets/                # Settings widgets
│   │
│   └── dashboard/                      # Dashboard/Analytics (optional)
│       ├── data/
│       │   ├── repositories/           # Dashboard data
│       │   └── services/               # Analytics services
│       └── presentation/
│           ├── bloc/                   # Dashboard BLoC
│           ├── pages/                  # Dashboard screens
│           └── widgets/                # Dashboard charts/widgets
│
├── shared/                             # Shared across features
│   ├── models/                         # Common data models
│   │   ├── user_model.dart
│   │   ├── scan_model.dart
│   │   └── settings_model.dart
│   ├── widgets/                        # Reusable UI components
│   │   ├── custom_buttons.dart
│   │   ├── custom_dialogs.dart
│   │   └── loading_indicators.dart
│   └── animations/                     # Animation utilities
│       └── custom_transitions.dart
│
├── l10n/                               # Localization
│   ├── app_en.arb                      # English strings
│   ├── app_fr.arb                      # French strings
│   └── app_ar.arb                      # Arabic strings (RTL)
│
└── flutter_gen/                        # Auto-generated localization
    └── gen_l10n/
        └── app_localizations.dart
```

---

## Architecture Layers

### 1. **Data Layer** (`data/`)

- **Repositories**: Implement the repository pattern for data abstraction
- **Services**: External API calls, database operations, file handling

### 2. **Presentation Layer** (`presentation/`)

- **BLoC**: State management (events, states)
- **Pages**: Full-screen widgets
- **Widgets**: Reusable UI components

### 3. **Domain Layer** (`domain/`) - Optional

- **Models**: Business logic models (used in OCR where complex)
- Only include if the feature has significant business logic

---

## Key Principles

✅ **Feature Independence**: Each feature is self-contained  
✅ **Clean Separation**: Data/Presentation/Domain layers clearly separated  
✅ **Reusability**: Common logic goes to `core/` or `shared/`  
✅ **State Management**: Use BLoC for complex UI state  
✅ **Singleton Services**: Use singleton pattern in `core/services/`  
✅ **Testing**: Each layer can be tested independently

---

## Dependency Flow

```
UI (Widgets) → BLoC → Repository → Service → Data Source (API/DB/Local)
```

---

## When to Add New Features

1. Create new folder in `lib/features/[feature_name]/`
2. Create `data/` and `presentation/` subdirectories
3. Add `repositories/` and `services/` under data
4. Add `bloc/`, `pages/`, `widgets/` under presentation
5. If complex business logic, add `domain/models/`

---

## Shared vs Core

- **`core/`**: App-wide services, constants, theme (singleton, stateless)
- **`shared/`**: Common UI components, models used across features (reusable, stateless)
- **`features/`**: Feature-specific code (feature-complete, can have state)
