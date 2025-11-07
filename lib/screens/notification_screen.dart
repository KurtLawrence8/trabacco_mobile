import 'package:flutter/material.dart';
import '../services/notification_service.dart' as notification_service;
import '../models/user_model.dart';

class NotificationScreen extends StatefulWidget {
  final String token;
  final Technician technician;

  const NotificationScreen({
    Key? key,
    required this.token,
    required this.technician,
  }) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<notification_service.Notification> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  bool _showAllNotifications =
      false; // Toggle between schedule only and all notifications

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      // Get notifications based on toggle - schedule only by default, all if toggled
      final notifications = _showAllNotifications
          ? await notification_service.NotificationService.getNotifications(
              widget.token,
              technicianId: widget.technician.id)
          : await notification_service.NotificationService
              .getScheduleNotifications(widget.token,
                  technicianId: widget.technician.id);

      // Get unread count based on current filter
      final unreadCount = _showAllNotifications
          ? await notification_service.NotificationService.getUnreadCount(
              widget.token,
              technicianId: widget.technician.id)
          : notifications.where((n) => n.readAt == null).length;

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
      case 'request_approved':
        return '✅';
      case 'request_rejected':
        return '❌';
      case 'request_submitted':
        return '📝';
      case 'schedule_reminder':
        return '📅';
      default:
        return '🔔';
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'request_approved':
        return const Color(0xFF27AE60);
      case 'request_rejected':
        return Colors.red;
      case 'request_submitted':
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
      appBar: AppBar(
        title: _showAllNotifications
            ? const Text('All Notifications')
            : const Text('Schedule Notifications'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        actions: [
          // Debug toggle button
          IconButton(
            icon: Icon(_showAllNotifications
                ? Icons.filter_list_off
                : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showAllNotifications = !_showAllNotifications;
              });
              _loadNotifications();
            },
            tooltip: _showAllNotifications
                ? 'Show schedule notifications only'
                : 'Show all notifications',
          ),
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      backgroundColor: Colors.white,
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
                            : const Color(0xFF27AE60).withOpacity(0.1),
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
                              // Show additional details for schedule notifications
                              if (notification.type == 'schedule_reminder' &&
                                  notification.data != null)
                                _buildScheduleNotificationDetails(
                                    notification, isRead),
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
        backgroundColor: const Color(0xFF27AE60),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
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

  Widget _buildScheduleNotificationDetails(
      notification_service.Notification notification, bool isRead) {
    try {
      if (notification.data == null) return const SizedBox.shrink();

      final data = notification.data as Map<String, dynamic>;
      final farmWorkerName =
          data['farm_worker_name']?.toString() ?? 'Unknown Farmer';
      final activity = data['activity']?.toString() ?? 'Unknown Activity';
      final scheduleDate = data['schedule_date']?.toString() ?? 'Unknown Date';

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: isRead ? Colors.grey[600] : Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Farmer: $farmWorkerName',
                    style: TextStyle(
                      fontSize: 12,
                      color: isRead ? Colors.grey[600] : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: isRead ? Colors.grey[600] : Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Activity: $activity',
                    style: TextStyle(
                      fontSize: 12,
                      color: isRead ? Colors.grey[600] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isRead ? Colors.grey[600] : Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Date: $scheduleDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: isRead ? Colors.grey[600] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
