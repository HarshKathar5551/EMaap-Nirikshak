import '../models/inspection_model.dart';
import '../services/mock_api_service.dart';

abstract class IInspectionRepository {
  Future<List<InspectionModel>> getInspections({String? officerId, String? status});
  Future<InspectionModel> getInspectionById(String id);
  Future<InspectionModel> completeInspection(String inspectionId, InspectionStatus status, {String? remarks, List<ChecklistItem>? checklist, List<MeasurementItem>? measurements});
  Future<InspectionModel> createInspection(InspectionModel inspection);
}

class InspectionRepository implements IInspectionRepository {
  final IApiService _apiService;

  InspectionRepository(this._apiService);

  @override
  Future<List<InspectionModel>> getInspections({String? officerId, String? status}) {
    return _apiService.getInspections(officerId: officerId, status: status);
  }

  @override
  Future<InspectionModel> getInspectionById(String id) {
    return _apiService.getInspectionById(id);
  }

  @override
  Future<InspectionModel> completeInspection(String inspectionId, InspectionStatus status, {String? remarks, List<ChecklistItem>? checklist, List<MeasurementItem>? measurements}) {
    return _apiService.completeInspection(inspectionId, status, remarks: remarks, checklist: checklist, measurements: measurements);
  }

  @override
  Future<InspectionModel> createInspection(InspectionModel inspection) {
    return _apiService.createInspection(inspection);
  }
}
