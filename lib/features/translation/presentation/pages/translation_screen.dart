import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:smart_scan/features/scan/data/services/ocr_service.dart';
import 'package:smart_scan/core/services/feedback_service.dart';
import 'package:smart_scan/shared/widgets/buttons.dart';
import '../../../../l10n/app_localizations.dart';

class TranslationScreen extends StatefulWidget {
  final String? initialText;

  const TranslationScreen({super.key, this.initialText});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  late TextEditingController _sourceController;
  late TextEditingController _targetController;
  String _selectedSourceLanguage = 'en';
  String _selectedTargetLanguage = 'fr';
  bool _isTranslating = false;
  bool _isPickingImage = false;
  String? _pickedImagePath;
  OnDeviceTranslator? _translator;

  // Status shown below the translate button
  String? _statusMessage;
  bool _statusIsError = false;

  // Cache translators for different language pairs to avoid recreating
  final Map<String, OnDeviceTranslator> _translatorCache = {};
  bool _isPreloadingTranslator = false;

  // Supported languages: at minimum Arabic, French, English, Spanish, German
  final Map<String, TranslateLanguage> _languageCodes = {
    'en': TranslateLanguage.english,
    'fr': TranslateLanguage.french,
    'ar': TranslateLanguage.arabic,
    'es': TranslateLanguage.spanish,
    'de': TranslateLanguage.german,
    'it': TranslateLanguage.italian,
    'pt': TranslateLanguage.portuguese,
    'ja': TranslateLanguage.japanese,
    'zh': TranslateLanguage.chinese,
  };

  final Map<String, String> _languageNames = {
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

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController(text: widget.initialText ?? '');
    _targetController = TextEditingController();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    _translator?.close();
    super.dispose();
  }

  // ─── Image Picking ─────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked != null && mounted) {
        await FeedbackService().onSuccess();
        await _runOcrOnImage(picked.path);
      }
    } catch (e) {
      if (mounted) {
        _showError('Gallery error: $e');
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _pickFromFiles() async {
    setState(() => _isPickingImage = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'bmp', 'tiff', 'webp'],
        allowMultiple: false,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null &&
          mounted) {
        await FeedbackService().onSuccess();
        await _runOcrOnImage(result.files.first.path!);
      }
    } catch (e) {
      if (mounted) {
        _showError('File picker error: $e');
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _showPickerDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.photo_library),
                ),
                title: const Text('Gallery'),
                subtitle: const Text('Pick a photo from your gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.folder_open),
                ),
                title: const Text('Documents / Storage'),
                subtitle: const Text(
                    'Pick an image from local files, USB or SD card'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromFiles();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── OCR ──────────────────────────────────────────────────────────────────

  Future<void> _runOcrOnImage(String imagePath) async {
    setState(() {
      _pickedImagePath = imagePath;
      _isPickingImage = true;
    });
    try {
      final text = await OCRService().extractTextFromImage(imagePath);
      if (mounted) {
        setState(() {
          _sourceController.text = text;
          _targetController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text extracted from image!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('OCR failed: $e');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // ─── Preload Translator ────────────────────────────────────────────────────

  /// Pre-initialize translator for the selected language pair in the background.
  /// This ensures faster translation when the user hits "Translate".
  /// Called when language selection changes.
  Future<void> _preloadTranslator() async {
    if (_isPreloadingTranslator) return;

    final cacheKey = '${_selectedSourceLanguage}_${_selectedTargetLanguage}';

    // Already cached
    if (_translatorCache.containsKey(cacheKey)) {
      _translator = _translatorCache[cacheKey];
      return;
    }

    setState(() => _isPreloadingTranslator = true);
    try {
      final sourceLang = _languageCodes[_selectedSourceLanguage];
      final targetLang = _languageCodes[_selectedTargetLanguage];

      if (sourceLang == null || targetLang == null) return;

      // Check if models are available offline
      final modelManager = OnDeviceTranslatorModelManager();
      final srcReady = await modelManager
          .isModelDownloaded(sourceLang.bcpCode)
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      final tgtReady = await modelManager
          .isModelDownloaded(targetLang.bcpCode)
          .timeout(const Duration(seconds: 5), onTimeout: () => false);

      if (srcReady && tgtReady) {
        // Models available – preload translator
        await _translator?.close();
        _translator = OnDeviceTranslator(
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );
        _translatorCache[cacheKey] = _translator!;
      }
    } catch (_) {
      // Silently fail; will retry during actual translation
    } finally {
      if (mounted) {
        setState(() => _isPreloadingTranslator = false);
      }
    }
  }

  // ─── Translation ──────────────────────────────────────────────────────────

  /// Entry point: tries the free MyMemory REST API first (no downloads, works
  /// on mobile data), then falls back to on-device ML Kit if there is no
  /// internet connection.
  Future<void> _translate() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty) {
      _setStatus('Please enter or pick text to translate', isError: true);
      return;
    }

    setState(() {
      _isTranslating = true;
      _statusMessage = null;
      _statusIsError = false;
    });
    _targetController.clear();

    try {
      _setStatus('Translating…');

      String result;

      // ── Strategy 1: MyMemory REST API (instant, no model download) ────────
      try {
        result = await _translateViaApi(
          text,
          _selectedSourceLanguage,
          _selectedTargetLanguage,
        );
        _setStatus('Translation complete ✓');
        FeedbackService().onSuccess();
      } on SocketException {
        // No internet – fall through to offline ML Kit
        _setStatus('No internet – trying offline engine…');
        result = await _translateOffline(
          text,
          _selectedSourceLanguage,
          _selectedTargetLanguage,
        );
        _setStatus('Translation complete ✓ (offline)');
        FeedbackService().onSuccess();
      }

      if (mounted) {
        setState(() => _targetController.text = result);
      }
    } catch (e) {
      FeedbackService().onError();
      final msg = _friendlyError(e);
      _setStatus(msg, isError: true);
      if (mounted) _showError(msg);
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  // ── MyMemory REST API ──────────────────────────────────────────────────────

  /// Translates [text] using the free MyMemory API.
  /// Long texts are split into ≤500-char chunks (API limit) and joined.
  Future<String> _translateViaApi(String text, String src, String tgt) async {
    const maxChunk = 490; // keep a small margin under the 500-char API limit

    if (text.length <= maxChunk) {
      return _apiChunk(text, src, tgt);
    }

    // Split into chunks at word boundaries
    final chunks = <String>[];
    int start = 0;
    while (start < text.length) {
      int end = (start + maxChunk).clamp(0, text.length);
      if (end < text.length) {
        // walk back to last whitespace to avoid splitting mid-word
        while (end > start && text[end] != ' ' && text[end] != '\n') {
          end--;
        }
        if (end == start) end = start + maxChunk; // no space found, hard split
      }
      chunks.add(text.substring(start, end).trim());
      start = end;
    }

    // Translate chunks sequentially to respect free-tier rate limit
    final buffer = StringBuffer();
    for (final chunk in chunks) {
      if (chunk.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(await _apiChunk(chunk, src, tgt));
    }
    return buffer.toString();
  }

  /// Performs a single MyMemory API call for one chunk of text.
  Future<String> _apiChunk(String text, String src, String tgt) async {
    final uri = Uri.https(
      'api.mymemory.translated.net',
      '/get',
      {'q': text, 'langpair': '$src|$tgt'},
    );

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request =
          await client.getUrl(uri).timeout(const Duration(seconds: 15));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response =
          await request.close().timeout(const Duration(seconds: 20));

      final body = await response
          .transform(const Utf8Decoder())
          .join()
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(body) as Map<String, dynamic>;
      final status = data['responseStatus'];

      if (status == 200 || status == '200') {
        final translated =
            (data['responseData'] as Map)['translatedText'] as String;
        // MyMemory occasionally returns the source language warning as text
        if (translated.toLowerCase().startsWith('mymemory warning')) {
          throw Exception('API quota reached – try again in a minute');
        }
        return translated;
      }
      throw Exception('MyMemory API returned status $status');
    } finally {
      client.close(force: false);
    }
  }

  // ── ML Kit offline fallback ───────────────────────────────────────────────

  /// Offline fallback using on-device ML Kit models.
  /// Only downloads a model if it is already on the device; never blocks on
  /// a fresh download so the offline path is truly instant.
  Future<String> _translateOffline(String text, String src, String tgt) async {
    final sourceLang = _languageCodes[src]!;
    final targetLang = _languageCodes[tgt]!;

    final modelManager = OnDeviceTranslatorModelManager();
    final srcReady = await modelManager
        .isModelDownloaded(sourceLang.bcpCode)
        .timeout(const Duration(seconds: 8), onTimeout: () => false);
    final tgtReady = await modelManager
        .isModelDownloaded(targetLang.bcpCode)
        .timeout(const Duration(seconds: 8), onTimeout: () => false);

    if (!srcReady || !tgtReady) {
      throw Exception(
          'Offline translation not available: language models are not yet '
          'downloaded. Please connect to the internet and try again.');
    }

    // Use cached translator if available, otherwise create new one
    final cacheKey = '${src}_${tgt}';
    if (!_translatorCache.containsKey(cacheKey)) {
      await _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );
      _translatorCache[cacheKey] = _translator!;
    } else {
      _translator = _translatorCache[cacheKey];
    }

    return _translator!.translateText(text).timeout(const Duration(seconds: 30),
        onTimeout: () =>
            throw TimeoutException('Offline translation timed out'));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setStatus(String msg, {bool isError = false}) {
    if (mounted) {
      setState(() {
        _statusMessage = msg;
        _statusIsError = isError;
      });
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('quota'))
      return 'Translation quota reached – try again in a minute.';
    if (s.contains('SocketException') || s.contains('internet')) {
      return 'No internet connection. Connect to the internet and try again.';
    }
    if (s.contains('TimeoutException') || s.contains('timed out')) {
      return 'Translation timed out. Check your connection and try again.';
    }
    if (s.contains('not yet downloaded')) {
      return 'Offline models not available. Please connect to the internet.';
    }
    return 'Translation failed. Please try again.';
  }

  void _swapLanguages() {
    setState(() {
      final tmp = _selectedSourceLanguage;
      _selectedSourceLanguage = _selectedTargetLanguage;
      _selectedTargetLanguage = tmp;
      final tmpText = _sourceController.text;
      _sourceController.text = _targetController.text;
      _targetController.text = tmpText;
    });
    _preloadTranslator();
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard!')),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.translation_settings ?? 'Translation'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FeedbackService().onTap();
            Navigator.pop(context);
          },
        ),
        actions: [
          // Image import button
          _isPickingImage
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : SmartIconButton(
                  icon: const Icon(Icons.add_photo_alternate),
                  onPressed: _showPickerDialog,
                  tooltip: 'Import image for OCR',
                ),
        ],
      ),
      body: Column(
        children: [
          // ── Picked image preview (optional) ─────────────────────────
          if (_pickedImagePath != null)
            SmartGestureDetector(
              onTap: () => setState(() => _pickedImagePath = null),
              child: Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_pickedImagePath!),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Import banner (no image yet) ─────────────────────────────
          if (_pickedImagePath == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SmartInkWell(
                onTap: _showPickerDialog,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_photo_alternate,
                          color: Colors.indigo[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Image for OCR',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo[700],
                              ),
                            ),
                            Text(
                              'Pick from gallery, files, USB or SD card',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.indigo[400]),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.indigo[400]),
                    ],
                  ),
                ),
              ),
            ),

          // ── Language selectors ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _LanguageDropdown(
                    label: 'Source',
                    value: _selectedSourceLanguage,
                    languages: _languageNames,
                    onChanged: (v) {
                      setState(() => _selectedSourceLanguage = v);
                      _preloadTranslator();
                    },
                  ),
                ),
                SmartIconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: _swapLanguages,
                  tooltip: 'Swap languages',
                ),
                Expanded(
                  child: _LanguageDropdown(
                    label: 'Target',
                    value: _selectedTargetLanguage,
                    languages: _languageNames,
                    onChanged: (v) {
                      setState(() => _selectedTargetLanguage = v);
                      _preloadTranslator();
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Source text + Target text (side by side on wide screens) ─
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                        child: _textPanel(
                            label: 'Original Text',
                            controller: _sourceController,
                            readOnly: false,
                            onCopy: () =>
                                _copyToClipboard(_sourceController.text))),
                    Container(width: 1, color: Colors.grey[300]),
                    Expanded(
                        child: _textPanel(
                            label: 'Translated Text',
                            controller: _targetController,
                            readOnly: true,
                            onCopy: () =>
                                _copyToClipboard(_targetController.text))),
                  ],
                );
              }
              // Narrow: vertical stacked
              return Column(
                children: [
                  Expanded(
                      child: _textPanel(
                          label: 'Original Text',
                          controller: _sourceController,
                          readOnly: false,
                          onCopy: () =>
                              _copyToClipboard(_sourceController.text))),
                  Container(height: 1, color: Colors.grey[300]),
                  Expanded(
                      child: _textPanel(
                          label: 'Translated Text',
                          controller: _targetController,
                          readOnly: true,
                          onCopy: () =>
                              _copyToClipboard(_targetController.text))),
                ],
              );
            }),
          ),

          // ── Action buttons ───────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status message (translating / error / done)
                if (_statusMessage != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusIsError ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _statusIsError
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusIsError
                              ? Icons.error_outline
                              : (_isTranslating
                                  ? Icons.sync
                                  : Icons.check_circle_outline),
                          size: 16,
                          color: _statusIsError
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _statusIsError
                                  ? Colors.red[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: SmartElevatedButton(
                    onPressed: _isTranslating ? null : _translate,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isTranslating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.translate),
                    isLoading: _isTranslating,
                    child: Text(
                      _isTranslating ? 'Translating…' : 'Translate',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textPanel({
    required String label,
    required TextEditingController controller,
    required bool readOnly,
    required VoidCallback onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              SmartIconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: controller.text.isEmpty ? null : onCopy,
                  tooltip: 'Copy',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              readOnly: readOnly,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: readOnly
                    ? 'Translation will appear here...'
                    : 'Enter text or import an image...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: readOnly,
                fillColor: readOnly ? Colors.grey[50] : Colors.transparent,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> languages;
  final ValueChanged<String> onChanged;

  const _LanguageDropdown({
    required this.label,
    required this.value,
    required this.languages,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: Container(height: 1, color: Colors.grey[300]),
          items: languages.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
