import 'package:uuid/uuid.dart';
import 'package:smart_scan/shared/models/scan_model.dart';
import 'package:smart_scan/shared/models/entity_model.dart';
import 'package:smart_scan/shared/models/bounding_box_model.dart';
import 'package:smart_scan/core/services/database_service.dart';
import 'package:smart_scan/core/services/file_storage_service.dart';

class ScanRepository {
  static final ScanRepository _instance = ScanRepository._internal();

  factory ScanRepository() {
    return _instance;
  }

  ScanRepository._internal();

  final DatabaseService _dbService = DatabaseService();
  final FileStorageService _fileService = FileStorageService();

  Future<String> saveScan({
    required String title,
    required String? imagePath,
    required String? rawText,
    String? summary,
    required String? categoryId,
    String? translatedText,
    String? detectedLanguage,
    String? targetLanguage,
    List<EntityModel>? entities,
    List<BoundingBoxModel>? boundingBoxes,
    String? documentType,
    double? documentTypeConfidence,
    String? reminderSuggestion,
    DateTime? suggestedReminderDate,
    int? imageWidth,
    int? imageHeight,
    List<String>? additionalImages,
  }) async {
    try {
      final scanId = const Uuid().v4();
      String? savedImagePath;

      if (imagePath != null && imagePath.isNotEmpty) {
        if (additionalImages != null && additionalImages.isNotEmpty) {
          final savedPaths = await _fileService.saveImagesForScan(
            scanId: scanId,
            sourceImagePaths: additionalImages,
          );
          savedImagePath = savedPaths.first;
          additionalImages = savedPaths;
        } else {
          savedImagePath = await _fileService.saveImageForScan(
            scanId: scanId,
            sourceImagePath: imagePath,
          );
        }
      }

      final scan = ScanModel(
        id: scanId,
        title: title,
        imagePath: savedImagePath,
        rawText: rawText,
        summary: summary,
        translatedText: translatedText,
        detectedLanguage: detectedLanguage,
        targetLanguage: targetLanguage,
        categoryId: categoryId,
        entities: entities,
        boundingBoxes: boundingBoxes,
        documentType: documentType,
        documentTypeConfidence: documentTypeConfidence,
        reminderSuggestion: reminderSuggestion,
        suggestedReminderDate: suggestedReminderDate,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        createdAt: DateTime.now(),
        additionalImages: additionalImages,
      );

      await _dbService.insertScan(scan.toMap(forDatabase: true));

      return scanId;
    } catch (e) {
      rethrow;
    }
  }\r\n\r\n  Future<ScanModel?> getScan(String scanId) async {
    try {
      final scanMap = await _dbService.getScan(scanId);
      if (scanMap == null) return null;

      return ScanModel.fromMap(scanMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ScanModel>> getAllScans({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final scans = await _dbService.getAllScans(
        limit: limit,
        offset: offset,
      );

      return scans.map((map) => ScanModel.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ScanModel>> getScansByCategory(
    String categoryId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final scans = await _dbService.getScansByCategory(
        categoryId,
        limit: limit,
        offset: offset,
      );

      return scans.map((map) => ScanModel.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ScanModel>> searchScans(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final scans = await _dbService.searchScans(
        query,
        limit: limit,
        offset: offset,
      );

      return scans.map((map) => ScanModel.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateScan({
    required String scanId,
    String? title,
    String? rawText,
    String? summary,
    String? translatedText,
    String? categoryId,
    String? targetLanguage,
    List<EntityModel>? entities,
    List<BoundingBoxModel>? boundingBoxes,
    String? documentType,
    double? documentTypeConfidence,
    String? reminderSuggestion,
    DateTime? suggestedReminderDate,
    bool? reminderDismissed,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (rawText != null) updates['raw_text'] = rawText;
      if (summary != null) updates['summary'] = summary;
      if (translatedText != null) updates['translated_text'] = translatedText;
      if (categoryId != null) updates['category_id'] = categoryId;
      if (targetLanguage != null) updates['target_language'] = targetLanguage;
      if (entities != null) {
        updates['entities_json'] = entities.map((e) => e.toMap()).toList();
      }
      if (boundingBoxes != null) {
        updates['bounding_boxes_json'] = boundingBoxes.map((b) => b.toMap()).toList();
      }
      if (documentType != null) updates['document_type'] = documentType;
      if (documentTypeConfidence != null) updates['document_type_confidence'] = documentTypeConfidence;
      if (reminderSuggestion != null) updates['reminder_suggestion'] = reminderSuggestion;
      if (suggestedReminderDate != null) updates['suggested_reminder_date'] = suggestedReminderDate.toIso8601String();
      if (reminderDismissed != null) updates['reminder_dismissed'] = reminderDismissed ? 1 : 0;

      if (updates.isNotEmpty) {
        await _dbService.updateScan(scanId, updates);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> dismissReminder(String scanId) async {
    try {
      await _dbService.updateScan(scanId, {'reminder_dismissed': 1});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteScan(String scanId) async {
    try {
      await _fileService.deleteImageForScan(scanId);

      await _dbService.deleteScan(scanId);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getScanCount() async {
    try {
      return await _dbService.getScanCount();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getStorageUsage() async {
    try {
      final bytes = await _fileService.getTotalScansSize();
      return FileStorageService.formatBytes(bytes);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAllScans() async {
    try {
      await _fileService.clearAllScansStorage();

      final allScans = await getAllScans(limit: 10000);
      for (final scan in allScans) {
        await _dbService.deleteScan(scan.id);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyImageIntegrity(String scanId, String imagePath) async {
    try {
      return await _fileService.verifyImageExists(imagePath);
    } catch (e) {
      return false;
    }
  }

  Future<String?> repairImagePath(String scanId) async {
    try {
      return await _fileService.findImageByScanId(scanId);
    } catch (e) {
      return null;
    }
  }

  // ─── Saved Translations ─────────────────────────────────────────────────
  Future<String> saveTranslation({
    required String sourceLanguage,
    required String targetLanguage,
    required String originalText,
    required String translatedText,
  }) async {
    try {
      final translationId = const Uuid().v4();
      final translation = {
        'id': translationId,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
        'original_text': originalText,
        'translated_text': translatedText,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _dbService.insertSavedTranslation(translation);
      return translationId;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllSavedTranslations({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _dbService.getAllSavedTranslations(
          limit: limit, offset: offset);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSavedTranslation(String translationId) async {
    try {
      await _dbService.deleteSavedTranslation(translationId);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getSavedTranslationCount() async {
    try {
      return await _dbService.getSavedTranslationCount();
    } catch (e) {
      rethrow;
    }
  }
}
