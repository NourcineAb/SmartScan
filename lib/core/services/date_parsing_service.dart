import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

/// Result of date parsing with context
class ParsedDateResult {
  final DateTime? date;
  final String originalText;
  final String type; // 'absolute', 'relative'
  final bool isAmbiguous;
  final String? ambiguityNote;

  ParsedDateResult({
    this.date,
    required this.originalText,
    required this.type,
    this.isAmbiguous = false,
    this.ambiguityNote,
  });
}

/// Flexible date parsing service supporting absolute and relative dates
class DateParsingService {
  static final DateParsingService _instance = DateParsingService._internal();
  factory DateParsingService() => _instance;
  DateParsingService._internal();

  // Reference date for relative calculations (usually "now")
  DateTime get _now => DateTime.now();

  /// Parse a date string with flexible format support
  ParsedDateResult parseDate(String dateText, {DateTime? referenceDate}) {
    final ref = referenceDate ?? _now;
    final trimmed = dateText.trim();

    if (trimmed.isEmpty) {
      return ParsedDateResult(
        date: null,
        originalText: dateText,
        type: 'unknown',
      );
    }

    // Try relative date parsing first
    final relativeResult = _parseRelativeDate(trimmed, ref);
    if (relativeResult.date != null) {
      return relativeResult;
    }

    // Try absolute date parsing
    final absoluteResult = _parseAbsoluteDate(trimmed, ref);
    if (absoluteResult.date != null) {
      return absoluteResult;
    }

    // Could not parse
    return ParsedDateResult(
      date: null,
      originalText: dateText,
      type: 'unknown',
      isAmbiguous: true,
      ambiguityNote: 'Could not parse date format',
    );
  }

  /// Parse relative dates like "tomorrow", "next Friday", etc.
  ParsedDateResult _parseRelativeDate(String text, DateTime ref) {
    final lower = text.toLowerCase();

    // Handle simple relative terms
    if (_matchesAny(lower, ['today', 'aujourd\'hui', 'hoy', 'oggi', 'heute'])) {
      return ParsedDateResult(
        date: DateTime(ref.year, ref.month, ref.day),
        originalText: text,
        type: 'relative',
      );
    }

    if (_matchesAny(lower, ['tomorrow', 'demain', 'mañana', 'domani', 'morgen'])) {
      final tomorrow = ref.add(const Duration(days: 1));
      return ParsedDateResult(
        date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
        originalText: text,
        type: 'relative',
      );
    }

    if (_matchesAny(lower, ['yesterday', 'hier', 'ayer', 'ieri', 'gestern'])) {
      final yesterday = ref.subtract(const Duration(days: 1));
      return ParsedDateResult(
        date: DateTime(yesterday.year, yesterday.month, yesterday.day),
        originalText: text,
        type: 'relative',
      );
    }

    // Handle "next X" patterns
    final nextMatch = RegExp(
      r'next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)',
      caseSensitive: false,
    ).firstMatch(lower);
    
    if (nextMatch != null) {
      final dayName = nextMatch.group(1)!;
      final targetDate = _getNextWeekday(ref, dayName);
      return ParsedDateResult(
        date: targetDate,
        originalText: text,
        type: 'relative',
      );
    }

    // Handle "this X" patterns
    final thisMatch = RegExp(
      r'this\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)',
      caseSensitive: false,
    ).firstMatch(lower);
    
    if (thisMatch != null) {
      final dayName = thisMatch.group(1)!;
      final targetDate = _getThisWeekday(ref, dayName);
      return ParsedDateResult(
        date: targetDate,
        originalText: text,
        type: 'relative',
      );
    }

    // Handle "in X days/weeks/months"
    final inMatch = RegExp(
      r'in\s+(\d+)\s+(day|days|week|weeks|month|months)',
      caseSensitive: false,
    ).firstMatch(lower);
    
    if (inMatch != null) {
      final amount = int.parse(inMatch.group(1)!);
      final unit = inMatch.group(2)!.toLowerCase();
      
      DateTime targetDate;
      if (unit.startsWith('day')) {
        targetDate = ref.add(Duration(days: amount));
      } else if (unit.startsWith('week')) {
        targetDate = ref.add(Duration(days: amount * 7));
      } else {
        targetDate = _addMonths(ref, amount);
      }
      
      return ParsedDateResult(
        date: DateTime(targetDate.year, targetDate.month, targetDate.day),
        originalText: text,
        type: 'relative',
      );
    }

    // Handle "next week"
    if (lower.contains('next week')) {
      final nextWeek = ref.add(const Duration(days: 7));
      // Set to Monday of next week
      final daysUntilMonday = (DateTime.monday - nextWeek.weekday + 7) % 7;
      final nextWeekMonday = nextWeek.add(Duration(days: daysUntilMonday));
      return ParsedDateResult(
        date: DateTime(nextWeekMonday.year, nextWeekMonday.month, nextWeekMonday.day),
        originalText: text,
        type: 'relative',
      );
    }

    return ParsedDateResult(
      date: null,
      originalText: text,
      type: 'relative',
    );
  }

  /// Parse absolute dates in various formats
  ParsedDateResult _parseAbsoluteDate(String text, DateTime ref) {
    final List<DateFormat> formats = [
      // ISO formats
      DateFormat('yyyy-MM-dd'),
      DateFormat('yyyy/MM/dd'),
      // US formats
      DateFormat('MM/dd/yyyy'),
      DateFormat('MM-dd-yyyy'),
      // European formats
      DateFormat('dd/MM/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('dd.MM.yyyy'),
      // Long formats
      DateFormat('MMMM dd, yyyy'),
      DateFormat('dd MMMM yyyy'),
      DateFormat('yyyy MMMM dd'),
      // Short year formats
      DateFormat('MM/dd/yy'),
      DateFormat('dd/MM/yy'),
      DateFormat('dd-MM-yy'),
      // Month/Year only
      DateFormat('MMMM yyyy'),
      DateFormat('MMM yyyy'),
    ];

    DateTime? bestResult;
    bool isAmbiguous = false;
    String? ambiguityNote;

    for (final format in formats) {
      try {
        final result = format.parseLoose(text);
        
        // Check for two-digit year ambiguity
        if (text.contains(RegExp(r'\d{2}$')) && !text.contains(RegExp(r'\d{4}'))) {
          isAmbiguous = true;
          ambiguityNote = 'Two-digit year - interpreted as ${result.year}';
        }

        // For dates that could be MM/DD or DD/MM, prefer future dates if close
        if (bestResult == null || _isBetterDate(result, bestResult, ref)) {
          bestResult = result;
        }
      } catch (_) {
        // Continue to next format
      }
    }

    if (bestResult != null) {
      return ParsedDateResult(
        date: bestResult,
        originalText: text,
        type: 'absolute',
        isAmbiguous: isAmbiguous,
        ambiguityNote: ambiguityNote,
      );
    }

    return ParsedDateResult(
      date: null,
      originalText: text,
      type: 'absolute',
    );
  }

  /// Determine if a date is "better" (prefer future dates if close to today)
  bool _isBetterDate(DateTime candidate, DateTime current, DateTime ref) {
    final candidateDiff = candidate.difference(ref).inDays.abs();
    final currentDiff = current.difference(ref).inDays.abs();

    // Prefer future dates when differences are similar
    if ((candidateDiff - currentDiff).abs() <= 1) {
      return candidate.isAfter(ref) && !current.isAfter(ref);
    }

    return candidateDiff < currentDiff;
  }

  /// Get next occurrence of a weekday
  DateTime _getNextWeekday(DateTime ref, String dayName) {
    final targetWeekday = _parseWeekday(dayName);
    if (targetWeekday == null) return ref;

    final daysUntilTarget = (targetWeekday - ref.weekday + 7) % 7;
    final daysToAdd = daysUntilTarget == 0 ? 7 : daysUntilTarget;
    
    return ref.add(Duration(days: daysToAdd));
  }

  /// Get this week's occurrence of a weekday (or next if already passed)
  DateTime _getThisWeekday(DateTime ref, String dayName) {
    final targetWeekday = _parseWeekday(dayName);
    if (targetWeekday == null) return ref;

    final daysUntilTarget = (targetWeekday - ref.weekday + 7) % 7;
    return ref.add(Duration(days: daysUntilTarget));
  }

  /// Parse weekday name to number (1 = Monday, 7 = Sunday)
  int? _parseWeekday(String dayName) {
    final days = {
      'monday': DateTime.monday, 'mon': DateTime.monday,
      'tuesday': DateTime.tuesday, 'tue': DateTime.tuesday, 'tues': DateTime.tuesday,
      'wednesday': DateTime.wednesday, 'wed': DateTime.wednesday,
      'thursday': DateTime.thursday, 'thu': DateTime.thursday, 'thur': DateTime.thursday, 'thurs': DateTime.thursday,
      'friday': DateTime.friday, 'fri': DateTime.friday,
      'saturday': DateTime.saturday, 'sat': DateTime.saturday,
      'sunday': DateTime.sunday, 'sun': DateTime.sunday,
    };
    return days[dayName.toLowerCase()];
  }

  /// Add months to a date
  DateTime _addMonths(DateTime date, int months) {
    final newMonth = date.month + months;
    final newYear = date.year + (newMonth - 1) ~/ 12;
    final month = ((newMonth - 1) % 12) + 1;
    
    // Handle day overflow (e.g., Jan 31 + 1 month = Feb 28)
    final lastDayOfMonth = DateTime(newYear, month + 1, 0).day;
    final newDay = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
    
    return DateTime(newYear, month, newDay, date.hour, date.minute, date.second);
  }

  /// Check if text matches any of the given terms
  bool _matchesAny(String text, List<String> terms) {
    return terms.any((term) => text == term || text.contains(term));
  }

  /// Find and parse all dates in text
  List<ParsedDateResult> findDatesInText(String text, {DateTime? referenceDate}) {
    final results = <ParsedDateResult>[];
    final ref = referenceDate ?? _now;

    // Date patterns to search for
    final patterns = [
      // ISO dates: 2026-04-30 or 2026/04/30
      RegExp(r'\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b'),
      // US dates: 04/30/2026 or 04-30-2026
      RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
      // European dates: 30.04.2026
      RegExp(r'\b\d{1,2}\.\d{1,2}\.\d{2,4}\b'),
      // Written dates: April 30, 2026
      RegExp(r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2}(?:,|\s)\s*\d{4}\b', caseSensitive: false),
      // Day Month Year: 30 April 2026
      RegExp(r'\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s*\d{4}\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final dateText = match.group(0)!;
        // Check if this date was already found
        final isDuplicate = results.any((r) => 
          r.originalText.contains(dateText) || dateText.contains(r.originalText)
        );
        
        if (!isDuplicate) {
          final parsed = parseDate(dateText, referenceDate: ref);
          if (parsed.date != null) {
            results.add(parsed);
          }
        }
      }
    }

    // Also search for relative date expressions
    final relativePatterns = [
      RegExp(r'\btomorrow\b', caseSensitive: false),
      RegExp(r'\bnext\s+(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', caseSensitive: false),
      RegExp(r'\bin\s+\d+\s+(?:day|days|week|weeks|month|months)\b', caseSensitive: false),
    ];

    for (final pattern in relativePatterns) {
      for (final match in pattern.allMatches(text)) {
        final dateText = match.group(0)!;
        final isDuplicate = results.any((r) => 
          r.originalText.toLowerCase() == dateText.toLowerCase()
        );
        
        if (!isDuplicate) {
          final parsed = parseDate(dateText, referenceDate: ref);
          if (parsed.date != null) {
            results.add(parsed);
          }
        }
      }
    }

    return results;
  }

  /// Format a parsed date for display
  String formatDate(DateTime date, {String? locale}) {
    final format = DateFormat.yMMMd(locale);
    return format.format(date);
  }

  /// Get human-readable description of relative date
  String getRelativeDescription(DateTime date, {DateTime? referenceDate}) {
    final ref = referenceDate ?? _now;
    final difference = date.difference(DateTime(ref.year, ref.month, ref.day)).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 1 && difference < 7) return 'In $difference days';
    if (difference >= 7 && difference < 14) return 'Next week';
    if (difference >= 14 && difference < 30) return 'In ${difference ~/ 7} weeks';
    if (difference > 30 && difference < 365) return 'In ${difference ~/ 30} months';
    if (difference >= 365) return 'In ${difference ~/ 365} years';
    if (difference < -1 && difference > -7) return '${difference.abs()} days ago';
    if (difference <= -7 && difference > -14) return 'Last week';
    
    return formatDate(date);
  }
}
