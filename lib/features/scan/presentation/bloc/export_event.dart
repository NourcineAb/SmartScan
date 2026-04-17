part of 'export_bloc.dart';

abstract class ExportEvent extends Equatable {
  const ExportEvent();

  @override
  List<Object?> get props => [];
}

/// Event to export scan to PDF
class ExportToPDFEvent extends ExportEvent {
  final ScanModel scan;

  const ExportToPDFEvent({required this.scan});

  @override
  List<Object?> get props => [scan];
}

/// Event to export scan to TXT
class ExportToTXTEvent extends ExportEvent {
  final ScanModel scan;

  const ExportToTXTEvent({required this.scan});

  @override
  List<Object?> get props => [scan];
}

/// Event to export scan to Word
class ExportToWordEvent extends ExportEvent {
  final ScanModel scan;

  const ExportToWordEvent({required this.scan});

  @override
  List<Object?> get props => [scan];
}

/// Event to load exported files
class LoadExportedFilesEvent extends ExportEvent {
  const LoadExportedFilesEvent();
}

/// Event to delete an exported file
class DeleteExportedFileEvent extends ExportEvent {
  final String filePath;

  const DeleteExportedFileEvent({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

/// Event to clear export message
class ClearExportMessageEvent extends ExportEvent {
  const ClearExportMessageEvent();
}

/// Event to share an exported file
class ShareExportedFileEvent extends ExportEvent {
  final String filePath;
  final String subject;

  const ShareExportedFileEvent({
    required this.filePath,
    required this.subject,
  });

  @override
  List<Object?> get props => [filePath, subject];
}
