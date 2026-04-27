import 'dart:convert';
import 'entity_model.dart';
import 'bounding_box_model.dart';

class ScanModel {
  final String id;
  final String title;
  final String? imagePath;
  final String? rawText;
  final String? translatedText;
  final String? detectedLanguage;
  final String? targetLanguage;
  final String? categoryId;
  final List<EntityModel>? entities;
  final List<BoundingBoxModel>? boundingBoxes;
  final String? documentType;
  final double? documentTypeConfidence;
  final String? reminderSuggestion;
  final DateTime? suggestedReminderDate;
  final bool reminderDismissed;
  final int? imageWidth;
  final int? imageHeight;
  final String? summary;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final List<String>? additionalImages;

  ScanModel({
    required this.id,
    required this.title,
    this.imagePath,
    this.rawText,
    this.summary,
    this.translatedText,
    this.detectedLanguage,
    this.targetLanguage,
    this.categoryId,
    this.entities,
    this.boundingBoxes,
    this.documentType,
    this.documentTypeConfidence,
    this.reminderSuggestion,
    this.suggestedReminderDate,
    this.reminderDismissed = false,
    this.imageWidth,
    this.imageHeight,
    required this.createdAt,
    this.updatedAt,
    this.isSynced = false,
    this.additionalImages,
  });

  Map<String, dynamic> toMap({bool forDatabase = false}) {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'image_path': imagePath,
      'raw_text': rawText,
      'summary': summary,
      'translated_text': translatedText,
      'detected_language': detectedLanguage,
      'target_language': targetLanguage,
      'category_id': categoryId,
      'entities_json': entities != null
          ? jsonEncode(entities!.map((e) => e.toMap()).toList())
          : null,
      'bounding_boxes_json': boundingBoxes != null
          ? jsonEncode(boundingBoxes!.map((b) => b.toMap()).toList())
          : null,
      'document_type': documentType,
      'document_type_confidence': documentTypeConfidence,
      'reminder_suggestion': reminderSuggestion,
      'suggested_reminder_date': suggestedReminderDate?.toIso8601String(),
      'reminder_dismissed': reminderDismissed ? 1 : 0,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'additional_images_json':
          additionalImages != null ? jsonEncode(additionalImages) : null,
    };
  }

  factory ScanModel.fromMap(Map<String, dynamic> map) {
    return ScanModel(
      id: map['id'] as String,
      title: map['title'] as String,
      imagePath: map['image_path'] as String?,
      rawText: map['raw_text'] as String?,
      summary: map['summary'] as String?,
      translatedText: map['translated_text'] as String?,
      detectedLanguage: map['detected_language'] as String?,
      targetLanguage: map['target_language'] as String?,
      categoryId: map['category_id'] as String?,
      entities: map['entities_json'] != null
          ? (jsonDecode(map['entities_json'] as String) as List)
              .map((e) => EntityModel.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
      boundingBoxes: map['bounding_boxes_json'] != null
          ? (jsonDecode(map['bounding_boxes_json'] as String) as List)
              .map((e) => BoundingBoxModel.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
      documentType: map['document_type'] as String?,
      documentTypeConfidence: map['document_type_confidence'] as double?,
      reminderSuggestion: map['reminder_suggestion'] as String?,
      suggestedReminderDate: map['suggested_reminder_date'] != null
          ? DateTime.parse(map['suggested_reminder_date'] as String)
          : null,
      reminderDismissed: (map['reminder_dismissed'] as int? ?? 0) == 1,
      imageWidth: map['image_width'] as int?,
      imageHeight: map['image_height'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      additionalImages: map['additional_images_json'] != null
          ? List<String>.from(
              jsonDecode(map['additional_images_json'] as String) as List)
          : null,
    );
  }

  ScanModel copyWith({
    String? id,
    String? title,
    String? imagePath,
    String? rawText,
    String? summary,
    String? translatedText,
    String? detectedLanguage,
    String? targetLanguage,
    String? categoryId,
    List<EntityModel>? entities,
    List<BoundingBoxModel>? boundingBoxes,
    String? documentType,
    double? documentTypeConfidence,
    String? reminderSuggestion,
    DateTime? suggestedReminderDate,
    bool? reminderDismissed,
    int? imageWidth,
    int? imageHeight,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    List<String>? additionalImages,
  }) {
    return ScanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      rawText: rawText ?? this.rawText,
      summary: summary ?? this.summary,
      translatedText: translatedText ?? this.translatedText,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      categoryId: categoryId ?? this.categoryId,
      entities: entities ?? this.entities,
      boundingBoxes: boundingBoxes ?? this.boundingBoxes,
      documentType: documentType ?? this.documentType,
      documentTypeConfidence:
          documentTypeConfidence ?? this.documentTypeConfidence,
      reminderSuggestion: reminderSuggestion ?? this.reminderSuggestion,
      suggestedReminderDate:
          suggestedReminderDate ?? this.suggestedReminderDate,
      reminderDismissed: reminderDismissed ?? this.reminderDismissed,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      additionalImages: additionalImages ?? this.additionalImages,
    );
  }

  @override
  String toString() {
    return 'ScanModel(id: $id, title: $title, categoryId: $categoryId, createdAt: $createdAt)';
  }
}
