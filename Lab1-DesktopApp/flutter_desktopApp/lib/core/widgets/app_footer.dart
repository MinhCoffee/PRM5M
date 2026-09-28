import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(color: AppColors.surfaceLow, border: Border(top: BorderSide(color: AppColors.outlineVariant))),
        child: Row(children: [
          Text('© Powered by FPT University', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
          const Spacer(),
          Text('FPT University', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('|')),
          Text('CMS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('|')),
          Text('Library', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
        ]),
      );
}