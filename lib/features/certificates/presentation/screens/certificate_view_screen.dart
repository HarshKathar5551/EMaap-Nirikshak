import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/certificate_model.dart';
import '../../../dashboard/presentation/screens/public_verification_screen.dart';

class CertificateViewScreen extends StatelessWidget {
  final CertificateModel certificate;

  const CertificateViewScreen({super.key, required this.certificate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Verification Certificate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Certificate',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing certificate ${certificate.certificateNumber}')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: AppCard(
              padding: const EdgeInsets.all(24),
              border: Border.all(color: AppColors.primary, width: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Certificate Top Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          AppConstants.departmentName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CERTIFICATE OF VERIFICATION',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '[Under Rule 14 of Legal Metrology (General) Rules, 2011]',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Certificate ID & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Certificate Number', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            certificate.certificateNumber,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                      StatusBadge.fromStatus(certificate.status.displayName),
                    ],
                  ),
                  const Divider(height: 28),

                  // Details Grid
                  _CertRow(label: 'Instrument ID', value: certificate.instrumentUniqueId, isBold: true),
                  _CertRow(label: 'Equipment Category', value: certificate.instrumentType),
                  _CertRow(label: 'Manufacturer & Model', value: '${certificate.manufacturer} (${certificate.model})'),
                  _CertRow(label: 'Serial Number', value: certificate.serialNumber),
                  _CertRow(label: 'Max Capacity', value: '${certificate.capacity} ${certificate.unit}'),
                  _CertRow(label: 'Owner ID', value: certificate.ownerId),
                  _CertRow(label: 'Owner / Establishment', value: certificate.ownerName),
                  _CertRow(label: 'Address', value: certificate.ownerAddress),
                  const Divider(height: 24),

                  _CertRow(label: 'Verification Date', value: DateFormatter.formatDate(certificate.verificationDate)),
                  if (certificate.completionDate != null)
                    _CertRow(label: 'Completion Date', value: DateFormatter.formatDate(certificate.completionDate!)),
                  _CertRow(
                    label: 'Valid Until',
                    value: DateFormatter.formatDate(certificate.validUntil),
                    valueColor: AppColors.success,
                    isBold: true,
                  ),
                  _CertRow(label: 'Verifying Officer', value: certificate.issuingOfficerName),
                  if (certificate.approvedBy != null && certificate.approvedBy!.isNotEmpty)
                    _CertRow(label: 'Approved By', value: certificate.approvedBy!),
                  _CertRow(label: 'Issuing Authority', value: certificate.issuingAuthority),
                  if (certificate.approvalRemarks != null && certificate.approvalRemarks!.isNotEmpty)
                    _CertRow(label: 'Approval Remarks', value: certificate.approvalRemarks!),
                  const Divider(height: 28),

                  // Scannable QR Code
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: certificate.qrVerificationCode,
                          version: QrVersions.auto,
                          size: 150.0,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primary,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Public Token: ${certificate.qrVerificationCode}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Scan with any QR scanner to verify validity',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              icon: const Icon(Icons.copy, size: 14),
                              label: const Text('Copy Token', style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: certificate.qrVerificationCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.primary,
                                    content: Text('Copied token: ${certificate.qrVerificationCode}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              icon: const Icon(Icons.verified_user, size: 14),
                              label: const Text('Verify in Portal', style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PublicVerificationScreen(initialCode: certificate.qrVerificationCode),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SHA-256 Tamper Seal
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint, size: 22, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cryptographic Tamper-Proof Seal (SHA-256):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                              Text(
                                certificate.sha256IntegrityHash,
                                style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Button to verify public view
                  ElevatedButton.icon(
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Test Public QR Verification'),
                    onPressed: () {
                      context.push('/public/verify');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CertRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _CertRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
