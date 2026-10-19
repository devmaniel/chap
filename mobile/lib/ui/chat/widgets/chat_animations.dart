import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';

/// iMessage-style entrance: the bubble springs up from its tail corner.
class BubblePop extends StatefulWidget {
  const BubblePop({super.key, required this.child, this.onComplete});

  final Widget child;
  final VoidCallback? onComplete;

  @override
  State<BubblePop> createState() => _BubblePopState();
}

class _BubblePopState extends State<BubblePop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final _scale = CurvedAnimation(
    parent: _animation,
    curve: Curves.easeOutBack,
  );
  late final _fade = CurvedAnimation(
    parent: _animation,
    curve: const Interval(0, .4, curve: Curves.easeOut),
  );
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _animation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 420),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onComplete?.call();
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onComplete?.call();
      });
    } else {
      _animation.forward();
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    _fade.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: .6, end: 1).animate(_scale),
        alignment: Alignment.bottomLeft,
        child: widget.child,
      ),
    );
  }
}

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({
    super.key,
    required this.name,
    required this.portraitAsset,
  });

  final String name;
  final String portraitAsset;

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  /// Soft sequential pulse like iMessage: each dot brightens and swells in turn.
  static double _pulse(double phase) =>
      phase < .5 ? math.sin(phase * 2 * math.pi) : 0;

  static Widget _dot(double pulse, ColorScheme colors) => Transform.scale(
    scale: .85 + .15 * pulse,
    child: Container(
      width: Dimens.typingDot,
      height: Dimens.typingDot,
      decoration: BoxDecoration(
        color: colors.outline.withValues(alpha: .4 + .6 * pulse),
        shape: BoxShape.circle,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: '${widget.name} is thinking',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Dimens.spaceL),
        child: Row(
          spacing: Dimens.spaceS,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipOval(
              child: Image.asset(
                widget.portraitAsset,
                width: Dimens.space3xl,
                height: Dimens.space3xl,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            BubblePop(
              child: Container(
                padding: Dimens.chatBubblePadding,
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(
                    color: colors.outlineVariant,
                    width: Dimens.borderWidth,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Dimens.bubbleRadius),
                    topRight: Radius.circular(Dimens.bubbleRadius),
                    bottomLeft: Radius.circular(Dimens.spaceXs),
                    bottomRight: Radius.circular(Dimens.bubbleRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.outlineVariant,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: Dimens.spaceTiny,
                    children: [
                      for (var i = 0; i < 3; i++)
                        _dot(_pulse((_animation.value - i * .2) % 1), colors),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
