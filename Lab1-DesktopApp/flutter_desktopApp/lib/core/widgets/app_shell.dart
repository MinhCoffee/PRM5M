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
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          const NavBar(),
          const BreadcrumbBar(),
          Expanded(child: child),
          const AppFooter(),
        ],
      ),
    );
  }
}