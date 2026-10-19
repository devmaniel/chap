import 'package:app/data/repositories/chat/chat_repository_local.dart';
import 'package:app/domain/models/chat/chat.dart';
import 'package:app/ui/chats/view_model/chats_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 16, 12);

Chat chat(String name, String lastMessage, Duration ago) => Chat(
  id: name.toLowerCase(),
  friendName: name,
  portraitAsset: 'assets/images/portrait_mina.png',
  friendVoice: 'Warm & gentle',
  lastMessage: lastMessage,
  lastMessageAt: _now.subtract(ago),
  unreadCount: 0,
);

void main() {
  late ChatsViewModel viewModel;

  setUp(() async {
    viewModel = ChatsViewModel(
      chatRepository: ChatRepositoryLocal(
        latency: Duration.zero,
        chats: [
          chat('Mina', 'I finally found that little bookshop.', Duration.zero),
          chat('Kai', 'One song for a rainy walk.', const Duration(hours: 1)),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);
  });

  test('loads every chat', () {
    expect(viewModel.load.running, isFalse);
    expect(viewModel.chats.map((c) => c.friendName), ['Mina', 'Kai']);
  });

  test('search matches names and message text, ignoring case', () {
    viewModel
      ..openSearch()
      ..setQuery('BOOK');
    expect(viewModel.chats.map((c) => c.friendName), ['Mina']);

    viewModel.setQuery('kai');
    expect(viewModel.chats.map((c) => c.friendName), ['Kai']);

    viewModel.setQuery('zebra');
    expect(viewModel.chats, isEmpty);
  });

  test('closing search drops the query', () {
    viewModel
      ..openSearch()
      ..setQuery('zebra')
      ..closeSearch();

    expect(viewModel.isSearching, isFalse);
    expect(viewModel.query, isEmpty);
    expect(viewModel.chats, hasLength(2));
  });

  test('time label: now, minutes, hours, yesterday, then month/day', () {
    String label(DateTime at) => chatTimeLabel(at, _now);

    expect(label(_now.subtract(const Duration(seconds: 20))), 'Now');
    expect(label(_now.subtract(const Duration(minutes: 12))), '12m');
    expect(label(_now.subtract(const Duration(hours: 3))), '3h');
    expect(label(DateTime(2026, 10, 15, 23)), 'Yesterday');
    expect(label(DateTime(2026, 10, 3, 9)), '10/3');
  });

  test('draft preview shows photos, text or both', () {
    expect(draftPreview((text: ' Hi ', imagePaths: [])), 'Hi');
    expect(draftPreview((text: '', imagePaths: ['a'])), 'Photo');
    expect(draftPreview((text: 'Hi', imagePaths: ['a', 'b'])), '2 photos · Hi');
  });
}
