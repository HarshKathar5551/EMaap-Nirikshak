import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/mock_api_service.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/instrument_repository.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/inspection_repository.dart';
import '../../repositories/certificate_repository.dart';
import '../../repositories/complaint_repository.dart';
import '../../repositories/system_repository.dart';

final apiServiceProvider = Provider<IApiService>((ref) {
  return MockApiService();
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});

final instrumentRepositoryProvider = Provider<IInstrumentRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return InstrumentRepository(apiService);
});

final applicationRepositoryProvider = Provider<IApplicationRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ApplicationRepository(apiService);
});

final inspectionRepositoryProvider = Provider<IInspectionRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return InspectionRepository(apiService);
});

final certificateRepositoryProvider = Provider<ICertificateRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CertificateRepository(apiService);
});

final complaintRepositoryProvider = Provider<IComplaintRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ComplaintRepository(apiService);
});

final systemRepositoryProvider = Provider<ISystemRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SystemRepository(apiService);
});
