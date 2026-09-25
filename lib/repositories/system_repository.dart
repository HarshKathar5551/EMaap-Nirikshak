import '../models/audit_model.dart';
import '../models/notification_model.dart';
import '../models/risk_model.dart';
import '../models/sync_model.dart';
import '../services/mock_api_service.dart';

abstract class ISystemRepository {
  Future<List<AuditLogModel>> getAuditLogs();
  Future<void> logAudit(AuditLogModel log);
  Future<List<AppNotificationModel>> getNotifications(String userId);
  Future<List<RiskAssessmentModel>> getRiskAssessments();
  Future<Map<String, dynamic>> syncOfflineQueue(List<SyncQueueItem> queue);
}

class SystemRepository implements ISystemRepository {
  final IApiService _apiService;

  SystemRepository(this._apiService);

  @override
  Future<List<AuditLogModel>> getAuditLogs() => _apiService.getAuditLogs();

  @override
  Future<void> logAudit(AuditLogModel log) => _apiService.logAudit(log);

  @override
  Future<List<AppNotificationModel>> getNotifications(String userId) =>
      _apiService.getNotifications(userId);

  @override
  Future<List<RiskAssessmentModel>> getRiskAssessments() =>
      _apiService.getRiskAssessments();

  @override
  Future<Map<String, dynamic>> syncOfflineQueue(List<SyncQueueItem> queue) =>
      _apiService.syncOfflineQueue(queue);
}
