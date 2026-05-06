/// Represents a normalized bounding box for text extraction
class BoundingBoxModel {
  final String id;
  final String text;
  final String type; // 'block', 'line', 'element'
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double confidence;
  final int? blockIndex;
  final int? lineIndex;
  final int? elementIndex;

  BoundingBoxModel({
    required this.id,
    required this.text,
    this.type = 'element',
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.confidence = 1.0,
    this.blockIndex,
    this.lineIndex,
    this.elementIndex,
  });

  double get width => right - left;

  double get height => bottom - top;

  Map<String, double> get center => {
        'x': (left + right) / 2,
        'y': (top + bottom) / 2,
      };

  bool containsPoint(double x, double y) {
    return x >= left && x <= right && y >= top && y <= bottom;
  }

  BoundingBoxModel scaleToSize(double imageWidth, double imageHeight) {
    return BoundingBoxModel(
      id: id,
      text: text,
      type: type,
      left: left * imageWidth,
      top: top * imageHeight,
      right: right * imageWidth,
      bottom: bottom * imageHeight,
      confidence: confidence,
      blockIndex: blockIndex,
      lineIndex: lineIndex,
      elementIndex: elementIndex,
    );
  }

  BoundingBoxModel normalize(double imageWidth, double imageHeight) {
    return BoundingBoxModel(
      id: id,
      text: text,
      type: type,
      left: left / imageWidth,
      top: top / imageHeight,
      right: right / imageWidth,
      bottom: bottom / imageHeight,
      confidence: confidence,
      blockIndex: blockIndex,
      lineIndex: lineIndex,
      elementIndex: elementIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'type': type,
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
      'confidence': confidence,
      'block_index': blockIndex,
      'line_index': lineIndex,
      'element_index': elementIndex,
    };
  }

  factory BoundingBoxModel.fromMap(Map<String, dynamic> map) {
    return BoundingBoxModel(
      id: map['id'] as String,
      text: map['text'] as String,
      type: map['type'] as String? ?? 'element',
      left: (map['left'] as num).toDouble(),
      top: (map['top'] as num).toDouble(),
      right: (map['right'] as num).toDouble(),
      bottom: (map['bottom'] as num).toDouble(),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      blockIndex: map['block_index'] as int?,
      lineIndex: map['line_index'] as int?,
      elementIndex: map['element_index'] as int?,
    );
  }

  BoundingBoxModel copyWith({
    String? id,
    String? text,
    String? type,
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? confidence,
    int? blockIndex,
    int? lineIndex,
    int? elementIndex,
  }) {
    return BoundingBoxModel(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      confidence: confidence ?? this.confidence,
      blockIndex: blockIndex ?? this.blockIndex,
      lineIndex: lineIndex ?? this.lineIndex,
      elementIndex: elementIndex ?? this.elementIndex,
    );
  }

  @override
  String toString() {
    return 'BoundingBoxModel(id: $id, type: $type, text: ${text.substring(0, text.length > 20 ? 20 : text.length)}...)';
  }
}

class OCRResult {
  final String fullText;
  final List<BoundingBoxModel> blocks;
  final List<BoundingBoxModel> lines;
  final List<BoundingBoxModel> elements;
  final int imageWidth;
  final int imageHeight;

  OCRResult({
    required this.fullText,
    required this.blocks,
    required this.lines,
    required this.elements,
    required this.imageWidth,
    required this.imageHeight,
  });

  Map<String, double>? getMainTextRegion() {
    if (blocks.isEmpty) return null;

    // Find the largest block by area
    BoundingBoxModel? largestBlock;
    double maxArea = 0;

    for (final block in blocks) {
      final area = block.width * block.height;
      if (area > maxArea) {
        maxArea = area;
        largestBlock = block;
      }
    }

    if (largestBlock == null) return null;

    // Add padding around the main region
    final padding = 0.02; // 2% padding
    return {
      'left': (largestBlock.left - padding).clamp(0.0, 1.0),
      'top': (largestBlock.top - padding).clamp(0.0, 1.0),
      'right': (largestBlock.right + padding).clamp(0.0, 1.0),
      'bottom': (largestBlock.bottom + padding).clamp(0.0, 1.0),
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'full_text': fullText,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'lines': lines.map((l) => l.toMap()).toList(),
      'elements': elements.map((e) => e.toMap()).toList(),
    };
  }

  factory OCRResult.fromMap(Map<String, dynamic> map) {
    return OCRResult(
      fullText: map['full_text'] as String,
      imageWidth: map['image_width'] as int,
      imageHeight: map['image_height'] as int,
      blocks: (map['blocks'] as List)
          .map((b) => BoundingBoxModel.fromMap(b as Map<String, dynamic>))
          .toList(),
      lines: (map['lines'] as List)
          .map((l) => BoundingBoxModel.fromMap(l as Map<String, dynamic>))
          .toList(),
      elements: (map['elements'] as List)
          .map((e) => BoundingBoxModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
