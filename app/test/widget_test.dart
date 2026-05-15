// F1.1 — login screen renders without crashing.
//
// We intentionally do NOT call Supabase.initialize() in tests; instead the
// test renders LoginScreen directly. main()'s bootstrap path (env load +
// Supabase init) is covered by device runs, not widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iter/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('ITER'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
