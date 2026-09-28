import '../models/application_model.dart';
import '../models/certificate_model.dart';
import '../services/mock_api_service.dart';

abstract class IApplicationRepository {
  Future<List<ApplicationModel>> getApplications({String? ownerId, String? officerId, String? status});
  Future<ApplicationModel> getApplicationById(String id);
  Future<ApplicationModel> submitApplication(ApplicationModel application);
  Future<ApplicationModel> assignOfficer(String applicationId, {String? officerId, String? officerName, String? gatcId, String? gatcName});
  Future<ApplicationModel> reviewApplication(String applicationId, {String? remarks});
  Future<ApplicationModel> approveApplication(String applicationId, {String? remarks});
  Future<ApplicationModel> rejectApplication(String applicationId, {String? remarks});
  Future<CertificateModel> issueCertificate(String applicationId, {String? remarks});
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

  @override
  Future<ApplicationModel> reviewApplication(String applicationId, {String? remarks}) {
    return _apiService.reviewApplication(applicationId, remarks: remarks);
  }

  @override
  Future<ApplicationModel> approveApplication(String applicationId, {String? remarks}) {
    return _apiService.approveApplication(applicationId, remarks: remarks);
  }

  @override
  Future<ApplicationModel> rejectApplication(String applicationId, {String? remarks}) {
    return _apiService.rejectApplication(applicationId, remarks: remarks);
  }

  @override
  Future<CertificateModel> issueCertificate(String applicationId, {String? remarks}) {
    return _apiService.issueCertificate(applicationId, remarks: remarks);
  }
}
