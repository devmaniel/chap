import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_local.dart';

/// Swap [AuthRepositoryLocal] for the remote implementation once the server exists.
List<SingleChildWidget> get providers => [
  ChangeNotifierProvider<AuthRepository>(
    create: (_) => AuthRepositoryLocal(
      // Test account. Emails are stored lowercase.
      passwordsByEmail: const {'melco@example.com': 'Password123'},
    ),
  ),
];
