import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PlantingService {
  static const String _endpoint = '/planting-reports';

  /// Submit a planting report
  Future<Map<String, dynamic>> submitPlantingReport({
    required String? token,
    required Map<String, dynamic> plantingData,
  }) async {
    try {
      final url = ApiConfig.getUrl('$_endpoint/submit');
      final headers = ApiConfig.getHeaders(token: token);

      print('🌱 [PlantingService] Submitting planting report to: $url');
      print('🌱 [PlantingService] Data: ${json.encode(plantingData)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(plantingData),
      );

      print('🌱 [PlantingService] Response status: ${response.statusCode}');
      print('🌱 [PlantingService] Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to submit planting report: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ [PlantingService] Error submitting planting report: $e');
      throw Exception('Failed to submit planting report: $e');
    }
  }

  /// Get planting reports for a farm
  Future<List<Map<String, dynamic>>> getFarmPlantingReports({
    required String? token,
    required int farmId,
    int? year,
    int? technicianId,
  }) async {
    try {
      String url = ApiConfig.getUrl('/farms/$farmId/planting-reports');

      // Add query parameters
      List<String> queryParams = [];
      if (year != null) queryParams.add('year=$year');
      if (technicianId != null) queryParams.add('technician_id=$technicianId');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final headers = ApiConfig.getHeaders(token: token);

      print('🌱 [PlantingService] Fetching planting reports from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🌱 [PlantingService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['reports'] ?? []);
      } else {
        throw Exception(
            'Failed to load planting reports: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [PlantingService] Error fetching planting reports: $e');
      throw Exception('Failed to fetch planting reports: $e');
    }
  }
}
