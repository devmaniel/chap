import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/repositories/chat/chat_repository_local.dart';
import 'package:app/domain/models/chat/chat.dart';
import 'package:app/ui/call/view_model/call_viewmodel.dart';

void main() {
  ChatRepositoryLocal repository({
    Duration ringDelay = Duration.zero,
    List<Exception> callFailures = const [],
    ({Duration after, Duration length})? callDrop,
  }) => ChatRepositoryLocal(
    latency: Duration.zero,
    ringDelay: ringDelay,
    callFailures: callFailures,
    callDrop: callDrop,
    chats: [
      Chat(
        id: 'mina',
        friendName: 'Mina',
        portraitAsset: 'assets/images/portrait_mina.png',
        friendVoice: 'Warm & gentle',
        lastMessage: 'Hi',
        lastMessageAt: DateTime(2026),
        unreadCount: 0,
      ),
    ],
  );

  test('rings until the friend picks up, then the timer starts', () {
    fakeAsync((async) {
      final viewModel = CallViewModel(
        chatId: 'mina',
        chatRepository: repository(ringDelay: const Duration(seconds: 3)),
      );

      expect(viewModel.isDialing, isTrue);
      viewModel.toggleMute();
      expect(viewModel.isMuted, isTrue);
      async.elapse(const Duration(seconds: 3));
      expect(viewModel.isAnswered, isTrue);
      expect(viewModel.elapsed, Duration.zero);
      async.elapse(const Duration(seconds: 2));
      expect(viewModel.elapsed, const Duration(seconds: 2));
      viewModel.dispose();
    });
  });

  test('hanging up while it rings leaves no call record', () {
    fakeAsync((async) {
      final chats = repository(ringDelay: const Duration(seconds: 3));
      final viewModel = CallViewModel(chatId: 'mina', chatRepository: chats);

      viewModel.end.execute();
      async.flushMicrotasks();
      expect(viewModel.end.completed, isTrue);
      expect(chats.cachedMessages('mina'), isEmpty);
      viewModel.dispose();
      async.elapse(const Duration(seconds: 3));
    });
  });

  test('a failed call can be called again', () {
    fakeAsync((async) {
      final viewModel = CallViewModel(
        chatId: 'mina',
        chatRepository: repository(callFailures: [Exception('call')]),
      );

      async.elapse(Duration.zero);
      expect(viewModel.isFailed, isTrue);
      expect(viewModel.isFriendTalking, isFalse);

      viewModel.start.execute();
      expect(viewModel.isDialing, isTrue);
      async.elapse(Duration.zero);
      expect(viewModel.isAnswered, isTrue);
      viewModel.dispose();
    });
  });

  test('a dropped connection pauses the call but keeps the timer', () {
    fakeAsync((async) {
      final viewModel = CallViewModel(
        chatId: 'mina',
        chatRepository: repository(
          callDrop: (
            after: const Duration(seconds: 2),
            length: const Duration(seconds: 3),
          ),
        ),
      );

      async.elapse(const Duration(seconds: 2));
      expect(viewModel.isReconnecting, isTrue);
      expect(viewModel.isFriendTalking, isFalse);
      expect(viewModel.canToggle, isFalse);
      async.elapse(const Duration(seconds: 3));
      expect(viewModel.isReconnecting, isFalse);
      expect(viewModel.elapsed, const Duration(seconds: 5));
      viewModel.dispose();
    });
  });

  test('timer counts up and muting keeps the friend talking', () {
    fakeAsync((async) {
      final viewModel = CallViewModel(
        chatId: 'mina',
        chatRepository: repository(),
      );

      async.elapse(const Duration(seconds: 7));
      expect(viewModel.elapsed, const Duration(seconds: 7));
      expect(viewModel.isYouTalking, isTrue);

      viewModel.toggleMute();
      expect(viewModel.isFriendTalking, isTrue);
      viewModel.dispose();
    });
  });

  test('ending records the call length in the chat', () {
    fakeAsync((async) {
      final chats = repository();
      final viewModel = CallViewModel(chatId: 'mina', chatRepository: chats);

      async.elapse(const Duration(seconds: 3));
      viewModel.end.execute();
      expect(viewModel.isEnded, isTrue);
      async.elapse(const Duration(seconds: 5));

      expect(viewModel.end.completed, isTrue);
      expect(viewModel.elapsed, const Duration(seconds: 3));
      expect(
        chats.cachedMessages('mina').last.callDuration,
        const Duration(seconds: 3),
      );
      expect(chats.cachedChat('mina')!.lastMessage, 'Voice call');
      viewModel.dispose();
    });
  });
}
