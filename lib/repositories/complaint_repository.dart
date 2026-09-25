import '../models/complaint_model.dart';
import '../services/mock_api_service.dart';

abstract class IComplaintRepository {
  Future<List<ComplaintModel>> getComplaints();
  Future<ComplaintModel> submitComplaint(ComplaintModel complaint);
}

class ComplaintRepository implements IComplaintRepository {
  final IApiService _apiService;

  ComplaintRepository(this._apiService);

  @override
  Future<List<ComplaintModel>> getComplaints() => _apiService.getComplaints();

  @override
  Future<ComplaintModel> submitComplaint(ComplaintModel complaint) =>
      _apiService.createComplaint(complaint);
}
