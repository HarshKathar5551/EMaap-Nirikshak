import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legal_metrology_verification/models/user_model.dart';
import 'package:legal_metrology_verification/models/instrument_model.dart';
import 'package:legal_metrology_verification/models/application_model.dart';
import 'package:legal_metrology_verification/features/auth/presentation/controllers/auth_controller.dart';
import 'package:legal_metrology_verification/features/instruments/presentation/controllers/instruments_controller.dart';
import 'package:legal_metrology_verification/features/applications/presentation/controllers/applications_controller.dart';
import 'package:legal_metrology_verification/features/dashboard/presentation/screens/owner_dashboard_screen.dart';
import 'package:legal_metrology_verification/features/certificates/presentation/screens/certificate_view_screen.dart';
import 'package:legal_metrology_verification/core/network/providers.dart';

void main() {
  testWidgets('Simulate issue certificate and view screens for both owners', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 1. Login Fresh Owner
    await tester.runAsync(() async {
      await container.read(authControllerProvider.notifier).loginWithDemo(UserRole.owner, isFreshOwner: true);
      final freshUser = container.read(authControllerProvider).user!;
      expect(freshUser.id, 'usr-owner-fresh');

      await container.read(instrumentsControllerProvider.notifier).loadInstruments(ownerId: freshUser.id);
      await container.read(applicationsControllerProvider.notifier).loadApplications(ownerId: freshUser.id);
    });

    // 2. Render OwnerDashboardScreen with UncontrolledProviderScope
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: OwnerDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('E-MAAP • Owner Portal'), findsOneWidget);
    expect(find.text('Your instrument portfolio is empty.'), findsOneWidget);

    // 3. Issue certificate as Admin
    final appRepo = container.read(applicationRepositoryProvider);
    final allApps = await tester.runAsync(() => appRepo.getApplications()) ?? [];
    expect(allApps.isNotEmpty, isTrue);
    final firstApp = allApps.first;

    final issuedCert = await tester.runAsync(() => appRepo.issueCertificate(firstApp.id, remarks: 'Approved test'));
    expect(issuedCert, isNotNull);

    // 4. Test viewing certificate screen directly
    await tester.pumpWidget(
      MaterialApp(
        home: CertificateViewScreen(certificate: issuedCert!),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Digital Verification Certificate'), findsOneWidget);
    expect(find.text('CERTIFICATE OF VERIFICATION'), findsOneWidget);

    // 5. Switch to Seeded Owner
    await tester.runAsync(() async {
      await container.read(authControllerProvider.notifier).loginWithDemo(UserRole.owner, isFreshOwner: false);
      final seededUser = container.read(authControllerProvider).user!;
      expect(seededUser.id, 'usr-owner-01');

      await container.read(instrumentsControllerProvider.notifier).loadInstruments(ownerId: seededUser.id);
      await container.read(applicationsControllerProvider.notifier).loadApplications(ownerId: seededUser.id);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: OwnerDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('E-MAAP • Owner Portal'), findsOneWidget);
    expect(find.text('My Instruments'), findsOneWidget);

    // Tap "View Certificate" on the first verified instrument card for Seeded Owner
    final viewBtn = find.text('View Certificate');
    expect(viewBtn, findsWidgets);
    await tester.tap(viewBtn.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Verify CertificateViewScreen opened!
    expect(find.text('Digital Verification Certificate'), findsOneWidget);
    expect(find.text('CERTIFICATE OF VERIFICATION'), findsOneWidget);

    // Now go back
    Navigator.of(tester.element(find.text('Digital Verification Certificate'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('E-MAAP • Owner Portal'), findsOneWidget);

    // Tap "View Certificates" quick action for Seeded Owner
    await tester.tap(find.text('View Certificates'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    // It should open sheet with title "Verified Digital Certificates"
    expect(find.text('Verified Digital Certificates'), findsOneWidget);
    Navigator.of(tester.element(find.text('Verified Digital Certificates'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 6. Now register an instrument as Fresh Owner and issue certificate, then view it
    await tester.runAsync(() async {
      await container.read(authControllerProvider.notifier).loginWithDemo(UserRole.owner, isFreshOwner: true);
      final freshUser = container.read(authControllerProvider).user!;
      expect(freshUser.id, 'usr-owner-fresh');

      // Register an instrument
      final inst = InstrumentModel(
        id: 'inst-fresh-01',
        instrumentId: 'LM-IN-MH-PUN-000888',
        type: 'Platform Scale',
        manufacturer: 'Avery India',
        model: 'PS-100',
        serialNumber: 'SN-FRESH-001',
        capacity: 100,
        unit: 'kg',
        yearOfManufacture: 2026,
        purchaseDate: DateTime.now(),
        locationName: 'Verma Mart',
        address: 'Shivajinagar, Pune',
        latitude: 18.52,
        longitude: 73.85,
        ownerId: freshUser.id,
        ownerName: freshUser.name,
        status: InstrumentStatus.registered,
        registrationDate: DateTime.now(),
        qrVerificationCode: 'VERIFY-LM-PUN-888',
      );
      final instRepo = container.read(instrumentRepositoryProvider);
      final createdInst = await instRepo.registerInstrument(inst);

      // Submit application
      final app = ApplicationModel(
        id: 'app-fresh-01',
        applicationId: 'LM-APP-2026-9988',
        instrumentId: createdInst.id,
        instrumentUniqueId: createdInst.instrumentId,
        instrumentType: createdInst.type,
        ownerId: freshUser.id,
        ownerName: freshUser.name,
        type: ApplicationType.newVerification,
        status: ApplicationStatus.submitted,
        submittedDate: DateTime.now(),
      );
      await appRepo.submitApplication(app);

      // Admin approves and issues certificate
      await appRepo.approveApplication(app.id);
      await appRepo.issueCertificate(app.id, remarks: 'Verified by Admin');

      // Reload fresh owner state
      await container.read(instrumentsControllerProvider.notifier).loadInstruments(ownerId: freshUser.id);
      await container.read(applicationsControllerProvider.notifier).loadApplications(ownerId: freshUser.id);
    });

    // Render Fresh Owner Dashboard
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: OwnerDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('E-MAAP • Owner Portal'), findsOneWidget);
    expect(find.text('My Instruments'), findsOneWidget);

    // Fresh Owner taps "View Certificate" on their newly verified instrument
    final freshViewBtn = find.text('View Certificate');
    expect(freshViewBtn, findsOneWidget);
    await tester.tap(freshViewBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Digital Verification Certificate'), findsOneWidget);
    expect(find.text('CERTIFICATE OF VERIFICATION'), findsOneWidget);
  });
}
