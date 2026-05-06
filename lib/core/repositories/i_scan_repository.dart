import 'package:smart_scan/shared/models/scan_model.dart';
import 'base_repository.dart';

/// Abstract repository for scan operations
/// Implementations handle persistence of scans to database/cloud
abstract class IScanRepository extends BaseRepository {
  /// Save a new scan with metadata
  Future<String> saveScan({
    required String title,
    required String? imagePath,
    required String? rawText,
    String? summary,
    required String? categoryId,
    String? translatedText,
    String? language,
  });

  /// Get a scan by ID
  Future<ScanModel?> getScanById(String id);

  /// Get all scans
  Future<List<ScanModel>> getAllScans();

  /// Get scans by category
  Future<List<ScanModel>> getScansByCategory(String categoryId);

  /// Update a scan
  Future<bool> updateScan(ScanModel scan);

  /// Delete a scan
  Future<bool> deleteScan(String scanId);

  /// Search scans by text
  Future<List<ScanModel>> searchScans(String query);
}
