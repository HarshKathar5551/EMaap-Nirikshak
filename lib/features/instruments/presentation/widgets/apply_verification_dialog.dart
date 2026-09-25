import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/instrument_model.dart';
import '../../../../models/application_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../applications/presentation/controllers/applications_controller.dart';
import '../controllers/instruments_controller.dart';

class ApplyVerificationDialog extends ConsumerStatefulWidget {
  final InstrumentModel instrument;

  const ApplyVerificationDialog({super.key, required this.instrument});

  @override
  ConsumerState<ApplyVerificationDialog> createState() => _ApplyVerificationDialogState();
}

class _ApplyVerificationDialogState extends ConsumerState<ApplyVerificationDialog> {
  ApplicationType _selectedType = ApplicationType.newVerification;
  DateTime _preferredDate = DateTime.now().add(const Duration(days: 2));
  final _remarksController = TextEditingController(text: 'Ready for official beat officer inspection.');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    final user = ref.read(authControllerProvider).user;
    final randomDigits = 1000 + Random().nextInt(9000);
    final appId = 'LM-APP-2026-$randomDigits';

    // Automatic Officer Assignment logic
    const officerId = 'usr-officer-01';
    const officerName = 'Inspector Vikram Patil (LMO)';

    final application = ApplicationModel(
      id: 'app-$randomDigits',
      applicationId: appId,
      instrumentId: widget.instrument.id,
      instrumentUniqueId: widget.instrument.instrumentId,
      instrumentType: widget.instrument.type,
      ownerId: user?.id ?? widget.instrument.ownerId,
      ownerName: user?.name ?? widget.instrument.ownerName,
      type: _selectedType,
      status: ApplicationStatus.assigned,
      submittedDate: DateTime.now(),
      scheduledDate: _preferredDate,
      assignedOfficerId: officerId,
      assignedOfficerName: officerName,
      remarks: _remarksController.text.trim(),
    );

    final created = await ref
        .read(applicationsControllerProvider.notifier)
        .submitApplication(application);

    if (created != null) {
      ref.read(instrumentsControllerProvider.notifier).updateInstrumentStatus(
            widget.instrument.id,
            InstrumentStatus.assigned,
          );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context, created);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✓ Verification Application $appId Submitted!'),
              const Text('Assigned to Inspector Vikram Patil (LMO Pune Beat).', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.assignment_turned_in, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Apply for Verification', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.instrument.instrumentId,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                  ),
                  Text(
                    '${widget.instrument.type} • ${widget.instrument.capacity} ${widget.instrument.unit}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    widget.instrument.locationName,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('Verification Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButtonFormField<ApplicationType>(
              initialValue: _selectedType,
              items: ApplicationType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 14),

            const Text('Preferred Inspection Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _preferredDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (d != null) setState(() => _preferredDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${_preferredDate.day}/${_preferredDate.month}/${_preferredDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Spacer(),
                    const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.primaryLight)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Remarks / Access Instructions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _remarksController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'e.g. Shop open between 10 AM to 7 PM.'),
            ),
            const SizedBox(height: 12),

            // Automatic allocation explanation
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Smart Allocation: Nearest Legal Metrology Officer will be automatically assigned to your beat.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Application'),
        ),
      ],
    );
  }
}
