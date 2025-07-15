import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';
import '../config/api_config.dart';

class ScheduleService {
  Future<void> updateScheduleStatus(int id, String status, String token) async {
    print('[updateScheduleStatus] Using token: $token');
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/schedules/$id'),
      headers: ApiConfig.getHeaders(token: token),
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update schedule');
    }
  }

  // Fetch all schedules for a specific farm worker
  Future<List<Schedule>> fetchSchedulesForFarmWorker(
      int farmWorkerId, String token) async {
    print('[fetchSchedulesForFarmWorker] Using token: $token');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/farm-workers/$farmWorkerId/schedules'),
      headers: ApiConfig.getHeaders(token: token),
    );
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      // If backend returns { schedules: [...] }
      final List schedules = body['schedules'] ?? [];
      return schedules.map((json) => Schedule.fromJson(json)).toList();
    } else {
      print('Error fetching schedules for farm worker: ${response.body}');
      print('Status code: ${response.statusCode}');
      throw Exception(
          'Failed to load schedules for farm worker. Status code: ${response.statusCode}. Body: ${response.body}');
    }
  }
}
