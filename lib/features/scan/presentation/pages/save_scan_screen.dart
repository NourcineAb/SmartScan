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

/// Screen shown after OCR to let the user title + categorise + save the scan.
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
    // Default title: "Scan <date>"
    final now = DateTime.now();
    _titleController = TextEditingController(
      text:
          'Scan ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
    );
    _textController = TextEditingController(text: widget.extractedText);
    _translatedTextController = TextEditingController();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _translatedTextController.dispose();
    _translator?.close();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final maps = await DatabaseService().getAllCategories();
      setState(() {
        _categories = maps.map((m) => CategoryModel.fromMap(m)).toList();
        _isLoadingCategories = false;
        // Pre-select first category if available
        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
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
      // Use translated text if available, otherwise use original text
      final textToSave = _translatedTextController.text.isNotEmpty
          ? _translatedTextController.text
          : _textController.text;

      final scanId = await ScanRepository().saveScan(
        title: title,
        imagePath: widget.imagePath,
        rawText: textToSave,
        categoryId: _selectedCategoryId,
      );

      if (mounted) {
        // Try to refresh dashboard statistics if DashboardBloc is available
        try {
          if (context.mounted) {
            context.read<DashboardBloc>().add(const RefreshDashboardEvent());
          }
        } catch (_) {
          // DashboardBloc not available in context, that's okay
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return the scan ID so parent can refresh
        FeedbackService().onSave();
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

      // Quick check (2 sec timeout) if models are available
      final srcAvailable = await modelManager
          .isModelDownloaded(sourceLang.bcpCode)
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      final tgtAvailable = await modelManager
          .isModelDownloaded(targetLang.bcpCode)
          .timeout(const Duration(seconds: 2), onTimeout: () => false);

      // If models not available, try to download them
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

        // Try to download missing models
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

      // Create translator and translate
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

  Widget _buildImagePreview() {
    try {
      return Image.file(File(widget.imagePath), fit: BoxFit.cover);
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
            // ── Image preview ──────────────────────────────────────────
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

            // ── Title ──────────────────────────────────────────────────
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

            // ── Category Picker ────────────────────────────────────────
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Document Analysis Results ──────────────────────────────
            if (widget.documentType != null && widget.documentType != 'unknown')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildInfoCard(
                  icon: Icons.document_scanner,
                  iconColor: Colors.blue,
                  title: 'Document Type',
                  content: '${widget.documentType} ${widget.documentTypeConfidence != null ? '(${(widget.documentTypeConfidence! * 100).toStringAsFixed(0)}%)' : ''}',
                ),
              ),

            if (widget.detectedLanguage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildInfoCard(
                  icon: Icons.language,
                  iconColor: Colors.green,
                  title: 'Detected Language',
                  content: widget.detectedLanguage!.toUpperCase(),
                ),
              ),

            // ── Extracted Entities ────────────────────────────────────
            if (widget.entities != null && widget.entities!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Entities',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

            // ── Extracted Text ─────────────────────────────────────────
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
                        onPressed: () =>
                            setState(() => _isEditingText = !_isEditingText),
                        icon: Icon(
                          _isEditingText ? Icons.check : Icons.edit,
                          size: 16,
                        ),
                        label: Text(
                            _isEditingText ? 'Done' : 'Edit Text (Optional)'),
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
                          constraints: const BoxConstraints(maxHeight: 160),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _textController.text.isEmpty
                                  ? 'No text detected'
                                  : _textController.text,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Optional Translation ────────────────────────────────────
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
                    // Language selectors
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('From',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600])),
                              DropdownButton<String>(
                                value: _sourceLanguage,
                                isExpanded: true,
                                underline: Container(
                                    height: 1, color: Colors.grey[300]),
                                items: _languageNames.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _sourceLanguage = v);
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
                                      fontSize: 11, color: Colors.grey[600])),
                              DropdownButton<String>(
                                value: _targetLanguage,
                                isExpanded: true,
                                underline: Container(
                                    height: 1, color: Colors.grey[300]),
                                items: _languageNames.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _targetLanguage = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Translate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isTranslating ? null : _translateText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        icon: _isTranslating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
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
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black87),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            entity.text.length > 20 ? '${entity.text.substring(0, 20)}...' : entity.text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
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
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'url':
        return Icons.link;
      case 'date':
        return Icons.calendar_today;
      case 'location':
      case 'address':
        return Icons.location_on;
      case 'price':
        return Icons.attach_money;
      default:
        return Icons.label;
    }
  }
}
