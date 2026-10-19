import 'package:flutter/material.dart';

import '../themes/dimens.dart';

/// Chunky 3D surface: a solid edge under the box, which a press sinks into.
/// Static when [onTap] is null.
class RaisedBox extends StatefulWidget {
  const RaisedBox({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.borderColor,
    this.edgeColor,
    this.isBordered = true,
    this.radius = 14,
    this.padding = EdgeInsets.zero,
    this.constraints,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Defaults to the page surface.
  final Color? color;

  /// Defaults to the hairline color.
  final Color? borderColor;

  /// Defaults to [borderColor].
  final Color? edgeColor;
  final bool isBordered;
  final double radius;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;

  @override
  State<RaisedBox> createState() => _RaisedBoxState();
}

class _RaisedBoxState extends State<RaisedBox> {
  static const _pressDuration = Duration(milliseconds: 100);

  bool _isPressed = false;

  void _setPressed(bool value) {
    if (widget.onTap != null) setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = widget.borderColor ?? colors.outlineVariant;
    final box = AnimatedContainer(
      duration: _pressDuration,
      curve: Curves.easeOut,
      constraints: widget.constraints,
      padding: widget.padding,
      clipBehavior: Clip.antiAlias,
      transform: Matrix4.translationValues(
        0,
        _isPressed ? Dimens.buttonEdge : 0,
        0,
      ),
      decoration: BoxDecoration(
        color: widget.color ?? colors.surface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: widget.isBordered
            ? Border.all(color: border, width: Dimens.borderWidth)
            : null,
        boxShadow: [
          if (!_isPressed)
            BoxShadow(
              color: widget.edgeColor ?? border,
              offset: const Offset(0, Dimens.buttonEdge),
            ),
        ],
      ),
      child: widget.child,
    );
    if (widget.onTap == null) return box;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: box,
      ),
    );
  }
}
