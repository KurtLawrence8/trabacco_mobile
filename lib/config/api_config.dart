import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Base URL for the Laravel backend
  static String get baseUrl {
    final url = kIsWeb
        ? 'http://127.0.0.1:8000/api' // For web - use localhost
        : Platform.isAndroid
            ? 'http://192.168.8.8:8000/api' // For Android - use your computer's IP
            : 'http://192.168.8.8:8000/api'; // For iOS and others - use your computer's IP

    print(
      '🌐 [API CONFIG] Platform: ${kIsWeb ? 'Web' : Platform.isAndroid ? 'Android' : 'iOS/Other'}',
    );
    print('🌐 [API CONFIG] Generated URL: $url');
    print('🌐 [API CONFIG] kIsWeb: $kIsWeb');
    print('🌐 [API CONFIG] Platform.isAndroid: ${Platform.isAndroid}');
    print('🌐 [API CONFIG] Platform.isIOS: ${Platform.isIOS}');

    return url;
  }

  // API Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String user = '/user';

  // Headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print('[ApiConfig] [getHeaders] Token provided: ${token != null}');
    print('[ApiConfig] [getHeaders] Headers: $headers');

    return headers;
  }

  // Auth endpoints
  static const String me = '/me';

  // Technician endpoints
  static const String technicians = '/technicians';
  static const String technicianTrashed = '/technicians/trashed';
  static const String technicianRestore = '/technicians/{id}/restore';
  static const String technicianForceDelete = '/technicians/{id}/force';

  // Farm Worker endpoints
  static const String farmWorkers = '/farm-workers';
  static const String farmWorkersByTechnician = '/farm-workers/by-technician';
  static const String farmWorkerTrashed = '/farm-workers/trashed';
  static const String farmWorkerRestore = '/farm-workers/{id}/restore';
  static const String farmWorkerForceDelete = '/farm-workers/{id}/force';

  // Request endpoints
  static const String requests = '/requests';

  // Distribution endpoints
  static const String supplyDistribution = '/supply-distribution';
  static const String cashDistribution = '/cash-distribution';

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Helper method to replace path parameters
  static String replacePathParams(
    String endpoint,
    Map<String, dynamic> params,
  ) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}
