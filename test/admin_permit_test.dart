import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legal_metrology_verification/models/user_model.dart';
import 'package:legal_metrology_verification/models/application_model.dart';
import 'package:legal_metrology_verification/features/auth/presentation/controllers/auth_controller.dart';
import 'package:legal_metrology_verification/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:legal_metrology_verification/features/certificates/presentation/screens/certificate_view_screen.dart';
import 'package:legal_metrology_verification/core/network/providers.dart';

void main() {
  testWidgets('Admin dashboard permits granting certificate and viewing it', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 1. Login as Admin
    await tester.runAsync(() async {
      await container.read(authControllerProvider.notifier).loginWithDemo(UserRole.admin);
      final admin = container.read(authControllerProvider).user!;
      expect(admin.role, UserRole.admin);
    });

    // 2. Render AdminDashboardScreen
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('E-MAAP • Admin Command Portal'), findsOneWidget);
    expect(find.text('STATE HEADQUARTERS • CONTROLLER LEVEL'), findsOneWidget);
    expect(find.text('Recent Applications for Assignment'), findsOneWidget);
    expect(find.text('Manage All'), findsOneWidget);

    final appRepo = container.read(applicationRepositoryProvider);
    final apps = await tester.runAsync(() => appRepo.getApplications()) ?? [];
    expect(apps.isNotEmpty, isTrue);

    // Let's find an uncertified application or test granting permit on app-003 / app-004
    final uncertifiedApp = apps.firstWhere((a) => a.status != ApplicationStatus.certificateIssued);

    final appCardFinder = find.text(uncertifiedApp.applicationId);
    expect(appCardFinder, findsOneWidget);

    await tester.tap(appCardFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Grant Permit & Issue Certificate'), findsOneWidget);

    // Tap Grant Permit
    await tester.tap(find.text('Grant Permit & Issue Certificate'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 1500)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CertificateViewScreen), findsOneWidget);
  });
}
