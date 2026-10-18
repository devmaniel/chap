import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';

/// Only a newly received reply reveals; history stays fully readable.
class ReplyText extends StatefulWidget {
  const ReplyText({
    super.key,
    required this.text,
    required this.style,
    required this.onComplete,
  });

  final String text;
  final TextStyle style;
  final VoidCallback onComplete;

  @override
  State<ReplyText> createState() => _ReplyTextState();
}

class _ReplyTextState extends State<ReplyText>
    with SingleTickerProviderStateMixin {
  late final _characters = widget.text.characters.toList();
  late final _animation =
      AnimationController(
        vsync: this,
        duration: Duration(milliseconds: math.max(1, _characters.length * 22)),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
      if (!_started || _animation.value < 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onComplete();
        });
      }
    } else if (!_started) {
      _animation.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => Text(
          reducedMotion
              ? widget.text
              : _characters
                    .take((_characters.length * _animation.value).ceil())
                    .join(),
          style: widget.style,
        ),
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
    duration: const Duration(seconds: 1),
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
            AnimatedBuilder(
              animation: _animation,
              builder: (context, _) => Row(
                spacing: Dimens.spaceXs,
                children: [
                  for (var i = 0; i < 3; i++)
                    Transform.translate(
                      offset: Offset(
                        0,
                        -Dimens.spaceXs *
                            math.max(
                              0,
                              math.sin(
                                (_animation.value - i * .15) * math.pi * 2,
                              ),
                            ),
                      ),
                      child: Container(
                        width: Dimens.spaceS,
                        height: Dimens.spaceS,
                        decoration: BoxDecoration(
                          color: colors.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
