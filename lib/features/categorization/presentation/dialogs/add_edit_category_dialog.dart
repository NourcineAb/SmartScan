import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../core/services/feedback_service.dart';

class AddEditCategoryDialog extends StatefulWidget {
  final CategoryModel? category;

  const AddEditCategoryDialog({super.key, this.category});

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late int _selectedColor;
  String? _errorMessage;

  final List<String> _iconOptions = [
    'receipt',
    'shopping_cart',
    'credit_card',
    'description',
    'folder',
    'image',
    'note',
    'assignment',
    'inventory_2',
    'local_library',
    'payment',
    'collections_bookmark',
    'article',
    'backup',
    'bookmarks',
    'domain',
  ];

  final List<Color> _colorOptions = [
    // Red range
    const Color(0xFFFF0000),
    const Color(0xFFFF4500),
    const Color(0xFFFF6347),
    const Color(0xFFFF8C00),
    // Yellow range
    const Color(0xFFFFD700),
    const Color(0xFFFFED4E),
    const Color(0xFFFFFF00),
    const Color(0xFFADFF2F),
    // Green range
    const Color(0xFF00FF00),
    const Color(0xFF00FA9A),
    const Color(0xFF00CED1),
    const Color(0xFF00BFFF),
    // Cyan/Blue range
    const Color(0xFF0099FF),
    const Color(0xFF0072FF),
    const Color(0xFF0000FF),
    const Color(0xFF4B0082),
    // Purple range
    const Color(0xFF9932CC),
    const Color(0xFFBA55D3),
    const Color(0xFFFF1493),
    const Color(0xFFFF69B4),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? 'folder';
    _selectedColor = widget.category?.color ?? _colorOptions[0].value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a category name';
      });
      return;
    }

    Navigator.pop(context, {
      'name': _nameController.text,
      'icon': _selectedIcon,
      'color': _selectedColor,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message (appears at the top if validation fails)
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    border:
                        Border.all(color: const Color(0xFFEF5350), width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF5350),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFEF5350),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _errorMessage = null);
                        },
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFFEF5350),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Header
              Text(
                widget.category == null ? 'New Category' : 'Edit Category',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Name input
              Text(
                'Category Name',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Invoices, Receipts',
                  filled: true,
                  fillColor: AppColors.neutral100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.neutral300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.neutral300),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Icon selection
              Text('Icon', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _iconOptions.length,
                  itemBuilder: (context, index) {
                    final icon = _iconOptions[index];
                    final isSelected = icon == _selectedIcon;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedIcon = icon);
                        },
                        child: Container(
                          width: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.neutral100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.neutral300,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getIconData(icon),
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Color selection with preview
              Text('Color Palette',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),

              // Preview of category
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(_selectedColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: Icon(
                    _getIconData(_selectedIcon),
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Color wheel palette
              Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Color wheel background
                      CustomPaint(
                        size: const Size(280, 280),
                        painter: ColorWheelPainter(
                          colors: _colorOptions,
                          selectedColorHash: _selectedColor,
                        ),
                      ),
                      // Color selection buttons on wheel
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: Stack(
                          children: List.generate(
                            _colorOptions.length,
                            (index) {
                              final angle =
                                  (index / _colorOptions.length) * 2 * pi;
                              final radius = 110.0;
                              final x = 140 + radius * cos(angle - pi / 2);
                              final y = 140 + radius * sin(angle - pi / 2);

                              final color = _colorOptions[index];
                              final isSelected = color.value == _selectedColor;

                              return Positioned(
                                left: x - 22,
                                top: y - 22,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(
                                        () => _selectedColor = color.value);
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                        width: isSelected ? 3 : 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 20)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      await FeedbackService().onTap();
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await FeedbackService().onTap();
                      _submit();
                    },
                    child: Text(widget.category == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final icons = {
      'receipt': Icons.receipt,
      'shopping_cart': Icons.shopping_cart,
      'credit_card': Icons.credit_card,
      'description': Icons.description,
      'folder': Icons.folder,
      'image': Icons.image,
      'note': Icons.note,
      'assignment': Icons.assignment,
      'inventory_2': Icons.inventory_2,
      'local_library': Icons.local_library,
      'payment': Icons.payment,
      'collections_bookmark': Icons.collections_bookmark,
      'article': Icons.article,
      'backup': Icons.backup,
      'bookmarks': Icons.bookmarks,
      'domain': Icons.domain,
    };
    return icons[iconName] ?? Icons.category;
  }
}

class ColorWheelPainter extends CustomPainter {
  final List<Color> colors;
  final int selectedColorHash;

  ColorWheelPainter({
    required this.colors,
    required this.selectedColorHash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;

    // Draw gradient background
    for (int i = 0; i < colors.length; i++) {
      final angle = (i / colors.length) * 2 * pi;
      final nextAngle = ((i + 1) / colors.length) * 2 * pi;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        angle - pi / 2,
        (nextAngle - angle),
        true,
      );
      path.close();

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }

    // Draw center circle
    canvas.drawCircle(
      center,
      30,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(ColorWheelPainter oldDelegate) => false;
}
