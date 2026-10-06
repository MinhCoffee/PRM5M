import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  static const items = [
    ('Home', '/home', Icons.home_outlined),
    ('My Classes', '/my-classes', Icons.class_outlined),
    ('Timetable', '/timetable', Icons.calendar_month_outlined),
    ('Export', '/fap-sync', Icons.sync_outlined),
    ('AI Assistant', '/ai-assistant', Icons.auto_awesome_outlined),
    ('Take Attendance', '/take-attendance', Icons.how_to_reg_outlined),
    ('Reports', '/reports', Icons.assessment_outlined),
    ('Settings', '/settings', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    return Container(
      height: 48,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: items.map((item) {
        final selected = currentPath == item.$2 || (item.$1 == 'Take Attendance' && currentPath.startsWith('/attendance/'));
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: TextButton(
            onPressed: () => context.go(item.$2),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: selected ? AppColors.primaryDark : Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
            child: Text(item.$1, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList()),
    );
  }
}

class MobileNavBar extends StatelessWidget {
  const MobileNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    var selectedIndex = NavBar.items.indexWhere(
      (item) => currentPath == item.$2 || (item.$1 == 'Take Attendance' && currentPath.startsWith('/attendance/')),
    );
    if (selectedIndex < 0) selectedIndex = 0;

    // Four primary destinations keep the mobile bar usable; the full list
    // remains available from the More destination.
    const primaryItems = [0, 1, 2, 5];
    final primaryIndex = primaryItems.indexOf(selectedIndex);
    return NavigationBar(
      selectedIndex: primaryIndex >= 0 ? primaryIndex : 4,
      onDestinationSelected: (index) {
        if (index == 4) {
          _showMoreMenu(context);
          return;
        }
        context.go(NavBar.items[primaryItems[index]].$2);
      },
      destinations: [
        for (final index in primaryItems.take(4))
          NavigationDestination(icon: Icon(NavBar.items[index].$3), label: NavBar.items[index].$1),
        const NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
      ],
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final index in [3, 4, 6, 7])
              ListTile(
                leading: Icon(NavBar.items[index].$3),
                title: Text(NavBar.items[index].$1),
                onTap: () {
                  Navigator.pop(context);
                  GoRouter.of(context).go(NavBar.items[index].$2);
                },
              ),
          ],
        ),
      ),
    );
  }
}