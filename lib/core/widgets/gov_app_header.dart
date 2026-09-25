import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class GovAppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const GovAppHeader({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_outlined, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user != null ? '${user.name} • ${user.role.displayName}' : AppConstants.portalSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Offline simulation switch
        IconButton(
          tooltip: authState.isOfflineSimulated
              ? 'Disable Simulated Offline Mode'
              : 'Simulate Offline Mode (Field Test)',
          icon: Icon(
            authState.isOfflineSimulated ? Icons.cloud_off : Icons.cloud_done,
            color: authState.isOfflineSimulated ? AppColors.secondary : Colors.white70,
          ),
          onPressed: () {
            ref.read(authControllerProvider.notifier).toggleSimulateOffline();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  !authState.isOfflineSimulated
                      ? '🔴 OFFLINE SIMULATION ENABLED: Network calls disabled. Working in local database mode.'
                      : '🟢 ONLINE MODE RESTORED: Network connectivity enabled.',
                ),
                backgroundColor: !authState.isOfflineSimulated ? AppColors.offline : AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        if (actions != null) ...actions!,
        if (user != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            tooltip: 'User Profile & Actions',
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.role.displayName,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
