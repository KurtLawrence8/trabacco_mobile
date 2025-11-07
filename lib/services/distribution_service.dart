import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/distribution_model.dart';

class DistributionService {
  Future<List<SupplyDistribution>> fetchSupplyDistributionsForFarmWorker(int farmWorkerId, String token) async {
    try {
      final url = '${ApiConfig.getUrl(ApiConfig.supplyDistribution)}?farm_worker_id=$farmWorkerId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> data = responseData['data'] ?? {};
        final List<dynamic> distributionsData = data['data'] ?? [];
        
        return distributionsData.map((json) => SupplyDistribution.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load supply distributions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching supply distributions: $e');
    }
  }

  Future<List<CashDistribution>> fetchCashDistributionsForFarmWorker(int farmWorkerId, String token) async {
    try {
      final url = '${ApiConfig.getUrl(ApiConfig.cashDistribution)}?farm_worker_id=$farmWorkerId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Handle both array and paginated response
        List<dynamic> distributionsData;
        if (responseData is List) {
          distributionsData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          distributionsData = responseData['data'] ?? [];
        } else {
          distributionsData = [];
        }
        
        return distributionsData.map((json) => CashDistribution.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cash distributions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching cash distributions: $e');
    }
  }
}

