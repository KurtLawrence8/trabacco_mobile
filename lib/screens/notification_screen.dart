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
  bool _showAllNotifications = false; // Debug toggle

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    print('🔔 [MOBILE SCREEN] Starting _loadNotifications...');
    setState(() => _isLoading = true);
    try {
      print(
          '🔔 [MOBILE SCREEN] Loading notifications for technician ${widget.technician.id}');
      print(
          '🔔 [MOBILE SCREEN] Technician name: ${widget.technician.firstName} ${widget.technician.lastName}');
      print(
          '🔔 [MOBILE SCREEN] Using token: ${widget.token.substring(0, 20)}...');
      print('🔔 [MOBILE SCREEN] Token length: ${widget.token.length}');

      print('🔔 [MOBILE SCREEN] Calling getNotifications...');
      // Temporarily get all notifications for debugging
      final allNotifications = await notification_service.NotificationService.getAllNotifications(widget.token);
      print('🔔 [MOBILE SCREEN] Total notifications available: ${allNotifications.length}');
      
      // Get notifications based on debug toggle
      // Note: We use technicianId for both technicians and farm workers since the NotificationScreen
      // was originally designed for technicians. The service will handle the filtering properly.
      final notifications = _showAllNotifications 
          ? allNotifications
          : await notification_service.NotificationService.getNotifications(
              widget.token, 
              technicianId: widget.technician.id); // This works for both technicians and farm workers

      print('🔔 [MOBILE SCREEN] Calling getUnreadCount...');
      final unreadCount =
          await notification_service.NotificationService.getUnreadCount(
              widget.token, 
              technicianId: widget.technician.id); // This works for both technicians and farm workers

      print(
          '🔔 [MOBILE SCREEN] SUCCESS: Fetched ${notifications.length} notifications');
      print('🔔 [MOBILE SCREEN] SUCCESS: Unread count: $unreadCount');

      // Log each notification for debugging
      for (int i = 0; i < notifications.length; i++) {
        final notification = notifications[i];
        print(
            '🔔 [MOBILE SCREEN] Notification $i: ID=${notification.id}, Type=${notification.type}, Message=${notification.message}');
      }

      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
        _isLoading = false;
      });

      print('🔔 [MOBILE SCREEN] State updated successfully');
    } catch (e) {
      print('🔔 [MOBILE SCREEN] ERROR: Error loading notifications: $e');
      print('🔔 [MOBILE SCREEN] ERROR: Stack trace: ${StackTrace.current}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(
      notification_service.Notification notification) async {
    if (notification.readAt != null) return; // Already read

    final success = await notification_service.NotificationService.markAsRead(
        notification.id, widget.token);
    if (success) {
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
    // Mark all current filtered notifications as read individually
    final unreadNotifications = _notifications.where((n) => n.readAt == null).toList();
    
    for (final notification in unreadNotifications) {
      await notification_service.NotificationService.markAsRead(notification.id, widget.token);
    }
    
    // Refresh the notifications list
    await _loadNotifications();
  }

  String _getNotificationIcon(String? type) {
    switch (type) {
      case 'request_approved':
        return '✅';
      case 'request_rejected':
        return '❌';
      case 'request_submitted':
        return '📝';
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
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showAllNotifications 
            ? const Text('Notifications (DEBUG)')
            : const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
        actions: [
          // Debug toggle button
          IconButton(
            icon: Icon(_showAllNotifications ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showAllNotifications = !_showAllNotifications;
              });
              _loadNotifications();
            },
            tooltip: _showAllNotifications ? 'Show filtered notifications' : 'Show all notifications (debug)',
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
                        color: isRead ? Colors.grey[50] : const Color(0xFF27AE60).withOpacity(0.1),
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
}
