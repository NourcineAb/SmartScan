import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart' as ml_kit;
import '../../shared/models/entity_model.dart';
import 'package:flutter/foundation.dart';

/// Enhanced entity extraction service with additional pattern matching
class EntityExtractionService {
  static final EntityExtractionService _instance = EntityExtractionService._internal();
  factory EntityExtractionService() => _instance;
  EntityExtractionService._internal();

  ml_kit.EntityExtractor? _extractor;

  ml_kit.EntityExtractor _getExtractor() {
    _extractor ??= ml_kit.EntityExtractor(language: ml_kit.EntityExtractorLanguage.english);
    return _extractor!;
  }

  /// Extract all entities from text using ML Kit and custom patterns
  Future<List<EntityModel>> extractEntities(String text) async {
    final entities = <EntityModel>[];

    if (text.isEmpty) return entities;

    try {
      // Try ML Kit entity extraction first (only on mobile)
      if (!kIsWeb) {
        try {
          final mlEntities = await _extractWithMLKit(text);
          entities.addAll(mlEntities);
        } catch (e) {
          debugPrint('ML Kit entity extraction failed: $e');
        }
      }

      // Always run custom pattern extraction for better coverage
      final customEntities = await _extractWithCustomPatterns(text);
      
      // Merge entities, avoiding duplicates
      for (final custom in customEntities) {
        final isDuplicate = entities.any((e) => 
          e.text.toLowerCase() == custom.text.toLowerCase() && 
          e.type == custom.type
        );
        if (!isDuplicate) {
          entities.add(custom);
        }
      }

    } catch (e) {
      debugPrint('Entity extraction error: $e');
    }

    return entities;
  }

  /// Extract entities using ML Kit
  Future<List<EntityModel>> _extractWithMLKit(String text) async {
    final entities = <EntityModel>[];
    
    try {
      final extractor = _getExtractor();
      final results = await extractor.annotateText(text);

      for (final annotation in results) {
        for (final entity in annotation.entities) {
          final type = _mapMLKitEntityType(entity.type);
          if (type != 'unknown') {
            entities.add(EntityModel(
              text: annotation.text,
              type: type,
              confidence: 0.85,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('ML Kit extraction error: $e');
    }

    return entities;
  }

  /// Map ML Kit entity types to our types
  String _mapMLKitEntityType(ml_kit.EntityType type) {
    switch (type) {
      case ml_kit.EntityType.address:
        return 'location';
      case ml_kit.EntityType.dateTime:
        return 'date';
      case ml_kit.EntityType.email:
        return 'email';
      case ml_kit.EntityType.phone:
        return 'phone';
      case ml_kit.EntityType.url:
        return 'url';
      case ml_kit.EntityType.money:
        return 'price';
      default:
        return 'unknown';
    }
  }

  /// Extract entities using custom regex patterns
  Future<List<EntityModel>> _extractWithCustomPatterns(String text) async {
    final entities = <EntityModel>[];

    // Email pattern
    final emailPattern = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
      caseSensitive: false,
    );
    for (final match in emailPattern.allMatches(text)) {
      entities.add(EntityModel(
        text: match.group(0)!,
        type: 'email',
        confidence: 0.95,
      ));
    }

    // Phone pattern (international formats)
    final phonePattern = RegExp(
      r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{2,4}[-.\s]?\d{2,4}(?:[-.\s]?\d{2,9})?',
      caseSensitive: false,
    );
    for (final match in phonePattern.allMatches(text)) {
      final phone = match.group(0)!;
      // Filter out short sequences that aren't likely phone numbers
      if (phone.replaceAll(RegExp(r'[^\d]'), '').length >= 7) {
        entities.add(EntityModel(
          text: phone,
          type: 'phone',
          confidence: 0.90,
        ));
      }
    }

    // URL pattern
    final urlPattern = RegExp(
      r'https?://(?:www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_+.~#?&/=]*)',
      caseSensitive: false,
    );
    for (final match in urlPattern.allMatches(text)) {
      entities.add(EntityModel(
        text: match.group(0)!,
        type: 'url',
        confidence: 0.95,
      ));
    }

    // Price/Currency pattern
    final pricePattern = RegExp(
      r'(?:[\$€£¥₹]\s?\d{1,3}(?:,\d{3})*(?:\.\d{2})?|\d{1,3}(?:,\d{3})*(?:\.\d{2})?\s?(?:USD|EUR|GBP|JPY|INR|\$|€|£|¥|₹))',
      caseSensitive: false,
    );
    for (final match in pricePattern.allMatches(text)) {
      entities.add(EntityModel(
        text: match.group(0)!,
        type: 'price',
        confidence: 0.85,
      ));
    }

    // Address/Location pattern (simplified)
    final addressPattern = RegExp(
      r'\d+\s+[A-Za-z0-9\s,.]+(?:Avenue|Street|Boulevard|Road|Lane|Drive|Way|Plaza|Center|City|Town)[,\s]+[A-Za-z\s]+(?:,\s*[A-Z]{2})?(?:\s+\d{5}(?:-\d{4})?)?',
      caseSensitive: false,
    );
    for (final match in addressPattern.allMatches(text)) {
      entities.add(EntityModel(
        text: match.group(0)!,
        type: 'location',
        confidence: 0.75,
      ));
    }

    // Date patterns
    final datePatterns = [
      // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'\b\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}\b'),
      // Month DD, YYYY or DD Month YYYY
      RegExp(r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2}(?:,|\s)\s*\d{4}\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s*\d{4}\b', caseSensitive: false),
      // ISO format YYYY-MM-DD
      RegExp(r'\b\d{4}-\d{2}-\d{2}\b'),
    ];

    for (final pattern in datePatterns) {
      for (final match in pattern.allMatches(text)) {
        final dateText = match.group(0)!;
        // Avoid duplicates
        final isDuplicate = entities.any((e) => 
          e.type == 'date' && 
          (e.text.contains(dateText) || dateText.contains(e.text))
        );
        if (!isDuplicate) {
          entities.add(EntityModel(
            text: dateText,
            type: 'date',
            confidence: 0.80,
          ));
        }
      }
    }

    return entities;
  }

  /// Group entities by type for display
  Map<String, List<EntityModel>> groupEntitiesByType(List<EntityModel> entities) {
    final grouped = <String, List<EntityModel>>{};
    
    for (final entity in entities) {
      grouped.putIfAbsent(entity.type, () => []);
      grouped[entity.type]!.add(entity);
    }

    // Sort each group by confidence (highest first)
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => b.confidence.compareTo(a.confidence));
    }

    return grouped;
  }

  /// Get entity type icon name
  String getEntityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return 'email';
      case 'phone':
        return 'phone';
      case 'url':
        return 'link';
      case 'date':
        return 'calendar_today';
      case 'location':
      case 'address':
        return 'location_on';
      case 'price':
      case 'money':
        return 'attach_money';
      default:
        return 'label';
    }
  }

  /// Get entity type display name
  String getEntityDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return 'Email Addresses';
      case 'phone':
        return 'Phone Numbers';
      case 'url':
        return 'Links & URLs';
      case 'date':
        return 'Dates';
      case 'location':
      case 'address':
        return 'Locations';
      case 'price':
      case 'money':
        return 'Prices & Amounts';
      default:
        return 'Other';
    }
  }

  void dispose() {
    _extractor?.close();
    _extractor = null;
  }
}
