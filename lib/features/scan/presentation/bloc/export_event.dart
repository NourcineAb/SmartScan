part of 'export_bloc.dart';

abstract class ExportEvent extends Equatable {
  const ExportEvent();

  @override
  List<Object?> get props => [];
}

class ExportToPDFEvent extends ExportEvent {
  final ScanModel scan;

  const ExportToPDFEvent({required this.scan});

  @override
  List<Object?> get props => [scan];
}

class ExportToTXTEvent extends ExportEvent {
  final ScanModel scan;

  const ExportToTXTEvent({required this.scan});

  @override
  List<Object?> get props => [scan];
}

class ExportToWordEvent extends ExportEvent {
  final ScanModel scan;

  const ExportToWordEvent({required this.scan});

  @override
  List<Object?> get props => [scan];
}

class LoadExportedFilesEvent extends ExportEvent {
  const LoadExportedFilesEvent();
}

class DeleteExportedFileEvent extends ExportEvent {
  final String filePath;

  const DeleteExportedFileEvent({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

class ClearExportMessageEvent extends ExportEvent {
  const ClearExportMessageEvent();
}

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
