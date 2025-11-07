import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CoordinatorService {
  // Get coordinator details by ID
  static Future<Map<String, dynamic>> getCoordinatorDetails(
      String token, int coordinatorId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/area-coordinators/$coordinatorId'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load coordinator details');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  // Get active area coordinators (for technician selection)
  static Future<List<Map<String, dynamic>>> getActiveCoordinators(
      String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/area-coordinators/active'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coordinators = data['data'];
        return coordinators.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load coordinators');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  // Get coordinator dashboard statistics
  static Future<Map<String, dynamic>> getStatistics(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/coordinator/dashboard/statistics'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load statistics');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  // Get pending reports for coordinator review
  static Future<List<Map<String, dynamic>>> getPendingReports(
      String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/coordinator/reports/pending'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> reports = data['data'];
        return reports.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load pending reports');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  // Get pending requests for coordinator review
  static Future<List<Map<String, dynamic>>> getPendingRequests(
      String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/coordinator/requests/pending'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> requests = data['data'];
        return requests.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load pending requests');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  // Get pending planting reports for coordinator review
  static Future<List<Map<String, dynamic>>> getPendingPlantingReports(
      String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/coordinator/planting-reports/pending'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> plantingReports = data['data'];
        return plantingReports.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load pending planting reports');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  // Get pending harvest reports for coordinator review
  static Future<List<Map<String, dynamic>>> getPendingHarvestReports(
      String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/coordinator/harvest-reports/pending'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> harvestReports = data['data'];
        return harvestReports.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load pending harvest reports');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  // Approve a report
  static Future<void> approveReport(
    String token,
    int reportId,
    String coordinatorNote,
  ) async {
    try {
      final url = '${ApiConfig.baseUrl}/coordinator/reports/$reportId/approve';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'coordinator_note': coordinatorNote,
        }),
      );


      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to approve report');
      }

    } catch (e) {
      throw Exception('Failed to approve report: ${e.toString()}');
    }
  }

  // Reject a report
  static Future<void> rejectReport(
    String token,
    int reportId,
    String coordinatorNote,
  ) async {
    try {
      final url = '${ApiConfig.baseUrl}/coordinator/reports/$reportId/reject';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'coordinator_note': coordinatorNote,
        }),
      );


      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject report');
      }

    } catch (e) {
      throw Exception('Failed to reject report: ${e.toString()}');
    }
  }

  // Approve a request
  static Future<void> approveRequest(
    String token,
    int requestId,
    String coordinatorNote,
  ) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/coordinator/requests/$requestId/approve';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'coordinator_note': coordinatorNote,
        }),
      );


      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to approve request');
      }

    } catch (e) {
      throw Exception('Failed to approve request: ${e.toString()}');
    }
  }

  // Reject a request
  static Future<void> rejectRequest(
    String token,
    int requestId,
    String coordinatorNote,
  ) async {
    try {
      final url = '${ApiConfig.baseUrl}/coordinator/requests/$requestId/reject';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'coordinator_note': coordinatorNote,
        }),
      );


      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject request');
      }

    } catch (e) {
      throw Exception('Failed to reject request: ${e.toString()}');
    }
  }

  // Approve a planting report
  static Future<void> approvePlantingReport(
    String token,
    int reportId,
    String coordinatorNote,
  ) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/coordinator/planting-reports/$reportId/approve';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'coordinator_note': coordinatorNote,
        }),
      );


      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Failed to approve planting report');
      }

    } catch (e) {
      throw Exception('Failed to approve planting report: ${e.toString()}');
    }
  }

  // Reject a planting report
  static Future<void> rejectPlantingReport(
    String token,
    int reportId,
    String coordinatorNote,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/coordinator/planting-reports/$reportId/reject'),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'coordinator_note': coordinatorNote,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject planting report');
      }
    } catch (e) {
      throw Exception('Failed to reject planting report: ${e.toString()}');
    }
  }

  // Approve a harvest report
  static Future<void> approveHarvestReport(
    String token,
    int reportId,
    String coordinatorNote,
  ) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/coordinator/harvest-reports/$reportId/approve';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'coordinator_note': coordinatorNote,
        }),
      );


      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to approve harvest report');
      }

    } catch (e) {
      throw Exception('Failed to approve harvest report: ${e.toString()}');
    }
  }

  // Reject a harvest report
  static Future<void> rejectHarvestReport(
    String token,
    int reportId,
    String coordinatorNote,
  ) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/coordinator/harvest-reports/$reportId/reject';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode({
          'coordinator_note': coordinatorNote,
        }),
      );


      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject harvest report');
      }

    } catch (e) {
      throw Exception('Failed to reject harvest report: ${e.toString()}');
    }
  }
}

