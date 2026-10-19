import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/chat/chat_repository.dart';
import '../../../domain/models/chat/chat.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// A mock voice call: no audio yet. It rings until the friend picks up, then
/// the friend and you take turns talking on a fixed rhythm so every call
/// state shows.
class CallViewModel extends ChangeNotifier {
  CallViewModel({
    required String chatId,
    required ChatRepository chatRepository,
    this.endingHold = const Duration(milliseconds: 1500),
  }) : _chatId = chatId,
       _chatRepository = chatRepository {
    start = Command0(_start)..addListener(_changed);
    end = Command0(_end)..addListener(_changed);
    _chatRepository.addListener(_changed);
    start.execute();
  }

  /// Seconds per turn cycle; the friend talks for the first [_friendTurn].
  static const _turnCycle = 10;
  static const _friendTurn = 6;

  final String _chatId;
  final ChatRepository _chatRepository;

  /// How long the Ending state stays up before the call closes.
  final Duration endingHold;

  /// Rings the friend; run again to call again after a failure.
  late final Command0<void> start;
  late final Command0<void> end;
  Timer? _ticker;

  Duration _elapsed = Duration.zero;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _disposed = false;

  Chat? get chat => _chatRepository.cachedChat(_chatId);
  Duration get elapsed => _elapsed;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isDialing => start.running;
  bool get isFailed => start.error;
  bool get isAnswered => start.completed;
  bool get isEnded => end.running || end.completed;

  /// The call is up but its connection dropped; the timer keeps running.
  bool get isReconnecting =>
      isAnswered && !isEnded && !_chatRepository.isCallOnline;

  /// Picked up, not ended and online: the friend talks and listens.
  bool get isLive => isAnswered && !isEnded && !isReconnecting;

  /// While you are muted the friend keeps talking.
  bool get isFriendTalking =>
      isLive && (_isMuted || _elapsed.inSeconds % _turnCycle < _friendTurn);
  bool get isYouTalking => isLive && !isFriendTalking;

  /// Mute and Speaker work while ringing and in a live call.
  bool get canToggle => isDialing || isLive;

  void toggleMute() {
    if (!canToggle) return;
    _isMuted = !_isMuted;
    _changed();
  }

  void toggleSpeaker() {
    if (!canToggle) return;
    _isSpeakerOn = !_isSpeakerOn;
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _chatRepository.removeListener(_changed);
    start.removeListener(_changed);
    end.removeListener(_changed);
    super.dispose();
  }

  Future<Result<void>> _start() async {
    final result = await _chatRepository.startCall(_chatId);
    if (result is Ok<void> && !_disposed) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsed += const Duration(seconds: 1);
        _changed();
      });
    }
    return result;
  }

  /// Hanging up before the friend picks up leaves without a call record.
  Future<Result<void>> _end() async {
    if (!isAnswered) return const Result.ok(null);
    _ticker?.cancel();
    final (result, _) = await (
      _chatRepository.endCall(chatId: _chatId, duration: _elapsed),
      Future<void>.delayed(endingHold),
    ).wait;
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }
}
