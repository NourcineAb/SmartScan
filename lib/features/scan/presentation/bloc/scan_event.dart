part of 'scan_bloc.dart';

abstract class ScanEvent {
  const ScanEvent();
}

class InitiateScanEvent extends ScanEvent {
  const InitiateScanEvent();
}

class ImageCapturedEvent extends ScanEvent {
  final String imagePath;

  const ImageCapturedEvent({required this.imagePath});
}

class OCRStartedEvent extends ScanEvent {
  final String imagePath;
  const OCRStartedEvent({required this.imagePath});
}

class OCRCompletedEvent extends ScanEvent {
  final String extractedText;
  final String imagePath;

  const OCRCompletedEvent({
    required this.extractedText,
    required this.imagePath,
  });
}

class TranslateTextEvent extends ScanEvent {
  final String text;
  final String targetLanguage;

  const TranslateTextEvent({
    required this.text,
    required this.targetLanguage,
  });
}

class TranslationCompletedEvent extends ScanEvent {
  final String translatedText;
  final String originalText;
  final String targetLanguage;
  final String imagePath;

  const TranslationCompletedEvent({
    required this.translatedText,
    required this.originalText,
    required this.targetLanguage,
    required this.imagePath,
  });
}

class SaveScanEvent extends ScanEvent {
  final String title;
  final String imagePath;
  final String rawText;
  final String targetLanguage;
  final String? categoryId;
  final String? detectedLanguage;
  final List<BoundingBoxModel>? boundingBoxes;
  final List<EntityModel>? entities;
  final String? documentType;
  final double? documentTypeConfidence;
  final String? reminderSuggestion;
  final DateTime? suggestedReminderDate;
  final int? imageWidth;
  final int? imageHeight;

  const SaveScanEvent({
    required this.title,
    required this.imagePath,
    required this.rawText,
    required this.targetLanguage,
    this.categoryId,
    this.detectedLanguage,
    this.boundingBoxes,
    this.entities,
    this.documentType,
    this.documentTypeConfidence,
    this.reminderSuggestion,
    this.suggestedReminderDate,
    this.imageWidth,
    this.imageHeight,
  });
}

class ApplySmartCropEvent extends ScanEvent {
  final Map<String, double> cropRegion;
  final String imagePath;

  const ApplySmartCropEvent({
    required this.cropRegion,
    required this.imagePath,
  });
}

class DismissReminderEvent extends ScanEvent {
  final String scanId;

  const DismissReminderEvent({required this.scanId});
}

class ReprocessOCREvent extends ScanEvent {
  final String imagePath;
  final Map<String, dynamic>? cropZone;

  const ReprocessOCREvent({
    required this.imagePath,
    this.cropZone,
  });
}

class CancelScanEvent extends ScanEvent {
  const CancelScanEvent();
}

class ClearStateEvent extends ScanEvent {
  const ClearStateEvent();
}
