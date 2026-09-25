import '../models/certificate_model.dart';
import '../services/mock_api_service.dart';

abstract class ICertificateRepository {
  Future<List<CertificateModel>> getCertificates();
  Future<CertificateModel> getCertificateById(String id);
  Future<CertificateModel> getCertificateByVerificationCode(String code);
  Future<CertificateModel?> verifyPublicQr(String code);
  Future<CertificateModel> generateCertificate(CertificateModel certificate);
}

class CertificateRepository implements ICertificateRepository {
  final IApiService _apiService;

  CertificateRepository(this._apiService);

  @override
  Future<List<CertificateModel>> getCertificates() => _apiService.getCertificates();

  @override
  Future<CertificateModel> getCertificateById(String id) => _apiService.getCertificateById(id);

  @override
  Future<CertificateModel> getCertificateByVerificationCode(String code) =>
      _apiService.getCertificateByVerificationCode(code);

  @override
  Future<CertificateModel?> verifyPublicQr(String code) => _apiService.verifyPublicQr(code);

  @override
  Future<CertificateModel> generateCertificate(CertificateModel certificate) =>
      _apiService.generateCertificate(certificate);
}
