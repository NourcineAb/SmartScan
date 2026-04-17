part of 'scans_bloc.dart';

abstract class ScansEvent {
  const ScansEvent();
}

/// Loads initial list of scans from repository
class LoadScansEvent extends ScansEvent {
  final int limit;

  const LoadScansEvent({this.limit = 100});
}

/// Deletes a specific scan by ID
class DeleteScanEvent extends ScansEvent {
  final String scanId;

  const DeleteScanEvent({required this.scanId});
}

/// Refreshes the scan list from repository
class RefreshScansEvent extends ScansEvent {
  final int limit;

  const RefreshScansEvent({this.limit = 100});
}

/// Searches scans by text query
class SearchScansEvent extends ScansEvent {
  final String query;
  final int limit;

  const SearchScansEvent({
    required this.query,
    this.limit = 50,
  });
}

/// Filters scans by category ID
class FilterScansByCategoryEvent extends ScansEvent {
  final String categoryId;
  final int limit;

  const FilterScansByCategoryEvent({
    required this.categoryId,
    this.limit = 100,
  });
}
