import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/schedule.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/schedule_service.dart';
import 'notification_service.dart' as notification_service;
import 'firebase_messaging_service.dart';

class ScheduleNotificationService {
  static String get _baseUrl => ApiConfig.baseUrl;

  // Timer for scheduled checks
  static Timer? _notificationTimer;

  // Cache to prevent duplicate notifications within a short time period
  static final Set<String> _recentNotifications = <String>{};

  // Flag to prevent multiple simultaneous notification checks
  static bool _isChecking = false;

  // Preferred notification times (24-hour format) - Updated for production
  static const List<int> _notificationHours = [7, 12, 20]; // 7 AM, 12 PM, 8 PM

  // Special debugging time for tonight
  static const List<Map<String, int>> _debugTimes = [
    {'hour': 21, 'minute': 50}, // 9:50 PM tonight for debugging
  ];

  // NOTE: For production, when app is closed, notifications should be sent via backend cron job
  // Backend should call this endpoint: POST /api/send-scheduled-notifications
  // This will ensure notifications work even when app is not running

  /// Check for today's schedules and incomplete activities, create notifications for technicians
  static Future<void> checkAndCreateScheduleNotifications(
    String token,
    int technicianId,
  ) async {
    // Prevent multiple simultaneous checks
    if (_isChecking) {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] Check already in progress, skipping...');
      return;
    }

    _isChecking = true;
    try {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] Starting comprehensive schedule notification check for technician $technicianId');

      // Get all farm workers assigned to this technician
      final farmWorkerService = FarmWorkerService();
      final farmWorkers =
          await farmWorkerService.getAssignedFarmWorkers(token, technicianId);

      print(
          '📅 [SCHEDULE NOTIFICATIONS] Found ${farmWorkers.length} farm workers for technician $technicianId');

      if (farmWorkers.isEmpty) {
        print(
            '📅 [SCHEDULE NOTIFICATIONS] ⚠️ No farm workers found for technician $technicianId - skipping notification check');
        return;
      }

      // Get today's date for checking schedules
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Collect all notifications to send together
      List<Map<String, dynamic>> todayNotifications = [];
      List<Map<String, dynamic>> incompleteNotifications = [];

      // Check schedules for each farm worker
      for (final farmWorker in farmWorkers) {
        // Check today's schedules
        final todayScheduleNotifs = await _checkTodaysSchedules(
          token,
          technicianId,
          farmWorker,
          today,
        );
        todayNotifications.addAll(todayScheduleNotifs);

        // Check incomplete activities from previous days (check last 7 days to avoid too many notifications)
        for (int daysBack = 1; daysBack <= 7; daysBack++) {
          final checkDate = today.subtract(Duration(days: daysBack));
          final incompleteNotifs = await _checkIncompleteActivities(
            token,
            technicianId,
            farmWorker,
            checkDate,
          );
          incompleteNotifications.addAll(incompleteNotifs);
        }
      }

      // Send combined notifications
      print(
          '📅 [SCHEDULE NOTIFICATIONS] Summary: ${todayNotifications.length} today\'s notifications, ${incompleteNotifications.length} incomplete notifications');

      if (todayNotifications.isNotEmpty || incompleteNotifications.isNotEmpty) {
        print('📅 [SCHEDULE NOTIFICATIONS] 🚀 Sending notifications...');
        await _sendCombinedNotifications(
          token,
          technicianId,
          todayNotifications,
          incompleteNotifications,
        );
      } else {
        print(
            '📅 [SCHEDULE NOTIFICATIONS] ❌ No notifications needed - no incomplete schedules found');
      }

      print(
          '📅 [SCHEDULE NOTIFICATIONS] Completed comprehensive schedule notification check');
    } catch (e) {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] ERROR: Failed to check schedule notifications: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Check today's schedules for a specific farm worker
  static Future<List<Map<String, dynamic>>> _checkTodaysSchedules(
    String token,
    int technicianId,
    FarmWorker farmWorker,
    DateTime today,
  ) async {
    List<Map<String, dynamic>> notifications = [];

    try {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] Checking today\'s schedules for farmer ${farmWorker.firstName} ${farmWorker.lastName} (ID: ${farmWorker.id})');

      // Get schedules for this farm worker
      final scheduleService = ScheduleService();
      final schedules = await scheduleService.fetchSchedulesForFarmWorker(
          farmWorker.id, token);

      print(
          '📅 [SCHEDULE NOTIFICATIONS] Found ${schedules.length} schedules for farmer ${farmWorker.id}');

      // Check for today's schedules only
      for (final schedule in schedules) {
        if (schedule.date != null) {
          final scheduleDate = DateTime(
              schedule.date!.year, schedule.date!.month, schedule.date!.day);
          final daysFromNow = scheduleDate.difference(today).inDays;

          print(
              '📅 [SCHEDULE NOTIFICATIONS] Schedule ${schedule.id}: ${schedule.activity} on ${schedule.date} (days: $daysFromNow, status: ${schedule.status})');

          // Only check for today's schedule and not completed
          if (daysFromNow == 0 &&
              schedule.status.toLowerCase() != 'completed' &&
              schedule.status.toLowerCase() != 'cancelled') {
            print(
                '📅 [SCHEDULE NOTIFICATIONS] ✅ Found today\'s schedule: ${schedule.activity}');
            final notificationData = await _buildScheduleNotificationData(
              token,
              technicianId,
              farmWorker,
              schedule,
              0, // daysFromNow for today's schedule
            );

            if (notificationData != null) {
              notifications.add(notificationData);
            }
          }
        }
      }
    } catch (e) {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] ERROR: Failed to check today\'s schedules for farmer ${farmWorker.id}: $e');
    }

    return notifications;
  }

  /// Check incomplete activities from a specific date
  static Future<List<Map<String, dynamic>>> _checkIncompleteActivities(
    String token,
    int technicianId,
    FarmWorker farmWorker,
    DateTime checkDate,
  ) async {
    List<Map<String, dynamic>> notifications = [];

    try {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] Checking incomplete activities for ${farmWorker.firstName} ${farmWorker.lastName} on ${checkDate.year}-${checkDate.month}-${checkDate.day}');

      // Get schedules for this farm worker
      final scheduleService = ScheduleService();
      final schedules = await scheduleService.fetchSchedulesForFarmWorker(
          farmWorker.id, token);

      // Check for incomplete activities on the specified date
      for (final schedule in schedules) {
        if (schedule.date != null) {
          final scheduleDate = DateTime(
              schedule.date!.year, schedule.date!.month, schedule.date!.day);

          // Check if this schedule is for the check date and is incomplete
          if (scheduleDate.year == checkDate.year &&
              scheduleDate.month == checkDate.month &&
              scheduleDate.day == checkDate.day) {
            print(
                '📅 [SCHEDULE NOTIFICATIONS] Found schedule for ${checkDate.year}-${checkDate.month}-${checkDate.day}: ${schedule.activity} (status: ${schedule.status})');

            if (schedule.status.toLowerCase() != 'completed' &&
                schedule.status.toLowerCase() != 'cancelled') {
              print(
                  '📅 [SCHEDULE NOTIFICATIONS] ✅ Found incomplete activity: ${schedule.activity}');

              final notificationData =
                  await _buildIncompleteActivityNotificationData(
                token,
                technicianId,
                farmWorker,
                schedule,
                checkDate,
              );

              if (notificationData != null) {
                notifications.add(notificationData);
              }
            } else {
              print(
                  '📅 [SCHEDULE NOTIFICATIONS] ⏭️ Skipping completed/cancelled activity: ${schedule.activity}');
            }
          }
        }
      }
    } catch (e) {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] ERROR: Failed to check incomplete activities for farmer ${farmWorker.id}: $e');
    }

    return notifications;
  }

  /// Build notification data for today's schedule
  static Future<Map<String, dynamic>?> _buildScheduleNotificationData(
    String token,
    int technicianId,
    FarmWorker farmWorker,
    Schedule schedule,
    int daysFromNow,
  ) async {
    try {
      // Check if notification already exists for this schedule
      final existingNotifications =
          await notification_service.NotificationService.getNotifications(
        token,
        technicianId: technicianId,
      );

      // Check if we already have a notification for this schedule today
      final today = DateTime.now();
      final todayString =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // Create unique key for this notification to prevent duplicates
      final notificationKey = "${schedule.id}_${technicianId}_$todayString";

      // Check cache first (prevents rapid duplicate notifications)
      bool isCached = _recentNotifications.contains(notificationKey);

      // Check database for existing notifications
      bool notificationExists = existingNotifications.any((notification) {
        if (notification.data != null) {
          final data = notification.data as Map<String, dynamic>;
          return data['schedule_id'] == schedule.id &&
              notification.timestamp.startsWith(todayString);
        }
        return false;
      });

      if (!notificationExists && !isCached) {
        // Format the schedule date
        String formattedDate = schedule.date != null
            ? "${schedule.date!.month}/${schedule.date!.day}/${schedule.date!.year}"
            : "Unknown date";

        // Add to cache to prevent duplicates
        _recentNotifications.add(notificationKey);
        _cleanupNotificationCache();

        return {
          'title': "📅 Schedule Today",
          'message':
              "Today: ${schedule.activity} for ${farmWorker.firstName} ${farmWorker.lastName} on $formattedDate",
          'data': {
            'schedule_id': schedule.id,
            'farm_worker_id': farmWorker.id,
            'farm_worker_name':
                '${farmWorker.firstName} ${farmWorker.lastName}',
            'activity': schedule.activity,
            'schedule_date': formattedDate,
            'days_from_now': daysFromNow,
            'type': 'schedule_reminder',
          },
          'notification_key': notificationKey,
        };
      }

      return null;
    } catch (e) {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] ERROR: Failed to build schedule notification data: $e');
      return null;
    }
  }

  /// Build notification data for incomplete activity
  static Future<Map<String, dynamic>?> _buildIncompleteActivityNotificationData(
    String token,
    int technicianId,
    FarmWorker farmWorker,
    Schedule schedule,
    DateTime incompleteDate,
  ) async {
    try {
      // Check if notification already exists for this incomplete activity
      final existingNotifications =
          await notification_service.NotificationService.getNotifications(
        token,
        technicianId: technicianId,
      );

      final today = DateTime.now();
      final todayString =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // Create unique key for this incomplete activity notification
      final notificationKey =
          "incomplete_${schedule.id}_${technicianId}_$todayString";

      // Check cache first (prevents rapid duplicate notifications)
      bool isCached = _recentNotifications.contains(notificationKey);

      // Check database for existing notifications
      bool notificationExists = existingNotifications.any((notification) {
        if (notification.data != null) {
          final data = notification.data as Map<String, dynamic>;
          return data['schedule_id'] == schedule.id &&
              data['type'] == 'incomplete_activity_reminder' &&
              notification.timestamp.startsWith(todayString);
        }
        return false;
      });

      if (!notificationExists && !isCached) {
        // Format the incomplete activity date
        String formattedDate =
            "${incompleteDate.month}/${incompleteDate.day}/${incompleteDate.year}";

        // Add to cache to prevent duplicates
        _recentNotifications.add(notificationKey);
        _cleanupNotificationCache();

        return {
          'title': "⚠️ Incomplete Activity",
          'message':
              "Incomplete activity ${schedule.activity} for ${farmWorker.firstName} ${farmWorker.lastName} on $formattedDate",
          'data': {
            'schedule_id': schedule.id,
            'farm_worker_id': farmWorker.id,
            'farm_worker_name':
                '${farmWorker.firstName} ${farmWorker.lastName}',
            'activity': schedule.activity,
            'schedule_date': formattedDate,
            'incomplete_date': formattedDate,
            'type': 'incomplete_activity_reminder',
          },
          'notification_key': notificationKey,
        };
      }

      return null;
    } catch (e) {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] ERROR: Failed to build incomplete activity notification data: $e');
      return null;
    }
  }

  /// Send combined notifications for today's schedules and incomplete activities
  static Future<void> _sendCombinedNotifications(
    String token,
    int technicianId,
    List<Map<String, dynamic>> todayNotifications,
    List<Map<String, dynamic>> incompleteNotifications,
  ) async {
    try {
      // If we have both types, combine them
      if (todayNotifications.isNotEmpty && incompleteNotifications.isNotEmpty) {
        final combinedTitle = "📅 Daily Schedule Reminders";
        final combinedMessage =
            _buildCombinedMessage(todayNotifications, incompleteNotifications);

        // Combine all data
        final combinedData = {
          'type': 'combined_schedule_reminder',
          'today_schedules': todayNotifications.map((n) => n['data']).toList(),
          'incomplete_activities':
              incompleteNotifications.map((n) => n['data']).toList(),
          'total_today': todayNotifications.length,
          'total_incomplete': incompleteNotifications.length,
        };

        // Send combined notification
        await _sendScheduleNotification(
          token,
          technicianId,
          combinedTitle,
          combinedMessage,
          combinedData,
        );

        print(
            '📅 [SCHEDULE NOTIFICATIONS] ✅ Sent combined notification: ${todayNotifications.length} today\'s schedules + ${incompleteNotifications.length} incomplete activities');
      }
      // Send today's notifications only
      else if (todayNotifications.isNotEmpty) {
        for (final notification in todayNotifications) {
          await _sendScheduleNotification(
            token,
            technicianId,
            notification['title'],
            notification['message'],
            notification['data'],
          );
        }
        print(
            '📅 [SCHEDULE NOTIFICATIONS] ✅ Sent ${todayNotifications.length} today\'s schedule notifications');
      }
      // Send incomplete activity notifications only
      else if (incompleteNotifications.isNotEmpty) {
        for (final notification in incompleteNotifications) {
          await _sendScheduleNotification(
            token,
            technicianId,
            notification['title'],
            notification['message'],
            notification['data'],
          );
        }
        print(
            '📅 [SCHEDULE NOTIFICATIONS] ✅ Sent ${incompleteNotifications.length} incomplete activity notifications');
      }
    } catch (e) {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] ERROR: Failed to send combined notifications: $e');
    }
  }

  /// Build combined message for notifications
  static String _buildCombinedMessage(
    List<Map<String, dynamic>> todayNotifications,
    List<Map<String, dynamic>> incompleteNotifications,
  ) {
    final buffer = StringBuffer();

    if (todayNotifications.isNotEmpty) {
      buffer.writeln("📅 Today's Activities:");
      for (final notification in todayNotifications) {
        final data = notification['data'] as Map<String, dynamic>;
        buffer.writeln("• ${data['activity']} - ${data['farm_worker_name']}");
      }
    }

    if (incompleteNotifications.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln("⚠️ Incomplete Activities:");
      for (final notification in incompleteNotifications) {
        final data = notification['data'] as Map<String, dynamic>;
        buffer.writeln(
            "• ${data['activity']} - ${data['farm_worker_name']} (${data['incomplete_date']})");
      }
    }

    return buffer.toString().trim();
  }

  /// Send schedule notification to backend and trigger Firebase push notification
  static Future<void> _sendScheduleNotification(
    String token,
    int technicianId,
    String title,
    String message,
    Map<String, dynamic> data,
  ) async {
    try {
      // Send notification to backend for storage
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'recipient_type': 'technician',
          'recipient_id': technicianId,
          'title': title,
          'message': message,
          'type': 'schedule_reminder',
          'data': data,
        }),
      );

      // Always show local notification regardless of backend response
      await _sendLocalNotificationFallback(title, message, data);
      print('📱 [LOCAL] ✅ Immediate local notification shown');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print(
            '📅 [SCHEDULE NOTIFICATIONS] Successfully sent notification to backend');

        // Now send Firebase push notification
        await _sendFirebasePushNotification(
          title: title,
          body: message,
          data: data,
          technicianId: technicianId,
          token: token,
        );
      } else {
        print(
            '📅 [SCHEDULE NOTIFICATIONS] Failed to send notification to backend. Status: ${response.statusCode}, Body: ${response.body}');
        print(
            '📱 [LOCAL] ✅ Local notification still shown despite backend error');
      }
    } catch (e) {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] ERROR: Failed to send notification to backend: $e');

      // Still try to show local notification even if backend fails
      try {
        await _sendLocalNotificationFallback(title, message, data);
        print('📱 [LOCAL] ✅ Emergency local notification shown after error');
      } catch (localError) {
        print(
            '📱 [LOCAL] ❌ Failed to show emergency notification: $localError');
      }
    }
  }

  /// Send Firebase push notification for schedule reminder
  static Future<void> _sendFirebasePushNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required int technicianId,
    required String token,
  }) async {
    try {
      print('🔥 [FCM] Sending push notification for schedule reminder...');

      // Send push notification via backend API
      final response = await http.post(
        Uri.parse('$_baseUrl/send-push-notification'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'recipient_type': 'technician',
          'recipient_id': technicianId,
          'title': title,
          'body': body,
          'data': {
            ...data,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'sound': 'default',
          },
          'notification_type': 'schedule_reminder',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('🔥 [FCM] ✅ Push notification sent successfully');
      } else {
        print(
            '🔥 [FCM] ❌ Failed to send push notification: ${response.statusCode}');
        print('🔥 [FCM] Response: ${response.body}');

        // Fallback: try sending locally if backend fails
        await _sendLocalNotificationFallback(title, body, data);
      }
    } catch (e) {
      print('🔥 [FCM] ❌ Error sending push notification: $e');

      // Fallback: try sending locally if backend fails
      await _sendLocalNotificationFallback(title, body, data);
    }
  }

  /// Fallback method to show local notification if push notification fails
  static Future<void> _sendLocalNotificationFallback(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // Use the FirebaseMessagingService local notification method
      await FirebaseMessagingService.showLocalNotification(
        title: title,
        body: body,
        payload: jsonEncode(data),
      );
      print('📱 [LOCAL] ✅ Fallback local notification shown successfully');
    } catch (e) {
      print('📱 [LOCAL] ❌ Error showing fallback notification: $e');
    }
  }

  /// Schedule a background check (this would be called periodically)
  static Future<void> scheduledCheck(
    String token,
    int technicianId,
  ) async {
    try {
      // print(
      //     '📅 [SCHEDULE NOTIFICATIONS] Running scheduled check for technician $technicianId');
      await checkAndCreateScheduleNotifications(token, technicianId);
    } catch (e) {
      // print('📅 [SCHEDULE NOTIFICATIONS] ERROR: Scheduled check failed: $e');
    }
  }

  /// Get upcoming schedule notifications for display
  static Future<List<notification_service.Notification>>
      getUpcomingScheduleNotifications(
    String token,
    int technicianId,
  ) async {
    try {
      final allNotifications =
          await notification_service.NotificationService.getNotifications(
        token,
        technicianId: technicianId,
      );

      // Filter for schedule-related notifications
      return allNotifications.where((notification) {
        if (notification.data != null &&
            notification.data is Map<String, dynamic>) {
          final data = notification.data as Map<String, dynamic>;
          return data['type'] == 'schedule_reminder';
        }
        return false;
      }).toList();
    } catch (e) {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] ERROR: Failed to get upcoming schedule notifications: $e');
      return [];
    }
  }

  /// Start scheduled notification checking at specific times
  static void startScheduledNotifications(String token, int technicianId) {
    print(
        '📅 [SCHEDULE NOTIFICATIONS] Starting scheduled notifications for technician $technicianId');

    // Cancel existing timer if any
    _notificationTimer?.cancel();

    // Check immediately first
    checkAndCreateScheduleNotifications(token, technicianId);

    // Schedule next check based on preferred times
    _scheduleNextNotificationCheck(token, technicianId);
  }

  /// Stop scheduled notifications
  static void stopScheduledNotifications() {
    // print('📅 [SCHEDULE NOTIFICATIONS] Stopping scheduled notifications');
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  /// Schedule the next notification check based on preferred times
  static void _scheduleNextNotificationCheck(String token, int technicianId) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    // Check debug times first (for debugging)
    DateTime? nextNotificationTime;

    for (var debugTime in _debugTimes) {
      final debugHour = debugTime['hour']!;
      final debugMinute = debugTime['minute']!;

      DateTime debugTimeToday =
          DateTime(now.year, now.month, now.day, debugHour, debugMinute);

      // If debug time is in the future today, use it
      if (debugTimeToday.isAfter(now)) {
        nextNotificationTime = debugTimeToday;
        break;
      }
    }

    // If no debug time found or debug time passed, use regular hours
    if (nextNotificationTime == null) {
      // Find next notification hour
      int? nextNotificationHour;
      for (int hour in _notificationHours) {
        if (hour > currentHour || (hour == currentHour && currentMinute < 30)) {
          nextNotificationHour = hour;
          break;
        }
      }

      // If no hour found today, use first hour tomorrow
      if (nextNotificationHour == null) {
        nextNotificationHour = _notificationHours.first;
      }

      // Calculate time until next notification
      if (nextNotificationHour > currentHour ||
          (nextNotificationHour == currentHour && currentMinute < 30)) {
        // Today
        nextNotificationTime =
            DateTime(now.year, now.month, now.day, nextNotificationHour, 0);
      } else {
        // Tomorrow
        nextNotificationTime =
            DateTime(now.year, now.month, now.day + 1, nextNotificationHour, 0);
      }
    }

    // At this point, nextNotificationTime should never be null due to fallback logic
    final notificationTime =
        nextNotificationTime ?? DateTime.now().add(Duration(hours: 1));
    final timeUntilNext = notificationTime.difference(now);

    print(
        '📅 [SCHEDULE NOTIFICATIONS] Next notification check scheduled in ${timeUntilNext.inHours}h ${timeUntilNext.inMinutes % 60}m');
    print(
        '📅 [SCHEDULE NOTIFICATIONS] Next check at: ${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}');

    _notificationTimer = Timer(timeUntilNext, () {
      print(
          '📅 [SCHEDULE NOTIFICATIONS] Running scheduled notification check at ${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}');
      checkAndCreateScheduleNotifications(token, technicianId);

      // Schedule next check
      _scheduleNextNotificationCheck(token, technicianId);
    });
  }

  /// Get notification schedule info for display
  static String getNotificationScheduleInfo() {
    // Add debug times to the display
    final debugTimesStr = _debugTimes.map((time) {
      final hour = time['hour']!;
      final minute = time['minute']!;
      if (hour < 12) {
        return '${hour}:${minute.toString().padLeft(2, '0')} AM';
      } else if (hour == 12) {
        return '12:${minute.toString().padLeft(2, '0')} PM';
      } else {
        return '${hour - 12}:${minute.toString().padLeft(2, '0')} PM';
      }
    }).join(', ');

    final times = _notificationHours.map((hour) {
      if (hour < 12) {
        return '${hour}:00 AM';
      } else if (hour == 12) {
        return '12:00 PM';
      } else {
        return '${hour - 12}:00 PM';
      }
    }).join(', ');

    return 'Notifications sent at: $debugTimesStr, $times';
  }

  /// Clean up old entries from notification cache to prevent memory leaks
  static void _cleanupNotificationCache() {
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Remove entries that don't match today's date (older than today)
    _recentNotifications.removeWhere((key) {
      return !key.contains(today);
    });
  }
}
