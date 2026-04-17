part of 'scan_bloc.dart';

abstract class ScanState {
  const ScanState();
}

/// Initial state - no scan in progress
class ScanInitial extends ScanState {
  const ScanInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanInitial;

  @override
  int get hashCode => 0;
}

/// Ready for scan - camera can be opened
class ScanReady extends ScanState {
  const ScanReady();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanReady;

  @override
  int get hashCode => 1;
}

/// Image has been captured, ready for OCR processing
class ScanImageCaptured extends ScanState {
  final String imagePath;

  const ScanImageCaptured({required this.imagePath});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanImageCaptured &&
          runtimeType == other.runtimeType &&
          imagePath == other.imagePath;

  @override
  int get hashCode => imagePath.hashCode;
}

/// OCR (text extraction) is currently in progress
class ScanOCRInProgress extends ScanState {
  const ScanOCRInProgress();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanOCRInProgress;

  @override
  int get hashCode => 2;
}

/// OCR is completed with extracted text
class ScanOCRCompleted extends ScanState {
  final String extractedText;
  final String imagePath;

  const ScanOCRCompleted({
    required this.extractedText,
    required this.imagePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanOCRCompleted &&
          runtimeType == other.runtimeType &&
          extractedText == other.extractedText &&
          imagePath == other.imagePath;

  @override
  int get hashCode => extractedText.hashCode ^ imagePath.hashCode;
}

/// Translation process is currently in progress
class ScanTranslationInProgress extends ScanState {
  const ScanTranslationInProgress();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanTranslationInProgress;

  @override
  int get hashCode => 3;
}

/// Translation is completed
class ScanTranslationCompleted extends ScanState {
  final String translatedText;
  final String originalText;
  final String targetLanguage;
  final String imagePath;

  const ScanTranslationCompleted({
    required this.translatedText,
    required this.originalText,
    required this.targetLanguage,
    required this.imagePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanTranslationCompleted &&
          runtimeType == other.runtimeType &&
          translatedText == other.translatedText &&
          originalText == other.originalText &&
          targetLanguage == other.targetLanguage &&
          imagePath == other.imagePath;

  @override
  int get hashCode =>
      translatedText.hashCode ^
      originalText.hashCode ^
      targetLanguage.hashCode ^
      imagePath.hashCode;
}

/// Scan is being saved to database and storage
class ScanSavingInProgress extends ScanState {
  const ScanSavingInProgress();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanSavingInProgress;

  @override
  int get hashCode => 4;
}

/// Scan has been successfully saved
class ScanSaveCompleted extends ScanState {
  const ScanSaveCompleted();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanSaveCompleted;

  @override
  int get hashCode => 5;
}

/// Scan operation was cancelled
class ScanCancelled extends ScanState {
  const ScanCancelled();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanCancelled;

  @override
  int get hashCode => 6;
}

/// An error occurred during the scan process
class ScanError extends ScanState {
  final String message;

  const ScanError({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
