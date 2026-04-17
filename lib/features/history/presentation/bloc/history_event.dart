part of 'history_bloc.dart';

abstract class HistoryEvent {
  const HistoryEvent();
}

/// Loads initial list of scans from repository
class LoadScansEvent extends HistoryEvent {
  final int limit;

  const LoadScansEvent({this.limit = 100});
}

/// Deletes a specific scan by ID
class DeleteScanEvent extends HistoryEvent {
  final String scanId;

  const DeleteScanEvent({required this.scanId});
}

/// Refreshes the scan list from repository
class RefreshScansEvent extends HistoryEvent {
  final int limit;

  const RefreshScansEvent({this.limit = 100});
}

/// Searches scans by text query
class SearchScansEvent extends HistoryEvent {
  final String query;
  final int limit;

  const SearchScansEvent({
    required this.query,
    this.limit = 50,
  });
}

/// Filters scans by category ID
class FilterScansByCategoryEvent extends HistoryEvent {
  final String categoryId;
  final int limit;

  const FilterScansByCategoryEvent({
    required this.categoryId,
    this.limit = 100,
  });
}
