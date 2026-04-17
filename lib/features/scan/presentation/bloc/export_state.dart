part of 'export_bloc.dart';

abstract class ExportState extends Equatable {
  const ExportState();

  @override
  List<Object?> get props => [];
}

/// Initial export state
class ExportInitial extends ExportState {
  const ExportInitial();
}

/// Export in progress
class ExportInProgress extends ExportState {
  final String exportType; // 'pdf', 'txt', 'word'

  const ExportInProgress({required this.exportType});

  @override
  List<Object?> get props => [exportType];
}

/// Export completed successfully
class ExportCompleted extends ExportState {
  final String filePath;
  final String exportType;
  final String message;

  const ExportCompleted({
    required this.filePath,
    required this.exportType,
    required this.message,
  });

  @override
  List<Object?> get props => [filePath, exportType, message];
}

/// Loading exported files
class ExportedFilesLoading extends ExportState {
  const ExportedFilesLoading();
}

/// Exported files loaded
class ExportedFilesLoaded extends ExportState {
  final List<String> filePaths;

  const ExportedFilesLoaded({required this.filePaths});

  @override
  List<Object?> get props => [filePaths];
}

/// Exported files list is empty
class ExportedFilesEmpty extends ExportState {
  const ExportedFilesEmpty();
}

/// File deleted successfully
class ExportedFileDeleted extends ExportState {
  final String message;

  const ExportedFileDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Export error
class ExportError extends ExportState {
  final String message;

  const ExportError({required this.message});

  @override
  List<Object?> get props => [message];
}
