import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return Column(
          children: [
            const SizedBox(
              height: 4,
              child: Row(children: [
                Expanded(child: ColoredBox(color: AppColors.orange)),
                Expanded(child: ColoredBox(color: AppColors.primary)),
                Expanded(child: ColoredBox(color: AppColors.green)),
              ]),
            ),
            Container(
              height: isMobile ? 56 : 60,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
              ),
              child: Row(
                children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.school_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              if (!isMobile) const SizedBox(height: 20, child: VerticalDivider(color: AppColors.outlineVariant)),
              if (!isMobile) const SizedBox(width: 12),
              Expanded(child: Text('Academic Portal - Attendance', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary))),
              if (!isMobile) ...[
                const SizedBox(width: 24),
                _headerTag('Semester: Fall 2026', AppColors.surfaceContainer, AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                _headerTag('FU - HCM', const Color(0xFFD1E4FF), const Color(0xFF184974)),
                const SizedBox(width: 16),
              ],
              const CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Icon(Icons.person_outline, color: Colors.white, size: 18)),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dr. Nguyen Van Minh', style: Theme.of(context).textTheme.labelLarge),
                  Text('ID: minhnd32', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                ]),
                const SizedBox(width: 16),
                OutlinedButton.icon(onPressed: () => context.go('/login'), icon: const Icon(Icons.logout, size: 16), label: const Text('Logout')),
              ],
              if (isMobile) IconButton(onPressed: () => context.go('/login'), icon: const Icon(Icons.logout_outlined), tooltip: 'Logout'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _headerTag(String text, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.outlineVariant)),
        child: Text(text, style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}