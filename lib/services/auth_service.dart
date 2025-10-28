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
    print('🔐 [AUTH] Starting login process...');
    print('🔐 [AUTH] Role Type: $roleType');
    print('🔐 [AUTH] Login: $login');
    print('🔐 [AUTH] Password length: ${password.length}');

    try {
      final client = http.Client();
      final url = '${ApiConfig.baseUrl}${ApiConfig.login}';
      final headers = ApiConfig.getHeaders();
      final body = json.encode({
        'role_type': roleType,
        'login': login,
        'password': password,
      });

      print('🔐 [AUTH] Request URL: $url');
      print('🔐 [AUTH] Request Headers: $headers');
      print('🔐 [AUTH] Request Body: $body');

      print('🔐 [AUTH] Sending HTTP POST request...');
      final response = await client.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('🔐 [AUTH] Response received!');
      print('🔐 [AUTH] Status Code: ${response.statusCode}');
      print('🔐 [AUTH] Response Headers: ${response.headers}');
      print('🔐 [AUTH] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('🔐 [AUTH] ✅ Login successful! Parsing response...');
        final data = json.decode(response.body);
        print('🔐 [AUTH] Parsed data: $data');
        final user = User.fromJson(data['user']);
        print('🔐 [AUTH] User object created: ${user.toString()}');
        await _saveUserData(user, roleType);
        print('🔐 [AUTH] User data saved to local storage');
        client.close();
        print('🔐 [AUTH] HTTP client closed');
        return user;
      } else if (response.statusCode == 403) {
        print('🔐 [AUTH] ❌ 403 Forbidden response');
        final data = json.decode(response.body);
        print('🔐 [AUTH] Error data: $data');
        client.close();
        // Check if this is an email verification required error
        if (data['email_verification_required'] == true) {
          print('🔐 [AUTH] Email verification required');
          throw Exception('email_verification_required: ${data['message']}');
        } else {
          print('🔐 [AUTH] Access denied: ${data['message']}');
          throw Exception(data['message'] ?? 'Access denied');
        }
      } else {
        print('🔐 [AUTH] ❌ Unexpected status code: ${response.statusCode}');
        final errorData = json.decode(response.body);
        print('🔐 [AUTH] Error response: $errorData');
        client.close();
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('🔐 [AUTH] ❌ Exception caught: ${e.toString()}');
      print('🔐 [AUTH] Exception type: ${e.runtimeType}');
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
        await _saveUserData(
            user, 'technician'); // Default role for registration
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

  // NEW ETO RESEND VERIFICATION EMAIL FOR TECHNICIAN
  Future<void> resendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/email/resend'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        // Success - verification email sent
        return;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to send verification email');
      }
    } catch (e) {
      throw Exception('Failed to send verification email: ${e.toString()}');
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

  // Validate if stored token is still valid
  Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        print('🔐 [AUTH] No token found for validation');
        return false;
      }

      print('🔐 [AUTH] Validating token: ${token.substring(0, 20)}...');
      print('🔐 [AUTH] URL: ${ApiConfig.getUrl(ApiConfig.me)}');

      // Test the token by making a simple API call with timeout
      final response = await http
          .get(
            Uri.parse(ApiConfig.getUrl(ApiConfig.me)),
            headers: ApiConfig.getHeaders(token: token),
          )
          .timeout(const Duration(seconds: 10));

      print('🔐 [AUTH] Token validation response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('🔐 [AUTH] ✅ Token is valid');
        return true;
      } else if (response.statusCode == 401) {
        print('🔐 [AUTH] ❌ Token expired (401 Unauthorized)');
        return false;
      } else {
        print('🔐 [AUTH] ⚠️ Unexpected status code: ${response.statusCode}');
        print('🔐 [AUTH] Response body: ${response.body}');
        // For now, consider non-network errors as valid token (server might be temporarily down)
        return response.statusCode < 500;
      }
    } catch (e) {
      print('🔐 [AUTH] Token validation failed: $e');

      // If it's a timeout or network error, don't invalidate the token immediately
      // User might be offline but token could still be valid
      if (e.toString().contains('timeout') ||
          e.toString().contains('SocketException')) {
        print('🔐 [AUTH] Network error during validation, keeping token');
        return true; // Assume token is valid if we can't reach server
      }

      return false;
    }
  }

  // Get user role type from storage
  Future<String?> getUserRoleType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role_type');
  }

  // Save user data to local storage
  Future<void> _saveUserData(User user, String roleType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token ?? '');
    await prefs.setString(_userKey, json.encode(user.toJson()));
    await prefs.setString(
        'user_role_type', roleType); // Store role type for navigation
  }

  // Clear user data from local storage
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove('user_role_type');
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
      throw Exception('Failed to load Farmers');
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
      print('Fetching Farmer profile from: $url');
      print('Using Farmer ID: $farmWorkerId');
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
        throw Exception('Farmer not found (404) - Endpoint may not exist');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401) - Check token');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden (403) - Check permissions');
      } else {
        throw Exception(
            'Failed to load Farmer profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getFarmWorkerProfile: $e');
      print('Error stack trace: ${StackTrace.current}');
      throw Exception('Failed to load Farmer profile: $e');
    }
  }

  /// Update farm worker profile
  Future<FarmWorkerProfile> updateFarmWorkerProfile(
      String token, int farmWorkerId, Map<String, dynamic> updateData) async {
    try {
      final url = ApiConfig.getUrl('/farm-workers/$farmWorkerId');
      print('Updating Farmer profile at: $url');

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
        throw Exception('Farmer not found (404)');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized (401) - Check token');
      } else {
        throw Exception(
            'Failed to update Farmer profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in updateFarmWorkerProfile: $e');
      print('Error stack trace: ${StackTrace.current}');
      throw Exception('Failed to update Farmer profile: $e');
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
  /// Helper method to clear authentication data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  /// Fetches only available inventory items (quantity > 0) from the backend.
  Future<List<InventoryItem>> getInventory(String token) async {
    final url = ApiConfig.getUrl('/inventories');
    final response = await http.get(Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => InventoryItem.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      print('[InventoryService] 401 Unauthorized - Token expired');
      await _clearAuthData();
      throw Exception(
          'AUTHENTICATION_EXPIRED: Session expired. Please login again.');
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
    print('RequestService: Farmer ID: $farmWorkerId');
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
            'RequestService: Filtered to ${filteredRequests.length} requests for Farmer $farmWorkerId');

        // Log any requests that were filtered out
        final otherRequests = allRequests
            .where((request) => request.farmWorkerId != farmWorkerId)
            .toList();

        if (otherRequests.isNotEmpty) {
          print(
              'RequestService: WARNING - Found ${otherRequests.length} requests for other Farmers:');
          for (var req in otherRequests) {
            print(
                'RequestService: - Request ID ${req.id} belongs to Farmer ${req.farmWorkerId}');
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

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode(updateData),
      );

      print('=== RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');
      print('=====================');

      // Accept multiple success status codes (200, 201, 204)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print(
            'Request updated successfully with status: ${response.statusCode}');
        return;
      } else {
        // Handle different error scenarios
        String errorMessage =
            'Failed to update request (Status: ${response.statusCode})';
        try {
          final responseBody = json.decode(response.body);
          if (responseBody is Map<String, dynamic>) {
            errorMessage = responseBody['message'] ??
                responseBody['error'] ??
                'Failed to update request (Status: ${response.statusCode})';
            print('Detailed error response: $responseBody');
          }
        } catch (e) {
          print('Could not parse error response: $e');
          errorMessage =
              'Failed to update request (Status: ${response.statusCode}): ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('=== REQUEST SERVICE ERROR ===');
      print('Error during update request: $e');
      print('==============================');
      rethrow;
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
