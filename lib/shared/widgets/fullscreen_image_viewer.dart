import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bounding_box_model.dart';
import '../models/entity_model.dart';
import 'bounding_box_overlay.dart';

/// Fullscreen image viewer with bounding box overlay support
class FullscreenImageViewer extends StatefulWidget {
  final String imagePath;
  final String? title;
  final List<BoundingBoxModel>? boundingBoxes;
  final List<EntityModel>? entities;
  final Size? imageSize;

  const FullscreenImageViewer({
    super.key,
    required this.imagePath,
    this.title,
    this.boundingBoxes,
    this.entities,
    this.imageSize,
  });

  @override
  State<FullscreenImageViewer> createState() =>
      _FullscreenImageViewerState();

  /// Show the fullscreen viewer as a modal
  static Future<void> show(
    BuildContext context, {
    required String imagePath,
    String? title,
    List<BoundingBoxModel>? boundingBoxes,
    List<EntityModel>? entities,
    Size? imageSize,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          imagePath: imagePath,
          title: title,
          boundingBoxes: boundingBoxes,
          entities: entities,
          imageSize: imageSize,
        ),
      ),
    );
  }
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _fadeController;
  bool _showOverlay = true;
  bool _showUI = true;
  final Set<String> _highlightedBoxIds = {};

  double _currentScale = 1.0;
  ImageProvider? _lowResProvider;
  ImageProvider? _highResProvider;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_handleZoomChange);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeController.value = 1.0;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  void _handleZoomChange() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale > 1.5 && _currentScale <= 1.5) ||
        (scale <= 1.5 && _currentScale > 1.5)) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleZoomChange);
    _transformationController.dispose();
    _fadeController.dispose();

    // Evict providers synchronously so the large GPU textures are released
    // before Flutter renders the next frame. Deferring this via
    // addPostFrameCallback would leave the textures alive during the
    // route-pop transition, wasting precious RAM on budget devices.
    _lowResProvider?.evict();
    _highResProvider?.evict();
    _lowResProvider = null;
    _highResProvider = null;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Hard-clear the image cache synchronously. This screen may have decoded
    // a very large image (up to 2500 px wide at 5× zoom) and we want that
    // memory back immediately, not after the next build pass.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    super.dispose();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      if (_showUI) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main image with zoom/pan
            _buildImageViewer(),

            // Bounding box overlay
            if (_showOverlay &&
                widget.boundingBoxes != null &&
                widget.imageSize != null)
              _buildOverlay(),

            // UI overlay
            FadeTransition(
              opacity: _fadeController,
              child: _buildUIOverlay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final imageFile = File(widget.imagePath);
    final bool isZoomed = _currentScale > 1.5;

    if (imageFile.existsSync()) {
      // Low-res provider (1000 px wide) is always prepared.
      _lowResProvider ??=
          ResizeImage(FileImage(imageFile), width: 1000);

      // High-res provider (2500 px wide) is only prepared on demand when
      // the user has actually zoomed in, to avoid decoding a large bitmap
      // before it is needed.
      if (isZoomed) {
        _highResProvider ??=
            ResizeImage(FileImage(imageFile), width: 2500);
      }

      final activeProvider =
          isZoomed ? _highResProvider! : _lowResProvider!;

      return Image(
        image: activeProvider,
        fit: BoxFit.contain,
        // Changing the key when zoom threshold crosses forces Flutter to
        // rebuild the Image widget with the new provider, which triggers
        // the higher-res decode at the right moment.
        key: ValueKey('${widget.imagePath}_$isZoomed'),
      );
    } else {
      // Fallback to asset
      _lowResProvider ??=
          ResizeImage(AssetImage(widget.imagePath), width: 1000);
      if (isZoomed) {
        _highResProvider ??=
            ResizeImage(AssetImage(widget.imagePath), width: 2500);
      }

      final activeProvider =
          isZoomed ? _highResProvider! : _lowResProvider!;

      return Image(
        image: activeProvider,
        fit: BoxFit.contain,
        key: ValueKey('${widget.imagePath}_$isZoomed'),
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.grey,
            ),
          );
        },
      );
    }
  }

  Widget _buildOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return BoundingBoxOverlay(
          boundingBoxes: widget.boundingBoxes!,
          entities: widget.entities,
          imageSize: widget.imageSize!,
          displaySize:
              Size(constraints.maxWidth, constraints.maxHeight),
          highlightedBoxIds: _highlightedBoxIds,
          showAllBoxes: true,
          onBoxTap: (box) => _handleBoxTap(box),
          onEntityTap: (entity) => _handleEntityTap(entity),
        );
      },
    );
  }

  Widget _buildUIOverlay() {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                if (widget.title != null)
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (widget.boundingBoxes != null)
                  IconButton(
                    icon: Icon(
                      _showOverlay
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: _toggleOverlay,
                    tooltip: 'Toggle highlighting',
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom controls
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.boundingBoxes != null)
                    _buildControlButton(
                      icon: Icons.select_all,
                      label: 'Clear',
                      onTap: () => setState(
                          () => _highlightedBoxIds.clear()),
                    ),
                  const SizedBox(width: 24),
                  _buildControlButton(
                    icon: Icons.zoom_out_map,
                    label: 'Reset',
                    onTap: () => _transformationController.value =
                        Matrix4.identity(),
                  ),
                  const SizedBox(width: 24),
                  _buildControlButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: _shareImage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBoxTap(BoundingBoxModel box) {
    setState(() {
      if (_highlightedBoxIds.contains(box.id)) {
        _highlightedBoxIds.remove(box.id);
      } else {
        _highlightedBoxIds.add(box.id);
      }
    });
  }

  void _handleEntityTap(EntityModel entity) {
    if (widget.boundingBoxes == null) return;

    final matchingBoxes = widget.boundingBoxes!.where((box) =>
        box.text.toLowerCase().contains(entity.text.toLowerCase()));

    setState(() {
      for (final box in matchingBoxes) {
        if (_highlightedBoxIds.contains(box.id)) {
          _highlightedBoxIds.remove(box.id);
        } else {
          _highlightedBoxIds.add(box.id);
        }
      }
    });
  }

  void _shareImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }
}