part of 'scan_bloc.dart';

abstract class ScanState {
  const ScanState();
}

class ScanInitial extends ScanState {
  const ScanInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanInitial;

  @override
  int get hashCode => 0;
}

class ScanReady extends ScanState {
  const ScanReady();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanReady;

  @override
  int get hashCode => 1;
}

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

class ScanOCRInProgress extends ScanState {
  const ScanOCRInProgress();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanOCRInProgress;

  @override
  int get hashCode => 2;
}

class ScanOCRCompleted extends ScanState {
  final String extractedText;
  final String imagePath;
  final List<BoundingBoxModel>? boundingBoxes;
  final List<EntityModel>? entities;
  final String? detectedLanguage;
  final String? documentType;
  final double? documentTypeConfidence;
  final Map<String, double>? smartCropRegion;
  final int? imageWidth;
  final int? imageHeight;

  const ScanOCRCompleted({
    required this.extractedText,
    required this.imagePath,
    this.boundingBoxes,
    this.entities,
    this.detectedLanguage,
    this.documentType,
    this.documentTypeConfidence,
    this.smartCropRegion,
    this.imageWidth,
    this.imageHeight,
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

class ScanTranslationInProgress extends ScanState {
  const ScanTranslationInProgress();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanTranslationInProgress;

  @override
  int get hashCode => 3;
}

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

class ScanSavingInProgress extends ScanState {
  const ScanSavingInProgress();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanSavingInProgress;

  @override
  int get hashCode => 4;
}

class ScanSaveCompleted extends ScanState {
  final String scanId;
  final ReminderSuggestion? reminderSuggestion;

  const ScanSaveCompleted({
    required this.scanId,
    this.reminderSuggestion,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanSaveCompleted;

  @override
  int get hashCode => 5;
}

class ScanSmartCropApplied extends ScanState {
  final Map<String, double> cropRegion;
  final String imagePath;

  const ScanSmartCropApplied({
    required this.cropRegion,
    required this.imagePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanSmartCropApplied &&
          runtimeType == other.runtimeType &&
          cropRegion == other.cropRegion;

  @override
  int get hashCode => cropRegion.hashCode;
}

class ScanReminderDismissed extends ScanState {
  final String scanId;

  const ScanReminderDismissed({required this.scanId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanReminderDismissed;

  @override
  int get hashCode => 7;
}

class ScanCancelled extends ScanState {
  const ScanCancelled();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanCancelled;

  @override
  int get hashCode => 6;
}

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
