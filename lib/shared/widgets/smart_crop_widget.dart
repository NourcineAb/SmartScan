import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// Smart crop region editor widget
class SmartCropWidget extends StatefulWidget {
  final String imagePath;
  final Map<String, double>? suggestedRegion;
  final Function(Map<String, double> region)? onRegionChanged;
  final Function(Map<String, double> region)? onApply;
  final VoidCallback? onSkip;

  const SmartCropWidget({
    super.key,
    required this.imagePath,
    this.suggestedRegion,
    this.onRegionChanged,
    this.onApply,
    this.onSkip,
  });

  @override
  State<SmartCropWidget> createState() => _SmartCropWidgetState();

  /// Show smart crop dialog
  static Future<Map<String, double>?> show(
    BuildContext context, {
    required String imagePath,
    Map<String, double>? suggestedRegion,
  }) async {
    return showModalBottomSheet<Map<String, double>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartCropWidget(
        imagePath: imagePath,
        suggestedRegion: suggestedRegion,
        onApply: (region) => Navigator.of(context).pop(region),
        onSkip: () => Navigator.of(context).pop(null),
      ),
    );
  }
}

class _SmartCropWidgetState extends State<SmartCropWidget> {
  late Map<String, double> _cropRegion;
  bool _isDragging = false;
  String? _activeHandle;
  Size _imageSize = Size.zero;
  
  // Minimum crop size (normalized)
  static const double _minSize = 0.1;

  @override
  void initState() {
    super.initState();
    // Initialize with suggested region or default
    _cropRegion = widget.suggestedRegion ?? {
      'left': 0.05,
      'top': 0.05,
      'right': 0.95,
      'bottom': 0.95,
    };
    
    // Haptic feedback for suggestion
    if (widget.suggestedRegion != null) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: screenSize.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          const SizedBox(height: 16),
          
          // Image with crop overlay
          Expanded(
            child: _buildImageWithOverlay(),
          ),
          
          const SizedBox(height: 16),
          
          // Controls
          _buildControls(),
          
          // Bottom actions
          _buildActions(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final bool hasSuggestion = widget.suggestedRegion != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.crop_free,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Crop',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      hasSuggestion
                          ? 'Auto-detected text region. Adjust as needed.'
                          : 'Select the area with text to scan.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageWithOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _imageSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset(
                  widget.imagePath,
                  fit: BoxFit.contain,
                ),
                
                // Darken outside crop area
                CustomPaint(
                  size: Size.infinite,
                  painter: CropOverlayPainter(
                    cropRegion: _cropRegion,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                
                // Crop border
                Positioned(
                  left: _cropRegion['left']! * _imageSize.width,
                  top: _cropRegion['top']! * _imageSize.height,
                  width: (_cropRegion['right']! - _cropRegion['left']!) * _imageSize.width,
                  height: (_cropRegion['bottom']! - _cropRegion['top']!) * _imageSize.height,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                
                // Corner handles
                ..._buildHandles(),
                
                // Size indicator
                Positioned(
                  left: _cropRegion['left']! * _imageSize.width + 8,
                  top: _cropRegion['top']! * _imageSize.height - 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, 
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${((_cropRegion['right']! - _cropRegion['left']!) * 100).toInt()}% × ${((_cropRegion['bottom']! - _cropRegion['top']!) * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildHandles() {
    final handles = [
      // Top-left
      {'x': _cropRegion['left']!, 'y': _cropRegion['top']!, 'id': 'tl'},
      // Top-right
      {'x': _cropRegion['right']!, 'y': _cropRegion['top']!, 'id': 'tr'},
      // Bottom-left
      {'x': _cropRegion['left']!, 'y': _cropRegion['bottom']!, 'id': 'bl'},
      // Bottom-right
      {'x': _cropRegion['right']!, 'y': _cropRegion['bottom']!, 'id': 'br'},
    ];

    return handles.map((handle) {
      final x = (handle['x'] as double) * _imageSize.width - 12;
      final y = (handle['y'] as double) * _imageSize.height - 12;
      final id = handle['id'] as String;

      return Positioned(
        left: x,
        top: y,
        child: GestureDetector(
          onPanStart: (_) {
            setState(() {
              _activeHandle = id;
              _isDragging = true;
            });
            HapticFeedback.selectionClick();
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlChip(
            icon: Icons.crop_free,
            label: 'Reset',
            onTap: () {
              setState(() {
                _cropRegion = {
                  'left': 0.05,
                  'top': 0.05,
                  'right': 0.95,
                  'bottom': 0.95,
                };
              });
              HapticFeedback.lightImpact();
            },
          ),
          const SizedBox(width: 12),
          if (widget.suggestedRegion != null)
            _buildControlChip(
              icon: Icons.auto_fix_high,
              label: 'Auto',
              onTap: () {
                setState(() {
                  _cropRegion = Map.from(widget.suggestedRegion!);
                });
                HapticFeedback.lightImpact();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildControlChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onSkip,
              child: const Text('Skip'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => widget.onApply?.call(_cropRegion),
              icon: const Icon(Icons.check),
              label: const Text('Apply Crop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    // Check if touching inside crop area
    final localPos = details.localPosition;
    final normalizedX = localPos.dx / _imageSize.width;
    final normalizedY = localPos.dy / _imageSize.height;

    final isInside = normalizedX >= _cropRegion['left']! &&
        normalizedX <= _cropRegion['right']! &&
        normalizedY >= _cropRegion['top']! &&
        normalizedY <= _cropRegion['bottom']!;

    if (isInside && _activeHandle == null) {
      setState(() {
        _isDragging = true;
      });
      HapticFeedback.selectionClick();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final delta = details.delta;
    final normalizedDx = delta.dx / _imageSize.width;
    final normalizedDy = delta.dy / _imageSize.height;

    setState(() {
      if (_activeHandle != null) {
        // Handle-based resizing
        switch (_activeHandle) {
          case 'tl':
            _cropRegion['left'] = (_cropRegion['left']! + normalizedDx).clamp(0.0, _cropRegion['right']! - _minSize);
            _cropRegion['top'] = (_cropRegion['top']! + normalizedDy).clamp(0.0, _cropRegion['bottom']! - _minSize);
            break;
          case 'tr':
            _cropRegion['right'] = (_cropRegion['right']! + normalizedDx).clamp(_cropRegion['left']! + _minSize, 1.0);
            _cropRegion['top'] = (_cropRegion['top']! + normalizedDy).clamp(0.0, _cropRegion['bottom']! - _minSize);
            break;
          case 'bl':
            _cropRegion['left'] = (_cropRegion['left']! + normalizedDx).clamp(0.0, _cropRegion['right']! - _minSize);
            _cropRegion['bottom'] = (_cropRegion['bottom']! + normalizedDy).clamp(_cropRegion['top']! + _minSize, 1.0);
            break;
          case 'br':
            _cropRegion['right'] = (_cropRegion['right']! + normalizedDx).clamp(_cropRegion['left']! + _minSize, 1.0);
            _cropRegion['bottom'] = (_cropRegion['bottom']! + normalizedDy).clamp(_cropRegion['top']! + _minSize, 1.0);
            break;
        }
      } else {
        // Moving entire crop region
        final width = _cropRegion['right']! - _cropRegion['left']!;
        final height = _cropRegion['bottom']! - _cropRegion['top']!;

        var newLeft = _cropRegion['left']! + normalizedDx;
        var newTop = _cropRegion['top']! + normalizedDy;

        // Keep within bounds
        if (newLeft < 0) newLeft = 0;
        if (newTop < 0) newTop = 0;
        if (newLeft + width > 1) newLeft = 1 - width;
        if (newTop + height > 1) newTop = 1 - height;

        _cropRegion['left'] = newLeft;
        _cropRegion['top'] = newTop;
        _cropRegion['right'] = newLeft + width;
        _cropRegion['bottom'] = newTop + height;
      }
    });

    widget.onRegionChanged?.call(_cropRegion);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _activeHandle = null;
    });
    HapticFeedback.lightImpact();
  }
}

/// Custom painter for crop overlay
class CropOverlayPainter extends CustomPainter {
  final Map<String, double> cropRegion;
  final Color color;

  CropOverlayPainter({
    required this.cropRegion,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // Draw dark overlay outside crop area
    final cropRect = Rect.fromLTRB(
      cropRegion['left']! * size.width,
      cropRegion['top']! * size.height,
      cropRegion['right']! * size.width,
      cropRegion['bottom']! * size.height,
    );

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw dark overlay
    final path = Path()
      ..addRect(fullRect)
      ..addRect(cropRect);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // Vertical grid lines
    for (int i = 1; i < 3; i++) {
      final x = cropRect.left + (cropRect.width / 3) * i;
      canvas.drawLine(
        Offset(x, cropRect.top),
        Offset(x, cropRect.bottom),
        gridPaint,
      );
    }

    // Horizontal grid lines
    for (int i = 1; i < 3; i++) {
      final y = cropRect.top + (cropRect.height / 3) * i;
      canvas.drawLine(
        Offset(cropRect.left, y),
        Offset(cropRect.right, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
