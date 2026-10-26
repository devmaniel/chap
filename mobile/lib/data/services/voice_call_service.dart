import 'package:elevenlabs_agents/elevenlabs_agents.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/result.dart';

/// Live voice calls through ElevenLabs. Each call starts from a short-lived
/// pass the server hands out, so the ElevenLabs key never ships in the app.
/// Notifies when a call connects or drops.
class VoiceCallService extends ChangeNotifier {
  /// Created on the first call, so nothing loads until one is made.
  ConversationClient? _client;

  /// True while a call is up; false before it, after it, and once it drops.
  bool get isConnected => _client?.status == ConversationStatus.connected;

  Future<bool> requestMicrophone() async =>
      (await Permission.microphone.request()).isGranted;

  /// Connects as the friend described by the pass. Completes once the call
  /// is up.
  Future<Result<void>> start({
    required String conversationToken,
    required String prompt,
    required String firstMessage,
    required String voiceId,
  }) async {
    final client = _client ??= ConversationClient()
      ..addListener(notifyListeners);
    try {
      await client.startSession(
        conversationToken: conversationToken,
        // The shared agent's prompt is "{{friend_prompt}}" and its first
        // message "{{greeting}}". ElevenLabs rejects this package's prompt
        // override (it sends the prompt unnested), so the friend arrives as
        // dynamic variables and only the voice is an override.
        dynamicVariables: {'friend_prompt': prompt, 'greeting': firstMessage},
        overrides: ConversationOverrides(tts: TtsOverrides(voiceId: voiceId)),
      );
      return const Result.ok(null);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<void> end() async => _client?.endSession();

  @override
  void dispose() {
    _client?.dispose();
    super.dispose();
  }
}
