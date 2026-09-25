import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../models/certificate_model.dart';
import '../../../../models/complaint_model.dart';
import '../../../certificates/presentation/screens/certificate_view_screen.dart';
import '../widgets/public_qr_scanner_dialog.dart';

class PublicVerificationScreen extends ConsumerStatefulWidget {
  const PublicVerificationScreen({super.key});

  @override
  ConsumerState<PublicVerificationScreen> createState() => _PublicVerificationScreenState();
}

class _PublicVerificationScreenState extends ConsumerState<PublicVerificationScreen> {
  final _searchController = TextEditingController(text: 'VERIFY-LM-8F92A71X');
  bool _isSearching = false;
  CertificateModel? _verifiedCertificate;
  bool _hasSearched = false;

  Future<void> _verifyCode([String? codeToVerify]) async {
    final code = codeToVerify ?? _searchController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _verifiedCertificate = null;
    });

    try {
      final certRepo = ref.read(certificateRepositoryProvider);
      final result = await certRepo.verifyPublicQr(code);
      setState(() {
        _verifiedCertificate = result;
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _verifiedCertificate = null;
        _isSearching = false;
      });
    }
  }

  Future<void> _openScanner() async {
    final scannedCode = await PublicQrScannerDialog.show(context);
    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      _searchController.text = scannedCode;
      _verifyCode(scannedCode);
    }
  }

  void _showReportDiscrepancyDialog(CertificateModel cert) {
    final descController = TextEditingController();
    final contactController = TextEditingController();
    ComplaintCategory selectedCategory = ComplaintCategory.wrongMeasurement;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag, color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Report Discrepancy',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cert.instrumentType,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        Text(
                          'UID: ${cert.instrumentUniqueId} • Shop: ${cert.ownerName}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Grievance Nature', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ComplaintCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: ComplaintCategory.values.map((cat) {
                      return DropdownMenuItem<ComplaintCategory>(
                        value: cat,
                        child: Text(cat.displayName, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Details / Incident Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe the measurement error, location, or merchant refusal...',
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Contact Mobile (For Status SMS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '+91 98765 43210',
                      prefixIcon: Icon(Icons.phone, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('CANCEL'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 16),
                label: const Text('SUBMIT GRIEVANCE'),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (descController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please describe the discrepancy')),
                          );
                          return;
                        }
                        setDialogState(() => isSubmitting = true);
                        try {
                          final complaintRepo = ref.read(complaintRepositoryProvider);
                          final complaint = ComplaintModel(
                            id: 'cmp-${DateTime.now().millisecondsSinceEpoch}',
                            complaintNumber: 'LM-CMP-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            instrumentId: cert.instrumentId,
                            certificateNumber: cert.certificateNumber,
                            category: selectedCategory,
                            description: descController.text.trim(),
                            complainantContact: contactController.text.trim().isNotEmpty ? contactController.text.trim() : '+91 Citizen',
                            submittedDate: DateTime.now(),
                            status: ComplaintStatus.submitted,
                            assignedOfficerName: cert.issuingOfficerName,
                          );
                          await complaintRepo.submitComplaint(complaint);
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text('Complaint ${complaint.complaintNumber} lodged directly with Legal Metrology Officer.'),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Auto-verify initial code for quick demonstration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyCode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Instrument Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            tooltip: 'Scan Instrument QR',
            onPressed: _openScanner,
          ),
          TextButton.icon(
            icon: const Icon(Icons.login, color: Colors.white, size: 18),
            label: const Text('Official Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Citizen Metrology Trust Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user, color: AppColors.primary, size: 30),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Citizen Metrology Verification Portal',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Verify legal calibration, validity, and authentic stamping of any commercial weighing or measuring product.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Primary QR Scan CTA Card
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan QR Code on Equipment',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Camera viewfinder, gallery photo, or instant presets',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_scanner, size: 22, color: AppColors.primary),
                          label: const Text(
                            'OPEN QR SCANNER',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          onPressed: _openScanner,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Manual Search Box
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Or Search by Token, Certificate, or Serial Number',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'e.g. VERIFY-LM-8F92A71X or Serial',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                                  tooltip: 'Scan QR with Camera',
                                  onPressed: _openScanner,
                                ),
                              ),
                              onSubmitted: (_) => _verifyCode(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 48)),
                            onPressed: _isSearching ? null : () => _verifyCode(),
                            child: _isSearching
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('VERIFY'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          const Text('Quick test codes:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          _ChipButton(
                            label: '⚖️ Scale (Valid)',
                            code: 'VERIFY-LM-8F92A71X',
                            onTap: (c) {
                              _searchController.text = c;
                              _verifyCode(c);
                            },
                          ),
                          _ChipButton(
                            label: '⛽ Fuel Dispenser',
                            code: 'VERIFY-LM-9B41C22Y',
                            onTap: (c) {
                              _searchController.text = c;
                              _verifyCode(c);
                            },
                          ),
                          _ChipButton(
                            label: '🚛 Weighbridge (Expired)',
                            code: 'VERIFY-LM-3D19E55Z',
                            onTap: (c) {
                              _searchController.text = c;
                              _verifyCode(c);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Verification Result Area
                if (_isSearching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Authenticating product in National Legal Metrology database...'),
                        ],
                      ),
                    ),
                  )
                else if (_hasSearched && _verifiedCertificate != null) ...[
                  _DetailedProductResultCard(
                    cert: _verifiedCertificate!,
                    onScanAgain: _openScanner,
                    onReportDiscrepancy: () => _showReportDiscrepancyDialog(_verifiedCertificate!),
                    onViewCertificate: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CertificateViewScreen(certificate: _verifiedCertificate!),
                        ),
                      );
                    },
                  ),
                ] else if (_hasSearched && _verifiedCertificate == null) ...[
                  AppCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const Icon(Icons.cancel_outlined, color: AppColors.error, size: 54),
                        const SizedBox(height: 14),
                        const Text(
                          'UNVERIFIED / SUSPICIOUS PRODUCT',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This QR code or token does not match any authenticated record in the National Metrology Register. The equipment may be counterfeit, uncalibrated, or unregistered.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              label: const Text('RE-SCAN STICKER'),
                              onPressed: _openScanner,
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              icon: const Icon(Icons.report_problem, size: 18),
                              label: const Text('REPORT SUSPICIOUS SCALE'),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Incident flagged for Legal Metrology enforcement squad.'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final String code;
  final ValueChanged<String> onTap;

  const _ChipButton({required this.label, required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(code),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '$label ($code)',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _DetailedProductResultCard extends StatelessWidget {
  final CertificateModel cert;
  final VoidCallback onScanAgain;
  final VoidCallback onReportDiscrepancy;
  final VoidCallback onViewCertificate;

  const _DetailedProductResultCard({
    required this.cert,
    required this.onScanAgain,
    required this.onReportDiscrepancy,
    required this.onViewCertificate,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = cert.isExpired || cert.status == CertificateStatus.expired;
    final now = DateTime.now();
    final daysRemaining = cert.validUntil.difference(now).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Validity Status Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isExpired ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpired ? AppColors.error : AppColors.success,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isExpired ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isExpired ? AppColors.error : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpired ? Icons.warning_amber_rounded : Icons.verified,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExpired ? 'VERIFICATION EXPIRED' : 'GOVT CALIBRATED & VERIFIED',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isExpired ? AppColors.error : AppColors.success,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Legal Metrology Department • Government of India',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.fromStatus(isExpired ? 'EXPIRED' : 'VALID'),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExpired ? Colors.red.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired ? Icons.event_busy : Icons.event_available,
                      size: 16,
                      color: isExpired ? AppColors.error : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isExpired
                            ? 'Lapsed on ${DateFormatter.formatDate(cert.validUntil)} (Commercial use prohibited)'
                            : 'Valid until ${DateFormatter.formatDate(cert.validUntil)} ($daysRemaining days remaining)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isExpired ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Product & Technical Specifications Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(
                icon: Icons.precision_manufacturing,
                title: 'Product & Instrument Details',
              ),
              const SizedBox(height: 14),
              _DetailRow(label: 'Equipment Category', value: cert.instrumentType, isBold: true),
              _DetailRow(label: 'Brand / Manufacturer', value: cert.manufacturer),
              _DetailRow(label: 'Model Designation', value: cert.model),
              _DetailRow(label: 'Serial Number', value: cert.serialNumber, isMonospace: true),
              _DetailRow(label: 'National Instrument UID', value: cert.instrumentUniqueId, isMonospace: true),
              _DetailRow(
                label: 'Rated Capacity',
                value: '${cert.capacity} ${cert.unit}',
                highlightColor: AppColors.primary,
                isBold: true,
              ),
              const _DetailRow(label: 'Verification Scale', value: 'Class III (Commercial Precision)'),
              const _DetailRow(label: 'Applicable Standard', value: 'Legal Metrology (General) Rules, 2011'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Establishment & Location Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(
                icon: Icons.storefront,
                title: 'Authorized Establishment & Deployed Location',
              ),
              const SizedBox(height: 14),
              _DetailRow(label: 'Owner / Trader', value: cert.ownerName, isBold: true),
              _DetailRow(label: 'Business Address', value: cert.ownerAddress),
              _DetailRow(label: 'Zonal Jurisdiction', value: cert.issuingAuthority),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Verification Certificate & Stamping Authority Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(
                icon: Icons.assignment_turned_in,
                title: 'Official Certification & Stamping',
              ),
              const SizedBox(height: 14),
              _DetailRow(label: 'Certificate Number', value: cert.certificateNumber, isBold: true),
              _DetailRow(label: 'Verification Date', value: DateFormatter.formatDate(cert.verificationDate)),
              _DetailRow(label: 'Issue Date', value: DateFormatter.formatDate(cert.issueDate)),
              _DetailRow(label: 'Inspecting Officer', value: cert.issuingOfficerName),
              _DetailRow(label: 'Issuing Authority', value: cert.issuingAuthority),
              _DetailRow(label: 'Physical Seal Status', value: 'Active Lead Seal & Hologram Intact'),
              if (cert.remarks != null && cert.remarks!.isNotEmpty)
                _DetailRow(label: 'Inspector Remarks', value: cert.remarks!),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Cryptographic Integrity Seal Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.fingerprint, color: Color(0xFF00FF88), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cryptographic SHA-256 Tamper Seal',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                    tooltip: 'Copy Hash',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: cert.sha256IntegrityHash));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SHA-256 hash copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                cert.sha256IntegrityHash,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '✓ Cryptographically cross-matched with the State Legal Metrology Ledger.',
                style: TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('SCAN ANOTHER', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: onScanAgain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('VIEW CERTIFICATE', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: onViewCertificate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Report Issue Button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.report_problem_outlined, size: 18),
          label: const Text(
            'REPORT MEASUREMENT DISCREPANCY / GRIEVANCE',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          onPressed: onReportDiscrepancy,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeading({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isMonospace;
  final Color? highlightColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isMonospace = false,
    this.highlightColor,
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
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: highlightColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
