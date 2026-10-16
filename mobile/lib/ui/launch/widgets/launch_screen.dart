import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../view_model/launch_viewmodel.dart';

/// Same wallpaper as the native splash, so the hand-off is seamless.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key, required this.viewModel});

  final LaunchViewModel viewModel;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  static const _contentTop = 112.0;

  @override
  void initState() {
    super.initState();
    widget.viewModel.load.addListener(_onLoad);
  }

  @override
  void dispose() {
    widget.viewModel.load.removeListener(_onLoad);
    super.dispose();
  }

  void _onLoad() {
    if (widget.viewModel.load.completed) context.go(Routes.chats);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash.png',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: _contentTop),
              child: Align(
                alignment: Alignment.topCenter,
                child: Semantics(
                  liveRegion: true,
                  label: 'Loading',
                  excludeSemantics: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Loading',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: Dimens.spaceL),
                      _BobbingDots(color: colors.onPrimary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three dots hopping in turn. Still when the OS asks for reduced motion.
class _BobbingDots extends StatefulWidget {
  const _BobbingDots({required this.color});

  final Color color;

  @override
  State<_BobbingDots> createState() => _BobbingDotsState();
}

class _BobbingDotsState extends State<_BobbingDots>
    with SingleTickerProviderStateMixin {
  static const _dotSize = 10.0;
  static const _hop = 6.0;

  /// Each dot starts 0.15s after the previous one in a 1.2s cycle.
  static const _stagger = 0.125;

  /// The hop peaks at 30% of the cycle and lands by 60%.
  static const _peak = 0.3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _offsetOf(int index) {
    final t = (_controller.value - index * _stagger) % 1.0;
    if (t >= _peak * 2) return 0;
    return -_hop * (1 - (t - _peak).abs() / _peak);
  }

  @override
  Widget build(BuildContext context) {
    final isStill = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Dimens.spaceS,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(0, isStill ? 0 : _offsetOf(i)),
              child: Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
