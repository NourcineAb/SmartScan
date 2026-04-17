import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/feedback_service.dart';

class FloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final bool isDarkMode;

  const FloatingNavBar({
    required this.currentIndex,
    required this.onTabChanged,
    required this.isDarkMode,
    super.key,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTabPressed(int index) async {
    await FeedbackService().onTap();
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.description, 'label': 'Scans'},
      {'icon': Icons.translate, 'label': 'Translate'},
      {'icon': Icons.settings, 'label': 'Settings'},
    ];

    final backgroundColor = widget.isDarkMode
        ? AppColors.darkCard.withValues(alpha: 0.95)
        : Colors.white;
    final inactiveColor = widget.isDarkMode
        ? AppColors.darkTextSecondary.withValues(alpha: 0.6)
        : AppColors.lightTextSecondary;
    final activeColor = widget.isDarkMode ? AppColors.coral : AppColors.primary;

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: 70,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              items.length,
              (index) => _buildNavItem(
                icon: items[index]['icon'] as IconData,
                label: items[index]['label'] as String,
                isActive: widget.currentIndex == index,
                onPressed: () => _onTabPressed(index),
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: activeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isActive ? _scaleAnimation.value : 1.0,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with active indicator dot
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 24,
                        color: isActive ? activeColor : inactiveColor,
                      ),
                      if (isActive)
                        Positioned(
                          bottom: -8,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isActive ? 11 : 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? activeColor : inactiveColor,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
