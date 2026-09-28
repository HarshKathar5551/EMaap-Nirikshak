import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gov_app_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/audit_model.dart';
import '../../../../models/application_model.dart';
import '../../../../models/certificate_model.dart';
import '../../../../models/instrument_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../certificates/presentation/screens/certificate_view_screen.dart';
import '../../../applications/presentation/controllers/applications_controller.dart';
import '../../../instruments/presentation/controllers/instruments_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'public_verification_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  DateTime? _lastBackPress;
  int _reloadKey = 0;

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showCertificateWindow(CertificateModel cert) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top header bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'STATUTORY VERIFICATION CERTIFICATE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Seal and Title
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'GOVERNMENT OF MAHARASHTRA • LEGAL METROLOGY',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'CERTIFICATE OF VERIFICATION',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cert.certificateNumber,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // QR Code Display
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: QrImageView(
                      data: cert.qrVerificationCode,
                      version: QrVersions.auto,
                      size: 160,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cert.qrVerificationCode,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.primary),
                ),
                const SizedBox(height: 14),

                // Details Rows
                _buildDetailRow('Certificate Number', cert.certificateNumber),
                _buildDetailRow('Owner ID', cert.ownerId),
                _buildDetailRow('Owner', cert.ownerName),
                _buildDetailRow('Instrument', cert.instrumentType),
                _buildDetailRow('Instrument UID', cert.instrumentUniqueId),
                _buildDetailRow('Serial Number', cert.serialNumber),
                _buildDetailRow('Manufacturer', '${cert.manufacturer} (${cert.model})'),
                _buildDetailRow('Capacity', '${cert.capacity} ${cert.unit}'),
                if (cert.completionDate != null)
                  _buildDetailRow('Completion Date', DateFormatter.formatDate(cert.completionDate!)),
                _buildDetailRow('Valid Until', DateFormatter.formatDate(cert.validUntil)),
                _buildDetailRow('Approved By', cert.approvedBy ?? 'Joint Controller'),
                _buildDetailRow('Issuing Authority', cert.issuingOfficerName),
                _buildDetailRow('Integrity Hash', '${cert.sha256IntegrityHash.substring(0, 16)}...'),

                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 8),

                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Print Certificate', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text('Certificate ${cert.certificateNumber} sent to printer queue.'),
                          ),
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Verify in Portal', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        try {
                          context.push('/public/verify?code=${cert.qrVerificationCode}');
                        } catch (_) {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => PublicVerificationScreen(initialCode: cert.qrVerificationCode),
                            ),
                          );
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      icon: const Icon(Icons.fullscreen, size: 16),
                      label: const Text('Full Screen', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => CertificateViewScreen(certificate: cert),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCertificate(ApplicationModel item) async {
    try {
      CertificateModel? cert;
      final certRepo = ref.read(certificateRepositoryProvider);
      if (item.certificateId != null && item.certificateId!.isNotEmpty) {
        try {
          cert = await certRepo.getCertificateById(item.certificateId!);
        } catch (_) {}
      }
      if (cert == null) {
        final allCerts = await certRepo.getCertificates();
        cert = allCerts.cast<CertificateModel?>().firstWhere(
          (c) =>
              c?.id == item.certificateId ||
              c?.instrumentId == item.instrumentId ||
              c?.instrumentUniqueId == item.instrumentUniqueId,
          orElse: () => null,
        );
      }
      if (cert == null && item.instrumentId.isNotEmpty) {
        try {
          cert = await certRepo.getCertificateById(item.instrumentId);
        } catch (_) {}
      }
      if (cert == null && item.instrumentUniqueId.isNotEmpty) {
        try {
          cert = await certRepo.getCertificateById(item.instrumentUniqueId);
        } catch (_) {}
      }
      if (!mounted) return;
      if (cert != null) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => CertificateViewScreen(certificate: cert!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate details not found in system.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading certificate: $e')),
        );
      }
    }
  }

  void _showApplicationPermitDialog(ApplicationModel item) {
    final remarksController = TextEditingController(
      text: 'Statutory verification permit granted and verification certificate approved under Legal Metrology Act, 2009.',
    );
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogContentCtx, setDialogState) {
          final isIssued = item.status == ApplicationStatus.certificateIssued;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isIssued ? AppColors.success.withValues(alpha: 0.12) : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isIssued ? Icons.verified : Icons.assignment_outlined,
                    color: isIssued ? AppColors.success : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.applicationId,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        isIssued ? 'Permit Granted • Certified' : 'Verification Permit Review',
                        style: TextStyle(
                          fontSize: 11,
                          color: isIssued ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge.fromStatus(item.status.displayName),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 6),
                    _buildDetailRow('Instrument', item.instrumentType),
                    _buildDetailRow('Instrument ID', item.instrumentUniqueId),
                    _buildDetailRow('Owner', item.ownerName),
                    _buildDetailRow('Type', item.type.displayName),
                    _buildDetailRow('Submission Date', DateFormatter.formatDate(item.submittedDate)),
                    _buildDetailRow('Assigned Officer', item.assignedOfficerName ?? 'Not Assigned'),
                    if (item.remarks != null && item.remarks!.isNotEmpty)
                      _buildDetailRow('Remarks / Notes', item.remarks!),
                    const SizedBox(height: 12),
                    if (isIssued) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Statutory Permit Active',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.success),
                                  ),
                                  Text(
                                    'Certificate ID: ${item.certificateId ?? "Active"}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Permit Remarks / Endorsement',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: remarksController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Enter statutory remarks for certificate...',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Close'),
              ),
              if (isIssued)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('View Certificate'),
                  onPressed: () {
                    if (Navigator.of(dialogCtx).canPop()) {
                      Navigator.of(dialogCtx).pop();
                    }
                    _openCertificate(item);
                  },
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.verified, size: 18),
                  label: Text(isProcessing ? 'Issuing Permit...' : 'Grant Permit & Issue Certificate'),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setDialogState(() => isProcessing = true);
                          final dialogNav = Navigator.of(dialogCtx);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            final cert = await ref.read(applicationRepositoryProvider).issueCertificate(
                              item.id,
                              remarks: remarksController.text.trim(),
                            );

                            ref.read(applicationsControllerProvider.notifier).updateApplicationStatus(
                              item.id,
                              ApplicationStatus.certificateIssued,
                              certificateId: cert.id,
                            );
                            if (item.applicationId != item.id) {
                              ref.read(applicationsControllerProvider.notifier).updateApplicationStatus(
                                item.applicationId,
                                ApplicationStatus.certificateIssued,
                                certificateId: cert.id,
                              );
                            }
                            ref.read(instrumentsControllerProvider.notifier).updateInstrumentStatus(
                              item.instrumentId,
                              InstrumentStatus.verified,
                              certificateId: cert.id,
                            );
                            if (item.instrumentUniqueId != item.instrumentId) {
                              ref.read(instrumentsControllerProvider.notifier).updateInstrumentStatus(
                                item.instrumentUniqueId,
                                InstrumentStatus.verified,
                                certificateId: cert.id,
                              );
                            }

                            if (mounted) {
                              setState(() {
                                _reloadKey++;
                              });
                            }

                            // Close the review dialog
                            if (dialogNav.canPop()) {
                              dialogNav.pop();
                            }

                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text('✓ Statutory Permit granted! Certificate ${cert.certificateNumber} issued.'),
                                duration: const Duration(seconds: 3),
                              ),
                            );

                            // Open the specific Certificate window/screen reliably
                            if (mounted) {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => CertificateViewScreen(certificate: cert),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isProcessing = false);
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.error,
                                content: Text('Failed to grant permit: $e'),
                              ),
                            );
                          }
                        },
                ),
            ],
          );
        },
      ),
    );
  }

  void _openManageAllApplications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<List<ApplicationModel>>(
          future: ref.read(applicationRepositoryProvider).getApplications(),
          builder: (context, snapshot) {
            final list = snapshot.data ?? [];
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Applications & Permits',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text('${list.length} Total', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('No applications available'))
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            return AppCard(
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                _showApplicationPermitDialog(item);
                              },
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.assignment, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.applicationId,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
                                        ),
                                        Text(
                                          item.instrumentType,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Owner: ${item.ownerName} • ${item.assignedOfficerName ?? "Unassigned"}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge.fromStatus(item.status.displayName),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openManageAllCertificates() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<List<CertificateModel>>(
          future: ref.read(certificateRepositoryProvider).getCertificates(),
          builder: (context, snapshot) {
            final list = snapshot.data ?? [];
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'All Issued Verification Certificates',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${list.length} Total', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('No certificates issued yet'))
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            return AppCard(
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                _showCertificateWindow(item);
                              },
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.verified, color: AppColors.success, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.certificateNumber,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
                                        ),
                                        Text(
                                          '${item.instrumentType} (${item.instrumentUniqueId})',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Owner: ${item.ownerName} [${item.ownerId}] • Valid until: ${item.validUntil.toString().split(" ")[0]}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge.fromStatus(item.status.displayName),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final instrumentRepo = ref.watch(instrumentRepositoryProvider);
    final applicationRepo = ref.watch(applicationRepositoryProvider);
    final complaintRepo = ref.watch(complaintRepositoryProvider);
    final systemRepo = ref.watch(systemRepositoryProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final now = DateTime.now();
          if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
            _lastBackPress = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Press back again to exit'), duration: Duration(seconds: 2)),
            );
          } else {
            await SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: const GovAppHeader(title: 'E-MAAP • Admin Command Portal'),
        body: Column(
          children: [
            OfflineBanner(isOffline: authState.isOfflineSimulated),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin HQ Header
                    AppCard(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'STATE HEADQUARTERS • CONTROLLER LEVEL',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  authState.user?.name ?? 'Shri Anand Kulkarni',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Joint Controller of Legal Metrology • Govt of Maharashtra',
                                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.admin_panel_settings, size: 36, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // State Overview KPI Grid
                    FutureBuilder(
                      key: ValueKey('kpi_$_reloadKey'),
                      future: Future.wait([
                        instrumentRepo.getInstruments(),
                        applicationRepo.getApplications(),
                        complaintRepo.getComplaints(),
                        systemRepo.getRiskAssessments(),
                      ]),
                      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final totalInst = (snapshot.data?[0] as List?)?.length ?? 0;
                        final totalApps = (snapshot.data?[1] as List?)?.length ?? 0;
                        final totalComplaints = (snapshot.data?[2] as List?)?.length ?? 0;
                        final highRisk = (snapshot.data?[3] as List?)?.length ?? 0;

                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: [
                            _StatCard(title: 'Registered Instruments', value: '$totalInst', icon: Icons.storage, color: AppColors.primary),
                            _StatCard(title: 'Verification Applications', value: '$totalApps', icon: Icons.assignment, color: AppColors.info),
                            _StatCard(title: 'Consumer Complaints', value: '$totalComplaints', icon: Icons.report_problem, color: AppColors.warning),
                            _StatCard(title: 'High Risk Watchlist', value: '$highRisk', icon: Icons.security_update_warning, color: AppColors.riskHigh),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Admin Quick Actions
                    const Text(
                      'Administrative Controls',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.verified_outlined,
                            label: 'Issued\nCertificates',
                            onTap: _openManageAllCertificates,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.person_add_alt_outlined,
                            label: 'Officer\nAssignment',
                            onTap: _openManageAllApplications,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.analytics_outlined,
                            label: 'Risk\nEngine',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Risk Assessment Engine (Phase 11)')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.rule_folder_outlined,
                            label: 'Complaints\nReview',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Consumer Complaints review (Phase 10)')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.history_edu_outlined,
                            label: 'Audit\nTrail',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Government Audit Logs (Phase 13)')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Verification Applications
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Applications for Assignment',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        TextButton(
                          onPressed: _openManageAllApplications,
                          child: const Text('Manage All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    FutureBuilder<List<ApplicationModel>>(
                      key: ValueKey('apps_$_reloadKey'),
                      future: applicationRepo.getApplications(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 60,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final list = snapshot.data ?? [];
                        if (list.isEmpty) {
                          return const AppCard(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No applications yet. Instrument owners must submit verification applications.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.take(5).length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            return AppCard(
                              onTap: () => _showApplicationPermitDialog(item),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.assignment, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.applicationId,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
                                        ),
                                        Text(
                                          item.instrumentType,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Owner: ${item.ownerName} • ${item.assignedOfficerName ?? "Unassigned"}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge.fromStatus(item.status.displayName),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Audit Trail Live Feed
                    const Text(
                      'Departmental Audit Trail Feed',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),

                    FutureBuilder<List<AuditLogModel>>(
                      key: ValueKey('logs_$_reloadKey'),
                      future: systemRepo.getAuditLogs(),
                      builder: (context, snapshot) {
                        final list = snapshot.data ?? [];
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.take(4).length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final log = list[index];
                            return AppCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.security, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              log.action,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.primary),
                                            ),
                                            Text(
                                              DateFormatter.formatTime(log.timestamp),
                                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${log.userName} (${log.role}): ${log.details}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
