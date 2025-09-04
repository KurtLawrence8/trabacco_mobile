import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../config/api_config.dart';
import 'farm_service.dart';

class ReportService {
  final FarmService _farmService = FarmService();

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
    try {
      print('Sending report to: ${ApiConfig.baseUrl}/reports');
      print('Headers: ${ApiConfig.getHeaders(token: token)}');
      print('Report data: $reportData');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/reports'),
      );

      // Add headers
      request.headers.addAll(ApiConfig.getHeaders(token: token));
      request.headers.remove('Content-Type'); // Let multipart set this

      // Add form fields
      reportData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add images
      if (kIsWeb && imageBytes != null && imageBytes.isNotEmpty) {
        // For web, use image bytes
        for (int i = 0; i < imageBytes.length; i++) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'images[$i]',
              imageBytes[i],
              filename: 'image_$i.jpg',
            ),
          );
        }
      } else if (images != null && images.isNotEmpty) {
        // For mobile, use file paths
        for (int i = 0; i < images.length; i++) {
          final image = images[i];
          if (await image.exists()) {
            final fileName = path.basename(image.path);
            request.files.add(
              await http.MultipartFile.fromPath(
                'images[$i]',
                image.path,
                filename: fileName,
              ),
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ??
            'Failed to create report (${response.statusCode})';
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
