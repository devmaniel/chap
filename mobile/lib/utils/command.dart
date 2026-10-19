import 'package:flutter/foundation.dart';

import 'result.dart';

/// Runs an async action and exposes running / completed / error to the UI.
class Command0<T> extends ChangeNotifier {
  Command0(this._action);

  final Future<Result<T>> Function() _action;

  bool _running = false;
  Result<T>? _result;

  bool get running => _running;
  bool get completed => _result is Ok<T>;
  bool get error => _result is Error<T>;
  Result<T>? get result => _result;

  Future<void> execute() async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await _action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    notifyListeners();
  }
}

/// [Command0] for an action that takes one argument.
class Command1<T, A> extends ChangeNotifier {
  Command1(this._action);

  final Future<Result<T>> Function(A) _action;

  bool _running = false;
  Result<T>? _result;

  bool get running => _running;
  bool get error => _result is Error<T>;
  Result<T>? get result => _result;

  Future<void> execute(A argument) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await _action(argument);
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}
