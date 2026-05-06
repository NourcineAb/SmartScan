import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/core/services/export_service.dart';
import 'package:smart_scan/shared/models/scan_model.dart';

part 'export_event.dart';
part 'export_state.dart';

class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final ExportService exportService = ExportService();

  ExportBloc() : super(const ExportInitial()) {
    on<ExportToPDFEvent>(_onExportToPDF);
    on<ExportToTXTEvent>(_onExportToTXT);
    on<ExportToWordEvent>(_onExportToWord);
    on<LoadExportedFilesEvent>(_onLoadExportedFiles);
    on<DeleteExportedFileEvent>(_onDeleteExportedFile);
    on<ClearExportMessageEvent>(_onClearExportMessage);
    on<ShareExportedFileEvent>(_onShareExportedFile);
  }

  Future<void> _onExportToPDF(
    ExportToPDFEvent event,
    Emitter<ExportState> emit,
  ) async {
    try {
      emit(const ExportInProgress(exportType: 'pdf'));
      final filePath = await exportService.exportToPDF(event.scan);
      emit(ExportCompleted(
        filePath: filePath,
        exportType: 'pdf',
        message: 'PDF exported successfully: ${event.scan.title}.pdf',
      ));
    } catch (e) {
      emit(ExportError(message: 'Error exporting to PDF: $e'));
    }
  }

  Future<void> _onExportToTXT(
    ExportToTXTEvent event,
    Emitter<ExportState> emit,
  ) async {
    try {
      emit(const ExportInProgress(exportType: 'txt'));
      final filePath = await exportService.exportToTXT(event.scan);
      emit(ExportCompleted(
        filePath: filePath,
        exportType: 'txt',
        message: 'Text file exported successfully: ${event.scan.title}.txt',
      ));
    } catch (e) {
      emit(ExportError(message: 'Error exporting to TXT: $e'));
    }
  }

  Future<void> _onExportToWord(
    ExportToWordEvent event,
    Emitter<ExportState> emit,
  ) async {
    try {
      emit(const ExportInProgress(exportType: 'word'));
      final filePath = await exportService.exportToWord(event.scan);
      emit(ExportCompleted(
        filePath: filePath,
        exportType: 'word',
        message:
            'Word document exported successfully: ${event.scan.title}.docx',
      ));
    } catch (e) {
      emit(ExportError(message: 'Error exporting to Word: $e'));
    }
  }

  Future<void> _onLoadExportedFiles(
    LoadExportedFilesEvent event,
    Emitter<ExportState> emit,
  ) async {
    try {
      emit(const ExportedFilesLoading());
      final files = await exportService.getExportedFiles();
      if (files.isEmpty) {
        emit(const ExportedFilesEmpty());
      } else {
        final filePaths = files.map((f) => f.path).toList();
        emit(ExportedFilesLoaded(filePaths: filePaths));
      }
    } catch (e) {
      emit(ExportError(message: 'Error loading exported files: $e'));
    }
  }

  Future<void> _onDeleteExportedFile(
    DeleteExportedFileEvent event,
    Emitter<ExportState> emit,
  ) async {
    try {
      await exportService.deleteExportedFile(event.filePath);
      emit(ExportedFileDeleted(
        message: 'File deleted successfully: ${event.filePath}',
      ));
      // Reload the files list
      add(const LoadExportedFilesEvent());
    } catch (e) {
      emit(ExportError(message: 'Error deleting file: $e'));
    }
  }

  Future<void> _onClearExportMessage(
    ClearExportMessageEvent event,
    Emitter<ExportState> emit,
  ) async {
    emit(const ExportInitial());
  }

  Future<void> _onShareExportedFile(
    ShareExportedFileEvent event,
    Emitter<ExportState> emit,
  ) async {
    try {
      await exportService.shareFile(event.filePath, subject: event.subject);
    } catch (e) {
      emit(ExportError(message: 'Error sharing file: $e'));
    }
  }
}
