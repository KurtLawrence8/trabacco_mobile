import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../config/api_config.dart';
import 'offline_storage_service.dart';

/// Offline-First Service - Wraps existing services with offline capabilities
class OfflineFirstService {
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  /// Create report with offline support
  Future<Map<String, dynamic>> createReport(
    Map<String, dynamic> reportData,
    String token, {
    List<File>? images,
    List<Uint8List>? imageBytes,
  }) async {
    try {
      // Check if online
      if (await _offlineStorage.isOnline()) {
        // Try to create report online
        try {
          return await _createReportOnline(reportData, token,
              images: images, imageBytes: imageBytes);
        } catch (e) {
          print('Online report creation failed, saving offline: $e');
          // Fall back to offline storage
          await _offlineStorage.saveReportOffline(reportData);
          return {
            'success': true,
            'offline': true,
            'message':
                'Report saved offline. Will sync when internet is available.',
            'offline_id': reportData['_offline_id'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
          };
        }
      } else {
        // Save offline
        await _offlineStorage.saveReportOffline(reportData);
        return {
          'success': true,
          'offline': true,
          'message':
              'Report saved offline. Will sync when internet is available.',
          'offline_id': reportData['_offline_id'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
        };
      }
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  /// Create request with offline support
  Future<void> createRequest(
      String token, Map<String, dynamic> requestData) async {
    try {
      // Check if online
      if (await _offlineStorage.isOnline()) {
        // Try to create request online
        try {
          await _createRequestOnline(token, requestData);
          return;
        } catch (e) {
          print('Online request creation failed, saving offline: $e');
          // Fall back to offline storage
          await _offlineStorage.saveRequestOffline(requestData);
          return;
        }
      } else {
        // Save offline
        await _offlineStorage.saveRequestOffline(requestData);
      }
    } catch (e) {
      throw Exception('Failed to create request: $e');
    }
  }

  /// Update profile with offline support
  Future<Map<String, dynamic>> updateProfile(
    String userType,
    int userId,
    Map<String, dynamic> updateData,
    String token,
  ) async {
    try {
      // Check if online
      if (await _offlineStorage.isOnline()) {
        // Try to update profile online
        try {
          return await _updateProfileOnline(
              userType, userId, updateData, token);
        } catch (e) {
          print('Online profile update failed, saving offline: $e');
          // Fall back to offline storage
          await _offlineStorage.saveProfileUpdateOffline(
              userType, userId, updateData);
          return {
            'success': true,
            'offline': true,
            'message':
                'Profile update saved offline. Will sync when internet is available.',
            'offline_id': DateTime.now().millisecondsSinceEpoch.toString(),
          };
        }
      } else {
        // Save offline
        await _offlineStorage.saveProfileUpdateOffline(
            userType, userId, updateData);
        return {
          'success': true,
          'offline': true,
          'message':
              'Profile update saved offline. Will sync when internet is available.',
          'offline_id': DateTime.now().millisecondsSinceEpoch.toString(),
        };
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Update schedule status with offline support
  Future<void> updateScheduleStatus(
      int scheduleId, String status, String token) async {
    try {
      // Check if online
      if (await _offlineStorage.isOnline()) {
        // Try to update schedule online
        try {
          await _updateScheduleStatusOnline(scheduleId, status, token);
          return;
        } catch (e) {
          print('Online schedule update failed, saving offline: $e');
          // Fall back to offline storage
          await _offlineStorage.saveScheduleUpdateOffline(scheduleId, status);
          return;
        }
      } else {
        // Save offline
        await _offlineStorage.saveScheduleUpdateOffline(scheduleId, status);
      }
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  /// Sync all pending data
  Future<Map<String, int>> syncAllPendingData(String token) async {
    return await _offlineStorage.syncAllPendingData(token);
  }

  /// Get pending items count
  Future<int> getPendingItemsCount() async {
    return await _offlineStorage.getTotalPendingItems();
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    return await _offlineStorage.isOnline();
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    return await _offlineStorage.getLastSyncTimestamp();
  }

  // Private methods for online operations

  Future<Map<String, dynamic>> _createReportOnline(
    Map<String, dynamic> reportData,
    String token, {
    List<File>? images,
    List<Uint8List>? imageBytes,
  }) async {
    print('Sending report to: ${ApiConfig.baseUrl}/reports');
    print('Headers: ${ApiConfig.getHeaders(token: token)}');
    print('Report data: $reportData');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/reports'),
    );

    // Add headers
    request.headers.addAll(ApiConfig.getHeaders(token: token));
    request.headers.remove('Content-Type'); // Let multipart set this

    // Add form fields
    reportData.forEach((key, value) {
      if (value != null) {
        // Handle arrays (like farm_worker_ids, laborer_ids)
        if (value is List) {
          for (int i = 0; i < value.length; i++) {
            request.fields['${key}[$i]'] = value[i].toString();
          }
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    // Add images
    if (kIsWeb && imageBytes != null && imageBytes.isNotEmpty) {
      // For web, use image bytes
      for (int i = 0; i < imageBytes.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images[$i]',
            imageBytes[i],
            filename: 'image_$i.jpg',
          ),
        );
      }
    } else if (images != null && images.isNotEmpty) {
      // For mobile, use file paths
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        if (await image.exists()) {
          final fileName = path.basename(image.path);
          request.files.add(
            await http.MultipartFile.fromPath(
              'images[$i]',
              image.path,
              filename: fileName,
            ),
          );
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      final errorMessage = errorBody['message'] ??
          'Failed to create report (${response.statusCode})';
      print('Error response: $errorMessage');
      throw Exception(errorMessage);
    }
  }

  Future<void> _createRequestOnline(
      String token, Map<String, dynamic> requestData) async {
    final url = ApiConfig.getUrl('/requests');

    print('[OfflineFirstService] _createRequestOnline called');
    print('[OfflineFirstService] Token: ${token.substring(0, 10)}...');
    print('[OfflineFirstService] Request data received: $requestData');

    // Check if data is already in new format (has 'request_type' field)
    Map<String, dynamic> payload;
    if (requestData.containsKey('request_type')) {
      // New format from request_screen.dart - use as is
      payload = requestData;
      print('[OfflineFirstService] Using new format payload');
    } else {
      // Old format - transform it
      final now = DateTime.now().toIso8601String();
      payload = {
        'technician_id': requestData['technician_id'],
        'farm_worker_id': requestData['farm_worker_id'],
        'request_type':
            requestData['type'] == 'cash_advance' ? 'Cash Advance' : 'Supply',
        'description': requestData['reason'],
        'status': 'Pending',
        'timestamp': now,
        if (requestData['amount'] != null) 'amount': requestData['amount'],
        if (requestData['supply_id'] != null)
          'supply_id': requestData['supply_id'],
        if (requestData['quantity'] != null)
          'quantity': requestData['quantity'],
      };
      print('[OfflineFirstService] Using old format payload (transformed)');
    }

    print('[OfflineFirstService] Final payload being sent: $payload');
    print(
        '[OfflineFirstService] Headers: ${ApiConfig.getHeaders(token: token)}');

    final response = await http.post(Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode(payload));

    print('[OfflineFirstService] Response status: ${response.statusCode}');
    print('[OfflineFirstService] Response body: ${response.body}');

    if (response.statusCode == 201) {
      // Request created successfully
      print('[OfflineFirstService] Request created successfully!');
      return;
    } else if (response.statusCode == 409) {
      // Daily limit exceeded
      final errorData = json.decode(response.body);
      final errorMsg =
          errorData['message'] ?? 'Daily limit exceeded for this request type';
      print('[OfflineFirstService] Error 409: $errorMsg');
      throw Exception(errorMsg);
    } else if (response.statusCode == 422) {
      // Validation error
      final errorData = json.decode(response.body);
      final errorMsg =
          errorData['message'] ?? errorData['error'] ?? 'Invalid request data';
      print('[OfflineFirstService] Error 422: $errorMsg');
      print('[OfflineFirstService] Error details: $errorData');
      throw Exception(errorMsg);
    } else {
      // Other errors
      final errorMsg =
          json.decode(response.body)['message'] ?? 'Failed to create request';
      print('[OfflineFirstService] Error ${response.statusCode}: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  Future<Map<String, dynamic>> _updateProfileOnline(
    String userType,
    int userId,
    Map<String, dynamic> updateData,
    String token,
  ) async {
    String endpoint;
    if (userType == 'Technician') {
      endpoint = '/technicians/$userId';
    } else {
      endpoint = '/farm-workers/$userId';
    }

    // Clean and validate the update data
    final cleanedData = <String, dynamic>{};
    updateData.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        cleanedData[key] = value;
      }
    });

    print('Update data (cleaned): $cleanedData');

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: ApiConfig.getHeaders(token: token),
      body: json.encode(cleanedData),
    );

    print('Update response status: ${response.statusCode}');
    print('Update response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 422) {
      // Validation error
      final errorData = json.decode(response.body);
      throw Exception(
          'Validation error: ${errorData['message'] ?? 'Invalid data'}');
    } else if (response.statusCode == 404) {
      throw Exception('User not found (404)');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized (401) - Check token');
    } else {
      throw Exception(
          'Failed to update profile: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> _updateScheduleStatusOnline(
      int scheduleId, String status, String token) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/schedules/$scheduleId'),
      headers: ApiConfig.getHeaders(token: token),
      body: json.encode({'status': status}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Failed to update schedule. Code: ${response.statusCode}. Body: ${response.body}');
    }
  }
}
