class SyncQueueItem {
  final String id;
  final String recordId;
  final String entityType; // inspection, photo, gps, application
  final String action; // CREATE, UPDATE
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deviceId;
  final String syncStatus; // PENDING, SYNCING, SYNCED, CONFLICT
  final Map<String, dynamic> payload;
  final Map<String, dynamic>? serverVersionPayload;
  final String? conflictDetails;

  const SyncQueueItem({
    required this.id,
    required this.recordId,
    required this.entityType,
    required this.action,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.syncStatus,
    required this.payload,
    this.serverVersionPayload,
    this.conflictDetails,
  });

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      recordId: json['recordId'] as String,
      entityType: json['entityType'] as String,
      action: json['action'] as String,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deviceId: json['deviceId'] as String? ?? 'OFFICER-TAB-01',
      syncStatus: json['syncStatus'] as String? ?? 'PENDING',
      payload: json['payload'] as Map<String, dynamic>,
      serverVersionPayload: json['serverVersionPayload'] as Map<String, dynamic>?,
      conflictDetails: json['conflictDetails'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recordId': recordId,
      'entityType': entityType,
      'action': action,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deviceId': deviceId,
      'syncStatus': syncStatus,
      'payload': payload,
      'serverVersionPayload': serverVersionPayload,
      'conflictDetails': conflictDetails,
    };
  }

  SyncQueueItem copyWith({
    String? id,
    String? recordId,
    String? entityType,
    String? action,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
    String? syncStatus,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? serverVersionPayload,
    String? conflictDetails,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      entityType: entityType ?? this.entityType,
      action: action ?? this.action,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      syncStatus: syncStatus ?? this.syncStatus,
      payload: payload ?? this.payload,
      serverVersionPayload: serverVersionPayload ?? this.serverVersionPayload,
      conflictDetails: conflictDetails ?? this.conflictDetails,
    );
  }
}
