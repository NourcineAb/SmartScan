# Contributing to SmartScan

Thank you for your interest in contributing to SmartScan! This guide outlines the standards and processes for contributing to this project.

## Code of Conduct

- Be respectful and inclusive
- Focus on the code, not the person
- Help others learn and grow
- Report issues responsibly

## Development Process

### 1. Setting Up Development Environment

```bash
# Clone the repository
git clone <repository-url>
cd Flutter-App

# Get dependencies
flutter pub get

# Generate code (localization, etc.)
flutter gen-l10n

# Enable pre-commit checks
chmod +x scripts/pre-commit.sh
```

### 2. Creating a Feature

Follow the feature-based architecture:

```
features/[feature_name]/
├── data/
│   ├── datasources/          # Remote/Local data sources
│   ├── models/               # Serializable models
│   └── repositories/         # Repository implementations
├── domain/
│   ├── entities/             # Core business entities
│   ├── repositories/         # Abstract repositories
│   └── usecases/             # Business logic
└── presentation/
    ├── bloc/                 # BLoC + Events + States
    ├── pages/                # Full-screen widgets
    └── widgets/              # Reusable components
```

### 3. Naming Conventions

**Files**

- Classes: `UpperCamelCase.dart`
- Variables/Functions: `lowerCamelCase`
- Constants: `kConstantName`
- Private: `_privateVariable`

**Classes**

- BLoCs: `[Feature]Bloc`
- Events: `[Feature]Event`
- States: `[Feature]State`
- Models: `[Entity]Model`
- Widgets: `[Feature]Widget` or `[Purpose]Widget`

### 4. Code Style

Follow Dart conventions and Google style guide:

```dart
// Good
class ScanModel {
  final String id;
  final String title;

  ScanModel({
    required this.id,
    required this.title,
  });

  /// Converts model to JSON-serializable map.
  Map<String, dynamic> toMap() => {...};
}

// Documentation
/// Saves a scan to the database.
///
/// Returns the scan ID if successful.
/// Throws [DatabaseException] on failure.
Future<String> saveScan(ScanModel scan) async {
  // Implementation
}
```

### 5. Localization

**❌ DO NOT** hardcode user-facing strings:

```dart
// BAD
Text('Invoice')

// GOOD
Text(AppLocalizations.of(context)?.category_invoice ?? 'Invoice')
```

**Add strings to all ARB files:**

```json
{
  "category_invoice": "Invoice",
  "category_invoice_fr": "Facture",
  "category_invoice_ar": "الفاتورة"
}
```

### 6. State Management (BLoC)

Always use BLoC pattern for state:

```dart
// 1. Define Events
abstract class ScanEvent {}
class ProcessScanEvent extends ScanEvent {
  final String imagePath;
  ProcessScanEvent({required this.imagePath});
}

// 2. Define States
abstract class ScanState {}
class ScanLoading extends ScanState {}
class ScanSuccess extends ScanState {
  final ScanModel scan;
  ScanSuccess({required this.scan});
}
class ScanFailure extends ScanState {
  final String message;
  ScanFailure({required this.message});
}

// 3. Create BLoC
class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc() : super(ScanInitial()) {
    on<ProcessScanEvent>(_onProcessScan);
  }

  Future<void> _onProcessScan(
    ProcessScanEvent event,
    Emitter<ScanState> emit,
  ) async {
    emit(ScanLoading());
    try {
      final scan = await _processScan(event.imagePath);
      emit(ScanSuccess(scan: scan));
    } catch (e) {
      emit(ScanFailure(message: e.toString()));
    }
  }
}

// 4. Use in UI
BlocBuilder<ScanBloc, ScanState>(
  builder: (context, state) {
    if (state is ScanLoading) {
      return const LoadingWidget();
    } else if (state is ScanSuccess) {
      return ResultWidget(scan: state.scan);
    } else if (state is ScanFailure) {
      return ErrorWidget(message: state.message);
    }
    return const SizedBox.shrink();
  },
)
```

### 7. Error Handling

Create custom exceptions:

```dart
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
}

class DatabaseException extends AppException {
  DatabaseException(String message) : super(message);
}

class OCRException extends AppException {
  OCRException(String message) : super(message);
}

// Usage
try {
  await processImage(imagePath);
} on OCRException catch (e) {
  showError(AppLocalizations.of(context)?.error_ocr_failed);
} on Exception catch (e) {
  showError('Unexpected error');
}
```

### 8. Testing

Write tests for all business logic:

```dart
test('ScanBloc processes image correctly', () async {
  final scanBloc = ScanBloc(scanRepository: mockRepo);

  expectLater(
    scanBloc.stream,
    emitsInOrder([
      isA<ScanLoading>(),
      isA<ScanSuccess>(),
    ]),
  );

  scanBloc.add(ProcessScanEvent(imagePath: 'test.jpg'));
});
```

### 9. Committing Changes

Use clear commit messages:

```bash
# Feature
git commit -m "feat: add OCR text extraction

- Implement text recognition using ML Kit
- Add support for multiple languages"

# Fix
git commit -m "fix: handle empty scan results gracefully

- Add null checks in OCR processor
- Show user-friendly error message"

# Style
git commit -m "style: format code according to dart conventions"

# Docs
git commit -m "docs: add database schema documentation"
```

### 10. Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** changes with clear messages
4. **Push** to your fork
5. **Create** a Pull Request with:
   - Clear title and description
   - Reference to related issues
   - Screenshots if UI changes
   - Test results

### 11. Code Review Checklist

Before requesting review, ensure:

- [ ] Code follows naming conventions
- [ ] All strings are localized
- [ ] No hardcoded values
- [ ] Proper error handling
- [ ] Unit tests written
- [ ] BLoC pattern used for state
- [ ] Documentation added
- [ ] No console.log or debug prints
- [ ] Builds without warnings
- [ ] Tested on both Android and iOS

### 12. Documentation

Document public APIs:

````dart
/// Analyzes an image for text content.
///
/// This method uses Google ML Kit for on-device OCR processing.
/// Results are cached to improve performance.
///
/// Parameters:
///   - [imageFile]: The image file to analyze
///   - [language]: Language code (en, fr, ar)
///   - [useCache]: Whether to use cached results
///
/// Returns:
///   A [ScanResult] containing extracted text and metadata.
///
/// Throws:
///   - [OCRException]: If text extraction fails
///   - [LanguageException]: If language is not supported
///
/// Example:
/// ```dart
/// final result = await ocr.analyzeImage(
///   imageFile: imageFile,
///   language: 'en',
/// );
/// ```
Future<ScanResult> analyzeImage({
  required File imageFile,
  required String language,
  bool useCache = true,
}) async {
  // Implementation
}
````

### 13. Performance Guidelines

- Use `const` constructors when possible
- Avoid rebuilds with `BlocListener` vs `BlocBuilder`
- Implement lazy loading for lists
- Cache expensive operations
- Use `Image.memory()` for local images
- Compress images before processing
- Dispose resources properly

### 14. Accessibility

- Minimum touch target: 48x48 dp
- Color contrast ratio: 4.5:1
- Add semantic labels
- Support screen readers
- Test with accessibility tools

### 15. Resources

- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
- [BLoC Library Docs](https://bloclibrary.dev/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Material Design Guidelines](https://material.io/design)

## Questions?

- Open an issue for bugs
- Start a discussion for questions
- Check existing documentation first

---

**Thank you for contributing to SmartScan!** 🎉

Your efforts help make this project better for everyone.
