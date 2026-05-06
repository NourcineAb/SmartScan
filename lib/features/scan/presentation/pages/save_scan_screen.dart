import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:smart_scan/core/services/database_service.dart';
import 'package:smart_scan/features/scan/data/repositories/scan_repository.dart';
import 'package:smart_scan/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_scan/shared/models/category_model.dart';
import 'package:smart_scan/shared/models/entity_model.dart';
import 'package:smart_scan/shared/models/bounding_box_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/core/services/feedback_service.dart';
import 'package:smart_scan/core/theme/app_colors.dart';
import 'package:smart_scan/l10n/app_localizations.dart';
import 'package:smart_scan/core/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:smart_scan/core/services/gemini_service.dart';
import 'package:smart_scan/core/services/document_type_service.dart';

class SaveScanScreen extends StatefulWidget {
  final String imagePath;
  final String extractedText;
  final List<EntityModel>? entities;
  final String? detectedLanguage;
  final String? documentType;
  final double? documentTypeConfidence;
  final List<BoundingBoxModel>? boundingBoxes;
  final Map<String, double>? smartCropRegion;
  final int? imageWidth;
  final int? imageHeight;
  final List<String>? additionalImages;

  const SaveScanScreen({
    super.key,
    required this.imagePath,
    required this.extractedText,
    this.entities,
    this.detectedLanguage,
    this.documentType,
    this.documentTypeConfidence,
    this.boundingBoxes,
    this.smartCropRegion,
    this.imageWidth,
    this.imageHeight,
    this.additionalImages,
  });

  @override
  State<SaveScanScreen> createState() => _SaveScanScreenState();
}

class _SaveScanScreenState extends State<SaveScanScreen> {
  late TextEditingController _titleController;
  late TextEditingController _textController;
  late TextEditingController _translatedTextController;
  bool _isEditingText = false;
  bool _showTranslation = false;
  bool _isTranslating = false;
  String? _selectedCategoryId;
  String _sourceLanguage = 'en';
  String _targetLanguage = 'fr';
  OnDeviceTranslator? _translator;
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;
  String? _suggestedCategoryName;
  bool _suggestedCategoryExists = false;
  String? _aiSummary;
  bool _isGeneratingSummary = false;
  bool _hasGeminiApiKey = false;
  final _geminiService = GeminiService();
  ImageProvider? _previewProvider;

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
    final now = DateTime.now();
    _titleController = TextEditingController(
      text:
          'Scan ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
    );
    _textController = TextEditingController(text: widget.extractedText);
    _translatedTextController = TextEditingController();
    _loadCategories();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await _geminiService.hasApiKey();
    if (mounted) {
      setState(() {
        _hasGeminiApiKey = hasKey;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _translatedTextController.dispose();
    _translator?.close();

    _previewProvider?.evict();
    _previewProvider = null;

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final maps = await DatabaseService().getAllCategories();
      setState(() {
        _categories = maps.map((m) => CategoryModel.fromMap(m)).toList();
        _isLoadingCategories = false;

        if (widget.documentType != null && widget.documentType != 'unknown') {
          // Use proper display name from DocumentTypeService
          _suggestedCategoryName = DocumentTypeService().getDisplayName(widget.documentType!);
          _suggestedCategoryExists = false;

          final docTypeStr = widget.documentType!.toLowerCase();
          for (final cat in _categories) {
            if (cat.name.toLowerCase().contains(docTypeStr) ||
                (docTypeStr == 'invoice' &&
                    cat.name.toLowerCase().contains('facture')) ||
                (docTypeStr == 'receipt' &&
                    cat.name.toLowerCase().contains('ticket'))) {
              _selectedCategoryId = cat.id;
              _suggestedCategoryExists = true;
              break;
            }
          }
        } else if (_categories.isNotEmpty && _selectedCategoryId == null) {
          _selectedCategoryId = _categories.first.id;
        }
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  String _capitalize(String s) =>
      s[0].toUpperCase() + s.substring(1).toLowerCase();

  Future<void> _createAndSelectSuggestedCategory() async {
    if (_suggestedCategoryName == null) return;

    FeedbackService().onTap();

    IconData icon = Icons.description;
    int colorValue = Colors.indigo.value;

    final type = _suggestedCategoryName!.toLowerCase();
    if (type.contains('invoice') || type.contains('facture')) {
      icon = Icons.receipt_long;
      colorValue = Colors.red.value;
    } else if (type.contains('receipt') || type.contains('ticket')) {
      icon = Icons.receipt;
      colorValue = Colors.orange.value;
    } else if (type.contains('id') ||
        type.contains('passport') ||
        type.contains('carte')) {
      icon = Icons.badge;
      colorValue = Colors.blue.value;
    }

    final newCat = CategoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _suggestedCategoryName!,
      icon: _getIconName(icon),
      color: colorValue,
      createdAt: DateTime.now(),
    );

    await DatabaseService().insertCategory(newCat.toMap());
    await _loadCategories();

    setState(() {
      _selectedCategoryId = newCat.id;
      _suggestedCategoryExists = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Category "${newCat.name}" created and selected!')),
      );
    }
  }

  String _getIconName(IconData icon) {
    if (icon == Icons.receipt_long) return 'receipt';
    if (icon == Icons.receipt) return 'receipt';
    if (icon == Icons.badge) return 'confirmation_number';
    return 'description';
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final rawTextToSave = _textController.text;
      final summaryToSave = _aiSummary;
      final translatedTextToSave = _translatedTextController.text.isNotEmpty
          ? _translatedTextController.text
          : null;
      final targetLangToSave =
          translatedTextToSave != null ? _targetLanguage : null;

      final scanId = await ScanRepository().saveScan(
        title: title,
        imagePath: widget.imagePath,
        rawText: rawTextToSave,
        summary: summaryToSave,
        translatedText: translatedTextToSave,
        detectedLanguage: widget.detectedLanguage,
        targetLanguage: targetLangToSave,
        categoryId: _selectedCategoryId,
        entities: widget.entities,
        boundingBoxes: widget.boundingBoxes,
        documentType: widget.documentType,
        documentTypeConfidence: widget.documentTypeConfidence,
        imageWidth: widget.imageWidth,
        imageHeight: widget.imageHeight,
        additionalImages: widget.additionalImages,
      );

      if (mounted) {
        try {
          if (context.mounted) {
            context.read<DashboardBloc>().add(const RefreshDashboardEvent());
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        FeedbackService().onSave();

        _textController.clear();
        _translatedTextController.clear();
        _titleController.clear();
        _aiSummary = null;

        Navigator.of(context).pop({'saved': true, 'scanId': scanId});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving scan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _translateText() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No text to translate'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isTranslating = true);
    _translatedTextController.clear();

    try {
      final sourceLang = _languageCodes[_sourceLanguage]!;
      final targetLang = _languageCodes[_targetLanguage]!;

      final modelManager = OnDeviceTranslatorModelManager();

      final srcAvailable = await modelManager
          .isModelDownloaded(sourceLang.bcpCode)
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      final tgtAvailable = await modelManager
          .isModelDownloaded(targetLang.bcpCode)
          .timeout(const Duration(seconds: 2), onTimeout: () => false);

      if (!srcAvailable || !tgtAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏳ Downloading translation models...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }

        try {
          if (!srcAvailable) {
            await modelManager.downloadModel(sourceLang.bcpCode).timeout(
                  const Duration(minutes: 5),
                  onTimeout: () => throw TimeoutException(
                      'Source language model download timeout - check your internet'),
                );
          }
          if (!tgtAvailable) {
            await modelManager.downloadModel(targetLang.bcpCode).timeout(
                  const Duration(minutes: 5),
                  onTimeout: () => throw TimeoutException(
                      'Target language model download timeout - check your internet'),
                );
          }
        } catch (downloadError) {
          if (mounted) {
            final msg = downloadError is TimeoutException
                ? '⏱️ Model download too slow - try with better WiFi'
                : '📡 Cannot download models - try later with internet';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          rethrow;
        }
      }

      await _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );

      final result =
          await _translator!.translateText(_textController.text).timeout(
                const Duration(seconds: 10),
                onTimeout: () =>
                    throw TimeoutException('Translation took too long'),
              );

      if (mounted) {
        setState(() => _translatedTextController.text = result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Translation complete!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await FeedbackService().onSuccess();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg;
        if (e is TimeoutException) {
          errorMsg = '⏱️ Translation timeout - try with shorter text';
        } else if (e.toString().contains('Model')) {
          errorMsg =
              '📥 Models not ready - use internet or try main translation screen';
        } else if (e.toString().contains('Socket')) {
          errorMsg = '📡 No internet - connect for translation';
        } else {
          errorMsg = '❌ Translation failed - try again';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        await FeedbackService().onError();
      }
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _generateSummary() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      final String languageCode =
          Localizations.localeOf(context).languageCode;

      final String geminiInput = _textController.text.length > 12000
          ? '${_textController.text.substring(0, 12000)}... [Truncated]'
          : _textController.text;

      final result = await GeminiService()
          .generateSummaryAndCategory(geminiInput, targetLanguage: languageCode);

      if (mounted && result != null) {
        setState(() {
          _aiSummary = result['summary'];

          if (result['category'] != null && result['category']!.isNotEmpty) {
            _suggestedCategoryName = _capitalize(result['category']!);
            _suggestedCategoryExists = false;

            final docTypeStr = result['category']!.toLowerCase();
            for (final cat in _categories) {
              if (cat.name.toLowerCase().contains(docTypeStr) ||
                  (docTypeStr == 'invoice' &&
                      cat.name.toLowerCase().contains('facture')) ||
                  (docTypeStr == 'receipt' &&
                      cat.name.toLowerCase().contains('ticket'))) {
                _selectedCategoryId = cat.id;
                _suggestedCategoryExists = true;
                break;
              }
            }
          }
        });
        await FeedbackService().onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate summary')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSummary = false;
        });
      }
    }
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (_aiSummary == null && !_isGeneratingSummary)
                TextButton.icon(
                  onPressed: _hasGeminiApiKey ? _generateSummary : null,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_hasGeminiApiKey ? 'Generate' : 'Key Missing'),
                  style: TextButton.styleFrom(
                    foregroundColor: _hasGeminiApiKey ? Colors.indigo : Colors.grey,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isGeneratingSummary)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_aiSummary != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _aiSummary!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _aiSummary = null),
                      child: const Text('Clear',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              'No summary generated yet.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    try {
      _previewProvider ??= ResizeImage(
        FileImage(File(widget.imagePath)),
        width: 800,
      );

      return Image(
        image: _previewProvider!,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Scan'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FeedbackService().onTap();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImagePreview(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Title',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter document title...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingCategories
                      ? const Center(child: CircularProgressIndicator())
                      : _categories.isEmpty
                          ? const Text(
                              'No categories found',
                              style: TextStyle(color: Colors.grey),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((cat) {
                                final isSelected =
                                    _selectedCategoryId == cat.id;
                                return GestureDetector(
                                  onTap: () {
                                    FeedbackService().onTap();
                                    setState(
                                        () => _selectedCategoryId = cat.id);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(cat.color)
                                          : Color(cat.color)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Color(cat.color),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getIconData(cat.icon),
                                          size: 16,
                                          color: isSelected
                                              ? Colors.white
                                              : Color(cat.color),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          cat.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : Color(cat.color),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                  if (!_suggestedCategoryExists &&
                      _suggestedCategoryName != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _createAndSelectSuggestedCategory,
                      icon:
                          const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(
                          'Create & Select category "$_suggestedCategoryName"'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo,
                        side: const BorderSide(color: Colors.indigo),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (widget.documentType != null &&
                widget.documentType != 'unknown')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildInfoCard(
                  icon: Icons.document_scanner,
                  iconColor: Colors.blue,
                  title: 'Document Type',
                  content:
                      '${widget.documentType} ${widget.documentTypeConfidence != null ? '(${(widget.documentTypeConfidence! * 100).toStringAsFixed(0)}%)' : ''}',
                ),
              ),

            if (widget.detectedLanguage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: _buildInfoCard(
                  icon: Icons.language,
                  iconColor: Colors.green,
                  title: 'Detected Language',
                  content: widget.detectedLanguage!.toUpperCase(),
                ),
              ),

            if (widget.entities != null && widget.entities!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Entities',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.entities!.map((entity) {
                        return _buildEntityChip(entity);
                      }).toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // AI Summary Section
            _buildSummarySection(),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Extracted Text',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(
                            () => _isEditingText = !_isEditingText),
                        icon: Icon(
                          _isEditingText ? Icons.check : Icons.edit,
                          size: 16,
                        ),
                        label: Text(_isEditingText
                            ? 'Done'
                            : 'Edit Text (Optional)'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _isEditingText
                      ? TextField(
                          controller: _textController,
                          maxLines: 8,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          constraints:
                              const BoxConstraints(maxHeight: 160),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _textController.text.isEmpty
                                  ? 'No text detected'
                                  : _textController.text,
                              style: TextStyle(
                                  fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Optional Translation',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Switch(
                        value: _showTranslation,
                        onChanged: (value) =>
                            setState(() => _showTranslation = value),
                      ),
                    ],
                  ),
                  if (_showTranslation) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('From',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600])),
                              DropdownButton<String>(
                                value: _sourceLanguage,
                                isExpanded: true,
                                underline: Container(
                                    height: 1,
                                    color: Colors.grey[300]),
                                items: _languageNames.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(
                                        () => _sourceLanguage = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('To',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600])),
                              DropdownButton<String>(
                                value: _targetLanguage,
                                isExpanded: true,
                                underline: Container(
                                    height: 1,
                                    color: Colors.grey[300]),
                                items: _languageNames.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(
                                        () => _targetLanguage = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isTranslating ? null : _translateText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        icon: _isTranslating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.translate, size: 18),
                        label: Text(
                          _isTranslating
                              ? 'Translating...'
                              : 'Suggest Translation',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    if (_translatedTextController.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        constraints:
                            const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.green.shade200),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Suggested Translation',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _translatedTextController.text,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Scan',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    const map = {
      'receipt': Icons.receipt,
      'shopping_cart': Icons.shopping_cart,
      'credit_card': Icons.credit_card,
      'description': Icons.description,
      'folder': Icons.folder,
      'confirmation_number': Icons.confirmation_number,
      'label': Icons.label,
      'category': Icons.category,
      'image': Icons.image,
      'note': Icons.note,
      'assignment': Icons.assignment,
    };
    return map[iconName] ?? Icons.category;
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityChip(EntityModel entity) {
    final color = _getEntityColor(entity.type);
    final icon = _getEntityIcon(entity.type);
    final isDate = entity.type.toLowerCase() == 'date';

    return GestureDetector(
      onTap: () {
        FeedbackService().onTap();
        if (isDate) {
          _showDateReminderDialog(entity.text);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Copied: ${entity.text}')),
          );
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDate ? color : color.withValues(alpha: 0.5),
            width: isDate ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              entity.text.length > 20
                  ? '${entity.text.substring(0, 20)}...'
                  : entity.text,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isDate ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
            if (isDate) ...[
              const SizedBox(width: 4),
              Icon(Icons.notifications_active_outlined,
                  color: color, size: 12),
            ],
          ],
        ),
      ),
    );
  }

  void _showDateReminderDialog(String dateText) {
    DateTime? parsedDate;
    try {
      final cleanedDate =
          dateText.replaceAll(RegExp(r'[^0-9/.-]'), ' ').trim();
      if (cleanedDate.contains('/')) {
        final parts = cleanedDate.split('/');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          if (year < 100) year += 2000;
          parsedDate = DateTime(year, month, day);
        }
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Do you want to set a reminder for this date?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(dateText,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              DateTime reminderDate = parsedDate ??
                  DateTime.now().add(const Duration(days: 1));
              if (reminderDate.isBefore(DateTime.now())) {
                reminderDate =
                    DateTime.now().add(const Duration(days: 1));
              }

              final finalDate = DateTime(reminderDate.year,
                  reminderDate.month, reminderDate.day, 9, 0);

              await NotificationService().scheduleDateReminder(
                title: _titleController.text,
                body: 'Reminder for document date: $dateText',
                scheduledDate: finalDate,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Reminder set for ${DateFormat('yyyy-MM-dd HH:mm').format(finalDate)}'),
                    backgroundColor: Colors.indigo,
                  ),
                );
              }
            },
            child: const Text('Set Reminder (9 AM)'),
          ),
        ],
      ),
    );
  }

  Color _getEntityColor(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return AppColors.entityEmail;
      case 'phone':
        return AppColors.entityPhone;
      case 'url':
        return AppColors.entityUrl;
      case 'date':
        return AppColors.entityDate;
      case 'location':
      case 'address':
        return AppColors.entityLocation;
      case 'price':
        return AppColors.entityPrice;
      default:
        return AppColors.primary;
    }
  }

  IconData _getEntityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return Icons.alternate_email;
      case 'phone':
        return Icons.call;
      case 'url':
        return Icons.language;
      case 'date':
        return Icons.event;
      case 'location':
      case 'address':
        return Icons.place;
      case 'price':
        return Icons.payments_outlined;
      default:
        return Icons.label_important_outline;
    }
  }
}
