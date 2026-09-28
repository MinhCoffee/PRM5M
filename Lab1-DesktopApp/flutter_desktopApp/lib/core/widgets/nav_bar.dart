import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    const items = {
      'Home': '/home',
      'My Classes': '/my-classes',
      'Take Attendance': '/take-attendance',
      'Timetable': '/timetable',
      'Reports': '/reports',
      'FAP Sync': '/fap-sync',
      'AI Assistant': '/ai-assistant',
      'Settings': '/settings',
    };
    final currentPath = GoRouterState.of(context).uri.path;
    return Container(
      height: 48,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: items.entries.map((entry) {
        final selected = currentPath == entry.value || (entry.key == 'Take Attendance' && currentPath.startsWith('/attendance/'));
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: TextButton(
            onPressed: () => context.go(entry.value),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: selected ? AppColors.primaryDark : Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
            child: Text(entry.key, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList()),
    );
  }
}