import 'base_repository.dart';

/// Abstract repository for scan history operations
/// Implementations handle retrieval and management of historical scans
abstract class IHistoryRepository extends BaseRepository {
  /// Get all historical scans
  Future<List<Map<String, dynamic>>> getAllHistory();

  /// Get scans created today
  Future<List<Map<String, dynamic>>> getTodayScans();

  /// Get scans from a specific date range
  Future<List<Map<String, dynamic>>> getScansByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get scans by category
  Future<List<Map<String, dynamic>>> getScansByCategory(String categoryId);

  /// Search history by text
  Future<List<Map<String, dynamic>>> searchHistory(String query);

  /// Get scan statistics
  Future<Map<String, dynamic>> getStatistics();

  /// Get action history (scans, translations, exports)
  Future<List<Map<String, dynamic>>> getActionHistory({
    int limit = 100,
  });
}
