import '../models/instrument_model.dart';
import '../services/mock_api_service.dart';

abstract class IInstrumentRepository {
  Future<List<InstrumentModel>> getInstruments({String? ownerId, String? search});
  Future<InstrumentModel> getInstrumentById(String id);
  Future<InstrumentModel> registerInstrument(InstrumentModel instrument);
}

class InstrumentRepository implements IInstrumentRepository {
  final IApiService _apiService;

  InstrumentRepository(this._apiService);

  @override
  Future<List<InstrumentModel>> getInstruments({String? ownerId, String? search}) {
    return _apiService.getInstruments(ownerId: ownerId, search: search);
  }

  @override
  Future<InstrumentModel> getInstrumentById(String id) {
    return _apiService.getInstrumentById(id);
  }

  @override
  Future<InstrumentModel> registerInstrument(InstrumentModel instrument) {
    return _apiService.createInstrument(instrument);
  }
}
