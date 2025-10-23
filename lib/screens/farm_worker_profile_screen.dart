import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class FarmWorkerProfileScreen extends StatefulWidget {
  final int farmWorkerId;

  const FarmWorkerProfileScreen({
    super.key,
    required this.farmWorkerId,
  });

  @override
  State<FarmWorkerProfileScreen> createState() =>
      _FarmWorkerProfileScreenState();
}

class _FarmWorkerProfileScreenState extends State<FarmWorkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmWorkerService = FarmWorkerProfileService();

  bool _loading = false;
  FarmWorkerProfile? _farmWorker;

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _birthDateController;
  String? _sex;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadFarmWorkerData();
    _testUrlConstruction();
  }

  // Test method to verify URL construction
  void _testUrlConstruction() {
    print('🧪 [URL TEST] Testing URL construction...');
    print('🧪 [URL TEST] Image Base URL: ${ApiConfig.imageBaseUrl}');

    // Test with your provided URL
    String testUrl =
        'https://navajowhite-chinchilla-897972.hostingersite.com/storage/profile_pictures/PSD9axEdnjBXtEhEUSq3JcVfjoy5zSxJF3NlhLrS.jpg';
    print('🧪 [URL TEST] Full URL test: ${_getImageUrl(testUrl)}');

    // Test with relative path
    String testPath =
        'profile_pictures/PSD9axEdnjBXtEhEUSq3JcVfjoy5zSxJF3NlhLrS.jpg';
    print('🧪 [URL TEST] Relative path test: ${_getImageUrl(testPath)}');

    // Test with storage path
    String testStoragePath =
        'storage/profile_pictures/PSD9axEdnjBXtEhEUSq3JcVfjoy5zSxJF3NlhLrS.jpg';
    print('🧪 [URL TEST] Storage path test: ${_getImageUrl(testStoragePath)}');
  }

  // Helper method to construct full image URL
  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // Sanitize the URL - replace any localhost references
    String sanitizedPath = imagePath.replaceAll(
        'localhost', 'navajowhite-chinchilla-897972.hostingersite.com');
    sanitizedPath = sanitizedPath.replaceAll(
        '127.0.0.1', 'navajowhite-chinchilla-897972.hostingersite.com');
    sanitizedPath = sanitizedPath.replaceAll('http://', 'https://');

    // If it's already a full URL, return as is
    if (sanitizedPath.startsWith('http')) {
      print('🌐 [IMAGE URL] Already full URL (sanitized): $sanitizedPath');
      return sanitizedPath;
    }

    // Always use the hosting URL, never localhost
    String baseUrl = ApiConfig.imageBaseUrl;

    // Remove leading slash if present and clean up the path
    String cleanPath = sanitizedPath.startsWith('/')
        ? sanitizedPath.substring(1)
        : sanitizedPath;

    // Ensure the path starts with storage/
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }

    final fullUrl = '$baseUrl/$cleanPath';
    print('🌐 [IMAGE URL] Constructed URL: $fullUrl');
    print('🌐 [IMAGE URL] Original path: $imagePath');
    print('🌐 [IMAGE URL] Sanitized path: $sanitizedPath');
    return fullUrl;
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _birthDateController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmWorkerData() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final token = await AuthService().getToken();
      print('Token available: ${token != null}');
      print('Farmer ID: ${widget.farmWorkerId}');
      print('API Base URL: ${ApiConfig.baseUrl}');

      if (token != null) {
        // Test API connection first
        final isApiReachable =
            await _farmWorkerService.testApiConnection(token);
        print('API reachable: $isApiReachable');

        final farmWorker = await _farmWorkerService.getFarmWorkerProfile(
            token, widget.farmWorkerId);
        if (mounted) {
          setState(() {
            _farmWorker = farmWorker;
            _firstNameController.text = farmWorker.firstName;
            _lastNameController.text = farmWorker.lastName;
            _middleNameController.text = farmWorker.middleName ?? '';
            _phoneController.text = farmWorker.phoneNumber;
            _addressController.text = farmWorker.address ?? '';
            _birthDateController.text =
                farmWorker.birthDate?.toIso8601String().split('T')[0] ?? '';
            _sex = farmWorker.sex;
            _loading = false;
          });
        }

        // Debug: Print image URLs
        print(
            '🖼️ [PROFILE] Profile Picture URL: ${farmWorker.profilePicture}');
        print('🖼️ [PROFILE] ID Picture URL: ${farmWorker.idPicture}');
        print('🖼️ [PROFILE] Image Base URL: ${ApiConfig.imageBaseUrl}');
        if (farmWorker.profilePicture != null) {
          print(
              '🖼️ [PROFILE] Full Profile Picture URL: ${_getImageUrl(farmWorker.profilePicture)}');
        }
        if (farmWorker.idPicture != null) {
          print(
              '🖼️ [PROFILE] Full ID Picture URL: ${_getImageUrl(farmWorker.idPicture)}');
        }
      } else {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Failed to load Farmer data - No token available')),
          );
        }
      }
    } catch (e) {
      print('Error loading Farmer data: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');

      // Check if widget is still mounted before calling setState
      if (mounted) {
        // Fallback: Show sample data for development/testing
        setState(() {
          _farmWorker = FarmWorkerProfile(
            id: widget.farmWorkerId,
            firstName: 'Sample',
            lastName: 'Farmer',
            middleName: 'M.',
            birthDate: DateTime(1990, 1, 1),
            sex: 'Male',
            phoneNumber: '+1234567890',
            address: '123 Sample Street, Sample City',
            status: 'Active',
            profilePicture: null,
            idPicture: null,
            technicianId: 1,
          );
          _firstNameController.text = _farmWorker!.firstName;
          _lastNameController.text = _farmWorker!.lastName;
          _middleNameController.text = _farmWorker!.middleName ?? '';
          _phoneController.text = _farmWorker!.phoneNumber;
          _addressController.text = _farmWorker!.address ?? '';
          _birthDateController.text =
              _farmWorker!.birthDate?.toIso8601String().split('T')[0] ?? '';
          _sex = _farmWorker!.sex;
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using sample data. API error: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2C3E50),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_farmWorker == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2C3E50),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No farmer data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try refreshing the page',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadFarmWorkerData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card with Profile Picture
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Cover/Background Section
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF27AE60),
                    ),
                  ),
                  // Profile Picture - Overlapping the cover
                  Transform.translate(
                    offset: const Offset(0, -35),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey[100],
                            backgroundImage: _farmWorker!.profilePicture != null
                                ? NetworkImage(
                                    _getImageUrl(_farmWorker!.profilePicture))
                                : null,
                            child: _farmWorker!.profilePicture == null
                                ? Icon(Icons.person,
                                    size: 35, color: Colors.grey[400])
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_farmWorker!.firstName} ${_farmWorker!.middleName ?? ""} ${_farmWorker!.lastName}',
                          style: const TextStyle(
                            color: Color(0xFF2C3E50),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Farmer',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _farmWorker!.status,
                            style: const TextStyle(
                              color: Color(0xFF27AE60),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Sections
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Contact Information Card
                  _buildInfoCard(
                    title: 'CONTACT INFORMATION',
                    children: [
                      if (_farmWorker!.phoneNumber != null &&
                          _farmWorker!.phoneNumber!.isNotEmpty)
                        _buildInfoRow(
                            'Phone Number', _farmWorker!.phoneNumber!),
                      if (_farmWorker!.address != null &&
                          _farmWorker!.address!.isNotEmpty)
                        _buildInfoRow('Address', _farmWorker!.address!),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Personal Information Card
                  _buildInfoCard(
                    title: 'PERSONAL INFORMATION',
                    children: [
                      _buildInfoRow('First Name', _farmWorker!.firstName),
                      if (_farmWorker!.middleName != null &&
                          _farmWorker!.middleName!.isNotEmpty)
                        _buildInfoRow('Middle Name', _farmWorker!.middleName!),
                      _buildInfoRow('Last Name', _farmWorker!.lastName),
                      if (_farmWorker!.birthDate != null)
                        _buildInfoRow(
                          'Birth Date',
                          _farmWorker!.birthDate!
                              .toIso8601String()
                              .split('T')[0],
                        ),
                      if (_farmWorker!.sex != null)
                        _buildInfoRow('Sex', _farmWorker!.sex!),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ID Document Card
                  _buildInfoCard(
                    title: 'IDENTIFICATION DOCUMENT',
                    children: [
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                          color: Colors.grey[50],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _farmWorker!.idPicture != null
                              ? Image.network(
                                  _getImageUrl(_farmWorker!.idPicture!),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Unable to load ID document',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.credit_card_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No ID document uploaded',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Government-issued identification document',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build info card
  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE9ECEF)),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6C757D),
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
