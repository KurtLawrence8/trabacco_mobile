import 'package:flutter/material.dart';

class CoordinatorStatusBadge extends StatelessWidget {
  final String? coordinatorStatus;
  final String? adminStatus;
  final String? overallStatus;
  final bool compact;

  const CoordinatorStatusBadge({
    Key? key,
    this.coordinatorStatus,
    this.adminStatus,
    this.overallStatus,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine status display and color
    String displayText;
    Color statusColor;
    IconData? statusIcon;

    // Priority: Check coordinator status first, then admin, then overall
    if (coordinatorStatus != null && coordinatorStatus!.isNotEmpty) {
      switch (coordinatorStatus!.toLowerCase()) {
        case 'pending':
          displayText = compact ? 'PENDING COORD' : 'Pending Coordinator';
          statusColor = const Color(0xFFF59E0B); // Orange
          statusIcon = Icons.pending_actions;
          break;
        case 'rejected':
          displayText = compact ? 'REJECTED' : 'Rejected by Coordinator';
          statusColor = const Color(0xFFEF4444); // Red
          statusIcon = Icons.cancel;
          break;
        case 'approved':
          // Check admin status if coordinator approved
          if (adminStatus != null && adminStatus!.isNotEmpty) {
            switch (adminStatus!.toLowerCase()) {
              case 'pending':
                displayText = compact ? 'PENDING ADMIN' : 'Pending Admin Review';
                statusColor = const Color(0xFFFBBF24); // Yellow
                statusIcon = Icons.hourglass_empty;
                break;
              case 'approved':
                displayText = compact ? 'APPROVED' : 'Approved';
                statusColor = const Color(0xFF10B981); // Green
                statusIcon = Icons.check_circle;
                break;
              case 'rejected':
                displayText = compact ? 'REJECTED' : 'Rejected by Admin';
                statusColor = const Color(0xFFEF4444); // Red
                statusIcon = Icons.cancel;
                break;
              default:
                displayText = compact ? 'PENDING ADMIN' : 'Pending Admin Review';
                statusColor = const Color(0xFFFBBF24);
                statusIcon = Icons.hourglass_empty;
            }
          } else {
            displayText = compact ? 'PENDING ADMIN' : 'Pending Admin Review';
            statusColor = const Color(0xFFFBBF24);
            statusIcon = Icons.hourglass_empty;
          }
          break;
        default:
          displayText = overallStatus?.toUpperCase() ?? 'PENDING';
          statusColor = const Color(0xFF6B7280);
          statusIcon = Icons.help_outline;
      }
    } else {
      // Fallback to overall status if coordinator status not available
      switch (overallStatus?.toLowerCase() ?? 'pending') {
        case 'pending':
          displayText = compact ? 'PENDING' : 'Pending';
          statusColor = const Color(0xFFF59E0B);
          statusIcon = Icons.pending_actions;
          break;
        case 'approved':
          displayText = compact ? 'APPROVED' : 'Approved';
          statusColor = const Color(0xFF10B981);
          statusIcon = Icons.check_circle;
          break;
        case 'rejected':
          displayText = compact ? 'REJECTED' : 'Rejected';
          statusColor = const Color(0xFFEF4444);
          statusIcon = Icons.cancel;
          break;
        default:
          displayText = overallStatus?.toUpperCase() ?? 'UNKNOWN';
          statusColor = const Color(0xFF6B7280);
          statusIcon = Icons.help_outline;
      }
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusIcon != null) ...[
              Icon(statusIcon, size: 12, color: statusColor),
              const SizedBox(width: 4),
            ],
            Text(
              displayText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusIcon != null) ...[
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 6),
          ],
          Text(
            displayText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper method to get status color (can be used separately)
Color getStatusColor(String? coordinatorStatus, String? adminStatus) {
  if (coordinatorStatus?.toLowerCase() == 'rejected' ||
      adminStatus?.toLowerCase() == 'rejected') {
    return const Color(0xFFEF4444); // Red
  } else if (coordinatorStatus?.toLowerCase() == 'pending') {
    return const Color(0xFFF59E0B); // Orange
  } else if (coordinatorStatus?.toLowerCase() == 'approved' &&
      adminStatus?.toLowerCase() == 'pending') {
    return const Color(0xFFFBBF24); // Yellow
  } else if (coordinatorStatus?.toLowerCase() == 'approved' &&
      adminStatus?.toLowerCase() == 'approved') {
    return const Color(0xFF10B981); // Green
  }
  return const Color(0xFF6B7280); // Gray
}

