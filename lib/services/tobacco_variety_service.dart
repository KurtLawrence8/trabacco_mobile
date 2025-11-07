import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/tobacco_variety.dart';

class TobaccoVarietyService {
  static const String _endpoint = '/tobacco-varieties';

  /// Get all tobacco varieties
  Future<List<TobaccoVariety>> getTobaccoVarieties(String? token) async {
    try {
      final url = ApiConfig.getUrl(_endpoint);
      final headers = ApiConfig.getHeaders(token: token);


      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => TobaccoVariety.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load tobacco varieties: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch tobacco varieties: $e');
    }
  }

  /// Get tobacco variety by ID
  Future<TobaccoVariety?> getTobaccoVarietyById(String? token, int id) async {
    try {
      final url = ApiConfig.getUrl('$_endpoint/$id');
      final headers = ApiConfig.getHeaders(token: token);

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TobaccoVariety.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
            'Failed to load tobacco variety: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch tobacco variety: $e');
    }
  }
}

