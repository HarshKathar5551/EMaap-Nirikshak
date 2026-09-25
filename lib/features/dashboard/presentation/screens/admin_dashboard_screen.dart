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
import '../../../auth/presentation/controllers/auth_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final instrumentRepo = ref.watch(instrumentRepositoryProvider);
    final applicationRepo = ref.watch(applicationRepositoryProvider);
    final complaintRepo = ref.watch(complaintRepositoryProvider);
    final systemRepo = ref.watch(systemRepositoryProvider);

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
                          icon: Icons.person_add_alt_outlined,
                          label: 'Officer\nAssignment',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Officer Assignment workflow (Phase 12)')),
                            );
                          },
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
                      TextButton(onPressed: () {}, child: const Text('Manage All')),
                    ],
                  ),
                  const SizedBox(height: 8),

                  FutureBuilder<List<ApplicationModel>>(
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


