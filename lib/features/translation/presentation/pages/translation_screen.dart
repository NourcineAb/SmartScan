import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:smart_scan/features/scan/data/services/ocr_service.dart';
import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';
import 'package:smart_scan/core/services/feedback_service.dart';
import 'package:smart_scan/core/services/connectivity_service.dart';
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
  bool _isSavingTranslation = false;
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

    // Preload translator for default language pair only (in background)
    // Avoids downloading all 9 languages which causes slowdown
    _preloadTranslator();
  }

  /// Download specific language model in background WITHOUT blocking UI.
  /// Fire-and-forget: doesn't update UI or wait for download.
  void _downloadModelInBackground(String langCode) {
    // Use Future.delayed to ensure the task is queued properly
    Future.delayed(Duration.zero, () async {
      try {
        final modelManager = OnDeviceTranslatorModelManager();
        final isReady = await modelManager
            .isModelDownloaded(langCode)
            .timeout(const Duration(seconds: 1), onTimeout: () => false);
        if (!isReady) {
          debugPrint('⏳ Downloading model for $langCode...');
          await modelManager.downloadModel(langCode).timeout(
                const Duration(minutes: 5),
              );
          debugPrint('✅ Downloaded model for $langCode');
        }
      } catch (e) {
        debugPrint('⚠️ Could not download $langCode: $e');
        // Silently fail - user can use online translation
      }
    });
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
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).textTheme.titleLarge?.color,
                ),
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

      // Quick check if models are available (fail fast - 1 sec timeout)
      final modelManager = OnDeviceTranslatorModelManager();
      final srcReady = await modelManager
          .isModelDownloaded(sourceLang.bcpCode)
          .timeout(const Duration(seconds: 1), onTimeout: () => false);
      final tgtReady = await modelManager
          .isModelDownloaded(targetLang.bcpCode)
          .timeout(const Duration(seconds: 1), onTimeout: () => false);

      if (srcReady && tgtReady) {
        // Models available – preload translator
        await _translator?.close();
        _translator = OnDeviceTranslator(
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );
        _translatorCache[cacheKey] = _translator!;
      } else {
        // Models not available - download them in background (don't block UI)
        if (!srcReady) _downloadModelInBackground(sourceLang.bcpCode);
        if (!tgtReady) _downloadModelInBackground(targetLang.bcpCode);
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

  /// Entry point: Smart strategy based on connectivity
  /// - No internet: Use offline ML Kit directly (fast, no timeout)
  /// - Has internet: Try online API first, then fall back to offline
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
      String result;

      // Check internet connectivity first
      final hasInternet = await ConnectivityService().hasInternetConnection();

      if (!hasInternet) {
        // ── NO INTERNET: Use offline translation directly ──────────────────
        debugPrint('📡 No internet detected - using offline translation');
        _setStatus('⏳ Offline mode: translating…');
        result = await _translateOffline(
          text,
          _selectedSourceLanguage,
          _selectedTargetLanguage,
        );
        _setStatus('✓ Offline translation complete');
        await FeedbackService().onSuccess();
      } else {
        // ── HAS INTERNET: Try online first, then offline fallback ──────────
        _setStatus('Translating…');
        try {
          debugPrint('📡 Internet available - trying online translation');
          result = await _translateViaApi(
            text,
            _selectedSourceLanguage,
            _selectedTargetLanguage,
          ).timeout(const Duration(seconds: 5));
          _setStatus('✓ Translation complete');
          await FeedbackService().onSuccess();
        } catch (onlineError) {
          debugPrint(
              'Online translation failed: $onlineError - trying offline');
          // Online failed or timed out - try offline
          try {
            _setStatus('⏳ Using offline translation…');
            result = await _translateOffline(
              text,
              _selectedSourceLanguage,
              _selectedTargetLanguage,
            );
            _setStatus('✓ Offline translation done');
            await FeedbackService().onSuccess();
          } catch (offlineError) {
            // Both failed - give helpful error
            throw Exception('Translation unavailable. '
                'No internet - connect to WiFi for online translation.');
          }
        }
      }

      if (mounted) {
        setState(() => _targetController.text = result);
      }
    } catch (e) {
      await FeedbackService().onError();
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
  /// Uses short timeouts to fail fast if no internet.
  Future<String> _apiChunk(String text, String src, String tgt) async {
    final uri = Uri.https(
      'api.mymemory.translated.net',
      '/get',
      {'q': text, 'langpair': '$src|$tgt'},
    );

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final request =
          await client.getUrl(uri).timeout(const Duration(seconds: 3));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response =
          await request.close().timeout(const Duration(seconds: 5));

      final body = await response
          .transform(const Utf8Decoder())
          .join()
          .timeout(const Duration(seconds: 5));

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
  /// If models aren't available, tries to download them.
  Future<String> _translateOffline(String text, String src, String tgt) async {
    final sourceLang = _languageCodes[src]!;
    final targetLang = _languageCodes[tgt]!;

    final modelManager = OnDeviceTranslatorModelManager();

    // Quick check (2 sec timeout) if models exist - fail fast if not
    final srcReady = await modelManager
        .isModelDownloaded(sourceLang.bcpCode)
        .timeout(const Duration(seconds: 2), onTimeout: () => false);
    final tgtReady = await modelManager
        .isModelDownloaded(targetLang.bcpCode)
        .timeout(const Duration(seconds: 2), onTimeout: () => false);

    if (!srcReady || !tgtReady) {
      // Models not available - try to download them NOW
      try {
        _setStatus('⏳ Downloading translation models...');
        if (!srcReady) {
          debugPrint('Downloading model for ${sourceLang.bcpCode}...');
          await modelManager.downloadModel(sourceLang.bcpCode).timeout(
                const Duration(minutes: 3),
              );
        }
        if (!tgtReady) {
          debugPrint('Downloading model for ${targetLang.bcpCode}...');
          await modelManager.downloadModel(targetLang.bcpCode).timeout(
                const Duration(minutes: 3),
              );
        }
        debugPrint('✅ Models downloaded, retrying translation...');
      } catch (e) {
        debugPrint('Could not download models: $e');
        throw Exception('Models not available - use internet for translation');
      }
    }

    // Use cached translator if available
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

    // Translate with 10 second timeout
    return _translator!.translateText(text).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Translation timed out'),
        );
  }

  // ── Save Translation ───────────────────────────────────────────────────────

  Future<void> _saveTranslation() async {
    if (_sourceController.text.isEmpty || _targetController.text.isEmpty) {
      _setStatus('Nothing to save - translate first', isError: true);
      return;
    }

    setState(() => _isSavingTranslation = true);

    try {
      await ScanRepository().saveTranslation(
        sourceLanguage: _selectedSourceLanguage,
        targetLanguage: _selectedTargetLanguage,
        originalText: _sourceController.text,
        translatedText: _targetController.text,
      );

      if (mounted) {
        _setStatus('✓ Translation saved to history');
        await FeedbackService().onSuccess();

        // Clear fields after saving
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _sourceController.clear();
              _targetController.clear();
              _statusMessage = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _setStatus('Error saving: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSavingTranslation = false);
    }
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
    final s = e.toString().toLowerCase();

    // Check for connection issues
    if (s.contains('socket') || s.contains('failed host lookup')) {
      return '📡 No internet - connect to WiFi for translation';
    }
    if (s.contains('timeout') || s.contains('timed out')) {
      return '⏱️ Connection too slow - try again';
    }
    // Check for offline model issues
    if (s.contains('model') || s.contains('not available')) {
      return '📥 Offline models not downloaded - use internet';
    }
    if (s.contains('unsupported') || s.contains('language')) {
      return 'Language pair not supported';
    }
    if (s.contains('unavailable')) {
      return '📡 No internet - connect to WiFi for translation';
    }

    return 'Translation failed - try again';
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

  /// Get save button label based on application language
  String _getSaveButtonLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return l10n?.save_scan ?? 'Save';
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
      resizeToAvoidBottomInset: true,
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
                  border: Border.all(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.3)),
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
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_photo_alternate,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Image for OCR',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Text(
                              'Pick from gallery, files, USB or SD card',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.7)),
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
          // ── Source text + Target text ─
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
                    Container(width: 1, color: Theme.of(context).dividerColor),
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
              return Column(
                children: [
                  Expanded(
                      child: _textPanel(
                          label: 'Original Text',
                          controller: _sourceController,
                          readOnly: false,
                          onCopy: () =>
                              _copyToClipboard(_sourceController.text))),
                  Container(height: 1, color: Theme.of(context).dividerColor),
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
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _statusIsError
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _statusIsError
                              ? Colors.red.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.3),
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
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
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
                              _isTranslating
                                  ? (AppLocalizations.of(context)?.processing ??
                                      'Translating…')
                                  : (AppLocalizations.of(context)
                                          ?.action_translation ??
                                      'Translate'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      if (_targetController.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: SmartElevatedButton(
                              onPressed: _isSavingTranslation
                                  ? null
                                  : _saveTranslation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: _isSavingTranslation
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save),
                              isLoading: _isSavingTranslation,
                              child: Text(
                                _isSavingTranslation
                                    ? (AppLocalizations.of(context)
                                            ?.processing ??
                                        'Saving…')
                                    : _getSaveButtonLabel(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          )
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
            child: ClipRect(
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: readOnly,
                  fillColor: readOnly
                      ? Theme.of(context).cardColor
                      : Colors.transparent,
                  contentPadding: const EdgeInsets.all(12),
                ),
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
        Text(label,
            style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline:
              Container(height: 1, color: Theme.of(context).dividerColor),
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
