import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class Equipment {
  final int id;
  final String equipmentName;
  final String serialNumber;
  final String status;
  final String? category;
  final String? location;

  Equipment({
    required this.id,
    required this.equipmentName,
    required this.serialNumber,
    required this.status,
    this.category,
    this.location,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? 0,
      equipmentName: json['equipment_name'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      status: json['status'] ?? '',
      category: json['category'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipment_name': equipmentName,
      'serial_number': serialNumber,
      'status': status,
      'category': category,
      'location': location,
    };
  }
}

class EquipmentService {
  // Helper method to clear authentication data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  // Get all available equipment
  Future<List<Equipment>> getAvailableEquipment(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/available-equipment'),
        headers: ApiConfig.getHeaders(token: token),
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final equipmentJson = data['data'] as List;
          
          final availableEquipment =
              equipmentJson.map((json) => Equipment.fromJson(json)).toList();

                    return availableEquipment;
        } else {
          final errorMsg = data['message'] ?? data['error'] ?? 'Unknown error';
          throw Exception('Failed to fetch equipment: $errorMsg');
        }
      } else if (response.statusCode == 401) {
        // Clear stored token and user data
        await _clearAuthData();
        throw Exception(
            'AUTHENTICATION_EXPIRED: Session expired. Please login again.');
      } else {
                throw Exception('Failed to fetch equipment: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get equipment by ID
  Future<Equipment> getEquipmentById(int id, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/equipment/$id'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Equipment.fromJson(data['data']);
        } else {
          throw Exception('Failed to fetch equipment: ${data['message']}');
        }
      } else if (response.statusCode == 401) {
        await _clearAuthData();
        throw Exception(
            'AUTHENTICATION_EXPIRED: Session expired. Please login again.');
      } else {
        throw Exception('Failed to fetch equipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching equipment: $e');
    }
  }
}

