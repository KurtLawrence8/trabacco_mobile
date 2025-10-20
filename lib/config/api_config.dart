import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Configuration for different environments
  // This setup automatically detects the environment and uses the appropriate URL:
  // - Web: localhost:8000/api
  // - Android Emulator: 10.0.2.2:8000/api (10.0.2.2 is the emulator's way to access host machine's localhost)
  // - Physical Device: 192.168.100.21:8000/api (your computer's IP address)

  static const String _localHost = 'localhost';
  static const String _emulatorHost = '10.0.2.2'; // Android emulator host
  static const String _physicalDeviceHost =
      '192.168.100.21'; // Your computer's IP address for development
  static const String _productionHost =
      'navajowhite-chinchilla-897972.hostingersite.com'; // PRODUCTION: Hostinger backend URL
  static const String _port = '8000';
  static const String _apiPath = '/api';

  // Helper method to detect if running on emulator
  static bool _isRunningOnEmulator() {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        // Check common emulator environment variables
        return Platform.environment.containsKey('ANDROID_SDK_ROOT') ||
            Platform.environment.containsKey('ANDROID_HOME') ||
            Platform.environment.containsKey('EMULATOR');
      }
      return false;
    } catch (e) {
      print('[API CONFIG] Error detecting emulator: $e');
      return false;
    }
  }

  // Helper method to detect if running in production
  static bool _isProduction() {
    // For now, you can set this to true when building for production
    // Or use build flavors/constants to determine this
    const bool isProduction = false; // CHANGE THIS TO TRUE FOR PRODUCTION BUILD
    return isProduction;
  }

  // Base URL for the Laravel backend - intelligently chooses the right URL
  static String get baseUrl {
    String host;
    bool isEmulator = _isRunningOnEmulator();
    bool isProduction = _isProduction();

    if (isProduction) {
      // For production deployment
      host = _productionHost;
      // Use HTTPS for production (assuming SSL is configured)
      return 'https://$host$_apiPath';
    } else if (kIsWeb) {
      // For web development
      host = _localHost;
    } else if (isEmulator) {
      // For Android emulator - use 10.0.2.2 which maps to host machine's localhost
      host = _emulatorHost;
    } else {
      // For physical devices, use your computer's IP address
      host = _physicalDeviceHost;
    }

    final url = 'http://$host:$_port$_apiPath';

    // print('[API CONFIG] =====================');
    // print(
    //     '[API CONFIG] Platform: ${kIsWeb ? 'Web' : (!kIsWeb && Platform.isAndroid) ? 'Android' : 'iOS/Other'}');
    // print('[API CONFIG] Is Emulator: $isEmulator');
    // print('[API CONFIG] Selected Host: $host');
    // print('[API CONFIG] Generated URL: $url');
    // print('[API CONFIG] Available URLs:');
    // print('[API CONFIG]   - Web: $_localHost:$_port$_apiPath');
    // print('[API CONFIG]   - Emulator: $_emulatorHost:$_port$_apiPath');
    // print(
    //     '[API CONFIG]   - Physical Device: $_physicalDeviceHost:$_port$_apiPath');
    // print('[API CONFIG] =====================');

    return url;
  }

  // Image Base URL for serving images - uses same logic as baseUrl
  static String get imageBaseUrl {
    String host;
    bool isEmulator = _isRunningOnEmulator();
    bool isProduction = _isProduction();

    if (isProduction) {
      // For production deployment
      host = _productionHost;
      // Use HTTPS for production (assuming SSL is configured)
      return 'https://$host';
    } else if (kIsWeb) {
      // For web development
      host = _localHost;
    } else if (isEmulator) {
      // For Android emulator - use 10.0.2.2 which maps to host machine's localhost
      host = _emulatorHost;
    } else {
      // For physical devices, use your computer's IP address
      host = _physicalDeviceHost;
    }

    return 'http://$host:$_port';
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

    // print('[ApiConfig] [getHeaders] Token provided: ${token != null}');
    // print('[ApiConfig] [getHeaders] Headers: $headers');

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

  // Google Maps API Key (for Directions API and other Google Maps services)
  static const String googleMapsApiKey =
      'AIzaSyBqeh2FJ10ybg0JGxTG5PF4YyvKTSvJmIg';

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
