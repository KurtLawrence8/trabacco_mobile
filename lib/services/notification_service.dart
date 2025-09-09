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
      data: json['data'] != null ? jsonDecode(json['data']) : null,
      timestamp: json['timestamp'],
      readAt: json['read_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class NotificationService {
  static String get _baseUrl => ApiConfig.baseUrl;

  // Get notifications for the authenticated technician
  static Future<List<Notification>> getNotifications(String token) async {
    try {
      final url = '$_baseUrl/notifications';
      print('🔔 [MOBILE] NotificationService: Starting notification fetch...');
      print('🔔 [MOBILE] URL: $url');
      print('🔔 [MOBILE] Token length: ${token.length}');
      print('🔔 [MOBILE] Token preview: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔔 [MOBILE] Response status: ${response.statusCode}');
      print('🔔 [MOBILE] Response headers: ${response.headers}');
      print('🔔 [MOBILE] Response body length: ${response.body.length}');
      print('🔔 [MOBILE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print(
            '🔔 [MOBILE] Successfully parsed ${jsonList.length} notifications');

        // Log each notification details
        for (int i = 0; i < jsonList.length; i++) {
          final notification = jsonList[i];
          print(
              '🔔 [MOBILE] Notification $i: ID=${notification['id']}, Type=${notification['type']}, Message=${notification['message']}');
        }

        return jsonList.map((json) => Notification.fromJson(json)).toList();
      } else {
        print(
            '🔔 [MOBILE] ERROR: Failed to fetch notifications with status ${response.statusCode}');
        print('🔔 [MOBILE] ERROR: Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('🔔 [MOBILE] EXCEPTION: Error fetching notifications: $e');
      print('🔔 [MOBILE] EXCEPTION: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount(String token) async {
    try {
      final url = '$_baseUrl/notifications/unread/count';
      print('🔔 [MOBILE] Getting unread count from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔔 [MOBILE] Unread count response status: ${response.statusCode}');
      print('🔔 [MOBILE] Unread count response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final count = json['count'] ?? 0;
        print('🔔 [MOBILE] Unread count: $count');
        return count;
      } else {
        print(
            '🔔 [MOBILE] ERROR: Failed to fetch unread count: ${response.statusCode}');
        print('🔔 [MOBILE] ERROR: Response body: ${response.body}');
        return 0;
      }
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
}
