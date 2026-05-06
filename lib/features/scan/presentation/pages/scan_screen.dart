import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_scan/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:smart_scan/l10n/app_localizations.dart';
import '../../data/services/ocr_service.dart';
import '../../../../core/services/entity_extraction_service.dart';
import '../../../../core/services/document_type_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/lifecycle_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/foreground_scan_service.dart';
import 'save_scan_screen.dart';

enum ScanMode { single, batch }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isProcessing = false;
  ScanMode? _selectedMode;

  final _ocrService = OCRService();
  final _languageService = LanguageService();
  final _entityService = EntityExtractionService();
  final _docTypeService = DocumentTypeService();
  final _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _logMemory('ScanScreen initialized');
  }

  @override
  void dispose() {
    _ocrService.reset();
    _languageService.reset();
    _entityService.reset();
    super.dispose();
  }

  void _logMemory(String step) {
    final rss = ProcessInfo.currentRss;
    final mb = (rss / 1024 / 1024).toStringAsFixed(2);
    dev.log('💾 MEMORY LOG [$step]: ${mb}MB', name: 'SmartScan.Memory');
    debugPrint('💾 MEMORY LOG [$step]: ${mb}MB');
  }

  void _deepCleanMemory() {
    _logMemory('Deep Clean Start');
    _ocrService.reset();
    _languageService.reset();
    _entityService.reset();

    PaintingBinding.instance.imageCache.maximumSize = 0;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Nudge Dart GC
    try {
      // ignore: unused_local_variable
      final _ = List.filled(1024 * 1024, 0);
    } catch (_) {}

    _logMemory('Deep Clean End');
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<String> imagePaths = [];

      if (_selectedMode == ScanMode.single) {
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) imagePaths.add(image.path);
      } else {
        final List<XFile> images = await picker.pickMultiImage();
        if (images.isNotEmpty) imagePaths.addAll(images.map((e) => e.path));
      }

      if (imagePaths.isEmpty) return;

      _deepCleanMemory();
      PaintingBinding.instance.imageCache.maximumSize = 50;

      await _runOCRPipeline(imagePaths);
    } catch (e) {
      debugPrint('Gallery picking error: $e');
    }
  }

  Future<void> _startScanner(ScanMode mode) async {
    _logMemory('Starting Scanner (Mode: ${mode.name})');
    DocumentScanner? documentScanner;

    try {
      _deepCleanMemory();

      AppLifecycleService().isScannerActive = true;

      _logMemory('Post-Service-Reset (Cache Disabled)');

      try {
        await ForegroundScanService.start();
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
      } catch (e) {
        debugPrint('Warning: Anti-suspension setup failed: $e');
      }

      await Future.delayed(const Duration(milliseconds: 400));
      _logMemory('Post-GC-Delay');

      final DocumentScannerOptions options = DocumentScannerOptions(
        mode: ScannerMode.full,
        pageLimit: mode == ScanMode.single ? 1 : 15,
      );
      documentScanner = DocumentScanner(options: options);

      DocumentScanningResult? result;
      try {
        result = await documentScanner.scanDocument();
      } catch (e) {
        _logMemory('Scanner Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scanner Error: $e')),
          );
        }
        return;
      } finally {
        AppLifecycleService().isScannerActive = false;

        try {
          await ForegroundScanService.stop();
          await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        } catch (_) {}

        try {
          documentScanner.close();
        } catch (_) {}
        documentScanner = null;
      }

      _logMemory('Scanner closed');

      if (result == null || result.images == null || result.images!.isEmpty) {
        _logMemory('No images captured');
        if (mounted) setState(() => _selectedMode = null);
        return;
      }

      final List<String> imagePaths = List<String>.from(result.images!);
      result = null;

      if (mounted) setState(() => _isProcessing = true);

      _logMemory('Captured ${imagePaths.length} images. Restoring Cache.');

      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 512 * 1024 * 1024;

      await Future.delayed(const Duration(milliseconds: 600));

      await _runOCRPipeline(imagePaths);
    } catch (e, stack) {
      _logMemory('CRITICAL OCR PIPELINE ERROR: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedMode = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Processing Failed: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // Safety net: close scanner if an exception escaped the inner try.
      try {
        documentScanner?.close();
      } catch (_) {}
      documentScanner = null;
      _logMemory('Scanner disposed in finally');

      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 512 * 1024 * 1024;
    }
  }

  Future<void> _runOCRPipeline(List<String> imagePaths) async {
    try {
      if (!mounted) return;

      _logMemory('Starting OCR Pipeline');
      final StringBuffer combinedText = StringBuffer();

      // Process first page
      _logMemory('Processing Page 1');
      final firstOcrResult =
          await _ocrService.extractStructuredText(imagePaths.first);
      combinedText.writeln(firstOcrResult.fullText);
      _logMemory('Page 1 OCR Done');

      // Process additional pages
      for (int i = 1; i < imagePaths.length; i++) {
        _logMemory('Preparing Page ${i + 1}');
        await Future.delayed(const Duration(milliseconds: 500));

        _logMemory('OCR Start: Page ${i + 1}');
        final pageResult =
            await _ocrService.extractStructuredText(imagePaths[i]);
        combinedText
          ..writeln('\n--- Page ${i + 1} ---\n')
          ..writeln(pageResult.fullText);
        _logMemory('OCR End: Page ${i + 1}');

        if (i % 3 == 0) {
          _logMemory('Periodic Cleanup Triggered');
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        }
      }

      String fullText = combinedText.toString();
      _logMemory('Full combined text length: ${fullText.length}');



      _logMemory('Detecting Language');
      final detectedLanguage =
          await _languageService.detectLanguage(fullText);

      _logMemory('Extracting Entities');
      final entities = await _entityService.extractEntities(fullText);

      _logMemory('Detecting Doc Type');
      final docTypeResult =
          _docTypeService.detectDocumentType(fullText, entities);

      _logMemory('Pipeline Complete, Navigating to Save');

      if (!mounted) return;

      _ocrService.reset();
      _languageService.reset();
      _entityService.reset();

      _navigateToSave(
        extractedText: fullText,
        imagePath: firstOcrResult.imagePath.isNotEmpty
            ? firstOcrResult.imagePath
            : imagePaths.first,
        boundingBoxes: firstOcrResult.elements,
        entities: entities,
        detectedLanguage: detectedLanguage,
        documentType: docTypeResult.type,
        documentTypeConfidence: docTypeResult.confidence,
        imageWidth: firstOcrResult.imageWidth,
        imageHeight: firstOcrResult.imageHeight,
        additionalImages: imagePaths,
      );
    } catch (e) {
      _logMemory('Pipeline Error: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing error: $e')),
        );
      }
    }
  }

  void _navigateToSave({
    required String extractedText,
    required String imagePath,
    var boundingBoxes,
    var entities,
    String? detectedLanguage,
    String? documentType,
    double? documentTypeConfidence,
    int? imageWidth,
    int? imageHeight,
    List<String>? additionalImages,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          try {
            final dashboardBloc = context.read<DashboardBloc>();
            return BlocProvider.value(
              value: dashboardBloc,
              child: SaveScanScreen(
                extractedText: extractedText,
                imagePath: imagePath,
                boundingBoxes: boundingBoxes,
                entities: entities,
                detectedLanguage: detectedLanguage,
                documentType: documentType,
                documentTypeConfidence: documentTypeConfidence,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                additionalImages: additionalImages,
              ),
            );
          } catch (_) {
            return SaveScanScreen(
              extractedText: extractedText,
              imagePath: imagePath,
              boundingBoxes: boundingBoxes,
              entities: entities,
              detectedLanguage: detectedLanguage,
              documentType: documentType,
              documentTypeConfidence: documentTypeConfidence,
              imageWidth: imageWidth,
              imageHeight: imageHeight,
              additionalImages: additionalImages,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isProcessing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Text(
                l10n?.processing ?? 'Processing...',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzing document...',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.scan_new ?? 'New Scan'),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.document_scanner,
                size: 80, color: Colors.indigo),
            const SizedBox(height: 24),
            Text(
              l10n?.scan_mode_selection_title ?? 'Choose Scan Mode',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildModeCard(
              mode: ScanMode.single,
              title: l10n?.scan_mode_single ?? 'Single Page',
              description: l10n?.scan_mode_single_desc ??
                  'Scan one page and process it immediately',
              icon: Icons.filter_1,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildModeCard(
              mode: ScanMode.batch,
              title: l10n?.scan_mode_batch ?? 'Batch Mode',
              description: l10n?.scan_mode_batch_desc ??
                  'Scan multiple pages and process them all at once',
              icon: Icons.filter_none,
              color: Colors.orange,
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _selectedMode == null
                      ? null
                      : () => _startScanner(_selectedMode!),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        l10n?.start_scan_button ?? 'Start Scanning',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _selectedMode == null ? null : _pickFromGallery,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.indigo),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _selectedMode == ScanMode.batch
                            ? (l10n?.upload_batch ?? 'Upload multiple images')
                            : (l10n?.upload_single ?? 'Upload from Gallery'),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required ScanMode mode,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          color: isSelected
              ? color.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
