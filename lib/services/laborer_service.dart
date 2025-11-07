import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/laborer.dart';
import '../config/api_config.dart';

class LaborerService {
  // Get all laborers (laborers are now independent workers)
  Future<List<Laborer>> getAllLaborers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/laborers'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final laborersJson = data['data'] as List;

          // Debug each laborer data
          for (int i = 0; i < laborersJson.length; i++) {
          }

          return laborersJson.map((json) => Laborer.fromJson(json)).toList();
        } else {
          throw Exception('Failed to fetch laborers: ${data['message']}');
        }
      } else {
                throw Exception('Failed to fetch laborers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching laborers: $e');
    }
  }

  // Create new laborer
  Future<Laborer> createLaborer({
    required String firstName,
    required String middleName,
    required String lastName,
    String? phoneNumber,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/laborers'),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Laborer.fromJson(data['data']);
        } else {
          throw Exception('Failed to create laborer: ${data['message']}');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to create laborer: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating laborer: $e');
    }
  }

  // Search laborers by name
  Future<List<Laborer>> searchLaborers({
    required String searchQuery,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/laborers/search'),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'search': searchQuery,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final laborersJson = data['data'] as List;
          return laborersJson.map((json) => Laborer.fromJson(json)).toList();
        } else {
          throw Exception('Failed to search laborers: ${data['message']}');
        }
      } else {
        throw Exception('Failed to search laborers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching laborers: $e');
    }
  }

  // Update laborer
  Future<Laborer> updateLaborer({
    required int laborerId,
    required String firstName,
    required String middleName,
    required String lastName,
    String? phoneNumber,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/laborers/$laborerId'),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Laborer.fromJson(data['data']);
        } else {
          throw Exception('Failed to update laborer: ${data['message']}');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to update laborer: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating laborer: $e');
    }
  }

  // Delete laborer
  Future<void> deleteLaborer(int laborerId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/laborers/$laborerId'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception('Failed to delete laborer: ${data['message']}');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to delete laborer: ${errorData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting laborer: $e');
    }
  }
}

