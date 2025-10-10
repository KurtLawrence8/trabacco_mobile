import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiConfig {
  // Base URL for the Laravel backend
  static String get baseUrl {
    // IMPORTANT: Replace 'YOUR_IP_ADDRESS' with your computer's actual IP address
    // To find your IP:
    // - Windows: Open CMD and run 'ipconfig' → look for IPv4 Address
    // - Mac/Linux: Open Terminal and run 'ifconfig' → look for inet address
    // Example: '192.168.1.100'

    final url = kIsWeb
        ? 'http://localhost:8000/api' // For web
        : (!kIsWeb && Platform.isAndroid)
            ? 'http://10.0.2.2:8000/api' // For Android Emulator ONLY
            : 'http://localhost:8000/api'; // For iOS Simulator and Physical Devices

    // UNCOMMENT AND USE THIS FOR PHYSICAL DEVICES:
    // final url = 'http://YOUR_IP_ADDRESS:8000/api'; // Replace YOUR_IP_ADDRESS

    print(
      '[API CONFIG] Platform: ${kIsWeb ? 'Web' : (!kIsWeb && Platform.isAndroid) ? 'Android' : 'iOS/Other'}',
    );
    print('[API CONFIG] Generated URL: $url');
    print('[API CONFIG] kIsWeb: $kIsWeb');
    if (!kIsWeb) {
      print('[API CONFIG] Platform.isAndroid: ${Platform.isAndroid}');
      print('[API CONFIG] Platform.isIOS: ${Platform.isIOS}');
    }

    return url;
  }

  // Image Base URL for serving images
  static String get imageBaseUrl {
    return kIsWeb
        ? 'http://localhost:8000' // For web
        : (!kIsWeb && Platform.isAndroid)
            ? 'http://10.0.2.2:8000' // For Android Emulator ONLY
            : 'http://localhost:8000'; // For iOS Simulator and Physical Devices

    // UNCOMMENT AND USE THIS FOR PHYSICAL DEVICES:
    // return 'http://YOUR_IP_ADDRESS:8000'; // Replace YOUR_IP_ADDRESS
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
