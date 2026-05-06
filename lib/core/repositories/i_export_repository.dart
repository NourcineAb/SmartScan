import 'base_repository.dart';

/// Abstract repository for export operations
/// Implementations handle PDF generation, sharing, and export formats
abstract class IExportRepository extends BaseRepository {
  /// Export scan to PDF
  Future<String> exportToPdf({
    required String scanId,
    required String fileName,
  });

  /// Export multiple scans to PDF
  Future<String> exportMultipleToPdf({
    required List<String> scanIds,
    required String fileName,
  });

  /// Share scan as PDF
  Future<bool> shareScanPdf({
    required String scanId,
    required String fileName,
  });

  /// Export as text file
  Future<String> exportAsText({
    required String scanId,
    required String fileName,
  });

  /// Get export history
  Future<List<Map<String, dynamic>>> getExportHistory();
}
