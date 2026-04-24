class SavedTranslationModel {
  final String id;
  final String sourceLanguage;
  final String targetLanguage;
  final String originalText;
  final String translatedText;
  final DateTime createdAt;

  SavedTranslationModel({
    required this.id,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.originalText,
    required this.translatedText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'original_text': originalText,
      'translated_text': translatedText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavedTranslationModel.fromMap(Map<String, dynamic> map) {
    return SavedTranslationModel(
      id: map['id'] as String,
      sourceLanguage: map['source_language'] as String,
      targetLanguage: map['target_language'] as String,
      originalText: map['original_text'] as String,
      translatedText: map['translated_text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SavedTranslationModel copyWith({
    String? id,
    String? sourceLanguage,
    String? targetLanguage,
    String? originalText,
    String? translatedText,
    DateTime? createdAt,
  }) {
    return SavedTranslationModel(
      id: id ?? this.id,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'SavedTranslationModel('
      'id: $id, '
      'sourceLanguage: $sourceLanguage, '
      'targetLanguage: $targetLanguage, '
      'originalText: $originalText, '
      'translatedText: $translatedText, '
      'createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedTranslationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceLanguage == other.sourceLanguage &&
          targetLanguage == other.targetLanguage &&
          originalText == other.originalText &&
          translatedText == other.translatedText &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        sourceLanguage,
        targetLanguage,
        originalText,
        translatedText,
        createdAt,
      );
}
