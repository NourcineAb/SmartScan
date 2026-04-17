part of 'scan_bloc.dart';

abstract class ScanEvent {
  const ScanEvent();
}

/// Initiates the scan process, preparing the camera
class InitiateScanEvent extends ScanEvent {
  const InitiateScanEvent();
}

/// Triggered when an image is captured from the camera
class ImageCapturedEvent extends ScanEvent {
  final String imagePath;

  const ImageCapturedEvent({required this.imagePath});
}

/// Starts the OCR (Optical Character Recognition) process
class OCRStartedEvent extends ScanEvent {
  const OCRStartedEvent();
}

/// Emitted when OCR is completed with extracted text
class OCRCompletedEvent extends ScanEvent {
  final String extractedText;
  final String imagePath;

  const OCRCompletedEvent({
    required this.extractedText,
    required this.imagePath,
  });
}

/// Starts the text translation process
class TranslateTextEvent extends ScanEvent {
  final String text;
  final String targetLanguage;

  const TranslateTextEvent({
    required this.text,
    required this.targetLanguage,
  });
}

/// Emitted when translation is completed
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

/// Triggers saving the scan with image and metadata
class SaveScanEvent extends ScanEvent {
  final String title;
  final String imagePath;
  final String rawText;
  final String targetLanguage;
  final String? categoryId;

  const SaveScanEvent({
    required this.title,
    required this.imagePath,
    required this.rawText,
    required this.targetLanguage,
    this.categoryId,
  });
}

/// Cancels the current scan operation
class CancelScanEvent extends ScanEvent {
  const CancelScanEvent();
}

/// Clears the BLoC state back to initial
class ClearStateEvent extends ScanEvent {
  const ClearStateEvent();
}
