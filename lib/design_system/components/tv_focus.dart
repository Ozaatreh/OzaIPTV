import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../motion/motion_tokens.dart';

/// Wraps any child widget with TV-friendly focus management.
///
/// Provides visible focus ring, scale animation, and D-pad
/// traversal support following 10-foot UI principles.
class TvFocusable extends StatefulWidget {
  const TvFocusable({
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = AppRadius.card,
    this.focusColor,
    this.scaleFactor = 1.05,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autofocus;
  final double borderRadius;
  final Color? focusColor;
  final double scaleFactor;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool focused) {
    setState(() => _isFocused = focused);
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.focusColor ?? AppColors.accentGold;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: (node, event) {
        // Handle select/enter as tap
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          setState(() => _isPressed = true);
          widget.onPressed?.call();
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) setState(() => _isPressed = false);
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          transform: Matrix4.identity()
            ..scale(
              _isFocused
                  ? (_isPressed ? 1.0 : widget.scaleFactor)
                  : (_isPressed ? 0.97 : 1.0),
            ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: _isFocused
                ? Border.all(color: focusColor, width: 2.5)
                : null,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: focusColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A TV-safe scrollable grid that manages focus traversal order.
class TvFocusTraversalGroup extends StatelessWidget {
  const TvFocusTraversalGroup({
    required this.child,
    this.policy,
    super.key,
  });

  final Widget child;
  final FocusTraversalPolicy? policy;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: policy ??  ReadingOrderTraversalPolicy(),
      child: child,
    );
  }
}
