import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'offline_first_service.dart';

export '../models/user_model.dart'
    show FarmWorker, RequestModel, InventoryItem, Technician, FarmWorkerProfile;

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login user
  Future<User> login(String roleType, String login, String password) async {
    try {
      final client = http.Client();
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'role_type': roleType,
          'login': login,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        await _saveUserData(user);
        client.close();
        return user;
      } else {
        client.close();
        throw Exception(
            json.decode(response.body)['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  // Register user
  Future<User> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        await _saveUserData(user);
        return user;
      } else {
        throw Exception(
            json.decode(response.body)['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logout}'),
          headers: ApiConfig.getHeaders(token: token),
        );
      }
    } finally {
      await _clearUserData();
    }
  }

  // NEW ETO FORGOT PASSWORD FOR TECHNICIAN
  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/technician/forgot-password'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        // Success - email sent
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to send password reset email');
      }
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        return User.fromJson(json.decode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save user data to local storage
  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token ?? '');
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  // Clear user data from local storage
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Helper method to create a client with credentials
  http.Client _getClient() {
    return http.Client();
  }

  // Helper method to close client
  void _closeClient(http.Client client) {
    client.close();
  }

  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        final user = json.decode(userData);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class FarmWorkerService {
  // FETCH FARM WORKERS ASSIGNED TO SPECIFIC TECHNICIAN
  Future<List<FarmWorker>> getAssignedFarmWorkers(
      String token, int technicianId) async {
    // USE THE CORRECT ENDPOINT THAT FILTERS BY TECHNICIAN ID
    final url = ApiConfig.getUrl('/farm-workers/by-technician');
    final response = await http.get(Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      // THE BACKEND NOW RETURNS ONLY THE TECHNICIAN'S ASSIGNED FARM WORKERS
      return data.map((e) => FarmWorker.fromJson(e)).toList();
    } else {
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Failed to load farm workers');
    }
  }
}

class FarmWorkerProfileService {
  /// Test if API is reachable
  Future<bool> testApiConnection(String token) async {
    try {
      final url = ApiConfig.getUrl('/test');
      print('Testing API connection to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('Test response status: ${response.statusCode}');
      return response.statusCode <
          500; // Any response means server is reachable
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }

  /// Fetch farm worker profile by ID
  Future<FarmWorkerProfile> getFarmWorkerProfile(
      String token, int farmWorkerId) async {
    try {
      final url = ApiConfig.getUrl('/farm-workers/$farmWorkerId');
      print('Fetching farm worker profile from: $url');
      print('Using farm worker ID: $farmWorkerId');
      print('Token length: ${token.length}');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');

        // Handle the case where data is wrapped in a 'farm_worker' object
        Map<String, dynamic> farmWorkerData;
        if (data.containsKey('farm_worker')) {
          farmWorkerData = data['farm_worker'];
        } else {
          farmWorkerData = data;
        }

        return FarmWorkerProfile.fromJson(farmWorkerData);
      } else if (response.statusCode == 404) {
        throw Exception('Farm worker not found (404) - Endpoint may not exist');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401) - Check token');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden (403) - Check permissions');
      } else {
        throw Exception(
            'Failed to load farm worker profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getFarmWorkerProfile: $e');
      print('Error stack trace: ${StackTrace.current}');
      throw Exception('Failed to load farm worker profile: $e');
    }
  }

  /// Update farm worker profile
  Future<FarmWorkerProfile> updateFarmWorkerProfile(
      String token, int farmWorkerId, Map<String, dynamic> updateData) async {
    try {
      final url = ApiConfig.getUrl('/farm-workers/$farmWorkerId');
      print('Updating farm worker profile at: $url');

      // Clean and validate the update data
      final cleanedData = <String, dynamic>{};
      updateData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          cleanedData[key] = value;
        }
      });

      print('Update data (cleaned): $cleanedData');

      final response = await http.patch(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode(cleanedData),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle the case where data is wrapped in a 'farm_worker' object
        Map<String, dynamic> farmWorkerData;
        if (data.containsKey('farm_worker')) {
          farmWorkerData = data['farm_worker'];
        } else {
          farmWorkerData = data;
        }

        return FarmWorkerProfile.fromJson(farmWorkerData);
      } else if (response.statusCode == 422) {
        // Validation error
        final errorData = json.decode(response.body);
        throw Exception(
            'Validation error: ${errorData['message'] ?? 'Invalid data'}');
      } else if (response.statusCode == 404) {
        throw Exception('Farm worker not found (404)');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401) - Check token');
      } else {
        throw Exception(
            'Failed to update farm worker profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in updateFarmWorkerProfile: $e');
      print('Error stack trace: ${StackTrace.current}');
      throw Exception('Failed to update farm worker profile: $e');
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture(String token, int farmWorkerId,
      List<int> imageBytes, String fileName) async {
    try {
      final url =
          ApiConfig.getUrl('/farm-workers/$farmWorkerId/profile-picture');
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'profile_picture',
        imageBytes,
        filename: fileName,
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['profile_picture_url'] ?? '';
      } else {
        throw Exception(
            'Failed to upload profile picture: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Upload ID picture
  Future<String> uploadIdPicture(String token, int farmWorkerId,
      List<int> imageBytes, String fileName) async {
    try {
      final url = ApiConfig.getUrl('/farm-workers/$farmWorkerId/id-picture');
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'id_picture',
        imageBytes,
        filename: fileName,
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['id_picture_url'] ?? '';
      } else {
        throw Exception(
            'Failed to upload ID picture: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Failed to upload ID picture: $e');
    }
  }
}

class InventoryService {
  /// Fetches only available inventory items (quantity > 0) from the backend.
  Future<List<InventoryItem>> getInventory(String token) async {
    final url = ApiConfig.getUrl('/inventories');
    final response = await http.get(Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => InventoryItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load inventory');
    }
  }
}

class RequestService {
  final OfflineFirstService _offlineService = OfflineFirstService();

  Future<List<RequestModel>> getRequestsForFarmWorker(
      String token, int farmWorkerId) async {
    final url = ApiConfig.getUrl('/requests?farm_worker_id=$farmWorkerId');
    print('RequestService: Fetching requests from: $url');
    print('RequestService: Farm worker ID: $farmWorkerId');
    print('RequestService: Token length: ${token.length}');

    final response = await http.get(Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token));

    print('RequestService: Response status: ${response.statusCode}');
    print('RequestService: Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('RequestService: Response data type: ${responseData.runtimeType}');
      print('RequestService: Response data: $responseData');

      List data;
      if (responseData is List) {
        // Direct array response
        data = responseData;
      } else if (responseData is Map) {
        // Object response - check common keys
        if (responseData.containsKey('data')) {
          data = responseData['data'] ?? [];
        } else if (responseData.containsKey('requests')) {
          data = responseData['requests'] ?? [];
        } else if (responseData.containsKey('results')) {
          data = responseData['results'] ?? [];
        } else {
          // If it's a single request object, wrap it in a list
          data = [responseData];
        }
      } else {
        data = [];
      }

      print('RequestService: Parsed ${data.length} requests');
      try {
        final allRequests = data.map((e) => RequestModel.fromJson(e)).toList();

        // Filter requests to only include those for the specific farm worker
        final filteredRequests = allRequests
            .where((request) => request.farmWorkerId == farmWorkerId)
            .toList();

        print(
            'RequestService: Filtered to ${filteredRequests.length} requests for farm worker $farmWorkerId');

        // Log any requests that were filtered out
        final otherRequests = allRequests
            .where((request) => request.farmWorkerId != farmWorkerId)
            .toList();

        if (otherRequests.isNotEmpty) {
          print(
              'RequestService: WARNING - Found ${otherRequests.length} requests for other farm workers:');
          for (var req in otherRequests) {
            print(
                'RequestService: - Request ID ${req.id} belongs to farm worker ${req.farmWorkerId}');
          }
        }

        return filteredRequests;
      } catch (e) {
        print('RequestService: Error parsing request data: $e');
        print(
            'RequestService: Sample data: ${data.isNotEmpty ? data.first : 'No data'}');
        throw Exception('Failed to parse request data: $e');
      }
    } else {
      print(
          'RequestService: Error response: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Failed to load requests: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> createRequest(
      String token, Map<String, dynamic> requestData) async {
    // Use offline-first service
    await _offlineService.createRequest(token, requestData);
  }

  Future<void> updateRequest(
      String token, int requestId, Map<String, dynamic> updateData) async {
    final url = ApiConfig.getUrl('/requests/$requestId');

    // Debug logging
    print('=== REQUEST SERVICE DEBUG ===');
    print('URL: $url');
    print('Request ID: $requestId');
    print('Update Data: $updateData');
    print('Headers: ${ApiConfig.getHeaders(token: token)}');
    print('============================');

    final response = await http.patch(
      Uri.parse(url),
      headers: ApiConfig.getHeaders(token: token),
      body: json.encode(updateData),
    );

    print('=== RESPONSE DEBUG ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=====================');

    if (response.statusCode != 200) {
      throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to update request');
    }
  }
}

class NotificationService {
  Future<List<NotificationModel>> getNotifications(String token) async {
    final url = ApiConfig.getUrl('/notifications');
    final response = await http.get(Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }
}

class TechnicianService {
  /// Test if API is reachable
  Future<bool> testApiConnection(String token) async {
    try {
      final url = ApiConfig.getUrl('/test');
      print('Testing API connection to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('Test response status: ${response.statusCode}');
      return response.statusCode <
          500; // Any response means server is reachable
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }

  /// Fetch technician profile by ID
  Future<Technician> getTechnicianProfile(
      String token, int technicianId) async {
    try {
      final url = ApiConfig.getUrl('/technicians/$technicianId');
      print('Fetching technician profile from: $url');
      print('Using technician ID: $technicianId');
      print('Token length: ${token.length}');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');

        // Handle the case where data is wrapped in a 'technician' object
        Map<String, dynamic> technicianData;
        if (data.containsKey('technician')) {
          technicianData = data['technician'];
        } else {
          technicianData = data;
        }

        return Technician.fromJson(technicianData);
      } else if (response.statusCode == 404) {
        throw Exception('Technician not found (404) - Endpoint may not exist');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401) - Check token');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden (403) - Check permissions');
      } else {
        throw Exception(
            'Failed to load technician profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getTechnicianProfile: $e');
      print('Error stack trace: ${StackTrace.current}');
      throw Exception('Failed to load technician profile: $e');
    }
  }

  /// Update technician profile
  Future<Technician> updateTechnicianProfile(
      String token, int technicianId, Map<String, dynamic> updateData) async {
    try {
      final url = ApiConfig.getUrl('/technicians/$technicianId');
      print('Updating technician profile at: $url');

      // Clean and validate the update data
      final cleanedData = <String, dynamic>{};
      updateData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          cleanedData[key] = value;
        }
      });

      print('Update data (cleaned): $cleanedData');

      final response = await http.patch(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode(cleanedData),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle the case where data is wrapped in a 'technician' object
        Map<String, dynamic> technicianData;
        if (data.containsKey('technician')) {
          technicianData = data['technician'];
        } else {
          technicianData = data;
        }

        return Technician.fromJson(technicianData);
      } else if (response.statusCode == 422) {
        // Validation error
        final errorData = json.decode(response.body);
        throw Exception(
            'Validation error: ${errorData['message'] ?? 'Invalid data'}');
      } else if (response.statusCode == 404) {
        throw Exception('Technician not found (404)');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401) - Check token');
      } else {
        throw Exception(
            'Failed to update technician profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in updateTechnicianProfile: $e');
      print('Error stack trace: ${StackTrace.current}');
      throw Exception('Failed to update technician profile: $e');
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture(String token, int technicianId,
      List<int> imageBytes, String fileName) async {
    try {
      final url =
          ApiConfig.getUrl('/technicians/$technicianId/profile-picture');
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'profile_picture',
        imageBytes,
        filename: fileName,
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['profile_picture_url'] ?? '';
      } else {
        throw Exception(
            'Failed to upload profile picture: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Upload ID picture
  Future<String> uploadIdPicture(String token, int technicianId,
      List<int> imageBytes, String fileName) async {
    try {
      final url = ApiConfig.getUrl('/technicians/$technicianId/id-picture');
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'id_picture',
        imageBytes,
        filename: fileName,
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['id_picture_url'] ?? '';
      } else {
        throw Exception(
            'Failed to upload ID picture: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Failed to upload ID picture: $e');
    }
  }
}
