import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onSyncTap;
  final int pendingSyncCount;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.onSyncTap,
    this.pendingSyncCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && pendingSyncCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isOffline ? AppColors.offline : AppColors.warning,
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            Icon(
              isOffline ? Icons.cloud_off : Icons.sync_problem,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOffline
                    ? '🔴 OFFLINE FIELD MODE — Working from local database'
                    : '🟡 $pendingSyncCount items queued for synchronization',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onSyncTap != null && !isOffline && pendingSyncCount > 0)
              GestureDetector(
                onTap: onSyncTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SYNC NOW',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
