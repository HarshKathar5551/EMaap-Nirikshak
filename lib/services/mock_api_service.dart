import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
  Future<ApplicationModel> reviewApplication(String applicationId, {String? remarks});
  Future<ApplicationModel> approveApplication(String applicationId, {String? remarks});
  Future<ApplicationModel> rejectApplication(String applicationId, {String? remarks});
  Future<CertificateModel> issueCertificate(String applicationId, {String? remarks});

  // Inspections
  Future<List<InspectionModel>> getInspections({String? officerId, String? status});
  Future<InspectionModel> getInspectionById(String id);
  Future<InspectionModel> completeInspection(String inspectionId, InspectionStatus status, {String? remarks, List<ChecklistItem>? checklist, List<MeasurementItem>? measurements});
  Future<InspectionModel> createInspection(InspectionModel inspection);

  // Certificates
  Future<List<CertificateModel>> getCertificates({String? ownerId});
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

  // In-memory static cache surviving service recreations in same session
  static List<InstrumentModel>? _cachedInstruments;
  static List<ApplicationModel>? _cachedApplications;
  static List<InspectionModel>? _cachedInspections;
  static List<CertificateModel>? _cachedCertificates;
  static List<AuditLogModel>? _cachedAuditLogs;

  static const String _kCertificatesStorageKey = 'emaap_certificates_store_v1';
  static const String _kInstrumentsStorageKey = 'emaap_instruments_store_v1';
  static const String _kApplicationsStorageKey = 'emaap_applications_store_v1';
  static const String _kInspectionsStorageKey = 'emaap_inspections_store_v1';
  static const String _kAuditLogsStorageKey = 'emaap_audit_logs_store_v1';

  MockApiService() {
    _initData();
  }

  void _initData() {
    _users = List.from(MockData.users);
    _complaints = List.from(MockData.complaints);
    _notifications = List.from(MockData.notifications);
    _riskAssessments = List.from(MockData.riskAssessments);

    if (_cachedInstruments != null) {
      _instruments = List.from(_cachedInstruments!);
      _applications = List.from(_cachedApplications ?? MockData.applications);
      _inspections = List.from(_cachedInspections ?? MockData.inspections);
      _certificates = List.from(_cachedCertificates ?? MockData.certificates);
      _auditLogs = List.from(_cachedAuditLogs ?? MockData.auditLogs);
    } else {
      _resetData();
    }

    _loadPersistentStorage();
  }

  Future<void> _loadPersistentStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final certsRaw = prefs.getString(_kCertificatesStorageKey);
      if (certsRaw != null && certsRaw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(certsRaw);
        final loaded = decoded.map((e) => CertificateModel.fromJson(e as Map<String, dynamic>)).toList();
        final existingIds = loaded.map((c) => c.id).toSet();
        for (final c in _certificates) {
          if (!existingIds.contains(c.id)) {
            loaded.add(c);
          }
        }
        _certificates = loaded;
        _cachedCertificates = loaded;
      }

      final instsRaw = prefs.getString(_kInstrumentsStorageKey);
      if (instsRaw != null && instsRaw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(instsRaw);
        final loaded = decoded.map((e) => InstrumentModel.fromJson(e as Map<String, dynamic>)).toList();
        final existingIds = loaded.map((i) => i.id).toSet();
        for (final i in _instruments) {
          if (!existingIds.contains(i.id)) {
            loaded.add(i);
          }
        }
        _instruments = loaded;
        _cachedInstruments = loaded;
      }

      final appsRaw = prefs.getString(_kApplicationsStorageKey);
      if (appsRaw != null && appsRaw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(appsRaw);
        final loaded = decoded.map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>)).toList();
        final existingIds = loaded.map((a) => a.id).toSet();
        for (final a in _applications) {
          if (!existingIds.contains(a.id)) {
            loaded.add(a);
          }
        }
        _applications = loaded;
        _cachedApplications = loaded;
      }

      final inspsRaw = prefs.getString(_kInspectionsStorageKey);
      if (inspsRaw != null && inspsRaw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(inspsRaw);
        final loaded = decoded.map((e) => InspectionModel.fromJson(e as Map<String, dynamic>)).toList();
        final existingIds = loaded.map((i) => i.id).toSet();
        for (final i in _inspections) {
          if (!existingIds.contains(i.id)) {
            loaded.add(i);
          }
        }
        _inspections = loaded;
        _cachedInspections = loaded;
      }
    } catch (_) {}
  }

  Future<void> _persistCertificates() async {
    _cachedCertificates = List.from(_certificates);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCertificatesStorageKey, jsonEncode(_certificates.map((c) => c.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _persistInstruments() async {
    _cachedInstruments = List.from(_instruments);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kInstrumentsStorageKey, jsonEncode(_instruments.map((i) => i.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _persistApplications() async {
    _cachedApplications = List.from(_applications);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kApplicationsStorageKey, jsonEncode(_applications.map((a) => a.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _persistInspections() async {
    _cachedInspections = List.from(_inspections);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kInspectionsStorageKey, jsonEncode(_inspections.map((i) => i.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _persistAuditLogs() async {
    _cachedAuditLogs = List.from(_auditLogs);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAuditLogsStorageKey, jsonEncode(_auditLogs.map((a) => a.toJson()).toList()));
    } catch (_) {}
  }

  void _resetData() {
    _users = List.from(MockData.users);
    _instruments = MockData.instruments.map((inst) {
      if (inst.qrVerificationCode == null || inst.qrVerificationCode!.isEmpty) {
        final cleanId = inst.instrumentId.replaceAll('LM-IN-', '').replaceAll('-', '');
        final serialSuffix = inst.serialNumber.replaceAll('-', '').replaceAll(' ', '');
        final token = serialSuffix.length >= 4
            ? serialSuffix.substring(serialSuffix.length - 4).toUpperCase()
            : 'X${inst.id.replaceAll('inst-', '')}';
        return inst.copyWith(qrVerificationCode: 'VERIFY-LM-$cleanId-$token');
      }
      return inst;
    }).toList();
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
    // Guarantee unique product QR code for this specific instrument
    var uniqueQr = instrument.qrVerificationCode?.trim() ?? '';
    if (uniqueQr.isEmpty || _instruments.any((i) => i.qrVerificationCode?.toUpperCase() == uniqueQr.toUpperCase())) {
      final cleanId = instrument.instrumentId.replaceAll('LM-IN-', '').replaceAll('-', '');
      final entropy = _uuid.v4().replaceAll('-', '').substring(0, 8).toUpperCase();
      uniqueQr = 'VERIFY-LM-$cleanId-$entropy';
    }
    final saved = instrument.copyWith(qrVerificationCode: uniqueQr);
    _instruments.insert(0, saved);
    await _persistInstruments();
    // Auto log audit
    final audit = AuditLogModel(
      id: _uuid.v4(),
      userId: saved.ownerId,
      userName: saved.ownerName,
      role: 'OWNER',
      action: 'INSTRUMENT_REGISTERED',
      entityType: 'Instrument',
      entityId: saved.instrumentId,
      timestamp: DateTime.now(),
      details: 'Registered new instrument: ${saved.type} (${saved.serialNumber}) with unique QR: $uniqueQr',
    );
    _auditLogs.insert(0, audit);
    await _persistAuditLogs();
    return saved;
  }

  @override
  Future<List<ApplicationModel>> getApplications({String? ownerId, String? officerId, String? status}) async {
    await _simulateNetworkDelay();
    var list = _applications;
    if (ownerId != null) {
      list = list.where((a) => a.ownerId == ownerId).toList();
    }
    if (officerId != null) {
      list = list.where((a) => a.assignedOfficerId == officerId || a.assignedOfficerId == null || a.assignedGatcId == officerId).toList();
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
    final index = _instruments.indexWhere((i) => i.id == application.instrumentId || i.instrumentId == application.instrumentUniqueId);
    if (index != -1) {
      _instruments[index] = _instruments[index].copyWith(status: InstrumentStatus.applied);
    }
    await _persistApplications();
    await _persistInstruments();
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
    await _persistApplications();
    return updated;
  }

  @override
  Future<ApplicationModel> reviewApplication(String applicationId, {String? remarks}) async {
    await _simulateNetworkDelay();
    final index = _applications.indexWhere((a) => a.id == applicationId || a.applicationId == applicationId);
    if (index == -1) throw const ServerFailure('Application not found');
    final updated = _applications[index].copyWith(
      status: ApplicationStatus.inspectionCompleted, // LMO reviewed → sent to Admin
      remarks: remarks ?? 'Reviewed by LMO. Documents verified. Forwarded to Administrator for approval.',
    );
    _applications[index] = updated;
    await _persistApplications();
    // Log audit
    _auditLogs.insert(0, AuditLogModel(
      id: _uuid.v4(),
      userId: updated.assignedOfficerId ?? 'usr-officer-01',
      userName: updated.assignedOfficerName ?? 'Inspector Vikram Patil',
      role: 'LMO',
      action: 'APPLICATION_FORWARDED_TO_ADMIN',
      entityType: 'Application',
      entityId: updated.applicationId,
      timestamp: DateTime.now(),
      details: 'LMO reviewed application ${updated.applicationId} and forwarded to Administrator for approval.',
    ));
    await _persistAuditLogs();
    return updated;
  }

  @override
  Future<ApplicationModel> rejectApplication(String applicationId, {String? remarks}) async {
    await _simulateNetworkDelay();
    final index = _applications.indexWhere((a) => a.id == applicationId || a.applicationId == applicationId);
    if (index == -1) throw const ServerFailure('Application not found');
    final updated = _applications[index].copyWith(
      status: ApplicationStatus.rejected,
      remarks: remarks ?? 'Application rejected.',
    );
    _applications[index] = updated;
    // Update instrument status to rejected
    final instIdx = _instruments.indexWhere((i) => i.id == updated.instrumentId || i.instrumentId == updated.instrumentUniqueId);
    if (instIdx != -1) {
      _instruments[instIdx] = _instruments[instIdx].copyWith(status: InstrumentStatus.rejected);
    }
    await _persistApplications();
    await _persistInstruments();
    _auditLogs.insert(0, AuditLogModel(
      id: _uuid.v4(),
      userId: 'system',
      userName: 'System',
      role: 'SYSTEM',
      action: 'APPLICATION_REJECTED',
      entityType: 'Application',
      entityId: updated.applicationId,
      timestamp: DateTime.now(),
      details: 'Application ${updated.applicationId} rejected. Reason: ${remarks ?? "Not specified"}',
    ));
    await _persistAuditLogs();
    return updated;
  }

  @override
  Future<ApplicationModel> approveApplication(String applicationId, {String? remarks}) async {
    await _simulateNetworkDelay();
    final index = _applications.indexWhere((a) => a.id == applicationId || a.applicationId == applicationId);
    if (index == -1) throw const ServerFailure('Application not found');
    final app = _applications[index];
    final updated = app.copyWith(
      status: ApplicationStatus.approved,
      remarks: remarks ?? 'Approved by Administrator. Certificate issuance authorized.',
    );
    _applications[index] = updated;
    await _persistApplications();
    _auditLogs.insert(0, AuditLogModel(
      id: _uuid.v4(),
      userId: 'usr-admin-01',
      userName: 'Shri Anand Kulkarni',
      role: 'ADMIN',
      action: 'APPLICATION_APPROVED',
      entityType: 'Application',
      entityId: updated.applicationId,
      timestamp: DateTime.now(),
      details: 'Administrator approved application ${updated.applicationId}. Instrument: ${updated.instrumentUniqueId}.',
    ));
    await _persistAuditLogs();
    return updated;
  }

  @override
  Future<CertificateModel> issueCertificate(String applicationId, {String? remarks}) async {
    await _simulateNetworkDelay(400);
    final appIndex = _applications.indexWhere((a) => a.id == applicationId || a.applicationId == applicationId);
    if (appIndex == -1) throw const ServerFailure('Application not found');
    final app = _applications[appIndex];

    // Find instrument
    var instIndex = _instruments.indexWhere((i) => i.id == app.instrumentId || i.instrumentId == app.instrumentUniqueId);
    if (instIndex == -1) {
      instIndex = _instruments.indexWhere((i) => i.id == app.instrumentId || i.instrumentId == app.instrumentId);
    }
    if (instIndex == -1) {
      instIndex = _instruments.indexWhere((i) => i.ownerId == app.ownerId && (i.type == app.instrumentType || i.instrumentId == app.instrumentUniqueId));
    }
    if (instIndex == -1) {
      instIndex = _instruments.indexWhere((i) => i.ownerId == app.ownerId || i.ownerName == app.ownerName);
    }
    if (instIndex == -1) throw const ServerFailure('Instrument associated with application not found');
    final inst = _instruments[instIndex];

    final certSuffix = (10000 + _certificates.length + 1).toString();
    final certNum = 'LM-CERT-${DateTime.now().year}-$certSuffix';
    final certId = _uuid.v4();
    final now = DateTime.now();
    final validUntil = now.add(const Duration(days: 365));
    final entropy = _uuid.v4().replaceAll('-', '').substring(0, 6).toUpperCase();

    // Generate unique QR verification code for this certificate
    final cleanCertId = certNum.replaceAll('LM-CERT-', '').replaceAll('-', '');
    final uniqueCertQr = 'VERIFY-CERT-$cleanCertId-$entropy';

    final targetOwnerId = inst.ownerId.isNotEmpty ? inst.ownerId : app.ownerId;
    final targetOwnerName = inst.ownerName.isNotEmpty ? inst.ownerName : app.ownerName;

    final certificate = CertificateModel(
      id: certId,
      certificateNumber: certNum,
      instrumentId: inst.id,
      instrumentUniqueId: inst.instrumentId,
      instrumentType: inst.type,
      serialNumber: inst.serialNumber,
      manufacturer: inst.manufacturer,
      model: inst.model,
      capacity: inst.capacity,
      unit: inst.unit,
      ownerId: targetOwnerId,
      ownerName: targetOwnerName,
      ownerAddress: inst.address,
      verificationDate: now,
      issueDate: now,
      validUntil: validUntil,
      completionDate: now,
      issuingOfficerName: 'Shri Anand Kulkarni',
      issuingAuthority: 'Directorate of Legal Metrology, Maharashtra State',
      approvedBy: 'Shri Anand Kulkarni (Joint Controller)',
      approvalRemarks: remarks ?? 'Approved and issued by Directorate',
      qrVerificationCode: uniqueCertQr,
      sha256IntegrityHash: MockData.generateSha256('$certNum:${inst.instrumentId}:${inst.serialNumber}:${now.toIso8601String()}'),
      status: CertificateStatus.valid,
      remarks: remarks ?? 'Certificate issued after successful verification and admin approval.',
    );

    _certificates.insert(0, certificate);

    // Update application → certificateIssued
    _applications[appIndex] = app.copyWith(
      status: ApplicationStatus.certificateIssued,
      certificateId: certId,
    );

    // Update instrument → verified, keeping its activeCertificateId
    _instruments[instIndex] = inst.copyWith(
      status: InstrumentStatus.verified,
      lastVerificationDate: now,
      nextVerificationDue: validUntil,
      activeCertificateId: certId,
    );

    await _persistCertificates();
    await _persistApplications();
    await _persistInstruments();

    // Audit log
    _auditLogs.insert(0, AuditLogModel(
      id: _uuid.v4(),
      userId: 'usr-admin-01',
      userName: 'Shri Anand Kulkarni',
      role: 'ADMIN',
      action: 'CERTIFICATE_ISSUED',
      entityType: 'Certificate',
      entityId: certNum,
      timestamp: now,
      details: 'Certificate $certNum issued for ${inst.type} (${inst.serialNumber}). Valid until ${validUntil.toLocal().toString().split(" ")[0]}.',
    ));
    await _persistAuditLogs();

    return certificate;
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
    await _persistInspections();
    return updated;
  }

  @override
  Future<InspectionModel> createInspection(InspectionModel inspection) async {
    await _simulateNetworkDelay();
    _inspections.insert(0, inspection);
    await _persistInspections();
    return inspection;
  }

  @override
  Future<List<CertificateModel>> getCertificates({String? ownerId}) async {
    await _simulateNetworkDelay();
    if (ownerId != null && ownerId.isNotEmpty) {
      return _certificates.where((c) => c.ownerId == ownerId).toList();
    }
    return _certificates;
  }

  @override
  Future<CertificateModel> getCertificateById(String id) async {
    await _simulateNetworkDelay();
    final query = id.trim().toLowerCase();
    for (final c in _certificates) {
      if (c.id.toLowerCase() == query ||
          c.certificateNumber.toLowerCase() == query ||
          c.qrVerificationCode.toLowerCase() == query ||
          c.instrumentId.toLowerCase() == query ||
          c.instrumentUniqueId.toLowerCase() == query) {
        return c;
      }
    }

    // Try reloading from persistent storage if not found in memory
    try {
      final prefs = await SharedPreferences.getInstance();
      final certsRaw = prefs.getString(_kCertificatesStorageKey);
      if (certsRaw != null && certsRaw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(certsRaw);
        final loaded = decoded.map((e) => CertificateModel.fromJson(e as Map<String, dynamic>)).toList();
        for (final c in loaded) {
          if (c.id.toLowerCase() == query ||
              c.certificateNumber.toLowerCase() == query ||
              c.qrVerificationCode.toLowerCase() == query ||
              c.instrumentId.toLowerCase() == query ||
              c.instrumentUniqueId.toLowerCase() == query) {
            if (!_certificates.any((x) => x.id == c.id)) {
              _certificates.add(c);
            }
            return c;
          }
        }
      }
    } catch (_) {}

    throw const ServerFailure('Certificate not found.');
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
    await _persistCertificates();
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

      // 2. Search instruments by instrument unique QR code, ID, or serial number
      for (final inst in _instruments) {
        if ((inst.qrVerificationCode != null && inst.qrVerificationCode!.toUpperCase() == code) ||
            inst.instrumentId.toUpperCase() == code ||
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
            ownerId: inst.ownerId,
            ownerName: inst.ownerName,
            ownerAddress: inst.address,
            verificationDate: inst.lastVerificationDate ?? inst.purchaseDate,
            issueDate: inst.lastVerificationDate ?? inst.purchaseDate,
            validUntil: inst.nextVerificationDue ?? inst.purchaseDate.add(const Duration(days: 365)),
            completionDate: inst.lastVerificationDate ?? inst.purchaseDate,
            issuingOfficerName: 'Inspector Vikram Patil',
            issuingAuthority: 'Legal Metrology Department, Pune Zone',
            approvedBy: 'Inspector Vikram Patil',
            qrVerificationCode: inst.qrVerificationCode ?? 'VERIFY-${inst.serialNumber}',
            sha256IntegrityHash: MockData.generateSha256('${inst.instrumentId}:${inst.serialNumber}:LIVE'),
            status: inst.status == InstrumentStatus.expired
                ? CertificateStatus.expired
                : CertificateStatus.valid,
            remarks: 'Instrument registered in National Legal Metrology Portal. Official QR Token.',
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
