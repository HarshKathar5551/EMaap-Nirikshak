import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legal_metrology_verification/models/user_model.dart';
import 'package:legal_metrology_verification/models/instrument_model.dart';
import 'package:legal_metrology_verification/models/application_model.dart';
import 'package:legal_metrology_verification/models/certificate_model.dart';
import 'package:legal_metrology_verification/features/auth/presentation/controllers/auth_controller.dart';
import 'package:legal_metrology_verification/features/certificates/presentation/screens/certificate_view_screen.dart';
import 'package:legal_metrology_verification/core/network/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Complete End-to-End Workflow: New Owner -> LMO -> Admin -> Certificate Visibility & Security', () async {
    // Shared persistent memory map across app restarts/refreshes
    final Map<String, Object> storageMap = {};
    SharedPreferences.setMockInitialValues(storageMap);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // ==============================================================
    // A. Login as New Owner
    // ==============================================================
    final authController = container.read(authControllerProvider.notifier);
    final loginOk = await authController.login('newowner@test.com', '123456');
    expect(loginOk, isTrue);
    final newOwnerUser = container.read(authControllerProvider).user!;
    expect(newOwnerUser.id, 'usr-owner-fresh');
    expect(newOwnerUser.role, UserRole.owner);

    // ==============================================================
    // B. New Owner adds a new Instrument
    // ==============================================================
    final instrumentRepo = container.read(instrumentRepositoryProvider);
    final applicationRepo = container.read(applicationRepositoryProvider);

    final testInstrument = InstrumentModel(
      id: 'inst-fresh-test-01',
      instrumentId: 'LM-IN-2026-9999',
      type: 'Electronic Weighing Scale Class III',
      manufacturer: 'Essae-Teraoka Ltd',
      model: 'DS-215 Counter Scale',
      serialNumber: 'SN-TEST-9999',
      capacity: 30.0,
      unit: 'kg',
      yearOfManufacture: 2026,
      purchaseDate: DateTime.now().subtract(const Duration(days: 2)),
      locationName: 'Fresh Mart Supermarket',
      address: 'Shop 101, FC Road, Pune - 411005',
      latitude: 18.5204,
      longitude: 73.8567,
      ownerId: newOwnerUser.id,
      ownerName: newOwnerUser.name,
      status: InstrumentStatus.registered,
      registrationDate: DateTime.now(),
      qrVerificationCode: 'VERIFY-LM-20269999-ABCD',
    );

    final createdInst = await instrumentRepo.registerInstrument(testInstrument);
    expect(createdInst, isNotNull);

    // Create verification application for this instrument
    final testApp = ApplicationModel(
      id: 'app-fresh-test-01',
      applicationId: 'LM-APP-2026-9999',
      instrumentId: createdInst.id,
      instrumentUniqueId: createdInst.instrumentId,
      instrumentType: createdInst.type,
      ownerId: createdInst.ownerId,
      ownerName: createdInst.ownerName,
      type: ApplicationType.newVerification,
      status: ApplicationStatus.submitted,
      submittedDate: DateTime.now(),
      assignedOfficerId: 'usr-officer-01',
      assignedOfficerName: 'Inspector Vikram Patil (LMO)',
      feeAmount: 450.0,
      feePaid: true,
      remarks: 'Initial verification request for new commercial balance.',
    );

    final createdApp = await applicationRepo.submitApplication(testApp);
    expect(createdApp, isNotNull);

    // ==============================================================
    // C. Verify the Instrument is created with correct owner relationship
    // ==============================================================
    expect(createdInst.ownerId, 'usr-owner-fresh');
    expect(createdInst.ownerName, newOwnerUser.name);
    expect(createdApp.ownerId, 'usr-owner-fresh');

    final ownerInstruments = await instrumentRepo.getInstruments(ownerId: 'usr-owner-fresh');
    expect(ownerInstruments.any((i) => i.id == createdInst.id), isTrue);

    // ==============================================================
    // D. Login/process as LMO
    // ==============================================================
    final lmoLogin = await authController.login('officer@test.com', '123456');
    expect(lmoLogin, isTrue);
    final lmoUser = container.read(authControllerProvider).user!;
    expect(lmoUser.role, UserRole.officer);
    expect(lmoUser.id, 'usr-officer-01');

    // ==============================================================
    // E. Complete the LMO stage
    // ==============================================================
    final reviewedApp = await applicationRepo.reviewApplication(
      createdApp.id,
      remarks: 'Physical inspection completed at premises. Tolerances verified within MPE. Forwarded to Admin.',
    );
    expect(reviewedApp.status, ApplicationStatus.inspectionCompleted);

    // ==============================================================
    // F. Login/process as Administrator
    // ==============================================================
    final adminLogin = await authController.login('admin@test.com', '123456');
    expect(adminLogin, isTrue);
    final adminUser = container.read(authControllerProvider).user!;
    expect(adminUser.role, UserRole.admin);

    // ==============================================================
    // G. Complete the Administrator stage
    // ==============================================================
    final certRepo = container.read(certificateRepositoryProvider);
    final certificate = await applicationRepo.issueCertificate(
      reviewedApp.id,
      remarks: 'Statutory verification permit granted under Legal Metrology Act, 2009.',
    );

    // ==============================================================
    // H. Verify that the Certificate is generated and stored correctly
    // ==============================================================
    expect(certificate, isNotNull);
    expect(certificate.id, isNotEmpty);
    expect(certificate.certificateNumber.startsWith('LM-CERT-'), isTrue);
    expect(certificate.instrumentId, createdInst.id);
    expect(certificate.instrumentUniqueId, createdInst.instrumentId);
    expect(certificate.ownerId, 'usr-owner-fresh');
    expect(certificate.ownerName, newOwnerUser.name);
    expect(certificate.completionDate, isNotNull);
    expect(certificate.approvedBy, isNotNull);
    expect(certificate.status, CertificateStatus.valid);
    expect(certificate.qrVerificationCode.startsWith('VERIFY-CERT-'), isTrue);

    // Verify instrument status updated to verified with activeCertificateId
    final verifiedInst = await instrumentRepo.getInstrumentById(createdInst.id);
    expect(verifiedInst.status, InstrumentStatus.verified);
    expect(verifiedInst.activeCertificateId, certificate.id);

    // Verify application status updated to certificateIssued
    final finalizedApp = await applicationRepo.getApplicationById(createdApp.id);
    expect(finalizedApp.status, ApplicationStatus.certificateIssued);
    expect(finalizedApp.certificateId, certificate.id);

    // ==============================================================
    // I. Verify Administrator can view the Certificate
    // ==============================================================
    final adminCertList = await certRepo.getCertificates();
    expect(adminCertList.any((c) => c.id == certificate.id), isTrue);

    final retrievedCertByAdmin = await certRepo.getCertificateById(certificate.id);
    expect(retrievedCertByAdmin.id, certificate.id);
    expect(retrievedCertByAdmin.certificateNumber, certificate.certificateNumber);

    // ==============================================================
    // J. Login again as the New Owner
    // ==============================================================
    final reloadedLogin = await authController.login('newowner@test.com', '123456');
    expect(reloadedLogin, isTrue);
    final reloadedOwner = container.read(authControllerProvider).user!;
    expect(reloadedOwner.id, 'usr-owner-fresh');

    // ==============================================================
    // K. Verify New Owner can view the Certificate for that Instrument
    // ==============================================================
    final freshOwnerCerts = await certRepo.getCertificates(ownerId: 'usr-owner-fresh');
    expect(freshOwnerCerts.isNotEmpty, isTrue);
    expect(freshOwnerCerts.any((c) => c.id == certificate.id), isTrue);

    final ownerCert = freshOwnerCerts.firstWhere((c) => c.id == certificate.id);
    expect(ownerCert.instrumentId, createdInst.id);
    expect(ownerCert.ownerId, 'usr-owner-fresh');
    expect(ownerCert.qrVerificationCode, certificate.qrVerificationCode);

    // ==============================================================
    // L. Refresh the page / restart app and verify Certificate is still visible
    // ==============================================================
    // Create brand new ProviderContainer to simulate restart/page refresh
    final freshRestartContainer = ProviderContainer();
    addTearDown(freshRestartContainer.dispose);

    final restartedCertRepo = freshRestartContainer.read(certificateRepositoryProvider);
    final restartedCert = await restartedCertRepo.getCertificateById(certificate.id);
    expect(restartedCert, isNotNull);
    expect(restartedCert.id, certificate.id);
    expect(restartedCert.ownerId, 'usr-owner-fresh');
    expect(restartedCert.instrumentUniqueId, createdInst.instrumentId);

    final restartedOwnerCerts = await restartedCertRepo.getCertificates(ownerId: 'usr-owner-fresh');
    expect(restartedOwnerCerts.any((c) => c.id == certificate.id), isTrue);

    // ==============================================================
    // M. Verify another unrelated owner cannot access this Certificate
    // ==============================================================
    final unrelatedLogin = await freshRestartContainer.read(authControllerProvider.notifier).login('owner@test.com', '123456');
    expect(unrelatedLogin, isTrue);
    final unrelatedOwnerUser = freshRestartContainer.read(authControllerProvider).user!;
    expect(unrelatedOwnerUser.id, 'usr-owner-01');

    // Unrelated owner queries their certificates
    final unrelatedOwnerCerts = await restartedCertRepo.getCertificates(ownerId: 'usr-owner-01');
    expect(unrelatedOwnerCerts.any((c) => c.id == certificate.id), isFalse);
    expect(unrelatedOwnerCerts.any((c) => c.ownerId == 'usr-owner-fresh'), isFalse);
  });

  testWidgets('CertificateViewScreen renders all required completion fields and QR code', (WidgetTester tester) async {
    final now = DateTime.now();
    final testCert = CertificateModel(
      id: 'cert-ui-test-01',
      certificateNumber: 'LM-CERT-2026-7777',
      instrumentId: 'inst-ui-01',
      instrumentUniqueId: 'LM-IN-2026-7777',
      instrumentType: 'Electronic Balance Class II',
      serialNumber: 'SN-7777',
      manufacturer: 'Mettler Toledo',
      model: 'ME204T Precision',
      capacity: 220.0,
      unit: 'g',
      ownerId: 'usr-owner-fresh',
      ownerName: 'Fresh Owner',
      ownerAddress: 'Shop 101, FC Road, Pune',
      verificationDate: now,
      issueDate: now,
      validUntil: now.add(const Duration(days: 365)),
      completionDate: now,
      issuingOfficerName: 'Inspector Vikram Patil',
      issuingAuthority: 'Legal Metrology Department',
      approvedBy: 'Shri Anand Kulkarni (Joint Controller)',
      approvalRemarks: 'Approved for statutory commercial trade use',
      qrVerificationCode: 'VERIFY-CERT-20267777-TEST',
      sha256IntegrityHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      status: CertificateStatus.valid,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CertificateViewScreen(certificate: testCert),
      ),
    );
    await tester.pump();

    expect(find.text('Digital Verification Certificate'), findsOneWidget);
    expect(find.text('LM-CERT-2026-7777'), findsOneWidget);
    expect(find.text('usr-owner-fresh'), findsOneWidget);
    expect(find.text('Fresh Owner'), findsOneWidget);
    expect(find.text('Shri Anand Kulkarni (Joint Controller)'), findsOneWidget);
    expect(find.text('Approved for statutory commercial trade use'), findsOneWidget);
    expect(find.text('Public Token: VERIFY-CERT-20267777-TEST'), findsOneWidget);
  });
}
