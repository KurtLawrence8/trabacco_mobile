import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ReportService {
  Future<List<Map<String, dynamic>>> getFarms() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/farms'),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load farms');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reports'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(reportData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message'] ?? 'Failed to create report');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reports'),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load reports');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }
} 