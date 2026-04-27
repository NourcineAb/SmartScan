import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const String _prefGeminiApiKey = 'gemini_api_key';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_prefGeminiApiKey);
    return (key != null && key.isNotEmpty) ? key : null;
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null;
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefGeminiApiKey, key.trim());
  }

  Future<Map<String, String>?> generateSummaryAndCategory(String rawText, {String targetLanguage = 'en'}) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = '''
You are a smart document summary assistant. I will provide you with the raw OCR text of a scanned document.
Your job is to provide a concise summary in exactly 3 bullet points AND suggest a single, short category name for this document (e.g., "Invoice", "Receipt", "ID Card", "Letter", "Note").

CRITICAL: The summary and the category MUST be written in the following language: $targetLanguage.

Return your response ONLY as a valid JSON object with the following structure, without any markdown formatting or code blocks:
{
  "summary": "1. point 1\\n2. point 2\\n3. point 3",
  "category": "Suggested Category"
}

RAW OCR TEXT:
"""
$rawText
"""
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        final text = response.text!.trim().replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> jsonMap = jsonDecode(text);
        return {
          'summary': jsonMap['summary']?.toString() ?? '',
          'category': jsonMap['category']?.toString() ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Gemini Summary Error: $e');
      return null;
    }
  }

  Future<String> parseDocumentWithAI(String rawText) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return rawText; // Fallback to raw text if no key is provided
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = '''
You are a smart document parsing assistant. I will provide you with the raw OCR text of a scanned document.
Your job is to clean up the text, correct minor OCR errors, and format it beautifully.
If it is a receipt or invoice, extract the key details (Vendor, Date, Total, Tax, Items) and present them clearly at the top, followed by the rest of the text.
If it is a letter or article, fix the formatting and add a very short summary at the top.
Return ONLY the formatted markdown text. Do not output markdown codeblock ticks.

RAW OCR TEXT:
"""
$rawText
"""
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      }
      return rawText;
    } catch (e) {
      print('Gemini API Error: $e');
      return rawText; // Fallback on error
    }
  }
}
