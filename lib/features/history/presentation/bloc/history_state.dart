part of 'history_bloc.dart';

abstract class HistoryState {
  const HistoryState();
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HistoryInitial;

  @override
  int get hashCode => 0;
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HistoryLoading;

  @override
  int get hashCode => 1;
}

/// Scans loaded successfully, with a map of categoryId → categoryName
class HistoryLoaded extends HistoryState {
  final List<ScanModel> scans;

  /// Map from categoryId → category name (for display)
  final Map<String, String> categoryNames;

  /// Map from categoryId → category color (int) (for display)
  final Map<String, int> categoryColors;

  const HistoryLoaded({
    required this.scans,
    this.categoryNames = const {},
    this.categoryColors = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryLoaded &&
          runtimeType == other.runtimeType &&
          scans == other.scans;

  @override
  int get hashCode => scans.hashCode;
}

class HistoryEmpty extends HistoryState {
  const HistoryEmpty();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HistoryEmpty;

  @override
  int get hashCode => 2;
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
