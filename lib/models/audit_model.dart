class AuditLogModel {
  final String id;
  final String userId;
  final String userName;
  final String role;
  final String action; // e.g. APPLICATION_CREATED, OFFICER_ASSIGNED, INSPECTION_COMPLETED
  final String entityType; // Application, Instrument, Certificate, Complaint, Inspection
  final String entityId;
  final DateTime timestamp;
  final String? deviceId;
  final double? latitude;
  final double? longitude;
  final String details;

  const AuditLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.timestamp,
    this.deviceId,
    this.latitude,
    this.longitude,
    required this.details,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      role: json['role'] as String,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceId: json['deviceId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      details: json['details'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'role': role,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'details': details,
    };
  }
}
