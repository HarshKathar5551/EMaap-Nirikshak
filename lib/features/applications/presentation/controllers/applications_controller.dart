import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers.dart';
import '../../../../models/application_model.dart';
import '../../../../repositories/application_repository.dart';

class ApplicationsState {
  final List<ApplicationModel> applications;
  final bool isLoading;
  final String? errorMessage;

  const ApplicationsState({
    this.applications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ApplicationsState copyWith({
    List<ApplicationModel>? applications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ApplicationsState(
      applications: applications ?? this.applications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ApplicationsController extends StateNotifier<ApplicationsState> {
  final IApplicationRepository _repository;

  ApplicationsController(this._repository) : super(const ApplicationsState());

  Future<void> loadApplications({String? ownerId, String? officerId, String? status}) async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getApplications(
        ownerId: ownerId,
        officerId: officerId,
        status: status,
      );
      state = state.copyWith(applications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<ApplicationModel?> submitApplication(ApplicationModel application) async {
    state = state.copyWith(isLoading: true);
    try {
      final created = await _repository.submitApplication(application);
      state = state.copyWith(
        applications: [created, ...state.applications],
        isLoading: false,
      );
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  void updateApplicationStatus(String applicationId, ApplicationStatus newStatus) {
    state = state.copyWith(
      applications: state.applications.map((a) {
        if (a.id == applicationId || a.applicationId == applicationId) {
          return a.copyWith(status: newStatus);
        }
        return a;
      }).toList(),
    );
  }
}

final applicationsControllerProvider =
    StateNotifierProvider<ApplicationsController, ApplicationsState>((ref) {
  final repo = ref.watch(applicationRepositoryProvider);
  return ApplicationsController(repo);
});
