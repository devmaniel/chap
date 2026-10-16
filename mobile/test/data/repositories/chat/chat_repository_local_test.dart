import 'package:app/data/repositories/chat/chat_repository_local.dart';
import 'package:app/domain/models/chat/chat.dart';
import 'package:app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

Chat chatAt(String id, DateTime at) => Chat(
  id: id,
  friendName: id,
  portraitAsset: 'assets/images/portrait_$id.png',
  lastMessage: 'hi',
  lastMessageAt: at,
  unreadCount: 0,
);

void main() {
  test('returns chats newest first', () async {
    final repository = ChatRepositoryLocal(
      latency: Duration.zero,
      chats: [
        chatAt('old', DateTime.utc(2026, 10, 1)),
        chatAt('new', DateTime.utc(2026, 10, 3)),
        chatAt('mid', DateTime.utc(2026, 10, 2)),
      ],
    );

    final result = await repository.getChats();

    final ids = (result as Ok<List<Chat>>).value.map((chat) => chat.id);
    expect(ids, ['new', 'mid', 'old']);
  });
}
