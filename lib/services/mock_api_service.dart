import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/instrument_model.dart';
import '../models/application_model.dart';
import '../models/inspection_model.dart';
import '../models/certificate_model.dart';
import '../models/complaint_model.dart';
import '../models/audit_model.dart';
import '../models/notification_model.dart';
import '../models/risk_model.dart';
import '../models/sync_model.dart';
import '../core/errors/failures.dart';
import 'mock_data.dart';

abstract class IApiService {
  bool get isOffline;
  void setOfflineMode(bool offline);

  // Auth
  Future<UserModel> login(String email, String password);

  // Instruments
  Future<List<InstrumentModel>> getInstruments({String? ownerId, String? search});
  Future<InstrumentModel> getInstrumentById(String id);
  Future<InstrumentModel> createInstrument(InstrumentModel instrument);

  // Applications
  Future<List<ApplicationModel>> getApplications({String? ownerId, String? officerId, String? status});
  Future<ApplicationModel> getApplicationById(String id);
  Future<ApplicationModel> createApplication(ApplicationModel application);
  Future<ApplicationModel> assignOfficer(String applicationId, {String? officerId, String? officerName, String? gatcId, String? gatcName});

  // Inspections
  Future<List<InspectionModel>> getInspections({String? officerId, String? status});
  Future<InspectionModel> getInspectionById(String id);
  Future<InspectionModel> completeInspection(String inspectionId, InspectionStatus status, {String? remarks, List<ChecklistItem>? checklist, List<MeasurementItem>? measurements});

  // Certificates
  Future<List<CertificateModel>> getCertificates();
  Future<CertificateModel> getCertificateById(String id);
  Future<CertificateModel> getCertificateByVerificationCode(String code);
  Future<CertificateModel> generateCertificate(CertificateModel certificate);

  // Public Verification
  Future<CertificateModel?> verifyPublicQr(String qrVerificationCode);

  // Complaints
  Future<List<ComplaintModel>> getComplaints();
  Future<ComplaintModel> createComplaint(ComplaintModel complaint);

  // Audit & Notifications
  Future<List<AuditLogModel>> getAuditLogs();
  Future<void> logAudit(AuditLogModel log);
  Future<List<AppNotificationModel>> getNotifications(String userId);

  // Risk
  Future<List<RiskAssessmentModel>> getRiskAssessments();

  // Sync
  Future<Map<String, dynamic>> syncOfflineQueue(List<SyncQueueItem> queue);
}

class MockApiService implements IApiService {
  bool _simulateOffline = false;
  final Uuid _uuid = const Uuid();

  // In-memory working copies of the dataset
  late List<UserModel> _users;
  late List<InstrumentModel> _instruments;
  late List<ApplicationModel> _applications;
  late List<InspectionModel> _inspections;
  late List<CertificateModel> _certificates;
  late List<ComplaintModel> _complaints;
  late List<AuditLogModel> _auditLogs;
  late List<AppNotificationModel> _notifications;
  late List<RiskAssessmentModel> _riskAssessments;

  MockApiService() {
    _resetData();
  }

  void _resetData() {
    _users = List.from(MockData.users);
    _instruments = List.from(MockData.instruments);
    _applications = List.from(MockData.applications);
    _inspections = List.from(MockData.inspections);
    _certificates = List.from(MockData.certificates);
    _complaints = List.from(MockData.complaints);
    _auditLogs = List.from(MockData.auditLogs);
    _notifications = List.from(MockData.notifications);
    _riskAssessments = List.from(MockData.riskAssessments);
  }

  @override
  bool get isOffline => _simulateOffline;

  @override
  void setOfflineMode(bool offline) {
    _simulateOffline = offline;
  }

  Future<void> _simulateNetworkDelay([int ms = 250]) async {
    if (_simulateOffline) {
      throw const ServerFailure('Cannot connect to server. Device is in OFFLINE mode.');
    }
    await Future.delayed(Duration(milliseconds: ms));
  }

  @override
  Future<UserModel> login(String email, String password) async {
    await _simulateNetworkDelay(300);
    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => throw const AuthFailure('Invalid credentials. Check email and password.'),
    );
    if (password != '123456') {
      throw const AuthFailure('Invalid password. Demo password is: 123456');
    }
    return user;
  }

  @override
  Future<List<InstrumentModel>> getInstruments({String? ownerId, String? search}) async {
    await _simulateNetworkDelay();
    var list = _instruments;
    if (ownerId != null) {
      list = list.where((i) => i.ownerId == ownerId).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((i) =>
        i.instrumentId.toLowerCase().contains(q) ||
        i.serialNumber.toLowerCase().contains(q) ||
        i.model.toLowerCase().contains(q) ||
        i.manufacturer.toLowerCase().contains(q) ||
        i.locationName.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  @override
  Future<InstrumentModel> getInstrumentById(String id) async {
    await _simulateNetworkDelay();
    return _instruments.firstWhere(
      (i) => i.id == id || i.instrumentId == id,
      orElse: () => throw const ServerFailure('Instrument not found.'),
    );
  }

  @override
  Future<InstrumentModel> createInstrument(InstrumentModel instrument) async {
    try {
      await _simulateNetworkDelay();
    } catch (_) {
      // Allow offline instrument creation in local mock store
    }
    _instruments.insert(0, instrument);
    // Auto log audit
    _auditLogs.insert(0, AuditLogModel(
      id: _uuid.v4(),
      userId: instrument.ownerId,
      userName: instrument.ownerName,
      role: 'OWNER',
      action: 'INSTRUMENT_REGISTERED',
      entityType: 'Instrument',
      entityId: instrument.instrumentId,
      timestamp: DateTime.now(),
      details: 'Registered new instrument: ${instrument.type} (${instrument.serialNumber})',
    ));
    return instrument;
  }

  @override
  Future<List<ApplicationModel>> getApplications({String? ownerId, String? officerId, String? status}) async {
    await _simulateNetworkDelay();
    var list = _applications;
    if (ownerId != null) {
      list = list.where((a) => a.ownerId == ownerId).toList();
    }
    if (officerId != null) {
      list = list.where((a) => a.assignedOfficerId == officerId || a.assignedGatcId == officerId).toList();
    }
    if (status != null) {
      list = list.where((a) => a.status.name.toLowerCase() == status.toLowerCase()).toList();
    }
    return list;
  }

  @override
  Future<ApplicationModel> getApplicationById(String id) async {
    await _simulateNetworkDelay();
    return _applications.firstWhere(
      (a) => a.id == id || a.applicationId == id,
      orElse: () => throw const ServerFailure('Application not found.'),
    );
  }

  @override
  Future<ApplicationModel> createApplication(ApplicationModel application) async {
    await _simulateNetworkDelay();
    _applications.insert(0, application);
    // Update instrument status to APPLIED
    final index = _instruments.indexWhere((i) => i.id == application.instrumentId);
    if (index != -1) {
      _instruments[index] = _instruments[index].copyWith(status: InstrumentStatus.applied);
    }
    return application;
  }

  @override
  Future<ApplicationModel> assignOfficer(String applicationId, {String? officerId, String? officerName, String? gatcId, String? gatcName}) async {
    await _simulateNetworkDelay();
    final index = _applications.indexWhere((a) => a.id == applicationId || a.applicationId == applicationId);
    if (index == -1) throw const ServerFailure('Application not found');
    final updated = _applications[index].copyWith(
      assignedOfficerId: officerId,
      assignedOfficerName: officerName,
      assignedGatcId: gatcId,
      assignedGatcName: gatcName,
      status: ApplicationStatus.assigned,
    );
    _applications[index] = updated;
    return updated;
  }

  @override
  Future<List<InspectionModel>> getInspections({String? officerId, String? status}) async {
    await _simulateNetworkDelay();
    var list = _inspections;
    if (officerId != null) {
      list = list.where((i) => i.officerId == officerId).toList();
    }
    if (status != null) {
      list = list.where((i) => i.status.name.toLowerCase() == status.toLowerCase()).toList();
    }
    return list;
  }

  @override
  Future<InspectionModel> getInspectionById(String id) async {
    await _simulateNetworkDelay();
    return _inspections.firstWhere(
      (i) => i.id == id || i.inspectionId == id,
      orElse: () => throw const ServerFailure('Inspection not found.'),
    );
  }

  @override
  Future<InspectionModel> completeInspection(
    String inspectionId,
    InspectionStatus status, {
    String? remarks,
    List<ChecklistItem>? checklist,
    List<MeasurementItem>? measurements,
  }) async {
    await _simulateNetworkDelay();
    final index = _inspections.indexWhere((i) => i.id == inspectionId || i.inspectionId == inspectionId);
    if (index == -1) throw const ServerFailure('Inspection not found');

    final current = _inspections[index];
    final updated = current.copyWith(
      status: status,
      completedDate: DateTime.now(),
      remarks: remarks ?? current.remarks,
      checklist: checklist ?? current.checklist,
      measurements: measurements ?? current.measurements,
      syncStatus: 'SYNCED',
    );
    _inspections[index] = updated;
    return updated;
  }

  @override
  Future<List<CertificateModel>> getCertificates() async {
    await _simulateNetworkDelay();
    return _certificates;
  }

  @override
  Future<CertificateModel> getCertificateById(String id) async {
    await _simulateNetworkDelay();
    return _certificates.firstWhere(
      (c) => c.id == id || c.certificateNumber == id,
      orElse: () => throw const ServerFailure('Certificate not found.'),
    );
  }

  @override
  Future<CertificateModel> getCertificateByVerificationCode(String code) async {
    await _simulateNetworkDelay();
    return _certificates.firstWhere(
      (c) => c.qrVerificationCode.toUpperCase() == code.trim().toUpperCase(),
      orElse: () => throw const ServerFailure('Certificate with verification code not found.'),
    );
  }

  @override
  Future<CertificateModel> generateCertificate(CertificateModel certificate) async {
    await _simulateNetworkDelay();
    _certificates.insert(0, certificate);
    return certificate;
  }

  @override
  Future<CertificateModel?> verifyPublicQr(String qrVerificationCode) async {
    await _simulateNetworkDelay(150);
    try {
      var code = qrVerificationCode.trim().toUpperCase();
      // Extract from URL if full URL is scanned (e.g. https://domain.gov/verify?code=VERIFY-...)
      if (code.contains('CODE=')) {
        final match = RegExp(r'CODE=([^&]+)').firstMatch(code);
        if (match != null && match.group(1) != null) {
          code = match.group(1)!;
        }
      } else if (code.contains('/')) {
        code = code.split('/').last;
      }

      // 1. Search existing certificates by QR code, certificate number, instrument UID, or serial
      for (final c in _certificates) {
        if (c.qrVerificationCode.toUpperCase() == code ||
            c.certificateNumber.toUpperCase() == code ||
            c.instrumentUniqueId.toUpperCase() == code ||
            c.serialNumber.toUpperCase() == code ||
            c.instrumentId.toUpperCase() == code) {
          return c;
        }
      }

      // 2. Search instruments if queried by instrument ID / serial number
      for (final inst in _instruments) {
        if (inst.instrumentId.toUpperCase() == code ||
            inst.serialNumber.toUpperCase() == code ||
            inst.id.toUpperCase() == code) {
          // If a certificate exists for this instrument, return it
          final existingCert = _certificates.cast<CertificateModel?>().firstWhere(
            (c) => c?.instrumentId == inst.id || c?.instrumentUniqueId == inst.instrumentId,
            orElse: () => null,
          );
          if (existingCert != null) return existingCert;

          // Otherwise return live certificate model representing this equipment
          return CertificateModel(
            id: 'cert-${inst.id}',
            certificateNumber: 'LM-CERT-LIVE-${inst.serialNumber}',
            instrumentId: inst.id,
            instrumentUniqueId: inst.instrumentId,
            instrumentType: inst.type,
            serialNumber: inst.serialNumber,
            manufacturer: inst.manufacturer,
            model: inst.model,
            capacity: inst.capacity,
            unit: inst.unit,
            ownerName: inst.ownerName,
            ownerAddress: inst.address,
            verificationDate: inst.lastVerificationDate ?? inst.purchaseDate,
            issueDate: inst.lastVerificationDate ?? inst.purchaseDate,
            validUntil: inst.nextVerificationDue ?? inst.purchaseDate.add(const Duration(days: 365)),
            issuingOfficerName: 'Inspector Vikram Patil',
            issuingAuthority: 'Legal Metrology Department, Pune Zone',
            qrVerificationCode: 'VERIFY-${inst.serialNumber}',
            sha256IntegrityHash: MockData.generateSha256('${inst.instrumentId}:${inst.serialNumber}:LIVE'),
            status: inst.status == InstrumentStatus.expired
                ? CertificateStatus.expired
                : CertificateStatus.valid,
            remarks: 'Instrument registered in National Legal Metrology Portal.',
          );
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    await _simulateNetworkDelay();
    return _complaints;
  }

  @override
  Future<ComplaintModel> createComplaint(ComplaintModel complaint) async {
    await _simulateNetworkDelay();
    _complaints.insert(0, complaint);
    return complaint;
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs() async {
    await _simulateNetworkDelay();
    return _auditLogs;
  }

  @override
  Future<void> logAudit(AuditLogModel log) async {
    _auditLogs.insert(0, log);
  }

  @override
  Future<List<AppNotificationModel>> getNotifications(String userId) async {
    await _simulateNetworkDelay();
    return _notifications.where((n) => n.userId == userId || userId == 'ALL').toList();
  }

  @override
  Future<List<RiskAssessmentModel>> getRiskAssessments() async {
    await _simulateNetworkDelay();
    return _riskAssessments;
  }

  @override
  Future<Map<String, dynamic>> syncOfflineQueue(List<SyncQueueItem> queue) async {
    await _simulateNetworkDelay(800);
    int syncedCount = 0;
    int conflictCount = 0;

    for (final item in queue) {
      if (item.version > 5) {
        conflictCount++;
      } else {
        syncedCount++;
      }
    }

    return {
      'total': queue.length,
      'synced': syncedCount,
      'conflicts': conflictCount,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
