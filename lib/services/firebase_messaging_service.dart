import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../main.dart';
import '../screens/notification_screen.dart';
import '../models/user_model.dart';

/// Firebase messaging service for handling push notifications
class FirebaseMessagingService {
  static FirebaseMessagingService? _instance;
  static FirebaseMessagingService get instance =>
      _instance ??= FirebaseMessagingService._();

  FirebaseMessagingService._();

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin get _localNotifications =>
      FlutterLocalNotificationsPlugin();

  // Background message handler (must be top-level function)
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print('🔥 [FCM] Background message received: ${message.messageId}');
    print('🔥 [FCM] Title: ${message.notification?.title}');
    print('🔥 [FCM] Body: ${message.notification?.body}');
    print('🔥 [FCM] Data: ${message.data}');

    // For background messages, Firebase should automatically display the notification
    // if the notification payload is present. We just need to ensure proper handling.
    // The system will show the notification even if this handler doesn't do anything special.

    print('🔥 [FCM] ✅ Background message handler completed');
  }

  /// Initialize Firebase messaging
  static Future<void> initialize() async {
    print('🔥 [FCM] Initializing Firebase messaging...');

    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔥 [FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('🔥 [FCM] ✅ User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('🔥 [FCM] ✅ User granted provisional permission');
      } else {
        print('🔥 [FCM] ❌ User declined or has not accepted permission');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token with error handling
      String? token;
      try {
        token = await _messaging.getToken();
        print('🔥 [FCM] FCM Token: $token');

        if (token != null) {
          await _saveFCMToken(token);
        }
      } catch (tokenError) {
        print(
            '🔥 [FCM] ⚠️ Cannot get FCM token (Google Play Services may be missing): $tokenError');
        print('🔥 [FCM] ℹ️ App will continue with local notifications only');
        return; // Exit early if FCM is not available
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔥 [FCM] Token refreshed: $newToken');
        _saveFCMToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages when app is resumed
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle initial message if app was opened from notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      print('🔥 [FCM] ✅ Firebase messaging initialized successfully');
    } catch (e) {
      print('🔥 [FCM] ❌ Error initializing Firebase messaging: $e');
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    print('📱 [LOCAL] Initializing local notifications...');

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final bool? initialized = await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('📱 [LOCAL] Local notifications initialized: $initialized');

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'schedule_reminders',
      'Schedule Reminders',
      description: 'Notifications for upcoming farmer schedules',
      importance: Importance.high,
    );

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(androidChannel);

    // Request permission for Android 13+ (API level 33+)
    final bool? permissionGranted =
        await androidImplementation?.requestNotificationsPermission();
    print('📱 [LOCAL] Notification permission granted: $permissionGranted');

    print('📱 [LOCAL] ✅ Local notifications setup completed');
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔥 [FCM] Received foreground message: ${message.messageId}');
    print('🔥 [FCM] Title: ${message.notification?.title}');
    print('🔥 [FCM] Body: ${message.notification?.body}');
    print('🔥 [FCM] Data: ${message.data}');

    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'Schedule Reminder',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle message when app is opened from notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔥 [FCM] App opened from message: ${message.messageId}');
    print('🔥 [FCM] Data: ${message.data}');

    // Navigate to notifications screen or handle based on data
    // This will be handled by the main app navigation
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      print('📱 [LOCAL] Attempting to show notification: $title');

      const androidDetails = AndroidNotificationDetails(
        'schedule_reminders',
        'Schedule Reminders',
        channelDescription: 'Notifications for upcoming farmer schedules',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('📱 [LOCAL] Showing notification with ID: $notificationId');

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );

      print('📱 [LOCAL] ✅ Notification shown successfully');
    } catch (e) {
      print('📱 [LOCAL] ❌ Error showing notification: $e');
      rethrow;
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) async {
    print('🔥 [FCM] Notification tapped: ${response.payload}');

    // Navigate to notification screen
    await _navigateToNotificationScreen();
  }

  /// Navigate to notification screen when notification is tapped
  static Future<void> _navigateToNotificationScreen() async {
    try {
      print('🔥 [FCM] Attempting to navigate to notification screen...');

      // Get user data from SharedPreferences using correct keys
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      final userDataString = prefs.getString('user_data'); // Correct key
      final roleType = prefs.getString('user_role_type') ??
          prefs.getString('remembered_role') ??
          'technician'; // Fallback to technician

      print('🔥 [FCM] Debug: authToken exists: ${authToken != null}');
      print('🔥 [FCM] Debug: userDataString exists: ${userDataString != null}');
      print('🔥 [FCM] Debug: roleType: $roleType');

      // Debug: check all available keys in SharedPreferences
      final allKeys = prefs.getKeys();
      print('🔥 [FCM] Debug: Available SharedPreferences keys: $allKeys');

      if (authToken == null || userDataString == null) {
        print('🔥 [FCM] ❌ Missing auth token or user data');
        print('🔥 [FCM] Debug: authToken value: $authToken');
        print('🔥 [FCM] Debug: userDataString value: $userDataString');

        // Try waiting a bit and retry in case the app is still initializing
        await Future.delayed(const Duration(seconds: 2));
        final retryAuthToken = prefs.getString('auth_token');
        final retryUserDataString = prefs.getString('user_data');

        if (retryAuthToken == null || retryUserDataString == null) {
          print(
              '🔥 [FCM] ❌ Still missing auth data after retry - navigation aborted');
          return;
        }
      }

      final finalAuthToken = authToken ?? prefs.getString('auth_token');
      final finalUserDataString =
          userDataString ?? prefs.getString('user_data');
      final finalRoleType = prefs.getString('user_role_type') ??
          prefs.getString('remembered_role') ??
          roleType;

      if (finalAuthToken != null && finalUserDataString != null) {
        final userData = jsonDecode(finalUserDataString);
        final userId = userData['id'];
        final userName = userData['name'] ?? 'Unknown User';
        final userEmail = userData['email'] ?? '';

        print(
            '🔥 [FCM] User type: $finalRoleType, ID: $userId, Name: $userName');

        // Navigate for technicians and coordinators
        if (finalRoleType == 'technician' || finalRoleType == 'area_coordinator') {
          // Create technician object (can be used for both roles)
          final technician = Technician(
            id: userId,
            firstName: userName.split(' ').first,
            lastName: userName.split(' ').length > 1
                ? userName.split(' ').skip(1).join(' ')
                : '',
            emailAddress: userEmail,
            status: 'Active',
          );

          // Navigate to notification screen using global navigator key
          if (navigatorKey.currentContext != null) {
            Navigator.of(navigatorKey.currentContext!).push(
              MaterialPageRoute(
                builder: (context) => NotificationScreen(
                  token: finalAuthToken,
                  technician: technician,
                ),
              ),
            );
            print('🔥 [FCM] ✅ Successfully navigated to notification screen');
          } else {
            print('🔥 [FCM] ❌ Navigator context is null');
          }
        } else {
          print(
              '🔥 [FCM] User role type is $finalRoleType, skipping notification navigation');
        }
      } else {
        print(
            '🔥 [FCM] ❌ Still missing auth token or user data after all attempts');
      }
    } catch (e) {
      print('🔥 [FCM] ❌ Error navigating to notification screen: $e');
    }
  }

  /// Save FCM token to backend
  static Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken != null) {
        // Get user data using correct keys (from auth_service.dart)
        final userDataString = prefs.getString('user_data');
        final userRoleType = prefs.getString('user_role_type');

        if (userDataString != null && userRoleType != null) {
          final userData = jsonDecode(userDataString);
          final userId = userData['id'];

          print(
              '🔥 [FCM] Saving FCM token for user: ID=$userId, Type=$userRoleType');

          // Send token to backend
          await _sendTokenToBackend(token, authToken, userRoleType, userId);
        } else {
          print(
              '🔥 [FCM] ❌ Missing user data or role type: userDataString=${userDataString != null}, userRoleType=$userRoleType');
        }
      } else {
        print('🔥 [FCM] ❌ Missing auth token, cannot save FCM token');
      }

      // Save token locally
      await prefs.setString('fcm_token', token);
    } catch (e) {
      print('🔥 [FCM] Error saving FCM token: $e');
    }
  }

  /// Send FCM token to backend
  static Future<void> _sendTokenToBackend(
    String token,
    String authToken,
    String userType,
    int userId,
  ) async {
    try {
      final url = '${ApiConfig.baseUrl}/fcm-token';
      final requestBody = {
        'fcm_token': token,
        'user_type': userType,
        'user_id': userId,
        'platform': 'mobile',
      };

      print('🔥 [FCM] Sending FCM token to backend:');
      print('🔥 [FCM] URL: $url');
      print('🔥 [FCM] User: $userType (ID: $userId)');
      print('🔥 [FCM] Token preview: ${token.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('🔥 [FCM] Backend response status: ${response.statusCode}');
      print('🔥 [FCM] Backend response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('🔥 [FCM] ✅ Token sent to backend successfully');
      } else {
        print(
            '🔥 [FCM] ❌ Failed to send token to backend: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔥 [FCM] ❌ Error sending token to backend: $e');
    }
  }

  /// Get stored FCM token
  static Future<String?> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('fcm_token');

      if (token != storedToken && token != null) {
        await _saveFCMToken(token);
      }

      return token;
    } catch (e) {
      print(
          '🔥 [FCM] ⚠️ Cannot get FCM token (Google Play Services issue): $e');
      print('🔥 [FCM] ℹ️ Returning cached token if available');

      // Try to get cached token
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('fcm_token');
      } catch (cacheError) {
        print('🔥 [FCM] No cached token available');
        return null;
      }
    }
  }

  /// Subscribe to topic for schedule notifications
  static Future<void> subscribeToScheduleNotifications() async {
    try {
      await _messaging.subscribeToTopic('schedule_reminders');
      print('🔥 [FCM] ✅ Subscribed to schedule_reminders topic');
    } catch (e) {
      print('🔥 [FCM] ❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromScheduleNotifications() async {
    try {
      await _messaging.unsubscribeFromTopic('schedule_reminders');
      print('🔥 [FCM] ✅ Unsubscribed from schedule_reminders topic');
    } catch (e) {
      print('🔥 [FCM] ❌ Error unsubscribing from topic: $e');
    }
  }

  /// Public method to show local notification (for fallback use)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }
}
