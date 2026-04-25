import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';
import 'package:smart_scan/features/scan/data/services/ocr_service.dart';
import 'package:smart_scan/core/services/entity_extraction_service.dart';
import 'package:smart_scan/core/services/document_type_service.dart';
import 'package:smart_scan/core/services/language_service.dart';
import 'package:smart_scan/core/services/reminder_suggestion_service.dart';
import 'package:smart_scan/core/services/analytics_service.dart';
import 'package:smart_scan/shared/models/bounding_box_model.dart';
import 'package:smart_scan/shared/models/entity_model.dart';

part 'scan_event.dart';
part 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final ScanRepository scanRepository;
  final OCRService _ocrService = OCRService();
  final EntityExtractionService _entityService = EntityExtractionService();
  final DocumentTypeService _documentTypeService = DocumentTypeService();
  final LanguageService _languageService = LanguageService();
  final ReminderSuggestionService _reminderService = ReminderSuggestionService();
  final AnalyticsService _analytics = AnalyticsService();

  // Store last OCR result for reprocessing
  StructuredOCRResult? _lastOcrResult;
  String? _lastImagePath;

  ScanBloc({required this.scanRepository}) : super(const ScanInitial()) {
    on<InitiateScanEvent>(_onInitiateScan);
    on<ImageCapturedEvent>(_onImageCaptured);
    on<OCRStartedEvent>(_onOCRStarted);
    on<OCRCompletedEvent>(_onOCRCompleted);
    on<TranslateTextEvent>(_onTranslateText);
    on<TranslationCompletedEvent>(_onTranslationCompleted);
    on<SaveScanEvent>(_onSaveScan);
    on<CancelScanEvent>(_onCancelScan);
    on<ClearStateEvent>(_onClearState);
    on<ApplySmartCropEvent>(_onApplySmartCrop);
    on<DismissReminderEvent>(_onDismissReminder);
    on<ReprocessOCREvent>(_onReprocessOCR);
  }

  Future<void> _onInitiateScan(
    InitiateScanEvent event,
    Emitter<ScanState> emit,
  ) async {
    emit(const ScanReady());
  }

  Future<void> _onImageCaptured(
    ImageCapturedEvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
      emit(ScanImageCaptured(imagePath: event.imagePath));
    } catch (e) {
      emit(ScanError(message: 'Erreur lors de la capture: $e'));
    }
  }

  Future<void> _onOCRStarted(
    OCRStartedEvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
      emit(const ScanOCRInProgress());

      // Process OCR with structured result
      final ocrResult = await _ocrService.extractStructuredText(event.imagePath);
      _lastOcrResult = ocrResult;
      _lastImagePath = event.imagePath;

      // Detect language
      final detectedLanguage = await _languageService.detectLanguage(ocrResult.fullText);

      // Extract entities
      final entities = await _entityService.extractEntities(ocrResult.fullText);

      // Detect document type
      final docTypeResult = _documentTypeService.detectDocumentType(
        ocrResult.fullText,
        entities,
      );

      // Get smart crop region
      final smartCropRegion = ocrResult.getMainTextRegion();

      // Track analytics
      await _analytics.logScanCompleted(
        scanId: DateTime.now().millisecondsSinceEpoch.toString(),
        detectedLanguage: detectedLanguage,
        textLength: ocrResult.fullText.length,
        isMock: ocrResult.isMock,
      );

      // Track entities
      if (entities.isNotEmpty) {
        final grouped = _entityService.groupEntitiesByType(entities);
        for (final entry in grouped.entries) {
          await _analytics.logEntityDetected(
            scanId: DateTime.now().millisecondsSinceEpoch.toString(),
            entityType: entry.key,
            entityCount: entry.value.length,
          );
        }
      }

      // Track document type
      await _analytics.logDocumentTypeDetected(
        scanId: DateTime.now().millisecondsSinceEpoch.toString(),
        documentType: docTypeResult.type,
        confidence: docTypeResult.confidence,
      );

      // Emit completed state with all data
      emit(ScanOCRCompleted(
        extractedText: ocrResult.fullText,
        imagePath: event.imagePath,
        boundingBoxes: ocrResult.elements,
        entities: entities,
        detectedLanguage: detectedLanguage,
        documentType: docTypeResult.type,
        documentTypeConfidence: docTypeResult.confidence,
        smartCropRegion: smartCropRegion,
        imageWidth: ocrResult.imageWidth,
        imageHeight: ocrResult.imageHeight,
      ));
    } catch (e) {
      debugPrint('OCR error: $e');
      await _analytics.logError(
        errorType: 'ocr_failed',
        errorMessage: e.toString(),
      );
      emit(ScanError(message: 'Erreur lors de l\'extraction de texte: $e'));
    }
  }

  Future<void> _onOCRCompleted(
    OCRCompletedEvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
      emit(ScanOCRCompleted(
        extractedText: event.extractedText,
        imagePath: event.imagePath,
      ));
    } catch (e) {
      emit(ScanError(message: 'Erreur lors de l\'extraction de texte: $e'));
    }
  }

  Future<void> _onTranslateText(
    TranslateTextEvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
      emit(const ScanTranslationInProgress());
    } catch (e) {
      emit(ScanError(message: 'Erreur lors de la traduction: $e'));
    }
  }

  Future<void> _onTranslationCompleted(
    TranslationCompletedEvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
      emit(ScanTranslationCompleted(
        translatedText: event.translatedText,
        targetLanguage: event.targetLanguage,
        originalText: event.originalText,
        imagePath: event.imagePath,
      ));
    } catch (e) {
      emit(ScanError(message: 'Erreur lors de la traduction: $e'));
    }
  }

  Future<void> _onSaveScan(
    SaveScanEvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
      emit(const ScanSavingInProgress());

      // Generate reminder suggestions
      ReminderSuggestion? reminderSuggestion;
      if (event.entities != null && event.documentType != null) {
        final suggestions = _reminderService.generateSuggestions(
          text: event.rawText,
          documentType: event.documentType!,
          entities: event.entities!,
          scanDate: DateTime.now(),
        );
        reminderSuggestion = _reminderService.getBestSuggestion(suggestions);

        // Track reminder suggestion
        if (reminderSuggestion != null) {
          await _analytics.logReminderSuggested(
            scanId: DateTime.now().millisecondsSinceEpoch.toString(),
            suggestionId: reminderSuggestion.id,
            sourceType: reminderSuggestion.sourceType,
            confidence: reminderSuggestion.confidence,
          );
        }
      }

      // Save scan with all metadata
      final scanId = await scanRepository.saveScan(
        title: event.title,
        imagePath: event.imagePath,
        rawText: event.rawText,
        targetLanguage: event.targetLanguage,
        categoryId: event.categoryId,
        detectedLanguage: event.detectedLanguage,
        entities: event.entities,
        boundingBoxes: event.boundingBoxes,
        documentType: event.documentType,
        documentTypeConfidence: event.documentTypeConfidence,
        reminderSuggestion: reminderSuggestion?.title,
        suggestedReminderDate: reminderSuggestion?.suggestedDate,
        imageWidth: event.imageWidth,
        imageHeight: event.imageHeight,
      );

      emit(ScanSaveCompleted(
        scanId: scanId,
        reminderSuggestion: reminderSuggestion,
      ));
    } catch (e) {
      debugPrint('Save scan error: $e');
      await _analytics.logError(
        errorType: 'save_failed',
        errorMessage: e.toString(),
      );
      emit(ScanError(message: 'Erreur lors de la sauvegarde: $e'));
    }
  }

  Future<void> _onApplySmartCrop(
    ApplySmartCropEvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
      emit(const ScanOCRInProgress());

      // Reprocess OCR with crop region
      final cropZone = {
        'topLeft': Offset(event.cropRegion['left']!, event.cropRegion['top']!),
        'bottomRight': Offset(event.cropRegion['right']!, event.cropRegion['bottom']!),
      };

      final ocrResult = await _ocrService.extractStructuredText(
        event.imagePath,
        cropZone: cropZone,
      );

      _lastOcrResult = ocrResult;

      // Track smart crop usage
      await _analytics.logSmartCropUsed(
        scanId: DateTime.now().millisecondsSinceEpoch.toString(),
        accepted: true,
      );

      emit(ScanSmartCropApplied(
        cropRegion: event.cropRegion,
        imagePath: event.imagePath,
      ));

      // Emit OCR completed with new results
      emit(ScanOCRCompleted(
        extractedText: ocrResult.fullText,
        imagePath: event.imagePath,
        boundingBoxes: ocrResult.elements,
      ));
    } catch (e) {
      emit(ScanError(message: 'Erreur lors du recadrage: $e'));
    }
  }

  Future<void> _onDismissReminder(
    DismissReminderEvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
      await scanRepository.dismissReminder(event.scanId);
      
      await _analytics.logReminderDismissed(
        scanId: event.scanId,
        suggestionId: event.scanId,
      );

      emit(ScanReminderDismissed(scanId: event.scanId));
    } catch (e) {
      debugPrint('Dismiss reminder error: $e');
    }
  }

  Future<void> _onReprocessOCR(
    ReprocessOCREvent event,
    Emitter<ScanState> emit,
  ) async {
    try {
      emit(const ScanOCRInProgress());

      final ocrResult = await _ocrService.extractStructuredText(
        event.imagePath,
        cropZone: event.cropZone,
      );

      _lastOcrResult = ocrResult;
      _lastImagePath = event.imagePath;

      emit(ScanOCRCompleted(
        extractedText: ocrResult.fullText,
        imagePath: event.imagePath,
        boundingBoxes: ocrResult.elements,
      ));
    } catch (e) {
      emit(ScanError(message: 'Erreur lors du retraitement OCR: $e'));
    }
  }

  @override
  Future<void> close() {
    _ocrService.dispose();
    _entityService.dispose();
    _languageService.dispose();
    return super.close();
  }

  Future<void> _onCancelScan(
    CancelScanEvent event,
    Emitter<ScanState> emit,
  ) async {
    emit(const ScanCancelled());
  }

  Future<void> _onClearState(
    ClearStateEvent event,
    Emitter<ScanState> emit,
  ) async {
    emit(const ScanInitial());
  }
}
