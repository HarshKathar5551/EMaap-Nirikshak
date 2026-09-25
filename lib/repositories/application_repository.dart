import '../models/application_model.dart';
import '../services/mock_api_service.dart';

abstract class IApplicationRepository {
  Future<List<ApplicationModel>> getApplications({String? ownerId, String? officerId, String? status});
  Future<ApplicationModel> getApplicationById(String id);
  Future<ApplicationModel> submitApplication(ApplicationModel application);
  Future<ApplicationModel> assignOfficer(String applicationId, {String? officerId, String? officerName, String? gatcId, String? gatcName});
}

class ApplicationRepository implements IApplicationRepository {
  final IApiService _apiService;

  ApplicationRepository(this._apiService);

  @override
  Future<List<ApplicationModel>> getApplications({String? ownerId, String? officerId, String? status}) {
    return _apiService.getApplications(ownerId: ownerId, officerId: officerId, status: status);
  }

  @override
  Future<ApplicationModel> getApplicationById(String id) {
    return _apiService.getApplicationById(id);
  }

  @override
  Future<ApplicationModel> submitApplication(ApplicationModel application) {
    return _apiService.createApplication(application);
  }

  @override
  Future<ApplicationModel> assignOfficer(String applicationId, {String? officerId, String? officerName, String? gatcId, String? gatcName}) {
    return _apiService.assignOfficer(applicationId, officerId: officerId, officerName: officerName, gatcId: gatcId, gatcName: gatcName);
  }
}
