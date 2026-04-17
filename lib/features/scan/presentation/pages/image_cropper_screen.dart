import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../core/services/feedback_service.dart';

class ImageCropperScreen extends StatefulWidget {
  final String imagePath;

  const ImageCropperScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<ImageCropperScreen> createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen> {
  late Offset _topLeft;
  late Offset _topRight;
  late Offset _bottomLeft;
  late Offset _bottomRight;
  String? _draggingPointName; // Store which corner is being dragged
  bool _imageLoaded = false;
  late GlobalKey _containerKey;

  @override
  void initState() {
    super.initState();
    _containerKey = GlobalKey();
    _initializeSelectionBox();
    _loadImageSize();
  }

  void _loadImageSize() async {
    try {
      final image = Image.file(File(widget.imagePath));
      image.image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((image, synchronousCall) {
          if (mounted) {
            setState(() {
              _imageLoaded = true;
            });
          }
        }),
      );
    } catch (_) {
      // If error, just set as loaded
      if (mounted) {
        setState(() {
          _imageLoaded = true;
        });
      }
    }
  }

  void _initializeSelectionBox() {
    // Initialize with a default selection box (90% of image)
    _topLeft = const Offset(0.05, 0.05);
    _topRight = const Offset(0.95, 0.05);
    _bottomLeft = const Offset(0.05, 0.95);
    _bottomRight = const Offset(0.95, 0.95);
  }

  Offset _getLocalCoordinates(Offset localPosition) {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;

    final size = renderBox.size;
    return Offset(
      (localPosition.dx / size.width).clamp(0.0, 1.0),
      (localPosition.dy / size.height).clamp(0.0, 1.0),
    );
  }

  Offset _constrainPoint(Offset point) {
    return Offset(
      point.dx.clamp(0.0, 1.0),
      point.dy.clamp(0.0, 1.0),
    );
  }

  void _updateDraggingPoint(Offset newPoint) {
    newPoint = _constrainPoint(newPoint);
    if (_draggingPointName == 'topLeft') {
      _topLeft = newPoint;
    } else if (_draggingPointName == 'topRight') {
      _topRight = Offset(newPoint.dx, newPoint.dy);
    } else if (_draggingPointName == 'bottomLeft') {
      _bottomLeft = Offset(newPoint.dx, newPoint.dy);
    } else if (_draggingPointName == 'bottomRight') {
      _bottomRight = newPoint;
    }
  }

  bool _isCornerNearby(Offset point, Offset corner, {double threshold = 0.08}) {
    return (point - corner).distance < threshold;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner la zone OCR'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FeedbackService().onTap();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Image with selection box
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                final normalizedPoint =
                    _getLocalCoordinates(details.localPosition);

                // Check which corner is closest
                if (_isCornerNearby(normalizedPoint, _topLeft)) {
                  _draggingPointName = 'topLeft';
                } else if (_isCornerNearby(normalizedPoint, _topRight)) {
                  _draggingPointName = 'topRight';
                } else if (_isCornerNearby(normalizedPoint, _bottomLeft)) {
                  _draggingPointName = 'bottomLeft';
                } else if (_isCornerNearby(normalizedPoint, _bottomRight)) {
                  _draggingPointName = 'bottomRight';
                }
              },
              onPanUpdate: (details) {
                if (_draggingPointName != null) {
                  setState(() {
                    final newPoint =
                        _getLocalCoordinates(details.localPosition);
                    _updateDraggingPoint(newPoint);
                  });
                }
              },
              onPanEnd: (_) {
                _draggingPointName = null;
              },
              onPanCancel: () {
                _draggingPointName = null;
              },
              child: Container(
                key: _containerKey,
                color: Colors.black,
                child: Stack(
                  children: [
                    // Image
                    Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                    ),
                    // Selection box overlay
                    if (_imageLoaded)
                      CustomPaint(
                        painter: SelectionBoxPainter(
                          topLeft: _topLeft,
                          topRight: _topRight,
                          bottomLeft: _bottomLeft,
                          bottomRight: _bottomRight,
                          isDragging: _draggingPointName != null,
                        ),
                        size: Size.infinite,
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Info text
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Ajustez les coins pour sélectionner la zone d\'extraction du texte',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Action buttons with safe area
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _initializeSelectionBox();
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Return the selected crop area
                        Navigator.pop(context, {
                          'topLeft': _topLeft,
                          'topRight': _topRight,
                          'bottomLeft': _bottomLeft,
                          'bottomRight': _bottomRight,
                        });
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectionBoxPainter extends CustomPainter {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;
  final bool isDragging;

  SelectionBoxPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Convert normalized coordinates to screen coordinates
    final screenTopLeft =
        Offset(topLeft.dx * size.width, topLeft.dy * size.height);
    final screenTopRight =
        Offset(topRight.dx * size.width, topRight.dy * size.height);
    final screenBottomLeft =
        Offset(bottomLeft.dx * size.width, bottomLeft.dy * size.height);
    final screenBottomRight =
        Offset(bottomRight.dx * size.width, bottomRight.dy * size.height);

    // Semi-transparent overlay outside selection
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Draw semi-transparent areas outside the selection box
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..moveTo(screenTopLeft.dx, screenTopLeft.dy)
          ..lineTo(screenTopRight.dx, screenTopRight.dy)
          ..lineTo(screenBottomRight.dx, screenBottomRight.dy)
          ..lineTo(screenBottomLeft.dx, screenBottomLeft.dy)
          ..close(),
      ),
      paint,
    );

    // Draw selection box border
    final borderPaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(screenTopLeft.dx, screenTopLeft.dy)
        ..lineTo(screenTopRight.dx, screenTopRight.dy)
        ..lineTo(screenBottomRight.dx, screenBottomRight.dy)
        ..lineTo(screenBottomLeft.dx, screenBottomLeft.dy)
        ..close(),
      borderPaint,
    );

    // Draw corner handles
    final handleRadius = 8.0;
    final handlePaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    final handleStrokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw all corner handles
    for (final corner in [
      screenTopLeft,
      screenTopRight,
      screenBottomLeft,
      screenBottomRight
    ]) {
      canvas.drawCircle(corner, handleRadius, handlePaint);
      canvas.drawCircle(corner, handleRadius, handleStrokePaint);
    }

    // Draw corner lines
    final cornerLinePaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 1.5;

    const cornerSize = 15.0;

    // Top left corner
    canvas.drawLine(
      Offset(screenTopLeft.dx, screenTopLeft.dy - cornerSize),
      Offset(screenTopLeft.dx, screenTopLeft.dy + cornerSize),
      cornerLinePaint,
    );
    canvas.drawLine(
      Offset(screenTopLeft.dx - cornerSize, screenTopLeft.dy),
      Offset(screenTopLeft.dx + cornerSize, screenTopLeft.dy),
      cornerLinePaint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(screenTopRight.dx, screenTopRight.dy - cornerSize),
      Offset(screenTopRight.dx, screenTopRight.dy + cornerSize),
      cornerLinePaint,
    );
    canvas.drawLine(
      Offset(screenTopRight.dx - cornerSize, screenTopRight.dy),
      Offset(screenTopRight.dx + cornerSize, screenTopRight.dy),
      cornerLinePaint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(screenBottomLeft.dx, screenBottomLeft.dy - cornerSize),
      Offset(screenBottomLeft.dx, screenBottomLeft.dy + cornerSize),
      cornerLinePaint,
    );
    canvas.drawLine(
      Offset(screenBottomLeft.dx - cornerSize, screenBottomLeft.dy),
      Offset(screenBottomLeft.dx + cornerSize, screenBottomLeft.dy),
      cornerLinePaint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(screenBottomRight.dx, screenBottomRight.dy - cornerSize),
      Offset(screenBottomRight.dx, screenBottomRight.dy + cornerSize),
      cornerLinePaint,
    );
    canvas.drawLine(
      Offset(screenBottomRight.dx - cornerSize, screenBottomRight.dy),
      Offset(screenBottomRight.dx + cornerSize, screenBottomRight.dy),
      cornerLinePaint,
    );
  }

  @override
  bool shouldRepaint(SelectionBoxPainter oldDelegate) {
    return oldDelegate.topLeft != topLeft ||
        oldDelegate.topRight != topRight ||
        oldDelegate.bottomLeft != bottomLeft ||
        oldDelegate.bottomRight != bottomRight ||
        oldDelegate.isDragging != isDragging;
  }
}
