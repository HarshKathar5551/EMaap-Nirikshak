enum ApplicationType {
  newVerification,
  reVerification;

  String get displayName {
    switch (this) {
      case ApplicationType.newVerification:
        return 'Initial Verification';
      case ApplicationType.reVerification:
        return 'Periodic Re-Verification';
    }
  }

  static ApplicationType fromString(String type) {
    return ApplicationType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase() ||
             e.displayName.toLowerCase() == type.toLowerCase(),
      orElse: () => ApplicationType.newVerification,
    );
  }
}

enum ApplicationStatus {
  submitted,
  underReview,
  assigned,
  scheduled,
  inInspection,
  inspectionCompleted,
  approved,
  rejected,
  certificateIssued,
  expired;

  String get displayName {
    switch (this) {
      case ApplicationStatus.submitted:
        return 'SUBMITTED';
      case ApplicationStatus.underReview:
        return 'UNDER_REVIEW';
      case ApplicationStatus.assigned:
        return 'ASSIGNED';
      case ApplicationStatus.scheduled:
        return 'SCHEDULED';
      case ApplicationStatus.inInspection:
        return 'IN_INSPECTION';
      case ApplicationStatus.inspectionCompleted:
        return 'INSPECTION_COMPLETED';
      case ApplicationStatus.approved:
        return 'APPROVED';
      case ApplicationStatus.rejected:
        return 'REJECTED';
      case ApplicationStatus.certificateIssued:
        return 'CERTIFICATE_ISSUED';
      case ApplicationStatus.expired:
        return 'EXPIRED';
    }
  }

  static ApplicationStatus fromString(String status) {
    return ApplicationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase() ||
             e.displayName.toLowerCase() == status.toLowerCase(),
      orElse: () => ApplicationStatus.submitted,
    );
  }
}

class ApplicationModel {
  final String id;
  final String applicationId; // e.g. LM-APP-2026-0089
  final String instrumentId; // reference to Instrument
  final String instrumentUniqueId; // e.g. LM-IN-MH-PUN-000123
  final String instrumentType;
  final String ownerId;
  final String ownerName;
  final ApplicationType type;
  final ApplicationStatus status;
  final DateTime submittedDate;
  final DateTime? scheduledDate;
  final String? assignedOfficerId;
  final String? assignedOfficerName;
  final String? assignedGatcId;
  final String? assignedGatcName;
  final String? inspectionId;
  final String? certificateId;
  final String? remarks;
  final double feeAmount;
  final bool feePaid;

  const ApplicationModel({
    required this.id,
    required this.applicationId,
    required this.instrumentId,
    required this.instrumentUniqueId,
    required this.instrumentType,
    required this.ownerId,
    required this.ownerName,
    required this.type,
    required this.status,
    required this.submittedDate,
    this.scheduledDate,
    this.assignedOfficerId,
    this.assignedOfficerName,
    this.assignedGatcId,
    this.assignedGatcName,
    this.inspectionId,
    this.certificateId,
    this.remarks,
    this.feeAmount = 450.00,
    this.feePaid = true,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as String,
      applicationId: json['applicationId'] as String,
      instrumentId: json['instrumentId'] as String,
      instrumentUniqueId: json['instrumentUniqueId'] as String,
      instrumentType: json['instrumentType'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      type: ApplicationType.fromString(json['type'] as String),
      status: ApplicationStatus.fromString(json['status'] as String),
      submittedDate: DateTime.parse(json['submittedDate'] as String),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      assignedOfficerId: json['assignedOfficerId'] as String?,
      assignedOfficerName: json['assignedOfficerName'] as String?,
      assignedGatcId: json['assignedGatcId'] as String?,
      assignedGatcName: json['assignedGatcName'] as String?,
      inspectionId: json['inspectionId'] as String?,
      certificateId: json['certificateId'] as String?,
      remarks: json['remarks'] as String?,
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 450.00,
      feePaid: json['feePaid'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicationId': applicationId,
      'instrumentId': instrumentId,
      'instrumentUniqueId': instrumentUniqueId,
      'instrumentType': instrumentType,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'type': type.name,
      'status': status.displayName,
      'submittedDate': submittedDate.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'assignedOfficerId': assignedOfficerId,
      'assignedOfficerName': assignedOfficerName,
      'assignedGatcId': assignedGatcId,
      'assignedGatcName': assignedGatcName,
      'inspectionId': inspectionId,
      'certificateId': certificateId,
      'remarks': remarks,
      'feeAmount': feeAmount,
      'feePaid': feePaid,
    };
  }

  ApplicationModel copyWith({
    String? id,
    String? applicationId,
    String? instrumentId,
    String? instrumentUniqueId,
    String? instrumentType,
    String? ownerId,
    String? ownerName,
    ApplicationType? type,
    ApplicationStatus? status,
    DateTime? submittedDate,
    DateTime? scheduledDate,
    String? assignedOfficerId,
    String? assignedOfficerName,
    String? assignedGatcId,
    String? assignedGatcName,
    String? inspectionId,
    String? certificateId,
    String? remarks,
    double? feeAmount,
    bool? feePaid,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      instrumentId: instrumentId ?? this.instrumentId,
      instrumentUniqueId: instrumentUniqueId ?? this.instrumentUniqueId,
      instrumentType: instrumentType ?? this.instrumentType,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      type: type ?? this.type,
      status: status ?? this.status,
      submittedDate: submittedDate ?? this.submittedDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
      assignedOfficerName: assignedOfficerName ?? this.assignedOfficerName,
      assignedGatcId: assignedGatcId ?? this.assignedGatcId,
      assignedGatcName: assignedGatcName ?? this.assignedGatcName,
      inspectionId: inspectionId ?? this.inspectionId,
      certificateId: certificateId ?? this.certificateId,
      remarks: remarks ?? this.remarks,
      feeAmount: feeAmount ?? this.feeAmount,
      feePaid: feePaid ?? this.feePaid,
    );
  }
}
