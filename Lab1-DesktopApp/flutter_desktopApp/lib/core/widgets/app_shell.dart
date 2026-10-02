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
          body: Column(
            children: [
              const AppHeader(),
              if (!isMobile) const NavBar(),
              const BreadcrumbBar(),
              Expanded(child: child),
              if (!isMobile) const AppFooter(),
            ],
          ),
          bottomNavigationBar: isMobile ? const MobileNavBar() : null,
        );
      },
    );
  }
}