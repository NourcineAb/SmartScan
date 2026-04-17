import 'dart:convert';
import 'entity_model.dart';

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
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;

  ScanModel({
    required this.id,
    required this.title,
    this.imagePath,
    this.rawText,
    this.translatedText,
    this.detectedLanguage,
    this.targetLanguage,
    this.categoryId,
    this.entities,
    required this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap({bool forDatabase = false}) {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'image_path': imagePath,
      'raw_text': rawText,
      'translated_text': translatedText,
      'detected_language': detectedLanguage,
      'target_language': targetLanguage,
      'category_id': categoryId,
      'entities_json': entities != null
          ? jsonEncode(entities!.map((e) => e.toMap()).toList())
          : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      if (!forDatabase) 'is_synced': isSynced ? 1 : 0,
    };
  }

  factory ScanModel.fromMap(Map<String, dynamic> map) {
    return ScanModel(
      id: map['id'] as String,
      title: map['title'] as String,
      imagePath: map['image_path'] as String?,
      rawText: map['raw_text'] as String?,
      translatedText: map['translated_text'] as String?,
      detectedLanguage: map['detected_language'] as String?,
      targetLanguage: map['target_language'] as String?,
      categoryId: map['category_id'] as String?,
      entities: map['entities_json'] != null
          ? (jsonDecode(map['entities_json'] as String) as List)
                .map((e) => EntityModel.fromMap(e as Map<String, dynamic>))
                .toList()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }

  ScanModel copyWith({
    String? id,
    String? title,
    String? imagePath,
    String? rawText,
    String? translatedText,
    String? detectedLanguage,
    String? targetLanguage,
    String? categoryId,
    List<EntityModel>? entities,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ScanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      rawText: rawText ?? this.rawText,
      translatedText: translatedText ?? this.translatedText,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      categoryId: categoryId ?? this.categoryId,
      entities: entities ?? this.entities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'ScanModel(id: $id, title: $title, categoryId: $categoryId, createdAt: $createdAt)';
  }
}
