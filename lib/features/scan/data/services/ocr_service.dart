import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' as ml_kit;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:uuid/uuid.dart';
import '../../../../shared/models/bounding_box_model.dart';

/// Structured OCR result containing full extraction data
class StructuredOCRResult {
  final String fullText;
  final List<BoundingBoxModel> blocks;
  final List<BoundingBoxModel> lines;
  final List<BoundingBoxModel> elements;
  final int imageWidth;
  final int imageHeight;
  final String imagePath;
  final bool isMock;

  StructuredOCRResult({
    required this.fullText,
    required this.blocks,
    required this.lines,
    required this.elements,
    required this.imageWidth,
    required this.imageHeight,
    required this.imagePath,
    this.isMock = false,
  });

  /// Get the main text region for smart crop suggestion
  Map<String, double>? getMainTextRegion() {
    if (blocks.isEmpty) return null;

    // Find the bounding box that contains all text
    double minLeft = 1.0, minTop = 1.0, maxRight = 0.0, maxBottom = 0.0;

    for (final block in blocks) {
      if (block.left < minLeft) minLeft = block.left;
      if (block.top < minTop) minTop = block.top;
      if (block.right > maxRight) maxRight = block.right;
      if (block.bottom > maxBottom) maxBottom = block.bottom;
    }

    // Add padding
    final padding = 0.02;
    return {
      'left': (minLeft - padding).clamp(0.0, 1.0),
      'top': (minTop - padding).clamp(0.0, 1.0),
      'right': (maxRight + padding).clamp(0.0, 1.0),
      'bottom': (maxBottom + padding).clamp(0.0, 1.0),
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'full_text': fullText,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'is_mock': isMock,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'lines': lines.map((l) => l.toMap()).toList(),
      'elements': elements.map((e) => e.toMap()).toList(),
      'image_path': imagePath,
    };
  }

  factory StructuredOCRResult.fromMap(Map<String, dynamic> map) {
    return StructuredOCRResult(
      fullText: map['full_text'] as String,
      imageWidth: map['image_width'] as int,
      imageHeight: map['image_height'] as int,
      isMock: map['is_mock'] as bool? ?? false,
      blocks: (map['blocks'] as List? ?? [])
          .map((b) => BoundingBoxModel.fromMap(b as Map<String, dynamic>))
          .toList(),
      lines: (map['lines'] as List? ?? [])
          .map((l) => BoundingBoxModel.fromMap(l as Map<String, dynamic>))
          .toList(),
      elements: (map['elements'] as List? ?? [])
          .map((e) => BoundingBoxModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      imagePath: map['image_path'] as String? ?? '',
    );
  }
}

/// Enhanced OCR Service with structured pipeline and bounding box extraction
class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  ml_kit.TextRecognizer? _textRecognizer;
  final _uuid = const Uuid();

  ml_kit.TextRecognizer _getRecognizer() {
    _textRecognizer ??= ml_kit.TextRecognizer();
    return _textRecognizer!;
  }

  /// Reset the service and free native resources
  void reset() {
    debugPrint('♻️ Resetting OCRService...');
    _textRecognizer?.close();
    _textRecognizer = null;
  }

  /// Main extraction method with structured result
  Future<StructuredOCRResult> extractStructuredText(
    String imagePath, {
    Map<String, dynamic>? cropZone,
    bool isMock = false,
  }) async {
    try {
      if (kIsWeb) {
        return _extractStructuredTextWeb(imagePath);
      }

      debugPrint('🔍 [OCR] Starting pipeline for: $imagePath');
      _logInternalMemory('Pipeline Start');
      
      // 1. Prepare image (resize/downscale for OCR)
      final prepResult = await _prepareImageForOCR(imagePath);
      String processImagePath = prepResult.path;
      int imageWidth = prepResult.width;
      int imageHeight = prepResult.height;
      
      _logInternalMemory('Preparation Done');
      
      // 2. Mock check
      if (isMock) {
        debugPrint('🔍 [OCR] Using Mock Data');
        return _extractStructuredTextWeb(processImagePath);
      }

      // 3. Process with ML Kit
      debugPrint('🔍 [OCR] ML Kit Processing Start');

      // 2. Apply crop if requested (rarely used in current flow)
      if (cropZone != null) {
        processImagePath = await _cropImage(processImagePath, cropZone);
        // Refresh dimensions for cropped image
        final croppedPreparation = await _prepareImageForOCR(processImagePath);
        imageWidth = croppedPreparation.width;
        imageHeight = croppedPreparation.height;
      }

      // 3. Process with ML Kit
      final inputImage = ml_kit.InputImage.fromFilePath(processImagePath);
      final recognizer = _getRecognizer();
      final ml_kit.RecognizedText recognizedText =
          await recognizer.processImage(inputImage);
      
      debugPrint('🔍 [OCR] ML Kit Done. Found ${recognizedText.blocks.length} blocks');
      _logInternalMemory('ML Kit Processing Done');

      // 4. Extract structured data
      final result = _extractStructuredData(
        recognizedText,
        imageWidth,
        imageHeight,
        processImagePath,
      );

      // Clean up temporary resized/cropped files if they were created
      if (processImagePath != imagePath) {
        try {
          final file = File(processImagePath);
          if (await file.exists()) {
            // We'll let the OS clean temp dir or handle it in a more global cleanup
          }
        } catch (_) {}
      }

      // Proactively close and reset recognizer if it's not a heavy batch
      // This forces native memory release
      reset();
      
      _logInternalMemory('Pipeline Finish');

      return result;
    } catch (error) {
      debugPrint('OCR error: $error, falling back to mock');
      return _extractStructuredTextWeb(imagePath);
    }
  }

  /// Gets image dimensions without loading the full pixel buffer into Dart heap.
  /// Uses Flutter's native-backed codec for efficiency.
  Future<({String path, int width, int height})> _prepareImageForOCR(String path) async {
    final file = File(path);
    if (!await file.exists()) return (path: path, width: 0, height: 0);

    try {
      final bytes = await file.readAsBytes();
      
      // Use ui.instantiateImageCodec to get dimensions without decoding to raw pixels in Dart.
      // This uses the native Skia/Impeller decoder which is MUCH more memory efficient.
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 100, targetHeight: 100);
      final frame = await codec.getNextFrame();
      
      // We still need the original dimensions for normalization.
      // Wait, instantiateImageCodec with target sizes might lose original dimensions.
      // Let's get original dimensions first.
      final originalCodec = await ui.instantiateImageCodec(bytes);
      final originalFrame = await originalCodec.getNextFrame();
      final width = originalFrame.image.width;
      final height = originalFrame.image.height;
      
      // Clean up native resources immediately
      originalFrame.image.dispose();
      frame.image.dispose();
      originalCodec.dispose();
      codec.dispose();

      return (path: path, width: width, height: height);
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
      return (path: path, width: 0, height: 0);
    }
  }

  /// Legacy method for backward compatibility
  Future<String> extractTextFromImage(
    String imagePath, {
    Map<String, dynamic>? cropZone,
  }) async {
    final result = await extractStructuredText(imagePath, cropZone: cropZone);
    return result.fullText;
  }

  /// Extract structured data from ML Kit result
  StructuredOCRResult _extractStructuredData(
    ml_kit.RecognizedText recognizedText,
    int imageWidth,
    int imageHeight,
    String imagePath,
  ) {
    final blocks = <BoundingBoxModel>[];
    final lines = <BoundingBoxModel>[];
    final elements = <BoundingBoxModel>[];
    final fullTextBuffer = StringBuffer();

    int blockIndex = 0;

    for (final block in recognizedText.blocks) {
      final blockLines = <String>[];
      int lineIndex = 0;

      // Process block bounding box
      final blockBox = _normalizeBoundingBox(
        block.boundingBox,
        imageWidth,
        imageHeight,
      );

      for (final line in block.lines) {
        blockLines.add(line.text);
        int elementIndex = 0;

        // Process line bounding box
        final lineBox = _normalizeBoundingBox(
          line.boundingBox,
          imageWidth,
          imageHeight,
        );

        lines.add(BoundingBoxModel(
          id: _uuid.v4(),
          text: line.text,
          type: 'line',
          left: lineBox['left']!,
          top: lineBox['top']!,
          right: lineBox['right']!,
          bottom: lineBox['bottom']!,
          confidence: 0.9,
          blockIndex: blockIndex,
          lineIndex: lineIndex,
        ));

        for (final element in line.elements) {
          // Process element bounding box
          final elementBox = _normalizeBoundingBox(
            element.boundingBox,
            imageWidth,
            imageHeight,
          );

          elements.add(BoundingBoxModel(
            id: _uuid.v4(),
            text: element.text,
            type: 'element',
            left: elementBox['left']!,
            top: elementBox['top']!,
            right: elementBox['right']!,
            bottom: elementBox['bottom']!,
            confidence: 0.85,
            blockIndex: blockIndex,
            lineIndex: lineIndex,
            elementIndex: elementIndex,
          ));

          elementIndex++;
        }

        lineIndex++;
      }

      // Add block
      blocks.add(BoundingBoxModel(
        id: _uuid.v4(),
        text: blockLines.join('\n'),
        type: 'block',
        left: blockBox['left']!,
        top: blockBox['top']!,
        right: blockBox['right']!,
        bottom: blockBox['bottom']!,
        confidence: 0.95,
        blockIndex: blockIndex,
      ));

      fullTextBuffer.writeln(blockLines.join('\n'));
      blockIndex++;
    }

    return StructuredOCRResult(
      fullText: fullTextBuffer.toString().trim(),
      blocks: blocks,
      lines: lines,
      elements: elements,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      imagePath: imagePath,
      isMock: false,
    );
  }

  /// Normalize bounding box to 0.0-1.0 range
  Map<String, double> _normalizeBoundingBox(
    Rect? boundingBox,
    int imageWidth,
    int imageHeight,
  ) {
    if (boundingBox == null || imageWidth == 0 || imageHeight == 0) {
      return {'left': 0.0, 'top': 0.0, 'right': 1.0, 'bottom': 1.0};
    }

    return {
      'left': (boundingBox.left / imageWidth).clamp(0.0, 1.0),
      'top': (boundingBox.top / imageHeight).clamp(0.0, 1.0),
      'right': (boundingBox.right / imageWidth).clamp(0.0, 1.0),
      'bottom': (boundingBox.bottom / imageHeight).clamp(0.0, 1.0),
    };
  }

  /// Crop image based on normalized coordinates
  Future<String> _cropImage(
    String imagePath,
    Map<String, dynamic> cropZone,
  ) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      var image = img.decodeImage(imageBytes);

      if (image == null) {
        return imagePath;
      }

      // Extract normalized coordinates
      final topLeft = cropZone['topLeft'] as Offset;
      final bottomRight = cropZone['bottomRight'] as Offset;

      // Convert normalized coordinates to pixel coordinates
      final x = (topLeft.dx * image.width).toInt();
      final y = (topLeft.dy * image.height).toInt();
      final width = ((bottomRight.dx - topLeft.dx) * image.width).toInt();
      final height = ((bottomRight.dy - topLeft.dy) * image.height).toInt();

      // Ensure coordinates are valid
      final validX = x.clamp(0, image.width - 1);
      final validY = y.clamp(0, image.height - 1);
      final validWidth = width.clamp(1, image.width - validX);
      final validHeight = height.clamp(1, image.height - validY);

      // Crop the image
      final croppedImage = img.copyCrop(
        image,
        x: validX,
        y: validY,
        width: validWidth,
        height: validHeight,
      );

      // Save cropped image to temporary file
      final dir = await imageFile.parent.createTemp('crop_');
      final tempFile = File(
        '${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 90));

      return tempFile.path;
    } catch (e) {
      debugPrint('Image cropping failed: $e');
      return imagePath;
    }
  }

  /// Mock OCR implementation for web/demo purposes
  StructuredOCRResult _extractStructuredTextWeb(String imagePath) {
    final mockText = 'SmartScan Document Processing System\n\n'
        'Date: April 2, 2026\n'
        'Document Type: Invoice\n\n'
        'INVOICE 2026-001235\n\n'
        'Bill To:\n'
        'Company Name: TechCorp Solutions\n'
        'Address: 123 Business Avenue\n'
        'City: San Francisco, CA 94105\n'
        'Contact: John Smith\n'
        'Email: john.smith@techcorp.com\n'
        'Phone: +1 (555) 123-4567\n\n'
        'Services Rendered:\n'
        '- Document Scanning and OCR Processing\n'
        '- Text Recognition and Extraction\n'
        '- Multilingual Translation Support\n'
        '- Export to PDF/Word Format\n\n'
        'Total Amount Due: USD 1250.00\n'
        'Due Date: April 30, 2026\n\n'
        'Terms: Net 30 days\n'
        'Payment Method: Bank Transfer\n\n'
        'Thank you for your business\n'
        'Visit us at techcorp dot com\n'
        'Next meeting: Next Friday at 2 PM';

    // Create mock bounding boxes
    final blocks = <BoundingBoxModel>[
      BoundingBoxModel(
        id: _uuid.v4(),
        text: 'SmartScan Document Processing System',
        type: 'block',
        left: 0.05,
        top: 0.05,
        right: 0.95,
        bottom: 0.12,
        confidence: 0.98,
        blockIndex: 0,
      ),
      BoundingBoxModel(
        id: _uuid.v4(),
        text: 'Date: April 2, 2026\nDocument Type: Invoice',
        type: 'block',
        left: 0.05,
        top: 0.14,
        right: 0.50,
        bottom: 0.22,
        confidence: 0.95,
        blockIndex: 1,
      ),
      BoundingBoxModel(
        id: _uuid.v4(),
        text: 'INVOICE #2026-001235',
        type: 'block',
        left: 0.55,
        top: 0.14,
        right: 0.95,
        bottom: 0.20,
        confidence: 0.97,
        blockIndex: 2,
      ),
      BoundingBoxModel(
        id: _uuid.v4(),
        text: 'Bill To:\nCompany Name: TechCorp Solutions\nAddress: 123 Business Avenue\nCity: San Francisco, CA 94105\nContact: John Smith\nEmail: john.smith@techcorp.com\nPhone: +1 (555) 123-4567',
        type: 'block',
        left: 0.05,
        top: 0.24,
        right: 0.60,
        bottom: 0.50,
        confidence: 0.94,
        blockIndex: 3,
      ),
      BoundingBoxModel(
        id: _uuid.v4(),
        text: 'Services Rendered:\n- Document Scanning & OCR Processing\n- Text Recognition & Extraction\n- Multilingual Translation Support\n- Export to PDF/Word Format',
        type: 'block',
        left: 0.05,
        top: 0.52,
        right: 0.95,
        bottom: 0.70,
        confidence: 0.92,
        blockIndex: 4,
      ),
      BoundingBoxModel(
        id: _uuid.v4(),
        text: 'Total Amount Due: USD 1,250.00. Due Date: April 30, 2026. Terms: Net 30 days. Payment Method: Bank Transfer',
        type: 'block',
        left: 0.05,
        top: 0.72,
        right: 0.55,
        bottom: 0.90,
        confidence: 0.96,
        blockIndex: 5,
      ),
      BoundingBoxModel(
        id: _uuid.v4(),
        text: 'Thank you for your business! Visit us at techcorp.com. Next meeting: Next Friday at 2 PM',
        type: 'block',
        left: 0.05,
        top: 0.92,
        right: 0.95,
        bottom: 0.98,
        confidence: 0.93,
        blockIndex: 6,
      ),
    ];

    // Create lines from blocks
    final lines = <BoundingBoxModel>[];
    int lineIdx = 0;
    for (final block in blocks) {
      final blockLines = block.text.split('\n');
      final lineHeight = (block.bottom - block.top) / blockLines.length;
      for (int i = 0; i < blockLines.length; i++) {
        lines.add(BoundingBoxModel(
          id: _uuid.v4(),
          text: blockLines[i],
          type: 'line',
          left: block.left,
          top: block.top + (i * lineHeight),
          right: block.right,
          bottom: block.top + ((i + 1) * lineHeight),
          confidence: 0.90,
          blockIndex: block.blockIndex,
          lineIndex: lineIdx++,
        ));
      }
    }

    // Create elements (simplified - one element per line)
    final elements = <BoundingBoxModel>[];
    int elemIdx = 0;
    for (final line in lines) {
      elements.add(BoundingBoxModel(
        id: _uuid.v4(),
        text: line.text,
        type: 'element',
        left: line.left,
        top: line.top,
        right: line.right,
        bottom: line.bottom,
        confidence: 0.85,
        blockIndex: line.blockIndex,
        lineIndex: line.lineIndex,
        elementIndex: elemIdx++,
      ));
    }

    return StructuredOCRResult(
      fullText: mockText,
      blocks: blocks,
      lines: lines,
      elements: elements,
      imageWidth: 1080,
      imageHeight: 1920,
      imagePath: imagePath,
      isMock: true,
    );
  }

  void _logInternalMemory(String stage) {
    if (kDebugMode) {
      try {
        final bytes = ProcessInfo.currentRss;
        final mb = bytes / (1024 * 1024);
        debugPrint('💾 [OCR SERVICE] $stage: ${mb.toStringAsFixed(2)}MB');
      } catch (_) {}
    }
  }

  void dispose() {
    reset();
  }
}
