import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class Notification {
  final int id;
  final String recipientType;
  final int recipientId;
  final int? userId;
  final String message;
  final String? title;
  final String? body;
  final String? type;
  final Map<String, dynamic>? data;
  final String timestamp;
  final String? readAt;
  final String createdAt;
  final String updatedAt;

  Notification({
    required this.id,
    required this.recipientType,
    required this.recipientId,
    this.userId,
    required this.message,
    this.title,
    this.body,
    this.type,
    this.data,
    required this.timestamp,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Safe JSON decode helper
  static Map<String, dynamic>? _safeJsonDecode(dynamic data) {
    try {
      if (data is String) {
        return jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (e) {
      print('🔔 [MOBILE] Error decoding JSON data: $e');
    }
    return null;
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      recipientType: json['recipient_type'],
      recipientId: json['recipient_id'],
      userId: json['user_id'],
      message: json['message'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      data: json['data'] != null ? _safeJsonDecode(json['data']) : null,
      timestamp: json['timestamp'],
      readAt: json['read_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class NotificationService {
  static String get _baseUrl => ApiConfig.baseUrl;

  // Helper method to safely extract data from notification
  static Map<String, dynamic>? _parseNotificationData(
      Notification notification) {
    try {
      if (notification.data != null &&
          notification.data is Map<String, dynamic>) {
        return notification.data as Map<String, dynamic>;
      }
    } catch (e) {
      print('🔔 [MOBILE] Error parsing notification data: $e');
    }
    return null;
  }

  // Helper method to safely convert value to int
  static int? _safeToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return int.tryParse(value.toString());
  }

  // Get additional notification details from data field
  static Map<String, String?> getNotificationDetails(
      Notification notification) {
    final data = _parseNotificationData(notification);
    return {
      'request_id': data?['request_id']?.toString(),
      'technician_name': data?['technician_name']?.toString(),
      'farm_worker_name': data?['farm_worker_name']?.toString(),
      'request_type': data?['request_type']?.toString(),
      'timestamp': data?['timestamp']?.toString(),
    };
  }

  // Get notifications for the authenticated user (technician, farm worker, or coordinator)
  static Future<List<Notification>> getNotifications(String token,
      {int? technicianId, int? farmWorkerId, int? coordinatorId}) async {
    try {
      final url = '$_baseUrl/notifications';
      // print('🔔 [MOBILE] NotificationService: Starting notification fetch...');
      // print('🔔 [MOBILE] URL: $url');
      // print('🔔 [MOBILE] Token length: ${token.length}');
      // print('🔔 [MOBILE] Token preview: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // print('🔔 [MOBILE] Response status: ${response.statusCode}');
      // print('🔔 [MOBILE] Response headers: ${response.headers}');
      // print('🔔 [MOBILE] Response body length: ${response.body.length}');
      // print('🔔 [MOBILE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        List<Notification> notifications =
            jsonList.map((json) => Notification.fromJson(json)).toList();

        print(
            '🔔 [MOBILE] Total notifications: ${notifications.length}, Filtering for Coordinator ID: $coordinatorId');

        // Debug: Show only area_coordinator notifications
        // for (var notification in notifications) {
        //   if (notification.recipientType.toLowerCase() == 'area_coordinator' ||
        //       notification.recipientType.toLowerCase() == 'areacoordinator') {
        //     print(
        //         '🔔 [MOBILE] AC Notification: ID=${notification.id}, Type=${notification.type}, RecipientId=${notification.recipientId}');
        //   }
        // }

        // Filter notifications for the specific user if ID is provided
        if (technicianId != null ||
            farmWorkerId != null ||
            coordinatorId != null) {
          List<Notification> filteredNotifications = [];

          for (var notification in notifications) {
            // Parse data field to extract additional IDs
            final notificationData = _parseNotificationData(notification);
            int? dataFarmWorkerId =
                _safeToInt(notificationData?['farm_worker_id']);
            int? dataTechnicianId =
                _safeToInt(notificationData?['technician_id']);
            int? dataCoordinatorId =
                _safeToInt(notificationData?['coordinator_id']);

            bool shouldInclude = false;
            final currentUserId = technicianId ?? farmWorkerId ?? coordinatorId;

            // Check if it's for this specific coordinator
            if (notification.recipientType.toLowerCase() ==
                    'area_coordinator' ||
                notification.recipientType.toLowerCase() == 'areacoordinator') {
              if (coordinatorId != null &&
                  notification.recipientId == coordinatorId) {
                shouldInclude = true;
              }
            }
            // Check if it's for this specific technician
            else if (notification.recipientType.toLowerCase() == 'technician' &&
                technicianId != null &&
                notification.recipientId == technicianId) {
              shouldInclude = true;
            }
            // Check if it's for this specific farm worker
            else if (notification.recipientType.toLowerCase() ==
                    'farm_worker' &&
                farmWorkerId != null &&
                notification.recipientId == farmWorkerId) {
              shouldInclude = true;
            }
            // Check if it's a broadcast notification
            else if (notification.recipientType.toLowerCase() == 'all') {
              shouldInclude = true;
            }
            // Check if it's related to this user's actions (userId matches current user)
            else if (notification.userId == currentUserId) {
              shouldInclude = true;
            }
            // Check if the data field contains this coordinator's ID
            else if (coordinatorId != null &&
                dataCoordinatorId == coordinatorId) {
              shouldInclude = true;
            }
            // Check if the data field contains this farm worker's ID
            else if (farmWorkerId != null && dataFarmWorkerId == farmWorkerId) {
              shouldInclude = true;
            }
            // Check if the data field contains this technician's ID
            else if (technicianId != null && dataTechnicianId == technicianId) {
              shouldInclude = true;
            }

            if (shouldInclude) {
              filteredNotifications.add(notification);
            }
          }

          notifications = filteredNotifications;
          print(
              '🔔 [MOBILE] ✅ Filtered to ${notifications.length} notifications for coordinator: $coordinatorId');
        }

        // Sort notifications: schedule_reminder notifications first, then by timestamp (newest first)
        notifications.sort((a, b) {
          // Prioritize schedule_reminder notifications
          bool aIsSchedule = a.type == 'schedule_reminder';
          bool bIsSchedule = b.type == 'schedule_reminder';

          if (aIsSchedule && !bIsSchedule) return -1; // a comes first
          if (!aIsSchedule && bIsSchedule) return 1; // b comes first

          // If both are same type, sort by timestamp (newest first)
          try {
            final aTimestamp = DateTime.parse(a.timestamp);
            final bTimestamp = DateTime.parse(b.timestamp);
            return bTimestamp.compareTo(aTimestamp);
          } catch (e) {
            // If parsing fails, maintain original order
            return 0;
          }
        });

        return notifications;
      } else if (response.statusCode == 401) {
        // print(
        //     '🔔 [MOBILE] ERROR: Unauthorized - Token may be invalid or expired');
        // print('🔔 [MOBILE] ERROR: Response body: ${response.body}');
        return [];
      } else if (response.statusCode == 403) {
        // print('🔔 [MOBILE] ERROR: Forbidden - Access denied');
        // print('🔔 [MOBILE] ERROR: Response body: ${response.body}');
        return [];
      } else {
        // print(
        //     '🔔 [MOBILE] ERROR: Failed to fetch notifications with status ${response.statusCode}');
        // print('🔔 [MOBILE] ERROR: Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      // print('🔔 [MOBILE] EXCEPTION: Error fetching notifications: $e');
      // print('🔔 [MOBILE] EXCEPTION: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount(String token,
      {int? technicianId, int? farmWorkerId, int? coordinatorId}) async {
    try {
      // Get all notifications and filter them, then count unread ones
      final notifications = await getNotifications(token,
          technicianId: technicianId,
          farmWorkerId: farmWorkerId,
          coordinatorId: coordinatorId);
      final unreadCount = notifications.where((n) => n.readAt == null).length;

      print(
          '🔔 [MOBILE] Unread count for user (technician: $technicianId, farmWorker: $farmWorkerId, coordinator: $coordinatorId): $unreadCount');
      return unreadCount;
    } catch (e) {
      print('🔔 [MOBILE] EXCEPTION: Error fetching unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  static Future<bool> markAsRead(int notificationId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/$notificationId/mark-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  static Future<bool> markAllAsRead(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Get all notifications without filtering (for debugging)
  static Future<List<Notification>> getAllNotifications(String token) async {
    return getNotifications(
        token); // Call without technicianId to skip filtering
  }

  // Get only schedule notifications for the authenticated user
  static Future<List<Notification>> getScheduleNotifications(String token,
      {int? technicianId, int? farmWorkerId, int? coordinatorId}) async {
    try {
      // Get all notifications first
      final allNotifications = await getNotifications(token,
          technicianId: technicianId,
          farmWorkerId: farmWorkerId,
          coordinatorId: coordinatorId);

      // Filter to only schedule_reminder notifications
      return allNotifications
          .where((notification) => notification.type == 'schedule_reminder')
          .toList();
    } catch (e) {
      print('🔔 [MOBILE] Error fetching schedule notifications: $e');
      return [];
    }
  }

  // Test API connection
  static Future<Map<String, dynamic>> testConnection(String token) async {
    try {
      print('🔔 [MOBILE] Testing API connection...');
      print('🔔 [MOBILE] Base URL: $_baseUrl');
      print('🔔 [MOBILE] Token length: ${token.length}');

      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🔔 [MOBILE] Test response status: ${response.statusCode}');
      print('🔔 [MOBILE] Test response body: ${response.body}');

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'body': response.body,
        'url': '$_baseUrl/notifications',
      };
    } catch (e) {
      print('🔔 [MOBILE] Test connection error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'url': '$_baseUrl/notifications',
      };
    }
  }
}
