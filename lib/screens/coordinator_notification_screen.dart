import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart' as notification_service;

class CoordinatorNotificationScreen extends StatefulWidget {
  final String token;
  final int coordinatorId;

  const CoordinatorNotificationScreen({
    Key? key,
    required this.token,
    required this.coordinatorId,
  }) : super(key: key);

  @override
  State<CoordinatorNotificationScreen> createState() =>
      _CoordinatorNotificationScreenState();
}

class _CoordinatorNotificationScreenState
    extends State<CoordinatorNotificationScreen> {
  List<notification_service.Notification> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      
      final notifications =
          await notification_service.NotificationService.getNotifications(
        widget.token,
        coordinatorId: widget.coordinatorId,
      );


      final unreadCount =
          await notification_service.NotificationService.getUnreadCount(
        widget.token,
        coordinatorId: widget.coordinatorId,
      );


      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load notifications: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsRead(
      notification_service.Notification notification) async {
    if (notification.readAt != null) return; // Already read

    final success = await notification_service.NotificationService.markAsRead(
        notification.id, widget.token);
    if (success && mounted) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification_service.Notification(
            id: notification.id,
            recipientType: notification.recipientType,
            recipientId: notification.recipientId,
            userId: notification.userId,
            message: notification.message,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            data: notification.data,
            timestamp: notification.timestamp,
            readAt: DateTime.now().toIso8601String(),
            createdAt: notification.createdAt,
            updatedAt: notification.updatedAt,
          );
        }
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (!mounted) return;

    // Mark all current filtered notifications as read individually
    final unreadNotifications =
        _notifications.where((n) => n.readAt == null).toList();

    for (final notification in unreadNotifications) {
      if (!mounted) return;
      await notification_service.NotificationService.markAsRead(
          notification.id, widget.token);
    }

    // Refresh the notifications list
    if (mounted) {
      await _loadNotifications();
    }
  }

  String _getNotificationIcon(String? type) {
    switch (type) {
      case 'request_coordinator_approved':
      case 'request_approved':
        return '✅';
      case 'request_coordinator_rejected':
      case 'request_rejected':
        return '❌';
      case 'request_submitted':
      case 'request_created':
        return '📝';
      case 'report_coordinator_approved':
      case 'report_approved':
        return '✅';
      case 'report_coordinator_rejected':
      case 'report_rejected':
        return '❌';
      case 'report_submitted':
      case 'report_created':
        return '📋';
      case 'planting_report_coordinator_approved':
      case 'planting_report_approved':
        return '✅';
      case 'planting_report_coordinator_rejected':
      case 'planting_report_rejected':
        return '❌';
      case 'planting_report_submitted':
      case 'planting_report_created':
        return '🌱';
      case 'harvest_coordinator_approved':
      case 'harvest_approved':
        return '✅';
      case 'harvest_coordinator_rejected':
      case 'harvest_rejected':
        return '❌';
      case 'harvest_submitted':
      case 'harvest_created':
        return '🌾';
      case 'schedule_reminder':
        return '📅';
      default:
        return '🔔';
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'request_coordinator_approved':
      case 'request_approved':
      case 'report_coordinator_approved':
      case 'report_approved':
      case 'planting_report_coordinator_approved':
      case 'planting_report_approved':
      case 'harvest_coordinator_approved':
      case 'harvest_approved':
        return const Color(0xFF27AE60);
      case 'request_coordinator_rejected':
      case 'request_rejected':
      case 'report_coordinator_rejected':
      case 'report_rejected':
      case 'planting_report_coordinator_rejected':
      case 'planting_report_rejected':
      case 'harvest_coordinator_rejected':
      case 'harvest_rejected':
        return Colors.red;
      case 'request_submitted':
      case 'request_created':
      case 'report_submitted':
      case 'report_created':
      case 'planting_report_submitted':
      case 'planting_report_created':
      case 'harvest_submitted':
      case 'harvest_created':
        return Colors.blue;
      case 'schedule_reminder':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.green,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read, color: Colors.white),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification.readAt != null;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: isRead
                            ? Colors.grey[50]
                            : Colors.blue.withOpacity(0.1),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _getNotificationColor(notification.type),
                            child: Text(
                              _getNotificationIcon(notification.type),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            notification.title ?? notification.message,
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Show notification message/body
                              if (notification.body != null)
                                Text(
                                  notification.body!,
                                  style: TextStyle(
                                    color: isRead
                                        ? Colors.grey[600]
                                        : Colors.grey[800],
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(notification.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          trailing: isRead
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.mark_email_read,
                                      size: 20),
                                  onPressed: () => _markAsRead(notification),
                                  tooltip: 'Mark as read',
                                ),
                          onTap: () => _markAsRead(notification),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadNotifications,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}

