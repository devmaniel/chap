import 'package:flutter/foundation.dart';

import '../../../data/repositories/character/character_repository.dart';
import '../../../domain/models/character/character.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class DiscoverViewModel extends ChangeNotifier {
  DiscoverViewModel({required CharacterRepository characterRepository})
    : _characterRepository = characterRepository {
    load = Command0(_load);
    if (_characterRepository.cachedCharacters == null) load.execute();
  }

  static const allFilter = 'All';
  static const filters = [allFilter, 'Art', 'Music', 'Stories', 'Ideas'];

  final CharacterRepository _characterRepository;

  late final Command0<void> load;

  String _filter = allFilter;

  /// Fires when the filter, the load or any character changes.
  Listenable get changes =>
      Listenable.merge([this, load, _characterRepository]);

  String get filter => _filter;

  /// Every character, or only those with the picked interest.
  List<Character> get characters {
    final all = _characterRepository.cachedCharacters ?? const <Character>[];
    if (_filter == allFilter) return all;
    return all.where((c) => c.interests.contains(_filter)).toList();
  }

  /// One filter at a time.
  void selectFilter(String filter) {
    if (filter == _filter) return;
    _filter = filter;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    switch (await _characterRepository.getCharacters()) {
      case Ok():
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }
}
