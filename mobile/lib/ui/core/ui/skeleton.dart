import 'package:flutter/material.dart';

/// Grey placeholder for content that is still loading. Pulses gently;
/// wrap a group of these in one `Semantics(liveRegion: true)` label.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 6,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final double radius;
  final BoxShape shape;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  static const _pulse = Duration(milliseconds: 900);
  static const _dimmest = 0.45;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _pulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: _dimmest).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
