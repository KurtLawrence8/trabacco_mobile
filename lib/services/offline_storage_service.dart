import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Offline Storage Service - Handles local storage and sync when online
class OfflineStorageService {
  static const String _pendingReportsKey = 'pending_reports';
  static const String _pendingRequestsKey = 'pending_requests';
  static const String _pendingProfileUpdatesKey = 'pending_profile_updates';
  static const String _pendingScheduleUpdatesKey = 'pending_schedule_updates';
  static const String _lastSyncKey = 'last_sync_timestamp';
  
  final Connectivity _connectivity = Connectivity();

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Test actual internet connection
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/test'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode < 500;
    } catch (e) {
      return false;
    }
  }

  /// Save report data locally for offline storage
  Future<void> saveReportOffline(Map<String, dynamic> reportData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingReports = await getPendingReports();
      
      // Add timestamp and offline flag
      reportData['_offline_id'] = DateTime.now().millisecondsSinceEpoch.toString();
      reportData['_created_at'] = DateTime.now().toIso8601String();
      reportData['_is_offline'] = true;
      
      existingReports.add(reportData);
      await prefs.setString(_pendingReportsKey, json.encode(existingReports));
      
      print('Report saved offline: ${reportData['_offline_id']}');
    } catch (e) {
      print('Error saving report offline: $e');
      throw Exception('Failed to save report offline');
    }
  }

  /// Save request data locally for offline storage
  Future<void> saveRequestOffline(Map<String, dynamic> requestData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRequests = await getPendingRequests();
      
      // Add timestamp and offline flag
      requestData['_offline_id'] = DateTime.now().millisecondsSinceEpoch.toString();
      requestData['_created_at'] = DateTime.now().toIso8601String();
      requestData['_is_offline'] = true;
      
      existingRequests.add(requestData);
      await prefs.setString(_pendingRequestsKey, json.encode(existingRequests));
      
      print('Request saved offline: ${requestData['_offline_id']}');
    } catch (e) {
      print('Error saving request offline: $e');
      throw Exception('Failed to save request offline');
    }
  }

  /// Save profile update data locally for offline storage
  Future<void> saveProfileUpdateOffline(String userType, int userId, Map<String, dynamic> updateData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingUpdates = await getPendingProfileUpdates();
      
      // Add metadata
      final profileUpdate = {
        'user_type': userType,
        'user_id': userId,
        'update_data': updateData,
        '_offline_id': DateTime.now().millisecondsSinceEpoch.toString(),
        '_created_at': DateTime.now().toIso8601String(),
        '_is_offline': true,
      };
      
      existingUpdates.add(profileUpdate);
      await prefs.setString(_pendingProfileUpdatesKey, json.encode(existingUpdates));
      
      print('Profile update saved offline: ${profileUpdate['_offline_id']}');
    } catch (e) {
      print('Error saving profile update offline: $e');
      throw Exception('Failed to save profile update offline');
    }
  }

  /// Save schedule update data locally for offline storage
  Future<void> saveScheduleUpdateOffline(int scheduleId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingUpdates = await getPendingScheduleUpdates();
      
      // Add metadata
      final scheduleUpdate = {
        'schedule_id': scheduleId,
        'status': status,
        '_offline_id': DateTime.now().millisecondsSinceEpoch.toString(),
        '_created_at': DateTime.now().toIso8601String(),
        '_is_offline': true,
      };
      
      existingUpdates.add(scheduleUpdate);
      await prefs.setString(_pendingScheduleUpdatesKey, json.encode(existingUpdates));
      
      print('Schedule update saved offline: ${scheduleUpdate['_offline_id']}');
    } catch (e) {
      print('Error saving schedule update offline: $e');
      throw Exception('Failed to save schedule update offline');
    }
  }

  /// Get all pending reports
  Future<List<Map<String, dynamic>>> getPendingReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getString(_pendingReportsKey);
      if (reportsJson != null) {
        final List<dynamic> reports = json.decode(reportsJson);
        return reports.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting pending reports: $e');
      return [];
    }
  }

  /// Get all pending requests
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getString(_pendingRequestsKey);
      if (requestsJson != null) {
        final List<dynamic> requests = json.decode(requestsJson);
        return requests.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  /// Get all pending profile updates
  Future<List<Map<String, dynamic>>> getPendingProfileUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatesJson = prefs.getString(_pendingProfileUpdatesKey);
      if (updatesJson != null) {
        final List<dynamic> updates = json.decode(updatesJson);
        return updates.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting pending profile updates: $e');
      return [];
    }
  }

  /// Get all pending schedule updates
  Future<List<Map<String, dynamic>>> getPendingScheduleUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatesJson = prefs.getString(_pendingScheduleUpdatesKey);
      if (updatesJson != null) {
        final List<dynamic> updates = json.decode(updatesJson);
        return updates.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting pending schedule updates: $e');
      return [];
    }
  }

  /// Sync all pending data when online
  Future<Map<String, int>> syncAllPendingData(String token) async {
    final results = {
      'reports_synced': 0,
      'requests_synced': 0,
      'profile_updates_synced': 0,
      'schedule_updates_synced': 0,
      'errors': 0,
    };

    if (!await isOnline()) {
      print('No internet connection - skipping sync');
      return results;
    }

    try {
      // Sync reports
      results['reports_synced'] = await _syncReports(token);
      
      // Sync requests
      results['requests_synced'] = await _syncRequests(token);
      
      // Sync profile updates
      results['profile_updates_synced'] = await _syncProfileUpdates(token);
      
      // Sync schedule updates
      results['schedule_updates_synced'] = await _syncScheduleUpdates(token);
      
      // Update last sync timestamp
      await _updateLastSyncTimestamp();
      
      print('Sync completed: $results');
    } catch (e) {
      print('Error during sync: $e');
      results['errors'] = (results['errors'] ?? 0) + 1;
    }

    return results;
  }

  /// Sync pending reports
  Future<int> _syncReports(String token) async {
    int syncedCount = 0;
    final pendingReports = await getPendingReports();
    
    for (final report in pendingReports) {
      try {
        // Remove offline metadata before sending
        final cleanReport = Map<String, dynamic>.from(report);
        cleanReport.remove('_offline_id');
        cleanReport.remove('_created_at');
        cleanReport.remove('_is_offline');
        
        // Send to server
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/reports'),
          headers: ApiConfig.getHeaders(token: token),
          body: json.encode(cleanReport),
        );
        
        if (response.statusCode == 201) {
          syncedCount++;
          print('Report synced: ${report['_offline_id']}');
        } else {
          print('Failed to sync report: ${response.statusCode}');
        }
      } catch (e) {
        print('Error syncing report ${report['_offline_id']}: $e');
      }
    }
    
    // Remove synced reports
    if (syncedCount > 0) {
      await _removeSyncedReports(syncedCount);
    }
    
    return syncedCount;
  }

  /// Sync pending requests
  Future<int> _syncRequests(String token) async {
    int syncedCount = 0;
    final pendingRequests = await getPendingRequests();
    
    for (final request in pendingRequests) {
      try {
        // Remove offline metadata before sending
        final cleanRequest = Map<String, dynamic>.from(request);
        cleanRequest.remove('_offline_id');
        cleanRequest.remove('_created_at');
        cleanRequest.remove('_is_offline');
        
        // Send to server
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/requests'),
          headers: ApiConfig.getHeaders(token: token),
          body: json.encode(cleanRequest),
        );
        
        if (response.statusCode == 201) {
          syncedCount++;
          print('Request synced: ${request['_offline_id']}');
        } else {
          print('Failed to sync request: ${response.statusCode}');
        }
      } catch (e) {
        print('Error syncing request ${request['_offline_id']}: $e');
      }
    }
    
    // Remove synced requests
    if (syncedCount > 0) {
      await _removeSyncedRequests(syncedCount);
    }
    
    return syncedCount;
  }

  /// Sync pending profile updates
  Future<int> _syncProfileUpdates(String token) async {
    int syncedCount = 0;
    final pendingUpdates = await getPendingProfileUpdates();
    
    for (final update in pendingUpdates) {
      try {
        final userType = update['user_type'];
        final userId = update['user_id'];
        final updateData = update['update_data'];
        
        String endpoint;
        if (userType == 'Technician') {
          endpoint = '/technicians/$userId';
        } else {
          endpoint = '/farm-workers/$userId';
        }
        
        // Send to server
        final response = await http.patch(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: ApiConfig.getHeaders(token: token),
          body: json.encode(updateData),
        );
        
        if (response.statusCode == 200) {
          syncedCount++;
          print('Profile update synced: ${update['_offline_id']}');
        } else {
          print('Failed to sync profile update: ${response.statusCode}');
        }
      } catch (e) {
        print('Error syncing profile update ${update['_offline_id']}: $e');
      }
    }
    
    // Remove synced updates
    if (syncedCount > 0) {
      await _removeSyncedProfileUpdates(syncedCount);
    }
    
    return syncedCount;
  }

  /// Sync pending schedule updates
  Future<int> _syncScheduleUpdates(String token) async {
    int syncedCount = 0;
    final pendingUpdates = await getPendingScheduleUpdates();
    
    for (final update in pendingUpdates) {
      try {
        final scheduleId = update['schedule_id'];
        final status = update['status'];
        
        // Send to server
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/schedules/$scheduleId'),
          headers: ApiConfig.getHeaders(token: token),
          body: json.encode({'status': status}),
        );
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          syncedCount++;
          print('Schedule update synced: ${update['_offline_id']}');
        } else {
          print('Failed to sync schedule update: ${response.statusCode}');
        }
      } catch (e) {
        print('Error syncing schedule update ${update['_offline_id']}: $e');
      }
    }
    
    // Remove synced updates
    if (syncedCount > 0) {
      await _removeSyncedScheduleUpdates(syncedCount);
    }
    
    return syncedCount;
  }

  /// Remove synced reports from local storage
  Future<void> _removeSyncedReports(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingReports = await getPendingReports();
    
    // Remove the first 'count' items (oldest first)
    final remainingReports = pendingReports.skip(count).toList();
    await prefs.setString(_pendingReportsKey, json.encode(remainingReports));
  }

  /// Remove synced requests from local storage
  Future<void> _removeSyncedRequests(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingRequests = await getPendingRequests();
    
    // Remove the first 'count' items (oldest first)
    final remainingRequests = pendingRequests.skip(count).toList();
    await prefs.setString(_pendingRequestsKey, json.encode(remainingRequests));
  }

  /// Remove synced profile updates from local storage
  Future<void> _removeSyncedProfileUpdates(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingUpdates = await getPendingProfileUpdates();
    
    // Remove the first 'count' items (oldest first)
    final remainingUpdates = pendingUpdates.skip(count).toList();
    await prefs.setString(_pendingProfileUpdatesKey, json.encode(remainingUpdates));
  }

  /// Remove synced schedule updates from local storage
  Future<void> _removeSyncedScheduleUpdates(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingUpdates = await getPendingScheduleUpdates();
    
    // Remove the first 'count' items (oldest first)
    final remainingUpdates = pendingUpdates.skip(count).toList();
    await prefs.setString(_pendingScheduleUpdatesKey, json.encode(remainingUpdates));
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get total pending items count
  Future<int> getTotalPendingItems() async {
    final reports = await getPendingReports();
    final requests = await getPendingRequests();
    final profileUpdates = await getPendingProfileUpdates();
    final scheduleUpdates = await getPendingScheduleUpdates();
    
    return reports.length + requests.length + profileUpdates.length + scheduleUpdates.length;
  }

  /// Clear all pending data (use with caution)
  Future<void> clearAllPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingReportsKey);
    await prefs.remove(_pendingRequestsKey);
    await prefs.remove(_pendingProfileUpdatesKey);
    await prefs.remove(_pendingScheduleUpdatesKey);
    await prefs.remove(_lastSyncKey);
  }
}
