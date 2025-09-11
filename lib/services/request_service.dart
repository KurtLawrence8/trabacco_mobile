import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/request_model.dart';

class RequestService {
  Future<List<Request>> fetchRequestsForFarmWorker(int farmWorkerId, String token) async {
    try {
      final url = '${ApiConfig.getUrl(ApiConfig.requests)}?farm_worker_id=$farmWorkerId';
      print('[RequestService] Fetching requests from: $url');
      print('[RequestService] Farm Worker ID: $farmWorkerId');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('[RequestService] Response status: ${response.statusCode}');
      print('[RequestService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> requestsData = data['data'] ?? [];
        
        return requestsData.map((json) => Request.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load requests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching requests: $e');
    }
  }

  Future<Request> createRequest({
    required int technicianId,
    required int farmWorkerId,
    required String requestType,
    required String description,
    double? amount,
    int? supplyId,
    int? quantity,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.requests)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'technician_id': technicianId,
          'farm_worker_id': farmWorkerId,
          'request_type': requestType,
          'description': description,
          'amount': amount,
          'supply_id': supplyId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Request.fromJson(data);
      } else {
        throw Exception('Failed to create request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating request: $e');
    }
  }
}
