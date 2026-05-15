// F1.1 — Supabase Auth in Flutter. App bootstraps Supabase, then routes
// between LoginScreen and HomeScreen based on the current auth state.
// Apple/Google sign-in defer to F1.1.5 (they require platform config —
// Apple Developer entitlement, Google client ID — that aren't set up yet).

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    // Session is persisted to platform secure storage by default — survives
    // app restart. No extra config needed.
  );

  runApp(const IterApp());
}

class IterApp extends StatelessWidget {
  const IterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITER',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

/// Renders LoginScreen or HomeScreen depending on whether a session exists.
/// Subscribes to Supabase's auth state stream so sign-in/out flips the
/// screen with no further routing code at the call sites.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const LoginScreen();
        return const HomeScreen();
      },
    );
  }
}
