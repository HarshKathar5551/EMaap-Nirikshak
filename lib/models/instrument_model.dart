enum InstrumentStatus {
  registered,
  applied,
  assigned,
  scheduled,
  underInspection,
  verified,
  rejected,
  expired,
  reverificationDue;

  String get displayName {
    switch (this) {
      case InstrumentStatus.registered:
        return 'REGISTERED';
      case InstrumentStatus.applied:
        return 'APPLIED';
      case InstrumentStatus.assigned:
        return 'ASSIGNED';
      case InstrumentStatus.scheduled:
        return 'SCHEDULED';
      case InstrumentStatus.underInspection:
        return 'IN_INSPECTION';
      case InstrumentStatus.verified:
        return 'VERIFIED';
      case InstrumentStatus.rejected:
        return 'REJECTED';
      case InstrumentStatus.expired:
        return 'EXPIRED';
      case InstrumentStatus.reverificationDue:
        return 'RE_VERIFICATION_DUE';
    }
  }

  static InstrumentStatus fromString(String status) {
    return InstrumentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase() ||
             e.displayName.toLowerCase() == status.toLowerCase(),
      orElse: () => InstrumentStatus.registered,
    );
  }
}

class InstrumentModel {
  final String id;
  final String instrumentId; // e.g. LM-IN-MH-PUN-000123
  final String type; // e.g. Non-Automatic Weighing Instrument (Class III)
  final String manufacturer;
  final String model;
  final String serialNumber;
  final double capacity;
  final String unit; // e.g. kg, g, tons, litres
  final int yearOfManufacture;
  final DateTime purchaseDate;
  final String locationName; // Business / Establishment Name
  final String address;
  final double latitude;
  final double longitude;
  final String ownerId;
  final String ownerName;
  final InstrumentStatus status;
  final DateTime registrationDate;
  final DateTime? lastVerificationDate;
  final DateTime? nextVerificationDue;
  final String? activeCertificateId;
  final List<String> documentUrls;
  final List<String> photoUrls;
  final String? qrVerificationCode;
  final String? riskLevel; // LOW, MEDIUM, HIGH

  const InstrumentModel({
    required this.id,
    required this.instrumentId,
    required this.type,
    required this.manufacturer,
    required this.model,
    required this.serialNumber,
    required this.capacity,
    required this.unit,
    required this.yearOfManufacture,
    required this.purchaseDate,
    required this.locationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.ownerId,
    required this.ownerName,
    required this.status,
    required this.registrationDate,
    this.lastVerificationDate,
    this.nextVerificationDue,
    this.activeCertificateId,
    this.documentUrls = const [],
    this.photoUrls = const [],
    this.qrVerificationCode,
    this.riskLevel = 'LOW',
  });

  factory InstrumentModel.fromJson(Map<String, dynamic> json) {
    return InstrumentModel(
      id: json['id'] as String,
      instrumentId: json['instrumentId'] as String,
      type: json['type'] as String,
      manufacturer: json['manufacturer'] as String,
      model: json['model'] as String,
      serialNumber: json['serialNumber'] as String,
      capacity: (json['capacity'] as num).toDouble(),
      unit: json['unit'] as String,
      yearOfManufacture: json['yearOfManufacture'] as int,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      locationName: json['locationName'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      status: InstrumentStatus.fromString(json['status'] as String),
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      lastVerificationDate: json['lastVerificationDate'] != null
          ? DateTime.parse(json['lastVerificationDate'] as String)
          : null,
      nextVerificationDue: json['nextVerificationDue'] != null
          ? DateTime.parse(json['nextVerificationDue'] as String)
          : null,
      activeCertificateId: json['activeCertificateId'] as String?,
      documentUrls: (json['documentUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      qrVerificationCode: json['qrVerificationCode'] as String?,
      riskLevel: json['riskLevel'] as String? ?? 'LOW',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instrumentId': instrumentId,
      'type': type,
      'manufacturer': manufacturer,
      'model': model,
      'serialNumber': serialNumber,
      'capacity': capacity,
      'unit': unit,
      'yearOfManufacture': yearOfManufacture,
      'purchaseDate': purchaseDate.toIso8601String(),
      'locationName': locationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'status': status.displayName,
      'registrationDate': registrationDate.toIso8601String(),
      'lastVerificationDate': lastVerificationDate?.toIso8601String(),
      'nextVerificationDue': nextVerificationDue?.toIso8601String(),
      'activeCertificateId': activeCertificateId,
      'documentUrls': documentUrls,
      'photoUrls': photoUrls,
      'qrVerificationCode': qrVerificationCode,
      'riskLevel': riskLevel,
    };
  }

  InstrumentModel copyWith({
    String? id,
    String? instrumentId,
    String? type,
    String? manufacturer,
    String? model,
    String? serialNumber,
    double? capacity,
    String? unit,
    int? yearOfManufacture,
    DateTime? purchaseDate,
    String? locationName,
    String? address,
    double? latitude,
    double? longitude,
    String? ownerId,
    String? ownerName,
    InstrumentStatus? status,
    DateTime? registrationDate,
    DateTime? lastVerificationDate,
    DateTime? nextVerificationDue,
    String? activeCertificateId,
    List<String>? documentUrls,
    List<String>? photoUrls,
    String? qrVerificationCode,
    String? riskLevel,
  }) {
    return InstrumentModel(
      id: id ?? this.id,
      instrumentId: instrumentId ?? this.instrumentId,
      type: type ?? this.type,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      capacity: capacity ?? this.capacity,
      unit: unit ?? this.unit,
      yearOfManufacture: yearOfManufacture ?? this.yearOfManufacture,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      status: status ?? this.status,
      registrationDate: registrationDate ?? this.registrationDate,
      lastVerificationDate: lastVerificationDate ?? this.lastVerificationDate,
      nextVerificationDue: nextVerificationDue ?? this.nextVerificationDue,
      activeCertificateId: activeCertificateId ?? this.activeCertificateId,
      documentUrls: documentUrls ?? this.documentUrls,
      photoUrls: photoUrls ?? this.photoUrls,
      qrVerificationCode: qrVerificationCode ?? this.qrVerificationCode,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }
}
