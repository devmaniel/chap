import 'package:flutter/foundation.dart';

import '../../../data/repositories/character/character_repository.dart';
import '../../../domain/models/character/character.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class FriendsViewModel extends ChangeNotifier {
  FriendsViewModel({required CharacterRepository characterRepository})
    : _characterRepository = characterRepository {
    load = Command0(_load);
    if (_characterRepository.cachedCharacters == null) load.execute();
  }

  final CharacterRepository _characterRepository;

  late final Command0<void> load;

  /// Fires when the load or any character changes.
  Listenable get changes => Listenable.merge([load, _characterRepository]);

  /// Characters you are friends with.
  List<Character> get friends => [
    for (final c
        in _characterRepository.cachedCharacters ?? const <Character>[])
      if (c.isFriend) c,
  ];

  Future<Result<void>> _load() async {
    switch (await _characterRepository.getCharacters()) {
      case Ok():
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }
}

/// "1 friend", "3 friends".
String friendCountLabel(int count) =>
    count == 1 ? '1 friend' : '$count friends';
