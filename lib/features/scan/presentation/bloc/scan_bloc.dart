import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';

part 'scan_event.dart';
part 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final ScanRepository scanRepository;

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
    } catch (e) {
      emit(ScanError(message: 'Erreur lors du démarrage de l\'OCR: $e'));
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

      await scanRepository.saveScan(
        title: event.title,
        imagePath: event.imagePath,
        rawText: event.rawText,
        targetLanguage: event.targetLanguage,
        categoryId: event.categoryId,
      );

      emit(const ScanSaveCompleted());
    } catch (e) {
      emit(ScanError(message: 'Erreur lors de la sauvegarde: $e'));
    }
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
