part of 'scans_bloc.dart';

abstract class ScansState {
  const ScansState();
}

class ScansInitial extends ScansState {
  const ScansInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScansInitial;

  @override
  int get hashCode => 0;
}

class ScansLoading extends ScansState {
  const ScansLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScansLoading;

  @override
  int get hashCode => 1;
}

/// Scans loaded successfully, with a map of categoryId → categoryName
class ScansLoaded extends ScansState {
  final List<ScanModel> scans;

  /// Map from categoryId → category name (for display)
  final Map<String, String> categoryNames;

  /// Map from categoryId → category color (int) (for display)
  final Map<String, int> categoryColors;

  const ScansLoaded({
    required this.scans,
    this.categoryNames = const {},
    this.categoryColors = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScansLoaded &&
          runtimeType == other.runtimeType &&
          scans == other.scans;

  @override
  int get hashCode => scans.hashCode;
}

class ScansEmpty extends ScansState {
  const ScansEmpty();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScansEmpty;

  @override
  int get hashCode => 2;
}

class ScansError extends ScansState {
  final String message;

  const ScansError({required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScansError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
