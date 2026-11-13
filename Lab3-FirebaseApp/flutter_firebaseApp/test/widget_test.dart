import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App starts on the login screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const AttendanceApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Sign in with Google'), findsOneWidget);

    // Reset surface size after test
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('Signed-out user cannot open protected screens', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AttendanceApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    for (final path in ['/home', '/reports', '/notifications', '/profile']) {
      GoRouter.of(context).go(path);
      await tester.pumpAndSettle();
      expect(find.textContaining('Sign in with Google'), findsOneWidget,
          reason: '$path must redirect to /login when signed out');
    }
  });
}
