import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legal_metrology_verification/main.dart';
import 'package:legal_metrology_verification/models/user_model.dart';
import 'package:legal_metrology_verification/models/instrument_model.dart';
import 'package:legal_metrology_verification/models/application_model.dart';
import 'package:legal_metrology_verification/models/inspection_model.dart';
import 'package:legal_metrology_verification/models/certificate_model.dart';
import 'package:legal_metrology_verification/features/auth/presentation/controllers/auth_controller.dart';
import 'package:legal_metrology_verification/features/certificates/presentation/screens/certificate_view_screen.dart';
import 'package:legal_metrology_verification/features/instruments/presentation/widgets/add_instrument_dialog.dart';
import 'package:legal_metrology_verification/core/network/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End Real App Lifecycle: New Owner -> LMO -> Admin -> View Certificate', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Pump real root app
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LegalMetrologyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // ==============================================================
    // 1. Login as New Owner
    // ==============================================================
    await tester.runAsync(() async {
      final loginOk = await container.read(authControllerProvider.notifier).login('newowner@test.com', '123456');
      expect(loginOk, isTrue);
    });
    await tester.pumpAndSettle();

    final newOwner = container.read(authControllerProvider).user!;
    debugPrint('Step 1: Logged in as ${newOwner.name} (${newOwner.id})');
    expect(newOwner.id, 'usr-owner-fresh');
    expect(find.text('E-MAAP • Owner Portal'), findsOneWidget);

    // ==============================================================
    // 2. Add New Instrument via Add Instrument Dialog
    // ==============================================================
    final addBtn = find.text('Add Equipment');
    expect(addBtn, findsWidgets);
    await tester.tap(addBtn.first);
    await tester.pumpAndSettle();

    expect(find.byType(AddInstrumentDialog), findsOneWidget);

    // Fill form
    await tester.tap(find.text('Quick Fill'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next: Location'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set Premise GPS'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next: Photos'));
    await tester.pumpAndSettle();

    // Submit
    await tester.tap(find.text('REGISTER INSTRUMENT'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 2500)));
    await tester.pumpAndSettle();

    // If QR popup is shown, close it
    final closeBtn = find.byIcon(Icons.close);
    if (closeBtn.evaluate().isNotEmpty) {
      await tester.tap(closeBtn.first);
      await tester.pumpAndSettle();
    }

    final instRepo = container.read(instrumentRepositoryProvider);
    final ownerInsts = await tester.runAsync(() => instRepo.getInstruments(ownerId: newOwner.id)) ?? [];
    expect(ownerInsts.length, 1);
    final createdInst = ownerInsts.first;
    debugPrint('Step 2: Instrument created: ${createdInst.id}, ${createdInst.instrumentId}');

    // ==============================================================
    // 3. Login as LMO (Officer)
    // ==============================================================
    await tester.runAsync(() async {
      await container.read(authControllerProvider.notifier).login('officer@test.com', '123456');
    });
    await tester.pumpAndSettle();

    expect(find.text('E-MAAP • LMO Field Officer Portal'), findsOneWidget);

    // Find assigned inspection for this instrument
    final inspRepo = container.read(inspectionRepositoryProvider);
    final allInsps = await tester.runAsync(() => inspRepo.getInspections(officerId: 'usr-officer-01')) ?? [];
    final matchingInsp = allInsps.firstWhere((i) => i.instrumentId == createdInst.id || i.instrumentUniqueId == createdInst.instrumentId);
    debugPrint('Step 3: LMO inspection found: ${matchingInsp.inspectionId}');

    // Tap on the inspection card
    final inspCard = find.text(matchingInsp.inspectionId);
    expect(inspCard, findsOneWidget);
    await tester.tap(inspCard);
    await tester.pumpAndSettle();

    // Pass and forward to Admin
    final passBtn = find.text('Pass & Forward to Admin');
    expect(passBtn, findsOneWidget);
    await tester.tap(passBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    debugPrint('Step 3: LMO passed inspection.');

    // ==============================================================
    // 4. Login as Admin
    // ==============================================================
    await tester.runAsync(() async {
      await container.read(authControllerProvider.notifier).login('admin@test.com', '123456');
    });
    await tester.pumpAndSettle();

    expect(find.text('E-MAAP • Admin Command Portal'), findsOneWidget);
    debugPrint('Step 4: Admin dashboard loaded.');

    final appRepo = container.read(applicationRepositoryProvider);
    final allApps = await tester.runAsync(() => appRepo.getApplications()) ?? [];
    final matchingApp = allApps.firstWhere((a) => a.instrumentId == createdInst.id || a.instrumentUniqueId == createdInst.instrumentId);
    debugPrint('Step 4: Matching application: ${matchingApp.applicationId}, status: ${matchingApp.status}');

    // Find and tap on the application card
    final appCard = find.text(matchingApp.applicationId);
    expect(appCard, findsWidgets);
    await tester.tap(appCard.first);
    await tester.pumpAndSettle();

    // Grant Permit & Issue Certificate
    final grantBtn = find.text('Grant Permit & Issue Certificate');
    expect(grantBtn, findsOneWidget);
    await tester.tap(grantBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify CertificateViewScreen opened for Admin
    debugPrint('Step 4: Checking Admin Certificate View...');
    expect(find.byType(CertificateViewScreen), findsOneWidget);
    expect(find.text('Digital Verification Certificate'), findsOneWidget);

    // Pop the certificate screen
    final backBtn = find.byType(BackButton);
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn.first);
    } else {
      Navigator.of(tester.element(find.byType(CertificateViewScreen))).pop();
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // ==============================================================
    // 5. Admin can also view certificate from "Issued Certificates"
    // ==============================================================
    await tester.tap(find.text('Issued\nCertificates'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final certRepo = container.read(certificateRepositoryProvider);
    final allCerts = await tester.runAsync(() => certRepo.getCertificates()) ?? [];
    final issuedCert = allCerts.firstWhere((c) => c.instrumentId == createdInst.id || c.instrumentUniqueId == createdInst.instrumentId);
    debugPrint('Step 5: Admin viewing certificates sheet. Searching for ${issuedCert.certificateNumber}');
    expect(find.text(issuedCert.certificateNumber), findsOneWidget);

    // Tap on the certificate in Admin list
    await tester.tap(find.text(issuedCert.certificateNumber));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('STATUTORY VERIFICATION CERTIFICATE'), findsOneWidget);

    // Close certificate window
    final closeCertDialog = find.byIcon(Icons.close);
    expect(closeCertDialog, findsWidgets);
    await tester.tap(closeCertDialog.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // ==============================================================
    // 6. Login as New Owner and View Certificate
    // ==============================================================
    debugPrint('Step 6: Logging in as New Owner...');
    await tester.runAsync(() async {
      await container.read(authControllerProvider.notifier).login('newowner@test.com', '123456');
    });
    await tester.pumpAndSettle();

    expect(find.text('E-MAAP • Owner Portal'), findsOneWidget);
    debugPrint('Step 6: Owner dashboard rendered for New Owner.');

    // Check if "View Certificate" is visible
    final ownerViewCertBtn = find.text('View Certificate');
    debugPrint('View Certificate button count: ${ownerViewCertBtn.evaluate().length}');
    expect(ownerViewCertBtn, findsWidgets);

    // Tap "View Certificate"
    await tester.tap(ownerViewCertBtn.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CertificateViewScreen), findsOneWidget);
    expect(find.text('Digital Verification Certificate'), findsOneWidget);
    debugPrint('Step 6: New Owner successfully viewed certificate!');

    // Close certificate
    if (find.byType(BackButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(BackButton).first);
    } else {
      Navigator.of(tester.element(find.byType(CertificateViewScreen))).pop();
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // ==============================================================
    // 7. New Owner taps "View Certificates" quick action tile
    // ==============================================================
    await tester.tap(find.text('View Certificates'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CertificateViewScreen), findsOneWidget);
    expect(find.text('Digital Verification Certificate'), findsOneWidget);
    debugPrint('Step 7: New Owner viewed certificate via Quick Action tile!');
  });
}
