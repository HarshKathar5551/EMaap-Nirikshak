import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.icon,
    this.isSmall = false,
  });

  factory StatusBadge.fromStatus(String status) {
    Color textColor;
    Color bgColor;
    IconData? statusIcon;

    switch (status.toUpperCase()) {
      case 'VERIFIED':
      case 'APPROVED':
      case 'PASSED':
      case 'VALID':
      case 'SYNCED':
        textColor = AppColors.success;
        bgColor = AppColors.successLight;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'PENDING':
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
      case 'ASSIGNED':
      case 'SCHEDULED':
      case 'SYNC_PENDING':
        textColor = AppColors.warning;
        bgColor = AppColors.warningLight;
        statusIcon = Icons.access_time;
        break;
      case 'FAILED':
      case 'REJECTED':
      case 'EXPIRED':
      case 'CONFLICT':
        textColor = AppColors.error;
        bgColor = AppColors.errorLight;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'IN_INSPECTION':
      case 'INSPECTION_COMPLETED':
      case 'INVESTIGATION':
      case 'IN_PROGRESS':
        textColor = AppColors.info;
        bgColor = AppColors.infoLight;
        statusIcon = Icons.sync;
        break;
      case 'HIGH_RISK':
      case 'HIGH':
        textColor = AppColors.riskHigh;
        bgColor = AppColors.riskHighLight;
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        textColor = AppColors.textSecondary;
        bgColor = AppColors.surfaceMuted;
        statusIcon = Icons.info_outline;
    }

    return StatusBadge(
      label: status.replaceAll('_', ' '),
      color: textColor,
      backgroundColor: bgColor,
      icon: statusIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: isSmall ? 11 : 12,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.textPrimary,
      letterSpacing: 0.2,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (color ?? AppColors.border).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isSmall ? 12 : 14,
              color: color ?? AppColors.textPrimary,
            ),
            const SizedBox(width: 4),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}
