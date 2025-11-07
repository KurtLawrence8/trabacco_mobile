import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../config/api_config.dart';
import '../utils/image_compressor.dart';

class HarvestService {
  Future<List<Map<String, dynamic>>> getYieldEstimates(String token) async {
    try {
      final url = '${ApiConfig.baseUrl}/yield-estimates/by-technician';

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );


      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Failed to load yield estimates: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load yield estimates: $e');
    }
  }

  Future<Map<String, dynamic>> checkHarvestStatus(
      String yieldEstimateId, String token) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/yield-estimates/$yieldEstimateId/harvest-status';

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );


      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to check harvest status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to check harvest status: $e');
    }
  }

  Future<Map<String, dynamic>> submitHarvest(
      Map<String, dynamic> harvestData, String token,
      [File? photo]) async {
    try {

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/farm-yield-records'),
      );

      request.headers.addAll(ApiConfig.getHeaders(token: token));
      request.headers.remove('Content-Type');

      harvestData.forEach((key, value) {
        if (value != null) {
          // Handle arrays (like laborer_ids)
          if (value is List) {
            for (int i = 0; i < value.length; i++) {
              request.fields['$key[$i]'] = value[i].toString();
            }
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Add photo if provided
      if (photo != null && await photo.exists()) {
        final rawBytes = await photo.readAsBytes();
        final compressedBytes = await ImageCompressor.compressFile(rawBytes);
        final baseName = path.basename(photo.path);
        final fileName = path.setExtension(baseName, '.jpg');
        request.files.add(
          http.MultipartFile.fromBytes(
            'photos[]',
            compressedBytes,
            filename: fileName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ??
            'Failed to submit harvest report (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }
}

