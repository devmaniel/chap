import 'package:app/data/repositories/auth/auth_repository_local.dart';
import 'package:app/ui/auth/view_model/sign_in_viewmodel.dart';
import 'package:app/ui/auth/widgets/sign_in_screen.dart';
import 'package:app/ui/core/themes/theme.dart';
import 'package:app/ui/core/ui/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SignInViewModel viewModel;

  setUp(() {
    viewModel = SignInViewModel(
      authRepository: AuthRepositoryLocal(latency: Duration.zero),
    );
  });

  Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: SignInScreen(viewModel: viewModel),
    ),
  );

  PrimaryButton submit(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton));

  testWidgets('Sign in stays grey until both fields have text', (tester) async {
    await pumpScreen(tester);
    expect(submit(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'jamie@example.com');
    await tester.pump();
    expect(submit(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'otterly42');
    await tester.pump();
    expect(submit(tester).onPressed, isNotNull);
  });

  testWidgets('unknown account shows one message and keeps the values', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField).first, 'jamie@example.com');
    await tester.enterText(find.byType(TextField).last, 'otterly42');
    await tester.pump();

    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();

    expect(find.text('Wrong email or password'), findsOneWidget);
    expect(find.text('jamie@example.com'), findsOneWidget);
  });
}
