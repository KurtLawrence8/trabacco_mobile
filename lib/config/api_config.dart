import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Base URL for the Laravel backend
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api'; // For web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api'; // For Android Emulator
    } else {
      return 'http://localhost:8000/api'; // For iOS Simulator and others
    }
  }

  // API Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String user = '/user';

  // Headers
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth endpoints
  static const String me = '/api/me';

  // Technician endpoints
  static const String technicians = '/api/technicians';
  static const String technicianTrashed = '/api/technicians/trashed';
  static const String technicianRestore = '/api/technicians/{id}/restore';
  static const String technicianForceDelete = '/api/technicians/{id}/force';

  // Farm Worker endpoints
  static const String farmWorkers = '/api/farm-workers';
  static const String farmWorkerTrashed = '/api/farm-workers/trashed';
  static const String farmWorkerRestore = '/api/farm-workers/{id}/restore';
  static const String farmWorkerForceDelete = '/api/farm-workers/{id}/force';

  // Farm endpoints
  static const String farms = '/api/farms';
  static const String farmTrashed = '/api/farms/trashed';
  static const String farmRestore = '/api/farms/{id}/restore';
  static const String farmForceDelete = '/api/farms/{id}/force';

  // Inventory endpoints
  static const String inventory = '/api/inventory';
  static const String inventoryTrashed = '/api/inventory/trashed';
  static const String inventoryRestore = '/api/inventory/{id}/restore';
  static const String inventoryForceDelete = '/api/inventory/{id}/force';

  // Supply Distribution endpoints
  static const String supplyDistribution = '/api/supply-distribution';
  static const String supplyDistributionTrashed =
      '/api/supply-distribution/trashed';
  static const String supplyDistributionRestore =
      '/api/supply-distribution/{id}/restore';
  static const String supplyDistributionForceDelete =
      '/api/supply-distribution/{id}/force';

  // Report endpoints
  static const String reports = '/api/reports';
  static const String reportTrashed = '/api/reports/trashed';
  static const String reportRestore = '/api/reports/{id}/restore';
  static const String reportForceDelete = '/api/reports/{id}/force';

  // Request endpoints
  static const String requests = '/api/requests';
  static const String requestTrashed = '/api/requests/trashed';
  static const String requestRestore = '/api/requests/{id}/restore';
  static const String requestForceDelete = '/api/requests/{id}/force';

  // Schedule endpoints
  static const String schedules = '/api/schedules';
  static const String scheduleTrashed = '/api/schedules/trashed';
  static const String scheduleRestore = '/api/schedules/{id}/restore';
  static const String scheduleForceDelete = '/api/schedules/{id}/force';

  // Notification endpoints
  static const String notifications = '/api/notifications';
  static const String notificationTrashed = '/api/notifications/trashed';
  static const String notificationRestore = '/api/notifications/{id}/restore';
  static const String notificationForceDelete = '/api/notifications/{id}/force';

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Helper method to replace path parameters
  static String replacePathParams(
      String endpoint, Map<String, dynamic> params) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}
