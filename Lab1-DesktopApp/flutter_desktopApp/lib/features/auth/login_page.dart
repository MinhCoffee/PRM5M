import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.school_outlined, color: Colors.white, size: 30)),
                const SizedBox(height: 20),
                Text('Academic Portal', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.primary)),
                const SizedBox(height: 6),
                Text('Sign in to manage classroom attendance', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 28),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => context.go('/take-attendance'), icon: const Icon(Icons.account_circle_outlined), label: const Text('Sign in with Google'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}