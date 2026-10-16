import 'package:flutter/material.dart';

import '../view_model/home_viewmodel.dart';

/// Placeholder landing after auth, until Chats exists.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: viewModel.signOut.execute,
          child: const Text('SIGN OUT'),
        ),
      ),
    );
  }
}
