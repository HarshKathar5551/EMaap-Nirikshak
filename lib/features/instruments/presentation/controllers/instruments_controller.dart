import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../../../models/instrument_model.dart';
import '../../../../repositories/instrument_repository.dart';

class InstrumentsState {
  final List<InstrumentModel> instruments;
  final bool isLoading;
  final String? errorMessage;

  const InstrumentsState({
    this.instruments = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  InstrumentsState copyWith({
    List<InstrumentModel>? instruments,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InstrumentsState(
      instruments: instruments ?? this.instruments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class InstrumentsController extends StateNotifier<InstrumentsState> {
  final IInstrumentRepository _repository;

  InstrumentsController(this._repository) : super(const InstrumentsState());

  Future<void> loadInstruments({String? ownerId, String? search}) async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getInstruments(ownerId: ownerId, search: search);
      state = state.copyWith(instruments: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<InstrumentModel?> registerInstrument(InstrumentModel instrument) async {
    state = state.copyWith(isLoading: true);
    try {
      final created = await _repository.registerInstrument(instrument);
      state = state.copyWith(
        instruments: [created, ...state.instruments],
        isLoading: false,
      );
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  void updateInstrumentStatus(String instrumentId, InstrumentStatus newStatus) {
    state = state.copyWith(
      instruments: state.instruments.map((i) {
        if (i.id == instrumentId || i.instrumentId == instrumentId) {
          return i.copyWith(status: newStatus);
        }
        return i;
      }).toList(),
    );
  }
}

final instrumentsControllerProvider =
    StateNotifierProvider<InstrumentsController, InstrumentsState>((ref) {
  final repo = ref.watch(instrumentRepositoryProvider);
  return InstrumentsController(repo);
});
