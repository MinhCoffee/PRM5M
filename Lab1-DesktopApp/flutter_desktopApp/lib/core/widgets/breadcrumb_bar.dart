import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(color: AppColors.surfaceLow, border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
        child: Row(children: [
          const Icon(Icons.school_outlined, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('FU - HCM', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.outline),
          Text('Academic Attendance Workbench', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurface)),
        ]),
      );
}