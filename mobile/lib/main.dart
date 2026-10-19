import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'routing/router.dart';
import 'ui/core/themes/theme.dart';

void main() {
  runApp(MultiProvider(providers: providers, child: const ChapsApp()));
}

class ChapsApp extends StatefulWidget {
  const ChapsApp({super.key});

  @override
  State<ChapsApp> createState() => _ChapsAppState();
}

class _ChapsAppState extends State<ChapsApp> {
  late final GoRouter _router = router(context.read());

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: MaterialApp.router(
        title: 'Chaps',
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
