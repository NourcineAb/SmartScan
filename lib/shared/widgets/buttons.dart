import 'package:flutter/material.dart';
import 'package:smart_scan/core/services/feedback_service.dart';

/// Custom ElevatedButton with tap sound feedback
class SmartElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget child;
  final ButtonStyle? style;
  final bool isLoading;

  const SmartElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.style,
    this.isLoading = false,
  });

  void _onPressed() async {
    if (!isLoading && onPressed != null) {
      await FeedbackService().onTap();
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : _onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return ElevatedButton(
      onPressed: isLoading ? null : _onPressed,
      style: style,
      child: child,
    );
  }
}

/// Custom TextButton with tap sound feedback
class SmartTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget child;
  final ButtonStyle? style;

  const SmartTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.style,
  });

  void _onPressed() async {
    if (onPressed != null) {
      await FeedbackService().onTap();
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return TextButton.icon(
        onPressed: _onPressed,
        style: style,
        icon: icon!,
        label: child,
      );
    }
    return TextButton(
      onPressed: _onPressed,
      style: style,
      child: child,
    );
  }
}

/// Custom IconButton with tap sound feedback
class SmartIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final double? iconSize;
  final Color? color;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final ButtonStyle? style;

  const SmartIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.padding,
    this.constraints,
    this.iconSize,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.style,
  });

  void _onPressed() async {
    if (onPressed != null) {
      await FeedbackService().onTap();
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _onPressed,
      icon: icon,
      tooltip: tooltip,
      padding: padding,
      constraints: constraints,
      iconSize: iconSize,
      color: color,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      style: style,
    );
  }
}

/// Custom FloatingActionButton with tap sound feedback
class SmartFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final FloatingActionButtonLocation? location;
  final FloatingActionButtonAnimator? animator;
  final bool isExtended;
  final ShapeBorder? shape;
  final Clip clipBehavior;
  final bool autofocus;
  final MaterialTapTargetSize? materialTapTargetSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? splashColor;
  final Color? elevation;
  final double? iconSize;

  const SmartFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.location,
    this.animator,
    this.isExtended = false,
    this.shape,
    this.clipBehavior = Clip.none,
    this.autofocus = false,
    this.materialTapTargetSize,
    this.backgroundColor,
    this.foregroundColor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.elevation,
    this.iconSize,
  });

  void _onPressed() async {
    if (onPressed != null) {
      await FeedbackService().onTap();
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _onPressed,
      tooltip: tooltip,
      shape: shape,
      clipBehavior: clipBehavior,
      autofocus: autofocus,
      materialTapTargetSize: materialTapTargetSize,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      splashColor: splashColor,
      child: child,
    );
  }
}

/// Custom InkWell with tap sound feedback
class SmartInkWell extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final MouseCursor? mouseCursor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final InteractiveInkFeatureFactory? splashFactory;
  final double? radius;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final bool enableFeedback;
  final bool excludeFromSemantics;
  final FocusNode? focusNode;
  final bool canRequestFocus;
  final bool autofocus;
  final Widget? child;

  const SmartInkWell({
    super.key,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onHover,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.splashFactory,
    this.radius,
    this.borderRadius,
    this.customBorder,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
    this.focusNode,
    this.canRequestFocus = true,
    this.autofocus = false,
    this.child,
  });

  void _onTap() async {
    if (onTap != null) {
      await FeedbackService().onTap();
      onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      onHover: onHover,
      mouseCursor: mouseCursor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      splashFactory: splashFactory,
      radius: radius,
      borderRadius: borderRadius,
      customBorder: customBorder,
      enableFeedback: enableFeedback,
      excludeFromSemantics: excludeFromSemantics,
      focusNode: focusNode,
      canRequestFocus: canRequestFocus,
      autofocus: autofocus,
      child: child,
    );
  }
}

/// Custom GestureDetector with tap sound feedback
class SmartGestureDetector extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final GestureDragCancelCallback? onVerticalDragCancel;
  final GestureDragStartCallback? onHorizontalDragStart;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final GestureDragCancelCallback? onHorizontalDragCancel;
  final Widget child;
  final HitTestBehavior? behavior;

  const SmartGestureDetector({
    super.key,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
    required this.child,
    this.behavior,
  });

  void _onTap() async {
    if (onTap != null) {
      await FeedbackService().onTap();
      onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      onVerticalDragCancel: onVerticalDragCancel,
      onHorizontalDragStart: onHorizontalDragStart,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      onHorizontalDragCancel: onHorizontalDragCancel,
      behavior: behavior,
      child: child,
    );
  }
}
