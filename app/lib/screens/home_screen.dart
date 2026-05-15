import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// F1.1 home placeholder. Real home view is the 3D globe (F3.1, ADR-010).
/// For now: confirms session, shows user email, sign-out button.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ITER'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public, size: 64),
              const SizedBox(height: 16),
              Text(
                'Signed in as',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                user?.email ?? '(no email)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                '3D globe + country map coming in F3 (ADR-010).',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
