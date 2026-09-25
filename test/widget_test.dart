import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_metrology_verification/features/instruments/presentation/widgets/add_instrument_dialog.dart';
import 'package:legal_metrology_verification/features/dashboard/presentation/screens/owner_dashboard_screen.dart';
import 'package:legal_metrology_verification/main.dart';
import 'package:legal_metrology_verification/services/mock_api_service.dart';
import 'package:legal_metrology_verification/models/user_model.dart';
import 'package:legal_metrology_verification/models/instrument_model.dart';
import 'package:legal_metrology_verification/models/application_model.dart';
import 'package:legal_metrology_verification/models/certificate_model.dart';
import 'package:legal_metrology_verification/core/utils/date_formatter.dart';
import 'package:legal_metrology_verification/core/errors/failures.dart';

void main() {
  group('Metrology Platform End-to-End Tests', () {
    late MockApiService apiService;

    setUp(() {
      apiService = MockApiService();
    });

    test('Demo Authentication should succeed for all official roles', () async {
      final owner = await apiService.login('owner@test.com', '123456');
      expect(owner.role, UserRole.owner);

      final freshOwner = await apiService.login('newowner@test.com', '123456');
      expect(freshOwner.role, UserRole.owner);

      final officer = await apiService.login('officer@test.com', '123456');
      expect(officer.role, UserRole.officer);

      final gatc = await apiService.login('gatc@test.com', '123456');
      expect(gatc.role, UserRole.gatc);

      final admin = await apiService.login('admin@test.com', '123456');
      expect(admin.role, UserRole.admin);
    });

    test('Authentication should fail on wrong password', () async {
      expect(
        () => apiService.login('owner@test.com', 'wrong_pass'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('Instrument dataset loads with 10+ records and correct statuses', () async {
      final instruments = await apiService.getInstruments();
      expect(instruments.length, greaterThanOrEqualTo(10));
      expect(instruments.any((i) => i.status == InstrumentStatus.verified), isTrue);
      expect(instruments.any((i) => i.status == InstrumentStatus.expired), isTrue);
    });

    test('Public QR Verification validates authentic certificates', () async {
      final validCert = await apiService.verifyPublicQr('VERIFY-LM-8F92A71X');
      expect(validCert, isNotNull);
      expect(validCert!.certificateNumber, 'LM-CERT-2026-10234');
      expect(validCert.sha256IntegrityHash, isNotEmpty);
      expect(validCert.status, CertificateStatus.valid);
    });

    test('DateFormatter accurately identifies expired certificates', () {
      final expiredDate = DateTime.now().subtract(const Duration(days: 30));
      final futureDate = DateTime.now().add(const Duration(days: 90));

      expect(DateFormatter.isExpired(expiredDate), isTrue);
      expect(DateFormatter.isExpired(futureDate), isFalse);
    });

    test('Offline mode simulation correctly blocks live network calls', () async {
      apiService.setOfflineMode(true);
      expect(apiService.isOffline, isTrue);

      expect(
        () => apiService.getInstruments(),
        throwsA(isA<ServerFailure>()),
      );

      apiService.setOfflineMode(false);
      expect(apiService.isOffline, isFalse);
      final list = await apiService.getInstruments();
      expect(list.isNotEmpty, isTrue);
    });

    test('Full SIH Lifecycle: New Owner (0 Equipment) -> Add -> Apply -> Assign Officer -> Inspection -> Certificate -> Public QR', () async {
      // 1. Fresh Owner starts with 0 instruments
      final freshOwner = await apiService.login('newowner@test.com', '123456');
      var ownerInstruments = await apiService.getInstruments(ownerId: freshOwner.id);
      expect(ownerInstruments.length, 0);

      // 2. Owner registers new equipment
      final newEquip = InstrumentModel(
        id: 'inst-new-999',
        instrumentId: 'LM-IN-MH-PUN-000999',
        type: 'Electronic Weighing Scale (Class III)',
        manufacturer: 'Avery India Ltd',
        model: 'EWS-30P',
        serialNumber: 'SN-2026-999',
        capacity: 30.0,
        unit: 'kg',
        yearOfManufacture: 2026,
        purchaseDate: DateTime.now(),
        locationName: 'Verma Provisions & Mart',
        address: 'Main Market, Kothrud, Pune',
        latitude: 18.5074,
        longitude: 73.8077,
        ownerId: freshOwner.id,
        ownerName: freshOwner.name,
        status: InstrumentStatus.registered,
        registrationDate: DateTime.now(),
        qrVerificationCode: 'VERIFY-LM-999X',
      );
      await apiService.createInstrument(newEquip);

      // 3. Equipment now belongs to owner (0 -> 1)
      ownerInstruments = await apiService.getInstruments(ownerId: freshOwner.id);
      expect(ownerInstruments.length, 1);
      expect(ownerInstruments.first.instrumentId, 'LM-IN-MH-PUN-000999');

      // 4. Submit verification application & automatically assign officer
      final app = ApplicationModel(
        id: 'app-999',
        applicationId: 'LM-APP-2026-0099',
        instrumentId: newEquip.id,
        instrumentUniqueId: newEquip.instrumentId,
        instrumentType: newEquip.type,
        ownerId: freshOwner.id,
        ownerName: freshOwner.name,
        type: ApplicationType.newVerification,
        status: ApplicationStatus.assigned,
        submittedDate: DateTime.now(),
        assignedOfficerId: 'usr-officer-01',
        assignedOfficerName: 'Inspector Vikram Patil (LMO)',
      );
      await apiService.createApplication(app);

      // 5. Officer sees assigned equipment
      final officerApps = await apiService.getApplications(officerId: 'usr-officer-01');
      expect(officerApps.any((a) => a.instrumentUniqueId == 'LM-IN-MH-PUN-000999'), isTrue);

      // 6. Admin sees equipment statewide
      final allApps = await apiService.getApplications();
      expect(allApps.any((a) => a.instrumentUniqueId == 'LM-IN-MH-PUN-000999'), isTrue);

      // 7. Inspection passes and certificate is generated
      final cert = CertificateModel(
        id: 'cert-999',
        certificateNumber: 'LM-CERT-2026-10099',
        instrumentId: newEquip.id,
        instrumentUniqueId: newEquip.instrumentId,
        instrumentType: newEquip.type,
        serialNumber: newEquip.serialNumber,
        manufacturer: newEquip.manufacturer,
        model: newEquip.model,
        capacity: newEquip.capacity,
        unit: newEquip.unit,
        ownerName: freshOwner.name,
        ownerAddress: newEquip.address,
        verificationDate: DateTime.now(),
        issueDate: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 365)),
        issuingOfficerName: 'Inspector Vikram Patil',
        issuingAuthority: 'Legal Metrology Department, Pune Beat',
        qrVerificationCode: 'VERIFY-LM-999X',
        sha256IntegrityHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        status: CertificateStatus.valid,
      );
      await apiService.generateCertificate(cert);

      // 8. Anyone can publicly verify the certificate via QR
      final publicResult = await apiService.verifyPublicQr('VERIFY-LM-999X');
      expect(publicResult, isNotNull);
      expect(publicResult!.certificateNumber, 'LM-CERT-2026-10099');
      expect(publicResult.status, CertificateStatus.valid);
      expect(publicResult.sha256IntegrityHash, isNotEmpty);
    });
  });

  testWidgets('App root smoke test renders and settles splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LegalMetrologyApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.byType(LegalMetrologyApp), findsOneWidget);
  });

  testWidgets('AddInstrumentDialog requires location before registration', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AddInstrumentDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dialog loaded and Step 1 Equipment Info is present
    expect(find.text('Register Weighing / Measuring Instrument'), findsOneWidget);
    expect(find.text('Next: Location'), findsOneWidget);

    // Tap Quick Fill button to populate required equipment fields
    final quickFillBtn = find.text('Quick Fill');
    expect(quickFillBtn, findsOneWidget);
    await tester.tap(quickFillBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Clear any demo snackbars
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
    await tester.pump(const Duration(milliseconds: 100));

    // Advance to Step 2 (Location)
    final nextBtn = find.text('Next: Location');
    await tester.tap(nextBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Step 2 is active and requires location enablement
    expect(find.text('Instrument Geo-Location'), findsOneWidget);
    expect(find.text('Location Must Be Enabled & Set Before Proceeding'), findsOneWidget);
    expect(find.text('Enable & Detect Device Location'), findsOneWidget);

    // Button is locked as "Set Location to Proceed" before location is enabled
    expect(find.text('Set Location to Proceed'), findsOneWidget);
    expect(find.text('Next: Photos'), findsNothing);

    // Use premise GPS coordinates to enable & set location
    final usePremiseBtn = find.text('Set Premise GPS');
    expect(usePremiseBtn, findsOneWidget);
    await tester.tap(usePremiseBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Clear confirmation snackbar so bottom nav isn't obstructed
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify location is now enabled and marked as verified
    expect(find.text('GPS Location Enabled & Set ✓'), findsOneWidget);
    expect(find.text('VERIFIED'), findsOneWidget);

    // Now button has unlocked to "Next: Photos"
    final nextPhotosBtn = find.text('Next: Photos');
    expect(nextPhotosBtn, findsOneWidget);
    await tester.tap(nextPhotosBtn);
    await tester.pump(const Duration(milliseconds: 500));

    // On Step 3: Registration is unlocked
    expect(find.text('Instrument Verification Photos'), findsOneWidget);
    expect(find.text('REGISTER INSTRUMENT'), findsOneWidget);
  });

  testWidgets('OwnerDashboardScreen tapping Add Instrument opens dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OwnerDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Owner Dashboard is rendered
    expect(find.text('E-MAAP • Owner Portal'), findsOneWidget);

    // Find and tap the floating action button
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify AddInstrumentDialog popped up
    expect(find.text('Register Weighing / Measuring Instrument'), findsOneWidget);
  });
}


