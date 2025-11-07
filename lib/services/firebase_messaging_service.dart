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

    // Show local notification even when app is in background/terminated
    if (message.notification != null) {
      await _showBackgroundLocalNotification(
        title: message.notification!.title ?? 'Trabacco Notification',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }

  }

  /// Show local notification for background messages
  static Future<void> _showBackgroundLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {

      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();

      // Initialize if not already initialized
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await localNotifications.initialize(initSettings);

      const androidDetails = AndroidNotificationDetails(
        'trabacco_notifications',
        'Trabacco Notifications',
        channelDescription: 'All notifications from Trabacco system',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        showWhen: true,
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
      await localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );

    } catch (e) {
    }
  }

  /// Initialize Firebase messaging
  static Future<void> initialize() async {

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


      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
      } else {
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token with error handling
      String? token;
      try {
        token = await _messaging.getToken();
        
        if (token != null) {
          await _saveFCMToken(token);
        } else {
        }
      } catch (tokenError) {
                return; // Exit early if FCM is not available
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
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

    } catch (e) {
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {

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


    // Create notification channels for Android
    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Channel for schedule reminders
    const scheduleChannel = AndroidNotificationChannel(
      'schedule_reminders',
      'Schedule Reminders',
      description: 'Notifications for upcoming farmer schedules',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Channel for all Trabacco notifications (reports, requests, etc.)
    const trabaccoChannel = AndroidNotificationChannel(
      'trabacco_notifications',
      'Trabacco Notifications',
      description: 'All notifications from Trabacco system',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidImplementation?.createNotificationChannel(scheduleChannel);
    await androidImplementation?.createNotificationChannel(trabaccoChannel);

    // Request permission for Android 13+ (API level 33+)
    final bool? permissionGranted =
        await androidImplementation?.requestNotificationsPermission();

  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {

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

      const androidDetails = AndroidNotificationDetails(
        'trabacco_notifications',
        'Trabacco Notifications',
        channelDescription: 'All notifications from Trabacco system',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        showWhen: true,
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

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );

    } catch (e) {
      rethrow;
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) async {

    // Navigate to notification screen
    await _navigateToNotificationScreen();
  }

  /// Navigate to notification screen when notification is tapped
  static Future<void> _navigateToNotificationScreen() async {
    try {

      // Get user data from SharedPreferences using correct keys
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      final userDataString = prefs.getString('user_data'); // Correct key
      final roleType = prefs.getString('user_role_type') ??
          prefs.getString('remembered_role') ??
          'technician'; // Fallback to technician


      // Debug: check all available keys in SharedPreferences
      final allKeys = prefs.getKeys();

      if (authToken == null || userDataString == null) {

        // Try waiting a bit and retry in case the app is still initializing
        await Future.delayed(const Duration(seconds: 2));
        final retryAuthToken = prefs.getString('auth_token');
        final retryUserDataString = prefs.getString('user_data');

        if (retryAuthToken == null || retryUserDataString == null) {
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
          } else {
          }
        } else {
                  }
      } else {
              }
    } catch (e) {
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

          
          // Send token to backend
          await _sendTokenToBackend(token, authToken, userRoleType, userId);
        } else {
                  }
      } else {
      }

      // Save token locally
      await prefs.setString('fcm_token', token);
    } catch (e) {
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


      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
      } else {
              }
    } catch (e) {
    }
  }

  /// Get stored FCM token (checks if changed before saving)
  static Future<String?> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('fcm_token');

      if (token != storedToken && token != null) {
        await _saveFCMToken(token);
      } else if (token == null) {
      } else {
      }

      return token;
    } catch (e) {
      
      // Try to get cached token
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedToken = prefs.getString('fcm_token');
        return cachedToken;
      } catch (cacheError) {
        return null;
      }
    }
  }

  /// Force save FCM token to backend (used after login to update user association)
  static Future<void> forceSaveFCMToken() async {
    try {
      final token = await _messaging.getToken();
      
      if (token != null) {
        await _saveFCMToken(token);
      } else {
      }
    } catch (e) {
    }
  }

  /// Subscribe to topic for schedule notifications
  static Future<void> subscribeToScheduleNotifications() async {
    try {
      await _messaging.subscribeToTopic('schedule_reminders');
    } catch (e) {
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromScheduleNotifications() async {
    try {
      await _messaging.unsubscribeFromTopic('schedule_reminders');
    } catch (e) {
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

