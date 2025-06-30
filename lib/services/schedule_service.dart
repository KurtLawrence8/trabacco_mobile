import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';
import '../config/api_config.dart';

class ScheduleService {
  Future<List<Schedule>> fetchTodaySchedules(String token) async {
    final today = DateTime.now();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/schedules'),
      headers: ApiConfig.getHeaders(token: token),
    );
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data
          .map((json) => Schedule.fromJson(json))
          .where((s) =>
              s.dateScheduled.year == today.year &&
              s.dateScheduled.month == today.month &&
              s.dateScheduled.day == today.day)
          .toList();
    } else {
      print('Error fetching schedules: ${response.body}');
      throw Exception('Failed to load schedules');
    }
  }

  Future<void> updateScheduleStatus(int id, String status, String token) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/schedules/$id'),
      headers: ApiConfig.getHeaders(token: token),
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update schedule');
    }
  }
} 