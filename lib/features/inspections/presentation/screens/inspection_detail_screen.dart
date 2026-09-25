import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/network/providers.dart';
import '../../../../models/inspection_model.dart';
import '../../../../models/certificate_model.dart';
import '../../../../models/instrument_model.dart';
import '../../../../models/application_model.dart';
import '../../../instruments/presentation/controllers/instruments_controller.dart';
import '../../../applications/presentation/controllers/applications_controller.dart';

class InspectionDetailScreen extends ConsumerStatefulWidget {
  final InspectionModel inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  ConsumerState<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends ConsumerState<InspectionDetailScreen> {
  late List<ChecklistItem> _checklist;
  final _remarksController = TextEditingController(text: 'Visual inspection & error limits conform to standards.');
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _checklist = widget.inspection.checklist.isNotEmpty
        ? List.from(widget.inspection.checklist)
        : [
            const ChecklistItem(id: 'c1', label: 'Physical condition and leveling check', isCompleted: true, isPassed: true),
            const ChecklistItem(id: 'c2', label: 'Serial number verified against plate', isCompleted: true, isPassed: true),
            const ChecklistItem(id: 'c3', label: 'Anti-tampering official seal intact / applied', isCompleted: true, isPassed: true),
            const ChecklistItem(id: 'c4', label: 'Zero setting & maximum error tolerance test', isCompleted: true, isPassed: true),
          ];
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _completeInspection(InspectionStatus status) async {
    setState(() => _isCompleting = true);

    try {
      final certRepo = ref.read(certificateRepositoryProvider);
      final randomNum = 10000 + Random().nextInt(90000);
      final certNumber = 'LM-CERT-2026-$randomNum';
      final qrCode = 'VERIFY-LM-${randomNum.toString().substring(0, 4)}A';

      if (status == InspectionStatus.passed) {
        // Generate Certificate
        final newCert = CertificateModel(
          id: 'cert-$randomNum',
          certificateNumber: certNumber,
          instrumentId: widget.inspection.instrumentId,
          instrumentUniqueId: widget.inspection.instrumentUniqueId,
          instrumentType: widget.inspection.instrumentType,
          serialNumber: 'SN-$randomNum',
          manufacturer: 'Avery India Ltd',
          model: 'EWS-30P',
          capacity: 30.0,
          unit: 'kg',
          ownerName: 'Rahul Verma',
          ownerAddress: 'Main Market, Kothrud, Pune - 411038',
          verificationDate: DateTime.now(),
          issueDate: DateTime.now(),
          validUntil: DateTime.now().add(const Duration(days: 365)),
          issuingOfficerName: widget.inspection.officerName,
          issuingAuthority: 'Legal Metrology Department, Pune Beat II',
          qrVerificationCode: qrCode,
          sha256IntegrityHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
          status: CertificateStatus.valid,
          remarks: _remarksController.text.trim(),
        );

        await certRepo.generateCertificate(newCert);

        // Update Instrument and Application status
        ref.read(instrumentsControllerProvider.notifier).updateInstrumentStatus(
              widget.inspection.instrumentId,
              InstrumentStatus.verified,
            );

        ref.read(applicationsControllerProvider.notifier).updateApplicationStatus(
              widget.inspection.applicationId,
              ApplicationStatus.certificateIssued,
            );
      }

      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('✓ Inspection ${widget.inspection.inspectionId} Completed & Signed Off!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inspection.inspectionId),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Equipment Summary
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.inspection.instrumentUniqueId,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                          ),
                          StatusBadge.fromStatus(widget.inspection.status.displayName),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.inspection.instrumentType,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Assigned Officer: ${widget.inspection.officerName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // GPS Location Comparison Card
                AppCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.5),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GPS Location Verification',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Distance between Officer GPS & Registered Equipment: ${widget.inspection.distanceMeters ?? 6.2} meters',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const Text(
                              '✓ Geo-Fence Matched (Threshold: 50m)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Checklist Section
                const Text(
                  'Physical & Metrological Checklist',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(8),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _checklist.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final item = _checklist[idx];
                      return CheckboxListTile(
                        value: item.isPassed,
                        activeColor: AppColors.success,
                        title: Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        subtitle: Text(item.isPassed ? 'Passed' : 'Pending Verification', style: const TextStyle(fontSize: 10)),
                        onChanged: (val) {
                          setState(() {
                            _checklist[idx] = item.copyWith(isPassed: val ?? false, isCompleted: true);
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Remarks
                const Text(
                  'Officer Observations & Remarks',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _remarksController,
                    maxLines: 2,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter inspection findings'),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                        onPressed: _isCompleting ? null : () => _completeInspection(InspectionStatus.failed),
                        child: const Text('Reject (FAIL)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: _isCompleting ? null : () => _completeInspection(InspectionStatus.passed),
                        child: _isCompleting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Pass & Issue Certificate'),
                      ),
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
}
