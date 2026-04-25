import 'package:flutter/material.dart';
import '../models/bounding_box_model.dart';
import '../models/entity_model.dart';
import '../../core/theme/app_colors.dart';

/// Widget that renders bounding boxes over an image for highlighting
class BoundingBoxOverlay extends StatelessWidget {
  final List<BoundingBoxModel> boundingBoxes;
  final List<EntityModel>? entities;
  final Size imageSize;
  final Size displaySize;
  final Function(BoundingBoxModel)? onBoxTap;
  final Function(EntityModel)? onEntityTap;
  final Set<String>? highlightedBoxIds;
  final bool showAllBoxes;

  const BoundingBoxOverlay({
    super.key,
    required this.boundingBoxes,
    this.entities,
    required this.imageSize,
    required this.displaySize,
    this.onBoxTap,
    this.onEntityTap,
    this.highlightedBoxIds,
    this.showAllBoxes = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ..._buildBoundingBoxes(),
        if (entities != null) ..._buildEntityHighlights(),
      ],
    );
  }

  List<Widget> _buildBoundingBoxes() {
    final boxes = <Widget>[];
    
    for (final box in boundingBoxes) {
      final isHighlighted = highlightedBoxIds?.contains(box.id) ?? false;
      
      // Skip non-highlighted boxes if not showing all
      if (!showAllBoxes && !isHighlighted) continue;
      
      final rect = _scaleBoxToDisplay(box);
      
      boxes.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: GestureDetector(
            onTap: () => onBoxTap?.call(box),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isHighlighted 
                      ? AppColors.primary 
                      : Colors.transparent,
                  width: isHighlighted ? 2 : 1,
                ),
                color: isHighlighted 
                    ? AppColors.primary.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: isHighlighted && box.text.isNotEmpty
                  ? Align(
                      alignment: Alignment.bottomLeft,
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
                          box.text.substring(0, box.text.length > 20 
                              ? 20 
                              : box.text.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      );
    }
    
    return boxes;
  }

  List<Widget> _buildEntityHighlights() {
    final highlights = <Widget>[];
    
    for (final entity in entities!) {
      // Find bounding boxes that contain this entity text
      final matchingBoxes = boundingBoxes.where((box) => 
        box.text.toLowerCase().contains(entity.text.toLowerCase()) ||
        entity.text.toLowerCase().contains(box.text.toLowerCase())
      ).toList();
      
      if (matchingBoxes.isNotEmpty) {
        final box = matchingBoxes.first;
        final rect = _scaleBoxToDisplay(box);
        final color = _getEntityColor(entity.type);
        
        highlights.add(
          Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: GestureDetector(
              onTap: () => onEntityTap?.call(entity),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEntityIcon(entity.type),
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entity.type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return highlights;
  }

  Rect _scaleBoxToDisplay(BoundingBoxModel box) {
    // Scale normalized coordinates to display size
    final scaleX = displaySize.width;
    final scaleY = displaySize.height;
    
    // Calculate position with aspect ratio preservation
    final imageAspect = imageSize.width / imageSize.height;
    final displayAspect = displaySize.width / displaySize.height;
    
    double offsetX = 0;
    double offsetY = 0;
    double scale = 1.0;
    
    if (imageAspect > displayAspect) {
      // Image is wider, fit to width
      scale = displaySize.width / imageSize.width;
      offsetY = (displaySize.height - imageSize.height * scale) / 2;
    } else {
      // Image is taller, fit to height
      scale = displaySize.height / imageSize.height;
      offsetX = (displaySize.width - imageSize.width * scale) / 2;
    }
    
    // Box coordinates are normalized (0.0-1.0)
    final left = box.left * imageSize.width * scale + offsetX;
    final top = box.top * imageSize.height * scale + offsetY;
    final width = box.width * imageSize.width * scale;
    final height = box.height * imageSize.height * scale;
    
    return Rect.fromLTWH(left, top, width, height);
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
        return Icons.location_on;
      case 'price':
        return Icons.attach_money;
      default:
        return Icons.label;
    }
  }
}

/// Interactive image viewer with bounding box highlighting
class InteractiveBoundingBoxViewer extends StatefulWidget {
  final String imagePath;
  final List<BoundingBoxModel> boundingBoxes;
  final List<EntityModel>? entities;
  final Size imageSize;

  const InteractiveBoundingBoxViewer({
    super.key,
    required this.imagePath,
    required this.boundingBoxes,
    this.entities,
    required this.imageSize,
  });

  @override
  State<InteractiveBoundingBoxViewer> createState() =>
      _InteractiveBoundingBoxViewerState();
}

class _InteractiveBoundingBoxViewerState
    extends State<InteractiveBoundingBoxViewer> {
  final Set<String> _highlightedBoxIds = {};
  final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final displaySize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.asset(
                widget.imagePath,
                fit: BoxFit.contain,
              ),
              // Bounding box overlay
              BoundingBoxOverlay(
                boundingBoxes: widget.boundingBoxes,
                entities: widget.entities,
                imageSize: widget.imageSize,
                displaySize: displaySize,
                highlightedBoxIds: _highlightedBoxIds,
                showAllBoxes: false,
                onBoxTap: (box) => _handleBoxTap(box),
                onEntityTap: (entity) => _handleEntityTap(entity),
              ),
            ],
          ),
        );
      },
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
    // Find and highlight all boxes containing this entity
    final matchingBoxes = widget.boundingBoxes.where((box) =>
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
}
