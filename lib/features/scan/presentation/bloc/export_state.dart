part of 'export_bloc.dart';

abstract class ExportState extends Equatable {
  const ExportState();

  @override
  List<Object?> get props => [];
}

class ExportInitial extends ExportState {
  const ExportInitial();
}

class ExportInProgress extends ExportState {
  final String exportType; // 'pdf', 'txt', 'word'

  const ExportInProgress({required this.exportType});

  @override
  List<Object?> get props => [exportType];
}

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

class ExportedFilesLoading extends ExportState {
  const ExportedFilesLoading();
}

class ExportedFilesLoaded extends ExportState {
  final List<String> filePaths;

  const ExportedFilesLoaded({required this.filePaths});

  @override
  List<Object?> get props => [filePaths];
}

class ExportedFilesEmpty extends ExportState {
  const ExportedFilesEmpty();
}

class ExportedFileDeleted extends ExportState {
  final String message;

  const ExportedFileDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

class ExportError extends ExportState {
  final String message;

  const ExportError({required this.message});

  @override
  List<Object?> get props => [message];
}
