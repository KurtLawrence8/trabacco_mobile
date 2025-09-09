import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class YieldMonitoringService {
  /// Fetch yield estimates for farms assigned to the current technician
  Future<List<Map<String, dynamic>>> getYieldEstimates(String token) async {
    try {
      final url = '${ApiConfig.baseUrl}/yield-estimates/by-technician';
      print('Fetching yield estimates from: $url');
      print('Headers: ${ApiConfig.getHeaders(token: token)}');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Failed to load yield estimates: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception in getYieldEstimates: $e');
      throw Exception('Failed to load yield estimates: $e');
    }
  }

  /// Create a new yield monitoring record
  Future<Map<String, dynamic>> createYieldMonitoring(
      Map<String, dynamic> monitoringData, String token) async {
    try {
      print(
          'Sending yield monitoring to: ${ApiConfig.baseUrl}/farm-yield-monitoring');
      print('Headers: ${ApiConfig.getHeaders(token: token)}');
      print('Monitoring data: $monitoringData');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/farm-yield-monitoring'),
      );

      // Add headers
      request.headers.addAll(ApiConfig.getHeaders(token: token));
      request.headers.remove('Content-Type'); // Let multipart set this

      // Add form fields
      monitoringData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // No images for yield monitoring

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ??
            'Failed to create yield monitoring (${response.statusCode})';
        print('Error response: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Exception caught: $e');
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  /// Get yield monitoring records for a specific farm
  Future<List<Map<String, dynamic>>> getYieldMonitoringByFarm(
      String token, int farmId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/farms/$farmId/yield-monitoring'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Failed to load yield monitoring records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load yield monitoring records: $e');
    }
  }
}
