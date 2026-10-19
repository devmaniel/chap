import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../chat/view_model/chat_viewmodel.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/illustrations.dart';
import '../../core/ui/ai_tag.dart';
import '../../core/ui/app_icon.dart';
import '../view_model/call_viewmodel.dart';
import 'call_cat.dart';

/// Dialing layer fades out this fast when the friend picks up.
const _answerDuration = Duration(milliseconds: 250);

/// CSS `saturate(.8)`, for the friend behind a failed or dropped call.
const _desaturate = ColorFilter.matrix([
  0.84252, 0.14304, 0.01444, 0, 0, //
  0.04252, 0.94304, 0.01444, 0, 0, //
  0.04252, 0.14304, 0.81444, 0, 0, //
  0, 0, 0, 1, 0, //
]);

class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.viewModel});

  final CallViewModel viewModel;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.end.addListener(_ended);
  }

  /// Leaves once the Ending state has been shown.
  void _ended() {
    final end = widget.viewModel.end;
    if (!end.running && end.result != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    widget.viewModel.end.removeListener(_ended);
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final isDialing = viewModel.isDialing;
        // Ringing shows at once; only picking up animates.
        final fade = isDialing || MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : _answerDuration;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDialing
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(
                  excluding: isDialing,
                  child: _CallStage(viewModel: viewModel),
                ),
                if (viewModel.isReconnecting)
                  const Align(
                    alignment: Alignment(0, -0.08),
                    child: _ReconnectingPill(),
                  ),
                IgnorePointer(
                  ignoring: !isDialing,
                  child: ExcludeSemantics(
                    excluding: !isDialing,
                    child: AnimatedOpacity(
                      opacity: isDialing ? 1 : 0,
                      duration: fade,
                      curve: Curves.fastOutSlowIn,
                      child: _DialLayer(viewModel: viewModel, fade: fade),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The call itself: friend full screen, timer, your tile, controls.
class _CallStage extends StatelessWidget {
  const _CallStage({required this.viewModel});

  final CallViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = viewModel.chat?.friendName ?? '';
    final clock = callDurationLabel(viewModel.elapsed);
    final isFailed = viewModel.isFailed;
    final isBlurred = isFailed || viewModel.isReconnecting;
    final isPaused = isBlurred || viewModel.isEnded;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Illustrations.callStage),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimens.gutter,
                Dimens.spaceXl,
                Dimens.gutter,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Dimens.spaceM,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Dimens.space2xs,
                      children: [
                        Row(
                          spacing: Dimens.spaceS,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  letterSpacing: 0,
                                  color: colors.onSurface,
                                  fontSize: 28,
                                  height: 1.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const AiTag(),
                          ],
                        ),
                        Semantics(
                          liveRegion: isPaused,
                          child: Text(
                            isFailed
                                ? 'Call Failed'
                                : viewModel.isEnded
                                ? 'Call ended · $clock'
                                : clock,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              letterSpacing: 0,
                              color: colors.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SelfTile(
                    isMuted: viewModel.isMuted && !viewModel.isEnded,
                    isTalking: viewModel.isYouTalking,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedOpacity(
              opacity: isPaused ? .55 : 1,
              duration: const Duration(milliseconds: 300),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // The cat is wider than the screen and sinks under
                  // the control bar, as in the mockup.
                  final side = constraints.maxWidth * 460 / 390;
                  final cat = CallCat(
                    name: name,
                    isTalking: viewModel.isFriendTalking,
                    isEnded: isPaused,
                  );
                  return ClipRect(
                    child: Stack(
                      children: [
                        Positioned(
                          left: (constraints.maxWidth - side) / 2,
                          bottom: -side * 60 / 460,
                          width: side,
                          height: side,
                          child: isBlurred
                              ? ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 14,
                                    sigmaY: 14,
                                  ),
                                  child: ColorFiltered(
                                    colorFilter: _desaturate,
                                    child: cat,
                                  ),
                                )
                              : cat,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          isFailed
              ? _FailedBar(viewModel: viewModel)
              : _CallBar(viewModel: viewModel),
        ],
      ),
    );
  }
}

/// iPhone-style outgoing call shown while it rings. On pick-up it fades out
/// over the call already in place underneath, the photo zooming slightly.
class _DialLayer extends StatelessWidget {
  const _DialLayer({required this.viewModel, required this.fade});

  final CallViewModel viewModel;
  final Duration fade;

  static const _photo = 128.0;
  static const _control = 76.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chat = viewModel.chat;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Illustrations.callDial),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimens.gutter,
                Dimens.space2xl,
                Dimens.gutter,
                0,
              ),
              child: Column(
                spacing: Dimens.space2xs,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: Dimens.spaceS,
                    children: [
                      Flexible(
                        child: Text(
                          chat?.friendName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            letterSpacing: 0,
                            color: colors.onPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const AiTag(),
                    ],
                  ),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'calling…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        letterSpacing: 0,
                        color: colors.onPrimary.withValues(alpha: .7),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: AnimatedScale(
                scale: viewModel.isDialing ? 1 : 1.15,
                duration: fade,
                curve: Curves.fastOutSlowIn,
                child: chat == null
                    ? const SizedBox.square(dimension: _photo)
                    : ClipOval(
                        child: Image.asset(
                          chat.portraitAsset,
                          width: _photo,
                          height: _photo,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                        ),
                      ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 72),
            child: Column(
              spacing: Dimens.space2xl,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 64,
                  children: [
                    _CallChoice(
                      label: 'Mute',
                      child: _CallControl(
                        label: 'Mute',
                        icon: viewModel.isMuted
                            ? AppIconName.micOff
                            : AppIconName.mic,
                        isPressed: viewModel.isMuted,
                        size: _control,
                        onPressed: viewModel.toggleMute,
                      ),
                    ),
                    _CallChoice(
                      label: 'Speaker',
                      child: _CallControl(
                        label: 'Speaker',
                        icon: AppIconName.speaker,
                        isPressed: viewModel.isSpeakerOn,
                        size: _control,
                        onPressed: viewModel.toggleSpeaker,
                      ),
                    ),
                  ],
                ),
                _CallChoice(
                  label: 'End',
                  child: _CallControl(
                    label: 'End call',
                    icon: AppIconName.phone,
                    fill: colors.error,
                    size: _control,
                    iconTurns: 135 / 360,
                    onPressed: viewModel.end.execute,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Connection dropped mid-call: glass pill over the blurred friend.
class _ReconnectingPill extends StatelessWidget {
  const _ReconnectingPill();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.gutter),
      child: Semantics(
        liveRegion: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: Dimens.spaceSm,
              ),
              color: const Color(0x991A252C),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: Dimens.spaceS,
                children: [
                  AppIcon(
                    AppIconName.wifiOff,
                    color: colors.onPrimary,
                    size: Dimens.iconS,
                  ),
                  Flexible(
                    child: Text(
                      'Reconnecting…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        letterSpacing: 0,
                        color: colors.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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

/// You have no camera on a call, so this shows your picture and name.
/// There is no profile picture yet, so it is always the person icon.
class _SelfTile extends StatelessWidget {
  const _SelfTile({required this.isMuted, required this.isTalking});

  final bool isMuted;
  final bool isTalking;

  static const _width = 88.0;
  static const _avatar = 56.0;
  static const _badge = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: isMuted
          ? 'You, muted'
          : isTalking
          ? 'You, talking'
          : 'You, mic on',
      excludeSemantics: true,
      child: Stack(
        children: [
          Container(
            width: _width,
            padding: const EdgeInsets.fromLTRB(
              Dimens.spaceS,
              Dimens.spaceM,
              Dimens.spaceS,
              Dimens.spaceS,
            ),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(Dimens.bubbleRadius),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: .12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              spacing: Dimens.spaceXs,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _avatar,
                  height: _avatar,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceContainerLow,
                    boxShadow: isTalking
                        ? [
                            BoxShadow(color: colors.surface, spreadRadius: 3),
                            BoxShadow(color: colors.primary, spreadRadius: 6),
                          ]
                        : const [],
                  ),
                  child: Center(
                    child: AppIcon(
                      AppIconName.person,
                      color: colors.onSurfaceVariant,
                      size: 28,
                    ),
                  ),
                ),
                Text(
                  'You',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    letterSpacing: 0,
                    color: colors.onSurface,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (isMuted)
            Positioned(
              top: Dimens.spaceXs,
              right: Dimens.spaceXs,
              child: Container(
                width: _badge,
                height: _badge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.error,
                ),
                child: Center(
                  child: AppIcon(
                    AppIconName.micOff,
                    color: colors.onError,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dark floor the call controls sit on.
class _ControlFloor extends StatelessWidget {
  const _ControlFloor({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Illustrations.callBar),
      // Mockup leaves 56 under the buttons, home indicator included, so the
      // inset counts toward it instead of adding to it.
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 56),
        child: Padding(
          padding: const EdgeInsets.only(top: Dimens.spaceXl),
          child: child,
        ),
      ),
    );
  }
}

class _CallBar extends StatelessWidget {
  const _CallBar({required this.viewModel});

  final CallViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canToggle = viewModel.canToggle;
    return _ControlFloor(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 36,
        children: [
          _CallControl(
            label: 'Mute',
            icon: viewModel.isMuted ? AppIconName.micOff : AppIconName.mic,
            isPressed: viewModel.isMuted,
            onPressed: canToggle ? viewModel.toggleMute : null,
          ),
          _CallControl(
            label: 'End call',
            icon: AppIconName.phone,
            fill: colors.error,
            size: 64,
            iconTurns: 135 / 360,
            onPressed: viewModel.isEnded ? null : viewModel.end.execute,
          ),
          _CallControl(
            label: 'Speaker',
            icon: AppIconName.speaker,
            isPressed: viewModel.isSpeakerOn,
            onPressed: canToggle ? viewModel.toggleSpeaker : null,
          ),
        ],
      ),
    );
  }
}

/// FaceTime-style Cancel and Call again after a call fails.
class _FailedBar extends StatelessWidget {
  const _FailedBar({required this.viewModel});

  final CallViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _ControlFloor(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 72,
        children: [
          _CallChoice(
            label: 'Cancel',
            child: _CallControl(
              label: 'Cancel',
              icon: AppIconName.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          _CallChoice(
            label: 'Call again',
            child: _CallControl(
              label: 'Call again',
              icon: AppIconName.phone,
              fill: colors.secondary,
              onPressed: viewModel.start.execute,
            ),
          ),
        ],
      ),
    );
  }
}

/// A call control with its name under it.
class _CallChoice extends StatelessWidget {
  const _CallChoice({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: Dimens.spaceS,
      children: [
        child,
        ExcludeSemantics(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              letterSpacing: 0,
              color: colors.onPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPressed,
    this.fill,
    this.size = 56,
    this.iconTurns = 0,
  });

  final String label;
  final AppIconName icon;
  final VoidCallback? onPressed;

  /// Null for a plain button, otherwise a toggle.
  final bool? isPressed;
  final Color? fill;
  final double size;
  final double iconTurns;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pressed = isPressed ?? false;
    return Semantics(
      button: true,
      toggled: isPressed,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? .5 : 1,
        child: Material(
          type: MaterialType.circle,
          color:
              fill ??
              (pressed
                  ? colors.surface
                  : colors.surface.withValues(alpha: .15)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: Transform.rotate(
                  angle: iconTurns * 2 * math.pi,
                  child: AppIcon(
                    icon,
                    color: pressed ? colors.onSurface : colors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
