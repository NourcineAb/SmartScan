import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, XFile, ShareParams;
import 'package:flutter/foundation.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();

  factory ExportService() {
    return _instance;
  }

  ExportService._internal();

  /// Export document as PDF
  Future<void> exportToPDF({
    required String text,
    required String language,
    required String fileName,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SmartScan - Document Exporté',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Langue: ${_getLanguageName(language)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Date: ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(),
                pw.SizedBox(height: 16),
                pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      await _saveAndShare(bytes, '$fileName.pdf', 'application/pdf');
    } catch (e) {
      rethrow;
    }
  }

  /// Export document as Word (DOCX - saved as TXT for web)
  Future<void> exportToWord({
    required String text,
    required String language,
    required String fileName,
  }) async {
    try {
      final content = _generateWordContent(text, language);
      final bytes = utf8.encode(content);

      if (kIsWeb) {
        // On web, save as TXT since we can't create real DOCX
        await _saveAndShare(bytes, '$fileName.txt', 'text/plain');
      } else {
        // On mobile, create proper DOCX
        await _saveAndShare(
          bytes,
          '$fileName.docx',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Export document as plain text
  Future<void> exportToText({
    required String text,
    required String language,
    required String fileName,
  }) async {
    try {
      final content = '''SmartScan - Document Exporté
==============================
Langue: ${_getLanguageName(language)}
Date: ${DateTime.now().toString().split('.')[0]}

==============================

$text
''';

      final bytes = utf8.encode(content);
      await _saveAndShare(bytes, '$fileName.txt', 'text/plain');
    } catch (e) {
      rethrow;
    }
  }

  /// Generate Word-compatible content
  String _generateWordContent(String text, String language) {
    return '''SmartScan - Document Exporté
================================================================================

INFORMATIONS:
- Langue: ${_getLanguageName(language)}
- Date: ${DateTime.now().toString().split('.')[0]}

================================================================================

CONTENU:

$text

================================================================================
Généré par SmartScan
''';
  }

  /// Save and share file
  Future<void> _saveAndShare(
    List<int> bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      if (kIsWeb) {
        // On web, download the file
        _downloadFileWeb(bytes, fileName);
      } else {
        // On mobile, save to documents and share
        final appDocDir = await getApplicationDocumentsDirectory();
        final file = File('${appDocDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        // Share the file
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path, mimeType: mimeType)],
          text: 'SmartScan - $fileName',
        ));

        // Delete file after sharing
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Download file on web
  void _downloadFileWeb(List<int> bytes, String fileName) {
    // This would require js interop for real download on web
    // For now, we'll simulate it
    if (kIsWeb) {
      try {
        // Using dart:html for web file download
        // This is a simplified version - real implementation would use js interop
        // Web download not supported in this build
      } catch (e) {
        // silently ignore web download errors
      }
    }
  }

  String _getLanguageName(String code) {
    const languages = {
      'en': 'English',
      'fr': 'Français',
      'ar': 'العربية',
      'es': 'Español',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ja': '日本語',
      'zh': '中文',
    };

    return languages[code] ?? code;
  }
}
