import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/google_sheet_service.dart';

class LoginPage extends StatefulWidget {
  final GoogleSheetService service;

  const LoginPage({super.key, required this.service});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  String? _error;

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // Clear cached OAuth credentials so Google always shows the account picker
    await widget.service.signOut();
    final connected = await widget.service.init();
    if (!mounted) return;
    if (!connected) {
      setState(() {
        _loading = false;
        _error = widget.service.lastError ?? 'Google authentication failed.';
      });
      return;
    }
    context.go('/take-attendance');
  }

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
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                ],
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _loading ? null : _connect, icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.account_circle_outlined), label: Text(_loading ? 'Connecting...' : 'Sign in with Google'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}