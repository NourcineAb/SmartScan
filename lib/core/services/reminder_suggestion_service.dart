import 'package:flutter/foundation.dart';
import '../../shared/models/entity_model.dart';
import 'date_parsing_service.dart';
import 'document_type_service.dart';

/// Reminder suggestion result
class ReminderSuggestion {
  final String id;
  final String title;
  final String description;
  final DateTime? suggestedDate;
  final String priority; // 'high', 'medium', 'low'
  final String sourceType; // 'payment_due', 'event_date', 'meeting', 'expiry', 'follow_up'
  final double confidence;

  ReminderSuggestion({
    required this.id,
    required this.title,
    required this.description,
    this.suggestedDate,
    required this.priority,
    required this.sourceType,
    required this.confidence,
  });
}

/// Smart reminder suggestion service
class ReminderSuggestionService {
  static final ReminderSuggestionService _instance = ReminderSuggestionService._internal();
  factory ReminderSuggestionService() => _instance;
  ReminderSuggestionService._internal();

  final DateParsingService _dateParser = DateParsingService();

  /// Generate reminder suggestions based on document content
  List<ReminderSuggestion> generateSuggestions({
    required String text,
    required String documentType,
    required List<EntityModel> entities,
    required DateTime scanDate,
  }) {
    final suggestions = <ReminderSuggestion>[];

    if (text.isEmpty) return suggestions;

    final normalizedText = text.toLowerCase();

    // Generate suggestions based on document type
    switch (documentType.toLowerCase()) {
      case 'invoice':
        suggestions.addAll(_suggestForInvoice(normalizedText, entities, scanDate));
        break;
      case 'receipt':
        suggestions.addAll(_suggestForReceipt(normalizedText, entities, scanDate));
        break;
      case 'ticket':
      case 'event':
        suggestions.addAll(_suggestForEvent(normalizedText, entities, scanDate));
        break;
      case 'contract':
        suggestions.addAll(_suggestForContract(normalizedText, entities, scanDate));
        break;
      default:
        suggestions.addAll(_suggestGeneric(normalizedText, entities, scanDate));
        break;
    }

    // Sort by confidence (highest first)
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

    return suggestions;
  }

  /// Suggestions for invoices
  List<ReminderSuggestion> _suggestForInvoice(
    String text,
    List<EntityModel> entities,
    DateTime scanDate,
  ) {
    final suggestions = <ReminderSuggestion>[];

    // Look for due dates
    final dueDatePatterns = [
      RegExp(r'due\s+(?:date|on)?[:\s]*(\w+\s+\d{1,2},?\s*\d{4})', caseSensitive: false),
      RegExp(r'payment\s+due[:\s]*(\w+\s+\d{1,2},?\s*\d{4})', caseSensitive: false),
      RegExp(r'due\s+by[:\s]*(\w+\s+\d{1,2},?\s*\d{4})', caseSensitive: false),
      RegExp(r'net\s+\d+[:\s]*(\w+\s+\d{1,2},?\s*\d{4})', caseSensitive: false),
    ];

    for (final pattern in dueDatePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final dateText = match.group(1);
        if (dateText != null) {
          final parsed = _dateParser.parseDate(dateText, referenceDate: scanDate);
          if (parsed.date != null) {
            suggestions.add(ReminderSuggestion(
              id: 'invoice_due_${parsed.date!.millisecondsSinceEpoch}',
              title: 'Payment Due',
              description: 'Invoice payment due date is approaching',
              suggestedDate: parsed.date,
              priority: 'high',
              sourceType: 'payment_due',
              confidence: 0.9,
            ));
          }
        }
      }
    }

    // Look for "Net 30", "Net 15", etc.
    final netPattern = RegExp(r'net\s+(\d+)', caseSensitive: false);
    final netMatch = netPattern.firstMatch(text);
    if (netMatch != null) {
      final days = int.tryParse(netMatch.group(1)!);
      if (days != null) {
        final dueDate = scanDate.add(Duration(days: days));
        suggestions.add(ReminderSuggestion(
          id: 'net_${days}_${dueDate.millisecondsSinceEpoch}',
          title: 'Payment Due (Net $days)',
          description: 'Payment is due $days days from invoice date',
          suggestedDate: dueDate,
          priority: 'high',
          sourceType: 'payment_due',
          confidence: 0.85,
        ));
      }
    }

    return suggestions;
  }

  /// Suggestions for receipts
  List<ReminderSuggestion> _suggestForReceipt(
    String text,
    List<EntityModel> entities,
    DateTime scanDate,
  ) {
    final suggestions = <ReminderSuggestion>[];

    // Check for return policy mentions
    if (text.contains('return') || text.contains('exchange') || text.contains('refund')) {
      final returnDate = scanDate.add(const Duration(days: 30));
      suggestions.add(ReminderSuggestion(
        id: 'return_policy_${scanDate.millisecondsSinceEpoch}',
        title: 'Check Return Policy',
        description: 'Verify return/exchange deadline',
        suggestedDate: returnDate,
        priority: 'low',
        sourceType: 'follow_up',
        confidence: 0.6,
      ));
    }

    // Check for warranty
    if (text.contains('warranty') || text.contains('guarantee')) {
      final warrantyDate = scanDate.add(const Duration(days: 365));
      suggestions.add(ReminderSuggestion(
        id: 'warranty_${scanDate.millisecondsSinceEpoch}',
        title: 'Warranty Expires',
        description: 'Product warranty expiration approaching',
        suggestedDate: warrantyDate,
        priority: 'medium',
        sourceType: 'expiry',
        confidence: 0.7,
      ));
    }

    return suggestions;
  }

  /// Suggestions for events/tickets
  List<ReminderSuggestion> _suggestForEvent(
    String text,
    List<EntityModel> entities,
    DateTime scanDate,
  ) {
    final suggestions = <ReminderSuggestion>[];

    // Extract event dates
    final dateEntities = entities.where((e) => e.type == 'date').toList();
    
    for (final dateEntity in dateEntities) {
      final parsed = _dateParser.parseDate(dateEntity.text, referenceDate: scanDate);
      if (parsed.date != null && parsed.date!.isAfter(scanDate)) {
        suggestions.add(ReminderSuggestion(
          id: 'event_${parsed.date!.millisecondsSinceEpoch}',
          title: 'Upcoming Event',
          description: 'You have an event or appointment on this date',
          suggestedDate: parsed.date,
          priority: 'high',
          sourceType: 'event_date',
          confidence: 0.9,
        ));
      }
    }

    // Look for specific time patterns
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?', caseSensitive: false);
    if (timePattern.hasMatch(text)) {
      // If there's a time mentioned, suggest arriving early
      final earliestDate = dateEntities.isNotEmpty 
          ? _dateParser.parseDate(dateEntities.first.text, referenceDate: scanDate).date
          : null;
      
      if (earliestDate != null) {
        final earlyArrival = earliestDate.subtract(const Duration(hours: 1));
        suggestions.add(ReminderSuggestion(
          id: 'early_arrival_${earliestDate.millisecondsSinceEpoch}',
          title: 'Leave for Event',
          description: 'Plan to leave early to arrive on time',
          suggestedDate: earlyArrival,
          priority: 'medium',
          sourceType: 'event_date',
          confidence: 0.75,
        ));
      }
    }

    return suggestions;
  }

  /// Suggestions for contracts
  List<ReminderSuggestion> _suggestForContract(
    String text,
    List<EntityModel> entities,
    DateTime scanDate,
  ) {
    final suggestions = <ReminderSuggestion>[];

    // Look for renewal dates
    final renewalPattern = RegExp(
      r'renewal\s+(?:date)?[:\s]*(\w+\s+\d{1,2},?\s*\d{4})',
      caseSensitive: false,
    );
    final renewalMatch = renewalPattern.firstMatch(text);
    if (renewalMatch != null) {
      final dateText = renewalMatch.group(1);
      if (dateText != null) {
        final parsed = _dateParser.parseDate(dateText, referenceDate: scanDate);
        if (parsed.date != null) {
          suggestions.add(ReminderSuggestion(
            id: 'renewal_${parsed.date!.millisecondsSinceEpoch}',
            title: 'Contract Renewal',
            description: 'Contract renewal date approaching',
            suggestedDate: parsed.date,
            priority: 'high',
            sourceType: 'expiry',
            confidence: 0.9,
          ));
        }
      }
    }

    // Look for expiry/expiration
    final expiryPatterns = [
      RegExp(r'expir(?:y|ation|es?)[:\s]*(\w+\s+\d{1,2},?\s*\d{4})', caseSensitive: false),
      RegExp(r'valid\s+until[:\s]*(\w+\s+\d{1,2},?\s*\d{4})', caseSensitive: false),
      RegExp(r'valid\s+through[:\s]*(\w+\s+\d{1,2},?\s*\d{4})', caseSensitive: false),
    ];

    for (final pattern in expiryPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final dateText = match.group(1);
        if (dateText != null) {
          final parsed = _dateParser.parseDate(dateText, referenceDate: scanDate);
          if (parsed.date != null) {
            suggestions.add(ReminderSuggestion(
              id: 'expiry_${parsed.date!.millisecondsSinceEpoch}',
              title: 'Document Expires',
              description: 'This document will expire soon',
              suggestedDate: parsed.date,
              priority: 'high',
              sourceType: 'expiry',
              confidence: 0.9,
            ));
          }
        }
        break; // Only take the first match
      }
    }

    return suggestions;
  }

  /// Generic suggestions for any document type
  List<ReminderSuggestion> _suggestGeneric(
    String text,
    List<EntityModel> entities,
    DateTime scanDate,
  ) {
    final suggestions = <ReminderSuggestion>[];

    // Look for meeting patterns
    final meetingPatterns = [
      RegExp(r'meeting\s+(?:on|at)?[:\s]*(\w+\s+\d{1,2})', caseSensitive: false),
      RegExp(r'appointment\s+(?:on|at)?[:\s]*(\w+\s+\d{1,2})', caseSensitive: false),
      RegExp(r'call\s+(?:on|at)?[:\s]*(\w+\s+\d{1,2})', caseSensitive: false),
      RegExp(r'conference\s+(?:on|at)?[:\s]*(\w+\s+\d{1,2})', caseSensitive: false),
    ];

    for (final pattern in meetingPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final dateText = match.group(1);
        if (dateText != null) {
          final parsed = _dateParser.parseDate(dateText, referenceDate: scanDate);
          if (parsed.date != null) {
            suggestions.add(ReminderSuggestion(
              id: 'meeting_${parsed.date!.millisecondsSinceEpoch}',
              title: 'Upcoming Meeting',
              description: 'You have a meeting or appointment',
              suggestedDate: parsed.date,
              priority: 'medium',
              sourceType: 'meeting',
              confidence: 0.75,
            ));
          }
        }
      }
    }

    // Look for follow-up patterns
    final followUpPatterns = [
      RegExp(r'follow[-\s]?up', caseSensitive: false),
      RegExp(r'followup', caseSensitive: false),
      RegExp(r'check[-\s]?back', caseSensitive: false),
      RegExp(r'review\s+(?:by|on)', caseSensitive: false),
    ];

    for (final pattern in followUpPatterns) {
      if (pattern.hasMatch(text)) {
        final followUpDate = scanDate.add(const Duration(days: 7));
        suggestions.add(ReminderSuggestion(
          id: 'followup_${scanDate.millisecondsSinceEpoch}',
          title: 'Follow-up Needed',
          description: 'This document mentions a follow-up action',
          suggestedDate: followUpDate,
          priority: 'low',
          sourceType: 'follow_up',
          confidence: 0.6,
        ));
        break;
      }
    }

    return suggestions;
  }

  /// Get the best suggestion from a list
  ReminderSuggestion? getBestSuggestion(List<ReminderSuggestion> suggestions) {
    if (suggestions.isEmpty) return null;
    return suggestions.first; // Already sorted by confidence
  }

  /// Filter suggestions by minimum confidence
  List<ReminderSuggestion> filterByConfidence(
    List<ReminderSuggestion> suggestions,
    double minConfidence,
  ) {
    return suggestions.where((s) => s.confidence >= minConfidence).toList();
  }

  /// Check if a suggestion has been dismissed before
  bool isDismissed(String suggestionId, List<String> dismissedIds) {
    return dismissedIds.contains(suggestionId);
  }
}
