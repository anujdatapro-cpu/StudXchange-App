import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PressableGlow extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Color glowColor;
  final Duration duration;
  final double pressedScale;
  final EdgeInsetsGeometry? padding;

  const PressableGlow({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.glowColor = const Color(0xFF00FFFF),
    this.duration = const Duration(milliseconds: 200),
    this.pressedScale = 0.98,
    this.padding,
  });

  @override
  State<PressableGlow> createState() => _PressableGlowState();
}

class _PressableGlowState extends State<PressableGlow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap?.call();
            }
          : null,
      child: Transform.scale(
        scale: _pressed ? widget.pressedScale : 1.0,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: widget.glowColor.withAlpha(153),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

