import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gov_app_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/network/providers.dart';
import '../../../../models/application_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class GatcDashboardScreen extends ConsumerWidget {
  const GatcDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final applicationRepo = ref.watch(applicationRepositoryProvider);

    return Scaffold(
      appBar: const GovAppHeader(title: 'GATC Test Centre Portal'),
      body: Column(
        children: [
          OfflineBanner(isOffline: authState.isOfflineSimulated),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    backgroundColor: AppColors.tertiary,
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
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'GATC ACCREDITATION: NABL/LM-2024-09',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                authState.user?.name ?? 'Dr. Neha Deshmukh',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                authState.user?.department ?? 'Government Approved Test Centre, Pune',
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
                          child: const Icon(Icons.science, size: 36, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metrics
                  FutureBuilder<List<ApplicationModel>>(
                    future: applicationRepo.getApplications(officerId: authState.user?.id),
                    builder: (context, snapshot) {
                      final list = snapshot.data ?? [];
                      final totalAssigned = list.length;
                      final inProgress = list.where((a) => a.status == ApplicationStatus.underReview || a.status == ApplicationStatus.scheduled).length;
                      final completed = list.where((a) => a.status == ApplicationStatus.certificateIssued).length;

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _StatCard(title: 'Assigned Instruments', value: '$totalAssigned', icon: Icons.assignment_outlined, color: AppColors.primary),
                          _StatCard(title: 'Under Testing', value: '$inProgress', icon: Icons.science_outlined, color: AppColors.warning),
                          _StatCard(title: 'Certificates Approved', value: '$completed', icon: Icons.verified_user_outlined, color: AppColors.success),
                          _StatCard(title: 'Standard Weights Calibrated', value: '48', icon: Icons.fitness_center_outlined, color: AppColors.tertiary),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Instruments Assigned for Laboratory Verification',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),

                  FutureBuilder<List<ApplicationModel>>(
                    future: applicationRepo.getApplications(officerId: authState.user?.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                      }
                      final list = snapshot.data ?? [];
                      if (list.isEmpty) {
                        return const AppCard(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No instruments currently assigned to GATC.')),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return AppCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.biotech, color: AppColors.tertiary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.applicationId,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                                      ),
                                      Text(
                                        item.instrumentType,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                      Text(
                                        'Owner: ${item.ownerName} • ID: ${item.instrumentUniqueId}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                ],
              ),
            ),
          ),
        ],
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
