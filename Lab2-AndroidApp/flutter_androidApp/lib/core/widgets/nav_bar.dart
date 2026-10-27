import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  static const items = [
    ('Trang chủ', '/home', Icons.home_outlined),
    ('Lớp học', '/my-classes', Icons.class_outlined),
    ('Lịch dạy', '/timetable', Icons.calendar_month_outlined),
    ('Điểm danh', '/take-attendance', Icons.how_to_reg_outlined),
    ('Báo cáo', '/reports', Icons.assessment_outlined),
    ('Đồng bộ FAP', '/fap-sync', Icons.sync_outlined),
    ('Trợ lý AI', '/ai-assistant', Icons.auto_awesome_outlined),
    ('Hồ sơ', '/profile', Icons.person_outline),
    ('Cài đặt', '/settings', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      height: 48,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: items.map((item) {
          final selected = currentPath == item.$2 ||
              (item.$2 == '/take-attendance' &&
                  currentPath.startsWith('/attendance/'));

          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: () => context.go(item.$2),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor:
                    selected ? AppColors.primaryDark : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
              ),
              child: Text(
                item.$1,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class MobileNavBar extends StatelessWidget {
  const MobileNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    // 4 primary destinations on mobile: Home, Classes, Attendance, Reports
    const primaryIndices = [0, 1, 3, 4];
    final selectedIndex = primaryIndices.indexWhere(
      (idx) =>
          currentPath == NavBar.items[idx].$2 ||
          (NavBar.items[idx].$2 == '/take-attendance' &&
              currentPath.startsWith('/attendance/')),
    );

    return NavigationBar(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 4,
      onDestinationSelected: (index) {
        if (index == 4) {
          _showMoreMenu(context);
          return;
        }
        context.go(NavBar.items[primaryIndices[index]].$2);
      },
      destinations: [
        for (final idx in primaryIndices)
          NavigationDestination(
            icon: Icon(NavBar.items[idx].$3),
            label: NavBar.items[idx].$1,
          ),
        const NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'Thêm',
        ),
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
            // Extra routes in bottom sheet: Timetable, Export, AI Assistant, Profile, Settings
            for (final idx in [2, 5, 6, 7, 8])
              ListTile(
                leading: Icon(NavBar.items[idx].$3, color: AppColors.primary),
                title: Text(
                  NavBar.items[idx].$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  GoRouter.of(context).go(NavBar.items[idx].$2);
                },
              ),
          ],
        ),
      ),
    );
  }
}
