enum CertificateStatus {
  valid,
  expired,
  suspended,
  revoked;

  String get displayName {
    switch (this) {
      case CertificateStatus.valid:
        return 'VALID';
      case CertificateStatus.expired:
        return 'EXPIRED';
      case CertificateStatus.suspended:
        return 'SUSPENDED';
      case CertificateStatus.revoked:
        return 'REVOKED';
    }
  }

  static CertificateStatus fromString(String status) {
    return CertificateStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase() ||
             e.displayName.toLowerCase() == status.toLowerCase(),
      orElse: () => CertificateStatus.valid,
    );
  }
}

class CertificateModel {
  final String id;
  final String certificateNumber; // e.g. LM-CERT-2026-10234
  final String instrumentId;
  final String instrumentUniqueId; // e.g. LM-IN-MH-PUN-000123
  final String instrumentType;
  final String serialNumber;
  final String manufacturer;
  final String model;
  final double capacity;
  final String unit;
  final String ownerName;
  final String ownerAddress;
  final DateTime verificationDate;
  final DateTime issueDate;
  final DateTime validUntil;
  final String issuingOfficerName;
  final String issuingAuthority; // e.g. Legal Metrology Department, Pune Zone
  final String qrVerificationCode; // e.g. VERIFY-LM-8F92A71X
  final String sha256IntegrityHash;
  final CertificateStatus status;
  final String? remarks;

  const CertificateModel({
    required this.id,
    required this.certificateNumber,
    required this.instrumentId,
    required this.instrumentUniqueId,
    required this.instrumentType,
    required this.serialNumber,
    required this.manufacturer,
    required this.model,
    required this.capacity,
    required this.unit,
    required this.ownerName,
    required this.ownerAddress,
    required this.verificationDate,
    required this.issueDate,
    required this.validUntil,
    required this.issuingOfficerName,
    required this.issuingAuthority,
    required this.qrVerificationCode,
    required this.sha256IntegrityHash,
    required this.status,
    this.remarks,
  });

  bool get isExpired => validUntil.isBefore(DateTime.now());

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'] as String,
      certificateNumber: json['certificateNumber'] as String,
      instrumentId: json['instrumentId'] as String,
      instrumentUniqueId: json['instrumentUniqueId'] as String,
      instrumentType: json['instrumentType'] as String,
      serialNumber: json['serialNumber'] as String,
      manufacturer: json['manufacturer'] as String,
      model: json['model'] as String,
      capacity: (json['capacity'] as num).toDouble(),
      unit: json['unit'] as String,
      ownerName: json['ownerName'] as String,
      ownerAddress: json['ownerAddress'] as String,
      verificationDate: DateTime.parse(json['verificationDate'] as String),
      issueDate: DateTime.parse(json['issueDate'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
      issuingOfficerName: json['issuingOfficerName'] as String,
      issuingAuthority: json['issuingAuthority'] as String,
      qrVerificationCode: json['qrVerificationCode'] as String,
      sha256IntegrityHash: json['sha256IntegrityHash'] as String,
      status: CertificateStatus.fromString(json['status'] as String),
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'certificateNumber': certificateNumber,
      'instrumentId': instrumentId,
      'instrumentUniqueId': instrumentUniqueId,
      'instrumentType': instrumentType,
      'serialNumber': serialNumber,
      'manufacturer': manufacturer,
      'model': model,
      'capacity': capacity,
      'unit': unit,
      'ownerName': ownerName,
      'ownerAddress': ownerAddress,
      'verificationDate': verificationDate.toIso8601String(),
      'issueDate': issueDate.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'issuingOfficerName': issuingOfficerName,
      'issuingAuthority': issuingAuthority,
      'qrVerificationCode': qrVerificationCode,
      'sha256IntegrityHash': sha256IntegrityHash,
      'status': status.displayName,
      'remarks': remarks,
    };
  }

  CertificateModel copyWith({
    String? id,
    String? certificateNumber,
    String? instrumentId,
    String? instrumentUniqueId,
    String? instrumentType,
    String? serialNumber,
    String? manufacturer,
    String? model,
    double? capacity,
    String? unit,
    String? ownerName,
    String? ownerAddress,
    DateTime? verificationDate,
    DateTime? issueDate,
    DateTime? validUntil,
    String? issuingOfficerName,
    String? issuingAuthority,
    String? qrVerificationCode,
    String? sha256IntegrityHash,
    CertificateStatus? status,
    String? remarks,
  }) {
    return CertificateModel(
      id: id ?? this.id,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      instrumentId: instrumentId ?? this.instrumentId,
      instrumentUniqueId: instrumentUniqueId ?? this.instrumentUniqueId,
      instrumentType: instrumentType ?? this.instrumentType,
      serialNumber: serialNumber ?? this.serialNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      capacity: capacity ?? this.capacity,
      unit: unit ?? this.unit,
      ownerName: ownerName ?? this.ownerName,
      ownerAddress: ownerAddress ?? this.ownerAddress,
      verificationDate: verificationDate ?? this.verificationDate,
      issueDate: issueDate ?? this.issueDate,
      validUntil: validUntil ?? this.validUntil,
      issuingOfficerName: issuingOfficerName ?? this.issuingOfficerName,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      qrVerificationCode: qrVerificationCode ?? this.qrVerificationCode,
      sha256IntegrityHash: sha256IntegrityHash ?? this.sha256IntegrityHash,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
    );
  }
}
