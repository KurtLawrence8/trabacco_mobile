import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/farm.dart';
import '../config/api_config.dart';

class FarmService {
  /// Fetch farms assigned to the current technician
  Future<List<Farm>> getFarmsByTechnician(String token) async {
    try {
      final url = ApiConfig.getUrl('/farms/by-technician');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((farm) => Farm.fromJson(farm)).toList();
      } else {
        throw Exception(
            'Failed to load farms: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load farms: $e');
    }
  }
}
