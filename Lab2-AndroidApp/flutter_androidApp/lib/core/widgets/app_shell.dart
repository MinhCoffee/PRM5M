import 'package:flutter/material.dart';
import 'app_footer.dart';
import 'app_header.dart';
import 'breadcrumb_bar.dart';
import 'nav_bar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return Scaffold(
          // Keep the header out of the system status bar; the bottom inset
          // is handled by the NavigationBar on mobile.
          body: SafeArea(
            bottom: !isMobile,
            child: Column(
              children: [
                const AppHeader(),
                if (!isMobile) const NavBar(),
                const BreadcrumbBar(),
                Expanded(child: child),
                if (!isMobile) const AppFooter(),
              ],
            ),
          ),
          bottomNavigationBar: isMobile ? const MobileNavBar() : null,
        );
      },
    );
  }
}