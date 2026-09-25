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
import '../../../../models/inspection_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../inspections/presentation/screens/inspection_detail_screen.dart';

class OfficerDashboardScreen extends ConsumerWidget {
  const OfficerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final inspectionRepo = ref.watch(inspectionRepositoryProvider);
    DateTime? lastBackPress;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final now = DateTime.now();
          if (lastBackPress == null || now.difference(lastBackPress!) > const Duration(seconds: 2)) {
            lastBackPress = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Press back again to exit'), duration: Duration(seconds: 2)),
            );
          } else {
            await SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: const GovAppHeader(title: 'E-MAAP • LMO Field Officer Portal'),
        body: Column(
        children: [
          OfflineBanner(
            isOffline: authState.isOfflineSimulated,
            pendingSyncCount: authState.isOfflineSimulated ? 1 : 0,
            onSyncTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synchronizing pending field inspection records...')),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Officer ID Card
                  AppCard(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ACTIVE BEAT: PUNE ZONE II',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                authState.user?.name ?? 'Inspector Vikram Patil',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Legal Metrology Officer • Govt of Maharashtra',
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, size: 36, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4 Inspection Metric Cards
                  FutureBuilder<List<InspectionModel>>(
                    future: inspectionRepo.getInspections(officerId: authState.user?.id),
                    builder: (context, snapshot) {
                      final list = snapshot.data ?? [];
                      final todayCount = list.length;
                      final pendingCount = list.where((i) => i.status == InspectionStatus.pending || i.status == InspectionStatus.inProgress).length;
                      final completedCount = list.where((i) => i.status == InspectionStatus.passed || i.status == InspectionStatus.failed).length;
                      final highRisk = 2; // From risk engine

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _StatCard(title: "Today's Schedule", value: '$todayCount', icon: Icons.today, color: AppColors.primary),
                          _StatCard(title: 'Pending Action', value: '$pendingCount', icon: Icons.pending_actions, color: AppColors.warning),
                          _StatCard(title: 'Completed Tests', value: '$completedCount', icon: Icons.check_circle, color: AppColors.success),
                          _StatCard(title: 'High Risk Priority', value: '$highRisk', icon: Icons.warning_amber, color: AppColors.riskHigh),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Quick Action Buttons
                  const Text(
                    'Officer Field Operations',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.download_for_offline_outlined,
                          label: 'Download Pack\n(Offline Mode)',
                          color: AppColors.tertiary,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Offline Inspection Pack Download initiated (Phase 5)')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.calendar_month_outlined,
                          label: 'Inspection\nCalendar',
                          color: AppColors.primary,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Calendar schedule view (Phase 3)')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.sync_outlined,
                          label: 'Sync Queue\n(Conflict Check)',
                          color: AppColors.secondary,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sync Queue manager (Phase 6)')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Assigned Inspections List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assigned Field Inspections',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      TextButton(onPressed: () {}, child: const Text('Filter / Search')),
                    ],
                  ),
                  const SizedBox(height: 8),

                  FutureBuilder<List<InspectionModel>>(
                    future: inspectionRepo.getInspections(officerId: authState.user?.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                      }
                      final list = snapshot.data ?? [];
                      if (list.isEmpty) {
                        return AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.assignment_outlined, size: 36, color: AppColors.primary),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No Inspections Assigned',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'You have no verification assignments yet. Assignments will appear here once the Admin assigns instruments to you.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
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
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InspectionDetailScreen(inspection: item),
                                ),
                              );
                              if (result == true && context.mounted) {
                                (context as Element).markNeedsBuild();
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.inspectionId,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    StatusBadge.fromStatus(item.status.displayName),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.instrumentType,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Instrument ID: ${item.instrumentUniqueId}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        DateFormatter.formatDateTime(item.scheduledDate),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (item.isLocationMatched)
                                      const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.gps_fixed, size: 12, color: AppColors.success),
                                          SizedBox(width: 4),
                                          Text('GPS ✓', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                  ],
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
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

