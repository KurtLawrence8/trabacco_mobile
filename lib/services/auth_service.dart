import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

export '../models/user_model.dart' show FarmWorker, RequestModel, InventoryItem;

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
  Future<List<FarmWorker>> getAssignedFarmWorkers(
      String token, int technicianId) async {
    final url = ApiConfig.getUrl(ApiConfig.farmWorkers);
    final response = await http.get(Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      // Filter farm workers by technicianId
      return data
          .map((e) => FarmWorker.fromJson(e))
          .where((fw) => fw.technicianId == technicianId)
          .toList();
    } else {
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Failed to load farm workers');
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
  Future<List<RequestModel>> getRequestsForFarmWorker(
      String token, int farmWorkerId) async {
    final url = ApiConfig.getUrl('/requests?farm_worker_id=$farmWorkerId');
    final response = await http.get(Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => RequestModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load requests');
    }
  }

  Future<void> createRequest(
      String token, Map<String, dynamic> requestData) async {
    final url = ApiConfig.getUrl('/requests');
    final now = DateTime.now().toIso8601String();
    final payload = {
      'technician_id': requestData['technician_id'],
      'farm_worker_id': requestData['farm_worker_id'],
      'request_type':
          requestData['type'] == 'cash_advance' ? 'Cash Advance' : 'Supply',
      'description': requestData['reason'],
      'status': 'Pending',
      'timestamp': now,
      if (requestData['amount'] != null) 'amount': requestData['amount'],
      if (requestData['supply_id'] != null)
        'supply_id': requestData['supply_id'],
    };
    final response = await http.post(Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: json.encode(payload));
    if (response.statusCode != 201) {
      throw Exception(
          json.decode(response.body)['message'] ?? 'Failed to create request');
    }
  }

  Future<void> updateRequest(
      String token, int requestId, Map<String, dynamic> updateData) async {
    final url = ApiConfig.getUrl('/requests/$requestId');
    final response = await http.patch(
      Uri.parse(url),
      headers: ApiConfig.getHeaders(token: token),
      body: json.encode(updateData),
    );
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
