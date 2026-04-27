import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service responsible for managing scan image file storage
/// Stores images in app documents directory under scans/{scanId}/
class FileStorageService {
  static final FileStorageService _instance = FileStorageService._internal();

  factory FileStorageService() {
    return _instance;
  }

  FileStorageService._internal();

  static const String _scansDirectory = 'scans';

  /// Get the scans directory path
  Future<Directory> _getScansDir() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory(path.join(appDocDir.path, _scansDirectory));

    // Create directory if it doesn't exist
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    return scansDir;
  }

  /// Get the scan-specific directory
  Future<Directory> _getScanDir(String scanId) async {
    final scansDir = await _getScansDir();
    final scanDir = Directory(path.join(scansDir.path, scanId));

    // Create directory if it doesn't exist
    if (!await scanDir.exists()) {
      await scanDir.create(recursive: true);
    }

    return scanDir;
  }

  /// Save an image file for a scan by copying it from source to app directory
  /// Returns the new image path in app documents
  Future<String> saveImageForScan({
    required String scanId,
    required String sourceImagePath,
    int index = 0,
  }) async {
    try {
      final sourceFile = File(sourceImagePath);

      // Verify source file exists
      if (!await sourceFile.exists()) {
        throw FileSystemException(
            'Source image does not exist', sourceImagePath);
      }

      // Get destination directory
      final scanDir = await _getScanDir(scanId);

      // Get file extension
      final extension = path.extension(sourceImagePath);
      // Use index to avoid overwriting in multi-page scans
      final filename = 'page_$index$extension';
      final destPath = path.join(scanDir.path, filename);

      // Copy file to destination
      final destFile = await sourceFile.copy(destPath);

      return destFile.path;
    } catch (e) {
      throw FileSystemException('Failed to save image for scan', e.toString());
    }
  }

  /// Save multiple images for a scan
  Future<List<String>> saveImagesForScan({
    required String scanId,
    required List<String> sourceImagePaths,
  }) async {
    final List<String> savedPaths = [];
    for (int i = 0; i < sourceImagePaths.length; i++) {
      final savedPath = await saveImageForScan(
        scanId: scanId,
        sourceImagePath: sourceImagePaths[i],
        index: i,
      );
      savedPaths.add(savedPath);
    }
    return savedPaths;
  }

  /// Get the image path for a scan (if it exists)
  Future<String?> getImagePathForScan(String scanId) async {
    try {
      final scanDir = await _getScanDir(scanId);

      // Look for image files (.jpg, .jpeg, .png)
      final files = scanDir.listSync();
      for (final file in files) {
        if (file is File) {
          final ext = path.extension(file.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png'].contains(ext)) {
            return file.path;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get total size of scan directory in bytes
  Future<int> getScanDirectorySize(String scanId) async {
    try {
      final scanDir = await _getScanDir(scanId);
      int totalSize = 0;

      final files = scanDir.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Delete all files for a scan
  Future<void> deleteImageForScan(String scanId) async {
    try {
      final scanDir = await _getScanDir(scanId);

      if (await scanDir.exists()) {
        await scanDir.delete(recursive: true);
      }
    } catch (e) {
      throw FileSystemException(
          'Failed to delete image for scan', e.toString());
    }
  }

  /// Get total size of all scans storage in bytes
  Future<int> getTotalScansSize() async {
    try {
      final scansDir = await _getScansDir();
      int totalSize = 0;

      final dirs = scansDir.listSync(recursive: true);
      for (final file in dirs) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all scans storage (caution: deletes all images)
  Future<void> clearAllScansStorage() async {
    try {
      final scansDir = await _getScansDir();

      if (await scansDir.exists()) {
        await scansDir.delete(recursive: true);
        // Recreate empty directory
        await scansDir.create(recursive: true);
      }
    } catch (e) {
      throw FileSystemException('Failed to clear scans storage', e.toString());
    }
  }

  /// Get human-readable size string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Verify file integrity: check if image path exists and is readable
  Future<bool> verifyImageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get absolute path in case image was renamed or moved
  /// Searches scan directory for any image file
  Future<String?> findImageByScanId(String scanId) async {
    try {
      final scanDir = await _getScanDir(scanId);
      final files = scanDir.listSync();

      for (final file in files) {
        if (file is File) {
          final ext = path.extension(file.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.webp', '.gif'].contains(ext)) {
            return file.path;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
