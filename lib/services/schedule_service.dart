import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';
import '../config/api_config.dart';

class ScheduleService {
  Future<void> updateScheduleStatus(
      int? id, String status, String token) async {
    if (id == null) {
      throw Exception('Cannot update schedule status: Schedule ID is null');
    }

    print(
        '[ScheduleService] [updateScheduleStatus] Starting update for schedule ID: $id with status: $status');
    print('[ScheduleService] [updateScheduleStatus] Using token: $token');
    print(
        '[ScheduleService] [updateScheduleStatus] API URL: ${ApiConfig.baseUrl}/schedules/$id');

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/schedules/$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({'status': status}),
      );

      print(
          '[ScheduleService] [updateScheduleStatus] Response status code: ${response.statusCode}');
      print(
          '[ScheduleService] [updateScheduleStatus] Response body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print(
            '[ScheduleService] [updateScheduleStatus] ERROR: HTTP ${response.statusCode}');
        throw Exception(
            'Failed to update schedule. Code: ${response.statusCode}. Body: ${response.body}');
      }

      print(
          '[ScheduleService] [updateScheduleStatus] Successfully updated schedule status');
    } catch (e) {
      print('[ScheduleService] [updateScheduleStatus] EXCEPTION: $e');
      rethrow;
    }
  }

  // Fetch all schedules for a specific farm worker
  Future<List<Schedule>> fetchSchedulesForFarmWorker(
      int farmWorkerId, String token) async {
    print(
        '[ScheduleService] [fetchSchedulesForFarmWorker] Starting fetch for farm worker ID: $farmWorkerId');
    print(
        '[ScheduleService] [fetchSchedulesForFarmWorker] Using token: $token');
    print(
        '[ScheduleService] [fetchSchedulesForFarmWorker] API URL: ${ApiConfig.baseUrl}/farm-workers/$farmWorkerId/schedules');

    try {
      final response = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}/farm-workers/$farmWorkerId/schedules'),
        headers: ApiConfig.getHeaders(token: token),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print(
              '[ScheduleService] [fetchSchedulesForFarmWorker] Request timeout after 30 seconds');
          throw Exception(
              'Request timeout: The server took too long to respond');
        },
      );

      print(
          '[ScheduleService] [fetchSchedulesForFarmWorker] Response status code: ${response.statusCode}');
      print(
          '[ScheduleService] [fetchSchedulesForFarmWorker] Response headers: ${response.headers}');
      print(
          '[ScheduleService] [fetchSchedulesForFarmWorker] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] Parsed response body: $body');

        // If backend returns { schedules: [...] }
        final List schedules = body['schedules'] ?? [];
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] Found ${schedules.length} schedules');

        final List<Schedule> result = schedules.map((json) {
          try {
            print(
                '[ScheduleService] [fetchSchedulesForFarmWorker] Parsing schedule: $json');
            print(
                '[ScheduleService] [fetchSchedulesForFarmWorker] Schedule ID type: ${json['id']?.runtimeType}');
            print(
                '[ScheduleService] [fetchSchedulesForFarmWorker] Schedule ID value: ${json['id']}');

            final schedule = Schedule.fromJson(json);
            print(
                '[ScheduleService] [fetchSchedulesForFarmWorker] Successfully parsed schedule with ID: ${schedule.id}');
            return schedule;
          } catch (e) {
            print(
                '[ScheduleService] [fetchSchedulesForFarmWorker] ERROR parsing schedule: $e');
            print(
                '[ScheduleService] [fetchSchedulesForFarmWorker] Problematic JSON: $json');
            print(
                '[ScheduleService] [fetchSchedulesForFarmWorker] Error type: ${e.runtimeType}');
            if (e is FormatException) {
              print(
                  '[ScheduleService] [fetchSchedulesForFarmWorker] FormatException details: ${e.message}');
              print(
                  '[ScheduleService] [fetchSchedulesForFarmWorker] FormatException source: ${e.source}');
              print(
                  '[ScheduleService] [fetchSchedulesForFarmWorker] FormatException offset: ${e.offset}');
            }
            rethrow;
          }
        }).toList();

        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] Successfully parsed ${result.length} schedules');
        return result;
      } else if (response.statusCode == 401) {
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] ERROR: Unauthorized (401)');
        throw Exception('Authentication failed. Please log in again.');
      } else if (response.statusCode == 403) {
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] ERROR: Forbidden (403)');
        throw Exception(
            'Access denied. You do not have permission to view these schedules.');
      } else if (response.statusCode == 404) {
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] ERROR: Not Found (404)');
        throw Exception('Farm worker or schedules not found.');
      } else if (response.statusCode >= 500) {
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] ERROR: Server error (${response.statusCode})');
        throw Exception('Server error. Please try again later.');
      } else {
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] ERROR: HTTP ${response.statusCode}');
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] Error response body: ${response.body}');
        throw Exception(
            'Failed to load schedules for farm worker. Status code: ${response.statusCode}. Body: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] [fetchSchedulesForFarmWorker] EXCEPTION: $e');
      if (e is FormatException) {
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] JSON parsing error: $e');
        throw Exception('Invalid response format from server');
      } else if (e is http.ClientException) {
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] Network error: $e');
        throw Exception(
            'Network error. Please check your internet connection.');
      } else if (e is SocketException) {
        print(
            '[ScheduleService] [fetchSchedulesForFarmWorker] Socket error: $e');
        throw Exception(
            'Connection error. Please check if the server is running.');
      }
      rethrow;
    }
  }
}
