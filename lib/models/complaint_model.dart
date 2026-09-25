enum ComplaintCategory {
  wrongMeasurement,
  damagedSeal,
  expiredCertificate,
  suspiciousCertificate,
  incorrectDetails,
  other;

  String get displayName {
    switch (this) {
      case ComplaintCategory.wrongMeasurement:
        return 'Wrong Measurement / Inaccurate Weight';
      case ComplaintCategory.damagedSeal:
        return 'Damaged or Missing Verification Seal';
      case ComplaintCategory.expiredCertificate:
        return 'Expired Verification Certificate';
      case ComplaintCategory.suspiciousCertificate:
        return 'Suspicious or Counterfeit Certificate';
      case ComplaintCategory.incorrectDetails:
        return 'Incorrect Instrument or Location Details';
      case ComplaintCategory.other:
        return 'Other Metrology Violation';
    }
  }

  static ComplaintCategory fromString(String category) {
    return ComplaintCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == category.toLowerCase(),
      orElse: () => ComplaintCategory.other,
    );
  }
}

enum ComplaintStatus {
  submitted,
  underReview,
  assigned,
  investigation,
  resolved,
  rejected;

  String get displayName {
    switch (this) {
      case ComplaintStatus.submitted:
        return 'SUBMITTED';
      case ComplaintStatus.underReview:
        return 'UNDER_REVIEW';
      case ComplaintStatus.assigned:
        return 'ASSIGNED';
      case ComplaintStatus.investigation:
        return 'INVESTIGATION';
      case ComplaintStatus.resolved:
        return 'RESOLVED';
      case ComplaintStatus.rejected:
        return 'REJECTED';
    }
  }

  static ComplaintStatus fromString(String status) {
    return ComplaintStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase() ||
             e.displayName.toLowerCase() == status.toLowerCase(),
      orElse: () => ComplaintStatus.submitted,
    );
  }
}

class ComplaintModel {
  final String id;
  final String complaintNumber; // e.g. CMP-2026-00123
  final String? instrumentId;
  final String? certificateNumber;
  final ComplaintCategory category;
  final String description;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final String? complainantContact;
  final DateTime submittedDate;
  final ComplaintStatus status;
  final String? assignedOfficerId;
  final String? assignedOfficerName;
  final String? resolutionRemarks;
  final DateTime? resolvedDate;

  const ComplaintModel({
    required this.id,
    required this.complaintNumber,
    this.instrumentId,
    this.certificateNumber,
    required this.category,
    required this.description,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.complainantContact,
    required this.submittedDate,
    required this.status,
    this.assignedOfficerId,
    this.assignedOfficerName,
    this.resolutionRemarks,
    this.resolvedDate,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String,
      complaintNumber: json['complaintNumber'] as String,
      instrumentId: json['instrumentId'] as String?,
      certificateNumber: json['certificateNumber'] as String?,
      category: ComplaintCategory.fromString(json['category'] as String),
      description: json['description'] as String,
      photoUrl: json['photoUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      complainantContact: json['complainantContact'] as String?,
      submittedDate: DateTime.parse(json['submittedDate'] as String),
      status: ComplaintStatus.fromString(json['status'] as String),
      assignedOfficerId: json['assignedOfficerId'] as String?,
      assignedOfficerName: json['assignedOfficerName'] as String?,
      resolutionRemarks: json['resolutionRemarks'] as String?,
      resolvedDate: json['resolvedDate'] != null
          ? DateTime.parse(json['resolvedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaintNumber': complaintNumber,
      'instrumentId': instrumentId,
      'certificateNumber': certificateNumber,
      'category': category.name,
      'description': description,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'complainantContact': complainantContact,
      'submittedDate': submittedDate.toIso8601String(),
      'status': status.displayName,
      'assignedOfficerId': assignedOfficerId,
      'assignedOfficerName': assignedOfficerName,
      'resolutionRemarks': resolutionRemarks,
      'resolvedDate': resolvedDate?.toIso8601String(),
    };
  }

  ComplaintModel copyWith({
    String? id,
    String? complaintNumber,
    String? instrumentId,
    String? certificateNumber,
    ComplaintCategory? category,
    String? description,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? complainantContact,
    DateTime? submittedDate,
    ComplaintStatus? status,
    String? assignedOfficerId,
    String? assignedOfficerName,
    String? resolutionRemarks,
    DateTime? resolvedDate,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      complaintNumber: complaintNumber ?? this.complaintNumber,
      instrumentId: instrumentId ?? this.instrumentId,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      category: category ?? this.category,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      complainantContact: complainantContact ?? this.complainantContact,
      submittedDate: submittedDate ?? this.submittedDate,
      status: status ?? this.status,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
      assignedOfficerName: assignedOfficerName ?? this.assignedOfficerName,
      resolutionRemarks: resolutionRemarks ?? this.resolutionRemarks,
      resolvedDate: resolvedDate ?? this.resolvedDate,
    );
  }
}
