import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'farm_service.dart';
import 'offline_first_service.dart';

class ReportService {
  final FarmService _farmService = FarmService();
  final OfflineFirstService _offlineService = OfflineFirstService();

  Future<List<Map<String, dynamic>>> getFarms(String token) async {
    try {
      final farms = await _farmService.getFarmsByTechnician(token);
      // Convert Farm objects to Map format for the dropdown
      return farms
          .map((farm) => {
                'id': farm.id,
                'name': farm.farmAddress,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to load farms: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createReport(
      Map<String, dynamic> reportData, String token,
      {List<File>? images, List<Uint8List>? imageBytes}) async {
    // Use offline-first service
    return await _offlineService.createReport(reportData, token, images: images, imageBytes: imageBytes);
  }

  Future<List<Map<String, dynamic>>> getReports(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reports'),
        headers: ApiConfig.getHeaders(token: token),
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
