# Firebase Push Notifications Setup Guide

## Overview
I've implemented Firebase Cloud Messaging (FCM) push notifications for the Trabacco mobile app. Now when farmers have upcoming schedules, technicians will receive push notifications directly on their mobile devices, not just in-app notifications.

## What Was Implemented

### 1. Dependencies Added
- `firebase_core: ^2.24.2`
- `firebase_messaging: ^14.7.10`
- `flutter_local_notifications: ^16.3.2`

### 2. Firebase Services Created

#### `lib/services/firebase_messaging_service.dart`
- Handles FCM token generation and management
- Subscribes to notification topics
- Processes foreground and background messages
- Shows local notifications for background messages

#### Updated `lib/services/schedule_notification_service.dart`
- Now sends both backend notifications AND Firebase push notifications
- Calls backend API endpoint `/send-push-notification` to trigger FCM
- Fallback to local notifications if push notification fails

### 3. Android Configuration Updated

#### `android/app/build.gradle.kts`
- Added Google Services plugin: `id("com.google.gms.google-services")`

#### `android/settings.gradle.kts`
- Added Google Services plugin dependency

#### `android/app/src/main/AndroidManifest.xml`
- Added Firebase permissions:
  - `WAKE_LOCK`
  - `VIBRATE`
  - `RECEIVE_BOOT_COMPLETED`
- Added Firebase Cloud Messaging service

#### `lib/main.dart`
- Initialize Firebase with proper configuration
- Set background message handler
- Initialize Firebase messaging service

#### `lib/screens/technician_landing_screen.dart`
- Subscribes to schedule reminder notifications when technician logs in

## Setup Required (Important!)

### 1. Firebase Project Setup
You need to create a Firebase project and configure it properly:

1. **Go to [Firebase Console](https://console.firebase.google.com/)**
2. **Create a new project** or use existing one
3. **Add Android app** with package name: `com.example.trabacco_mobile`
4. **Download `google-services.json`** and place it in `android/app/`
5. **Generate Firebase configuration** by running:
   ```bash
   cd trabacco_mobile
   flutter packages pub run build_runner build
   ```

### 2. Update Firebase Configuration
Update `lib/firebase_options.dart` with your actual Firebase project details:
- Replace `your-project-id` with your actual Firebase project ID
- Replace API keys with your actual keys from Firebase Console

### 3. Backend API Endpoint
You need to implement the `/send-push-notification` endpoint in your Laravel backend:

```php
Route::post('/send-push-notification', [NotificationController::class, 'sendPushNotification']);
```

The endpoint should:
- Accept the notification data (title, body, recipient info)
- Send FCM notification using Laravel FCM package or direct API calls
- Use stored FCM tokens from users

### 4. FCM Token Storage
Update your backend to store and manage FCM tokens when users log in. You'll need:
- A database table to store FCM tokens per user
- API endpoint to save/update FCM tokens: `/fcm-token`

## How It Works Now

### 1. When Technician Logs In
- App initializes Firebase messaging
- Subscribes to 'schedule_reminders' topic
- Sends FCM token to backend for storage

### 2. When Schedule Notification is Created
1. **Backend Notification**: Creates record in notifications table
2. **Firebase Push**: Calls `/send-push-notification` API endpoint
3. **Backend sends FCM**: Uses stored token to send push notification
4. **Device receives**: Shows notification even when app is closed

### 3. Notification Display
- **Foreground**: Shows local notification
- **Background**: Handled by Firebase background handler
- **Click**: Opens app and navigates to notifications

## Testing

1. **Install dependencies**:
   ```bash
   cd trabacco_mobile
   flutter pub get
   ```

2. **Run the app** and check logs for Firebase initialization:
   ```
   [main] ✅ Firebase initialized
   🔥 [FCM] Firebase messaging initialized successfully
   ```

3. **Check FCM token**: Look for logs like:
   ```
   🔥 [FCM] FCM Token: [token]
   🔥 [FCM] ✅ Token sent to backend successfully
   ```

## Next Steps

1. **Set up Firebase project** (as described above)
2. **Configure backend** to handle FCM token storage and push notification sending
3. **Test notifications** by creating schedule reminders
4. **Deploy and test** on physical devices

## Troubleshooting

### If Firebase doesn't initialize:
- Check `firebase_options.dart` has correct configuration
- Ensure `google-services.json` is in `android/app/`
- Verify package name matches in Firebase Console

### If push notifications don't work:
- Check backend `/send-push-notification` endpoint exists
- Verify FCM tokens are being stored properly
- Check Android device notification permissions

The implementation is complete on the mobile side - you just need to set up Firebase project and backend integration!
