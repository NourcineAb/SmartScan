import '../../shared/models/entity_model.dart';

/// Document type detection result
class DocumentTypeResult {
  final String type;
  final double confidence;
  final Map<String, dynamic> metadata;

  DocumentTypeResult({
    required this.type,
    required this.confidence,
    this.metadata = const {},
  });
}

/// Rule-based document type detection service
class DocumentTypeService {
  static final DocumentTypeService _instance = DocumentTypeService._internal();
  factory DocumentTypeService() => _instance;
  DocumentTypeService._internal();

  // Document type definitions with keywords and rules
  static final Map<String, DocumentTypeDefinition> _documentTypes = {
    'invoice': DocumentTypeDefinition(
      name: 'Invoice',
      keywords: [
        'invoice', 'facture', 'rechnung', 'fattura', 'factura',
        'bill to', 'ship to', 'total amount', 'amount due', 'due date',
        'payment terms', 'invoice number', 'invoice #', 'invoice no',
        'tax', 'subtotal', 'vat', 'gst', 'ht', 'ttc',
      ],
      requiredKeywords: 2,
      weight: 1.0,
    ),
    'receipt': DocumentTypeDefinition(
      name: 'Receipt',
      keywords: [
        'receipt', 'reçu', 'bon', 'ticket', 'quittance',
        'cash', 'change', 'total', 'paid', 'payment',
        'store', 'shop', 'merchant', 'transaction',
        'thank you', 'merci', 'gracias', 'danke',
      ],
      requiredKeywords: 2,
      weight: 0.9,
    ),
    'ticket': DocumentTypeDefinition(
      name: 'Ticket/Event',
      keywords: [
        'ticket', 'billet', 'entrada', 'biglietto',
        'event', 'concert', 'movie', 'flight', 'boarding',
        'seat', 'gate', 'terminal', 'departure', 'arrival',
        'admission', 'venue', 'show', 'performance',
        'date:', 'time:', 'location:', 'place:',
      ],
      requiredKeywords: 2,
      weight: 0.9,
    ),
    'official_document': DocumentTypeDefinition(
      name: 'Official Document',
      keywords: [
        'certificate', 'diploma', 'license', 'permit',
        'passport', 'id card', 'identity', 'national',
        'government', 'official', 'ministry', 'department',
        'authorized', 'certified', 'notarized',
        'valid until', 'issue date', 'date of birth',
      ],
      requiredKeywords: 2,
      weight: 0.95,
    ),
    'note': DocumentTypeDefinition(
      name: 'Note',
      keywords: [
        'note', 'memo', 'reminder', 'todo', 'task',
        'meeting', 'agenda', 'minutes', 'summary',
        'personal', 'private', 'draft',
      ],
      requiredKeywords: 1,
      weight: 0.7,
    ),
    'contract': DocumentTypeDefinition(
      name: 'Contract',
      keywords: [
        'contract', 'agreement', 'terms', 'conditions',
        'party', 'parties', 'signature', 'sign',
        'hereby', 'witness', 'whereas', 'thereof',
        'legal', 'binding', 'obligation', 'clause',
      ],
      requiredKeywords: 2,
      weight: 0.9,
    ),
  };

  /// Detect document type based on text content and entities
  DocumentTypeResult detectDocumentType(String text, List<EntityModel> entities) {
    if (text.isEmpty) {
      return DocumentTypeResult(type: 'unknown', confidence: 1.0);
    }

    final normalizedText = text.toLowerCase();
    final scores = <String, double>{};

    // Calculate score for each document type
    for (final entry in _documentTypes.entries) {
      final typeKey = entry.key;
      final definition = entry.value;
      
      int keywordMatches = 0;
      for (final keyword in definition.keywords) {
        if (normalizedText.contains(keyword.toLowerCase())) {
          keywordMatches++;
        }
      }

      // Check if minimum keywords are met
      if (keywordMatches >= definition.requiredKeywords) {
        // Calculate base score from keywords
        double score = (keywordMatches / definition.keywords.length) * definition.weight;
        
        // Boost score based on entity types
        score = _boostScoreWithEntities(score, typeKey, entities);
        
        scores[typeKey] = score.clamp(0.0, 1.0);
      }
    }

    // Return the highest scoring type, or unknown
    if (scores.isEmpty) {
      return DocumentTypeResult(type: 'unknown', confidence: 0.0);
    }

    // Find highest score
    final bestMatch = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    // Calculate confidence based on score differential
    final confidence = _calculateConfidence(bestMatch.value, scores.values.toList());

    return DocumentTypeResult(
      type: bestMatch.key,
      confidence: confidence,
      metadata: {
        'matched_keywords': _getMatchedKeywords(bestMatch.key, normalizedText),
        'all_scores': scores,
      },
    );
  }

  /// Boost score based on entity types relevant to document type
  double _boostScoreWithEntities(double score, String type, List<EntityModel> entities) {
    switch (type) {
      case 'invoice':
      case 'receipt':
        // Boost if we find price amounts
        final hasPrice = entities.any((e) => e.type == 'price' || e.type == 'money');
        if (hasPrice) score += 0.2;
        break;
      case 'ticket':
      case 'event':
        // Boost if we find dates
        final hasDate = entities.any((e) => e.type == 'date');
        final hasLocation = entities.any((e) => e.type == 'location' || e.type == 'address');
        if (hasDate) score += 0.15;
        if (hasLocation) score += 0.1;
        break;
      case 'official_document':
        // Boost if we find proper names and dates
        final hasDate = entities.any((e) => e.type == 'date');
        if (hasDate) score += 0.1;
        break;
    }
    return score.clamp(0.0, 1.0);
  }

  /// Calculate confidence based on how much the winner stands out
  double _calculateConfidence(double winnerScore, List<double> allScores) {
    if (allScores.length < 2) return winnerScore;
    
    // Sort scores descending
    final sorted = List<double>.from(allScores)..sort((a, b) => b.compareTo(a));
    
    // If winner is significantly higher than runner-up, confidence is higher
    if (sorted.length >= 2) {
      final runnerUp = sorted[1];
      final margin = winnerScore - runnerUp;
      return (winnerScore + margin * 0.5).clamp(0.0, 1.0);
    }
    
    return winnerScore;
  }

  /// Get the list of matched keywords for debugging
  List<String> _getMatchedKeywords(String type, String normalizedText) {
    final definition = _documentTypes[type];
    if (definition == null) return [];

    return definition.keywords
        .where((k) => normalizedText.contains(k.toLowerCase()))
        .toList();
  }

  /// Get display name for document type
  String getDisplayName(String type) {
    final definition = _documentTypes[type];
    return definition?.name ?? 'Unknown';
  }

  /// Get icon name for document type
  String getIconName(String type) {
    switch (type.toLowerCase()) {
      case 'invoice':
        return 'receipt_long';
      case 'receipt':
        return 'receipt';
      case 'ticket':
        return 'confirmation_number';
      case 'official_document':
        return 'badge';
      case 'note':
        return 'sticky_note_2';
      case 'contract':
        return 'gavel';
      default:
        return 'description';
    }
  }

  /// Get color for document type
  int getColor(String type) {
    switch (type.toLowerCase()) {
      case 'invoice':
        return 0xFF2196F3; // Blue
      case 'receipt':
        return 0xFF4CAF50; // Green
      case 'ticket':
        return 0xFFFF9800; // Orange
      case 'official_document':
        return 0xFF9C27B0; // Purple
      case 'note':
        return 0xFFFFEB3B; // Yellow
      case 'contract':
        return 0xFF795548; // Brown
      default:
        return 0xFF757575; // Grey
    }
  }

  /// Get all available document types
  List<String> getAvailableTypes() {
    return _documentTypes.keys.toList();
  }
}

/// Definition of a document type for detection
class DocumentTypeDefinition {
  final String name;
  final List<String> keywords;
  final int requiredKeywords;
  final double weight;

  DocumentTypeDefinition({
    required this.name,
    required this.keywords,
    required this.requiredKeywords,
    required this.weight,
  });
}
