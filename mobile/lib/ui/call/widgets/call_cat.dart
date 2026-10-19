import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The friend on the call stage, from a sprite copied from the master mockup:
/// 5 mouth columns on one body, rows are eyes open, half-closed, closed.
/// Talking runs sentences of 1-3 syllable words; blinking runs on its own clock.
class CallCat extends StatefulWidget {
  const CallCat({
    super.key,
    required this.name,
    required this.isTalking,
    required this.isEnded,
  });

  final String name;
  final bool isTalking;

  /// Eyes stay half-closed and nothing moves.
  final bool isEnded;

  @override
  State<CallCat> createState() => _CallCatState();
}

const _closed = 0, _smallO = 1, _half = 2, _open = 3, _wide = 4, _frames = 5;
const _eyesOpen = 0, _eyesHalf = 1, _eyesShut = 2, _eyeRows = 3;
const _peaks = [_smallO, _open, _open, _wide, _half];

/// A mouth or eye frame and how long it holds, in milliseconds.
typedef _Step = (int frame, double ms);

class _CallCatState extends State<CallCat> {
  final _random = math.Random();
  int _mouth = _closed;
  int _eyes = _eyesOpen;
  List<_Step> _sentence = [];
  Timer? _talkTimer;
  Timer? _blinkTimer;

  double _rand(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  Duration _ms(double ms) => Duration(milliseconds: ms.round());

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(CallCat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTalking != widget.isTalking ||
        oldWidget.isEnded != widget.isEnded) {
      _sync();
    }
  }

  void _sync() {
    _talkTimer?.cancel();
    _sentence = [];
    if (widget.isEnded) {
      _blinkTimer?.cancel();
      _blinkTimer = null;
      _setFrame(mouth: _closed, eyes: _eyesHalf);
      return;
    }
    _setFrame(mouth: _closed);
    if (widget.isTalking) _talk();
    _blinkTimer ??= Timer(_ms(_rand(800, 3000)), () => _blink(_blinkSteps()));
  }

  void _setFrame({int? mouth, int? eyes}) {
    if (!mounted) return;
    setState(() {
      _mouth = mouth ?? _mouth;
      _eyes = eyes ?? _eyes;
    });
  }

  List<_Step> _newSentence() {
    final steps = <_Step>[];
    for (var w = _rand(3, 7).round(); w > 0; w--) {
      for (var s = _rand(1, 3).round(); s > 0; s--) {
        final peak = _peaks[_random.nextInt(_peaks.length)];
        steps.addAll([(_half, _rand(50, 70)), (peak, _rand(90, 140))]);
        if (peak != _smallO) steps.add((_half, _rand(50, 70)));
      }
      steps.add((_closed, _rand(120, 240)));
    }
    steps.add((_closed, _rand(700, 1400)));
    return steps;
  }

  void _talk() {
    if (_sentence.isEmpty) _sentence = _newSentence();
    final (frame, ms) = _sentence.first;
    _sentence = _sentence.sublist(1);
    _setFrame(mouth: frame);
    _talkTimer = Timer(_ms(ms), _talk);
  }

  /// Lid comes down fast, holds briefly, opens a little slower.
  List<_Step> _blinkSteps() => [
    (_eyesHalf, 40),
    (_eyesShut, _rand(60, 90)),
    (_eyesHalf, 60),
    (_eyesOpen, 0),
  ];

  void _blink(List<_Step> steps) {
    final (eyes, ms) = steps.first;
    _setFrame(eyes: eyes);
    final rest = steps.sublist(1);
    // Sometimes a quick double blink, otherwise wait 2-6s.
    _blinkTimer = rest.isNotEmpty
        ? Timer(_ms(ms), () => _blink(rest))
        : Timer(
            _ms(
              _random.nextDouble() < 0.2 ? _rand(120, 200) : _rand(2000, 6000),
            ),
            () => _blink(_blinkSteps()),
          );
  }

  @override
  void dispose() {
    _talkTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.isEnded
        ? 'call ended'
        : widget.isTalking
        ? 'talking'
        : 'listening';
    return Semantics(
      image: true,
      label: '${widget.name}, an orange cat, $state',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.maxWidth;
          return ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: -_mouth * side,
                  top: -_eyes * side,
                  width: side * _frames,
                  height: side * _eyeRows,
                  child: Image.asset(
                    'assets/images/call_cat.png',
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
