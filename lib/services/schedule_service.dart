import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/laborer.dart';
import '../models/schedule.dart';

class ScheduleService {
  Future<void> updateScheduleStatus(int? id, String status, String token) async {
    if (id == null) {
      throw Exception('Cannot update schedule status: Schedule ID is null');
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/schedules/$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({'status': status}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to update schedule. Code: ${response.statusCode}. Body: ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Schedule>> fetchSchedulesForFarmWorker(
    int farmWorkerId,
    String token,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/farm-workers/$farmWorkerId/schedules'),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout: The server took too long to respond');
            },
          );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List rawSchedules;

        if (decoded is List) {
          rawSchedules = decoded;
        } else if (decoded is Map<String, dynamic>) {
          rawSchedules = (decoded['schedules'] as List?) ?? [];
        } else {
          throw Exception('Unexpected response format from server');
        }

        return rawSchedules
            .map((item) => Schedule.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      }

      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Access denied. You do not have permission to view these schedules.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception('Farmer or schedules not found.');
      }

      if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      }

      throw Exception(
        'Failed to load schedules for farmer. Status code: ${response.statusCode}. Body: ${response.body}',
      );
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      if (e is http.ClientException || e is SocketException) {
        throw Exception('Network error. Please check your connection.');
      }
      rethrow;
    }
  }

  // Assign existing laborer to schedule and mark as completed
  Future<Schedule> assignLaborerAndComplete({
    required int scheduleId,
    int? laborerId,
    String? unit,
    double? budget,
    required String token,
  }) async {
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/schedules/$scheduleId/assign-laborer'),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'laborer_id': laborerId,
          'unit': unit,
          'budget': budget,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return Schedule.fromJson(data['data'] as Map<String, dynamic>);
        }
        throw Exception('Failed to assign laborer: ${data['message']}');
      }

      final errorData = json.decode(response.body);
      throw Exception(
        'Failed to assign laborer: ${(errorData as Map<String, dynamic>)['message'] ?? response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Assign multiple laborers to schedule (existing + new)
  Future<Map<String, dynamic>> assignMultipleLaborersAndComplete({
    required int scheduleId,
    List<int>? existingLaborerIds,
    List<Map<String, String?>>? newLaborers,
    String? unit,
    double? budget,
    required String token,
  }) async {
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/schedules/$scheduleId/assign-multiple-laborers'),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'existing_laborers': existingLaborerIds,
          'new_laborers': newLaborers,
          'unit': unit,
          'budget': budget,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final payload = data['data'] as Map<String, dynamic>;
          return {
            'schedule': Schedule.fromJson(payload['schedule'] as Map<String, dynamic>),
            'created_laborers': payload['created_laborers'],
            'total_assigned': payload['total_assigned'],
          };
        }
        throw Exception('Failed to assign laborers: ${data['message']}');
      }

      final errorData = json.decode(response.body);
      throw Exception(
        'Failed to assign laborers: ${(errorData as Map<String, dynamic>)['message'] ?? response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Create new laborer and assign to schedule
  Future<Map<String, dynamic>> createLaborerAndAssign({
    required int scheduleId,
    required String firstName,
    required String middleName,
    required String lastName,
    String? phoneNumber,
    String? unit,
    double? budget,
    required String token,
  }) async {
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/schedules/$scheduleId/create-laborer'),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'unit': unit,
          'budget': budget,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final payload = data['data'] as Map<String, dynamic>;
          return {
            'laborer': Laborer.fromJson(payload['laborer'] as Map<String, dynamic>),
            'schedule': Schedule.fromJson(payload['schedule'] as Map<String, dynamic>),
          };
        }
        throw Exception('Failed to create laborer: ${data['message']}');
      }

      final errorData = json.decode(response.body);
      throw Exception(
        'Failed to create laborer: ${(errorData as Map<String, dynamic>)['message'] ?? response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update completed schedule laborers, unit, and budget
  Future<Map<String, dynamic>> updateCompletedSchedule({
    required int scheduleId,
    List<int>? existingLaborerIds,
    List<Map<String, String?>>? newLaborers,
    String? unit,
    double? budget,
    required String token,
  }) async {
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/schedules/$scheduleId/assign-multiple-laborers'),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'existing_laborers': existingLaborerIds,
          'new_laborers': newLaborers,
          'unit': unit,
          'budget': budget,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final payload = data['data'] as Map<String, dynamic>;
          return {
            'schedule': Schedule.fromJson(payload['schedule'] as Map<String, dynamic>),
            'created_laborers': payload['created_laborers'],
            'total_assigned': payload['total_assigned'],
          };
        }
        throw Exception('Failed to update schedule: ${data['message']}');
      }

      final errorData = json.decode(response.body);
      throw Exception(
        'Failed to update schedule: ${(errorData as Map<String, dynamic>)['message'] ?? response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }
}

