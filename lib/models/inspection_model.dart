enum InspectionStatus {
  pending,
  inProgress,
  passed,
  failed,
  needsReview;

  String get displayName {
    switch (this) {
      case InspectionStatus.pending:
        return 'PENDING';
      case InspectionStatus.inProgress:
        return 'IN_PROGRESS';
      case InspectionStatus.passed:
        return 'PASSED';
      case InspectionStatus.failed:
        return 'FAILED';
      case InspectionStatus.needsReview:
        return 'NEEDS_REVIEW';
    }
  }

  static InspectionStatus fromString(String status) {
    return InspectionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase() ||
             e.displayName.toLowerCase() == status.toLowerCase(),
      orElse: () => InspectionStatus.pending,
    );
  }
}

class ChecklistItem {
  final String id;
  final String label;
  final bool isCompleted;
  final bool isPassed;
  final String? remarks;

  const ChecklistItem({
    required this.id,
    required this.label,
    this.isCompleted = false,
    this.isPassed = false,
    this.remarks,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      label: json['label'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isPassed: json['isPassed'] as bool? ?? false,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'isCompleted': isCompleted,
      'isPassed': isPassed,
      'remarks': remarks,
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? label,
    bool? isCompleted,
    bool? isPassed,
    String? remarks,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      label: label ?? this.label,
      isCompleted: isCompleted ?? this.isCompleted,
      isPassed: isPassed ?? this.isPassed,
      remarks: remarks ?? this.remarks,
    );
  }
}

class MeasurementItem {
  final String id;
  final String parameterName;
  final double expectedValue;
  final double observedValue;
  final double error;
  final String unit;
  final bool isPassed;
  final double maximumPermissibleError;

  const MeasurementItem({
    required this.id,
    required this.parameterName,
    required this.expectedValue,
    required this.observedValue,
    required this.error,
    required this.unit,
    required this.isPassed,
    this.maximumPermissibleError = 0.5,
  });

  factory MeasurementItem.fromJson(Map<String, dynamic> json) {
    return MeasurementItem(
      id: json['id'] as String,
      parameterName: json['parameterName'] as String,
      expectedValue: (json['expectedValue'] as num).toDouble(),
      observedValue: (json['observedValue'] as num).toDouble(),
      error: (json['error'] as num).toDouble(),
      unit: json['unit'] as String,
      isPassed: json['isPassed'] as bool,
      maximumPermissibleError: (json['maximumPermissibleError'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parameterName': parameterName,
      'expectedValue': expectedValue,
      'observedValue': observedValue,
      'error': error,
      'unit': unit,
      'isPassed': isPassed,
      'maximumPermissibleError': maximumPermissibleError,
    };
  }
}

class EvidencePhoto {
  final String id;
  final String title;
  final String imagePathOrBase64;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String category; // Instrument, Serial Number, Seal, Environment

  const EvidencePhoto({
    required this.id,
    required this.title,
    required this.imagePathOrBase64,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  factory EvidencePhoto.fromJson(Map<String, dynamic> json) {
    return EvidencePhoto(
      id: json['id'] as String,
      title: json['title'] as String,
      imagePathOrBase64: json['imagePathOrBase64'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imagePathOrBase64': imagePathOrBase64,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
    };
  }
}

class InspectionModel {
  final String id;
  final String inspectionId; // e.g. LM-INSP-2026-0045
  final String applicationId;
  final String instrumentId;
  final String instrumentUniqueId;
  final String instrumentType;
  final String officerId;
  final String officerName;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final InspectionStatus status;
  final List<ChecklistItem> checklist;
  final List<MeasurementItem> measurements;
  final List<EvidencePhoto> evidencePhotos;
  final String? remarks;

  // GPS Verification
  final double registeredLatitude;
  final double registeredLongitude;
  final double? actualLatitude;
  final double? actualLongitude;
  final double? distanceMeters;
  final bool isLocationMatched;

  // Offline Sync metadata
  final String syncStatus; // SYNCED, SYNC_PENDING, CONFLICT
  final int version;
  final String? deviceId;

  const InspectionModel({
    required this.id,
    required this.inspectionId,
    required this.applicationId,
    required this.instrumentId,
    required this.instrumentUniqueId,
    required this.instrumentType,
    required this.officerId,
    required this.officerName,
    required this.scheduledDate,
    this.completedDate,
    required this.status,
    this.checklist = const [],
    this.measurements = const [],
    this.evidencePhotos = const [],
    this.remarks,
    required this.registeredLatitude,
    required this.registeredLongitude,
    this.actualLatitude,
    this.actualLongitude,
    this.distanceMeters,
    this.isLocationMatched = true,
    this.syncStatus = 'SYNCED',
    this.version = 1,
    this.deviceId,
  });

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    return InspectionModel(
      id: json['id'] as String,
      inspectionId: json['inspectionId'] as String,
      applicationId: json['applicationId'] as String,
      instrumentId: json['instrumentId'] as String,
      instrumentUniqueId: json['instrumentUniqueId'] as String,
      instrumentType: json['instrumentType'] as String,
      officerId: json['officerId'] as String,
      officerName: json['officerName'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      status: InspectionStatus.fromString(json['status'] as String),
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      measurements: (json['measurements'] as List<dynamic>?)
              ?.map((e) => MeasurementItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      evidencePhotos: (json['evidencePhotos'] as List<dynamic>?)
              ?.map((e) => EvidencePhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      remarks: json['remarks'] as String?,
      registeredLatitude: (json['registeredLatitude'] as num).toDouble(),
      registeredLongitude: (json['registeredLongitude'] as num).toDouble(),
      actualLatitude: (json['actualLatitude'] as num?)?.toDouble(),
      actualLongitude: (json['actualLongitude'] as num?)?.toDouble(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      isLocationMatched: json['isLocationMatched'] as bool? ?? true,
      syncStatus: json['syncStatus'] as String? ?? 'SYNCED',
      version: json['version'] as int? ?? 1,
      deviceId: json['deviceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inspectionId': inspectionId,
      'applicationId': applicationId,
      'instrumentId': instrumentId,
      'instrumentUniqueId': instrumentUniqueId,
      'instrumentType': instrumentType,
      'officerId': officerId,
      'officerName': officerName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'status': status.displayName,
      'checklist': checklist.map((e) => e.toJson()).toList(),
      'measurements': measurements.map((e) => e.toJson()).toList(),
      'evidencePhotos': evidencePhotos.map((e) => e.toJson()).toList(),
      'remarks': remarks,
      'registeredLatitude': registeredLatitude,
      'registeredLongitude': registeredLongitude,
      'actualLatitude': actualLatitude,
      'actualLongitude': actualLongitude,
      'distanceMeters': distanceMeters,
      'isLocationMatched': isLocationMatched,
      'syncStatus': syncStatus,
      'version': version,
      'deviceId': deviceId,
    };
  }

  InspectionModel copyWith({
    String? id,
    String? inspectionId,
    String? applicationId,
    String? instrumentId,
    String? instrumentUniqueId,
    String? instrumentType,
    String? officerId,
    String? officerName,
    DateTime? scheduledDate,
    DateTime? completedDate,
    InspectionStatus? status,
    List<ChecklistItem>? checklist,
    List<MeasurementItem>? measurements,
    List<EvidencePhoto>? evidencePhotos,
    String? remarks,
    double? registeredLatitude,
    double? registeredLongitude,
    double? actualLatitude,
    double? actualLongitude,
    double? distanceMeters,
    bool? isLocationMatched,
    String? syncStatus,
    int? version,
    String? deviceId,
  }) {
    return InspectionModel(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      applicationId: applicationId ?? this.applicationId,
      instrumentId: instrumentId ?? this.instrumentId,
      instrumentUniqueId: instrumentUniqueId ?? this.instrumentUniqueId,
      instrumentType: instrumentType ?? this.instrumentType,
      officerId: officerId ?? this.officerId,
      officerName: officerName ?? this.officerName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      checklist: checklist ?? this.checklist,
      measurements: measurements ?? this.measurements,
      evidencePhotos: evidencePhotos ?? this.evidencePhotos,
      remarks: remarks ?? this.remarks,
      registeredLatitude: registeredLatitude ?? this.registeredLatitude,
      registeredLongitude: registeredLongitude ?? this.registeredLongitude,
      actualLatitude: actualLatitude ?? this.actualLatitude,
      actualLongitude: actualLongitude ?? this.actualLongitude,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      isLocationMatched: isLocationMatched ?? this.isLocationMatched,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
