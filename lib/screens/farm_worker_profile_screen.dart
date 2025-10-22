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
    setState(() => _loading = true);
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
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load Farmer data - No token available')),
        );
      }
    } catch (e) {
      print('Error loading Farmer data: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
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
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_farmWorker == null) {
      return Scaffold(
        backgroundColor: Colors.white,
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
                'No Farmer data available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try refreshing the page',
                style: TextStyle(
                  fontSize: 14,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        actions: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Profile Picture
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF27AE60).withOpacity(0.2),
                      width: 1),
                ),
                child: Column(
                  children: [
                    // Profile Picture Section
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[100],
                          backgroundImage:
                              (_farmWorker!.profilePicture != null &&
                                      _farmWorker!.profilePicture!.isNotEmpty
                                  ? NetworkImage(_getImageUrl(
                                          _farmWorker!.profilePicture!))
                                      as ImageProvider?
                                  : null),
                          child: ((_farmWorker!.profilePicture == null ||
                                  _farmWorker!.profilePicture!.isEmpty))
                              ? const Icon(Icons.person,
                                  size: 50, color: Color(0xFF27AE60))
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_farmWorker!.firstName} ${_farmWorker!.lastName}',
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Farmer',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ID Picture Section - Right Below Profile Picture
              _buildSectionHeader('ID Picture', Icons.credit_card),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID Picture Display
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
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
                                  return Container(
                                    color: Colors.grey[100],
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.credit_card,
                                          size: 60,
                                          color: Color(0xFF27AE60),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Error loading ID picture',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[100],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.credit_card,
                                      size: 60,
                                      color: Color(0xFF27AE60),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No ID picture uploaded',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ID Picture',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload a clear photo of your ID document',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.person),
              const SizedBox(height: 16),

              // Name fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      labelText: 'First Name *',
                      fieldId: 'first_name',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      labelText: 'Last Name *',
                      fieldId: 'last_name',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _middleNameController,
                labelText: 'Middle Name',
                fieldId: 'middle_name',
              ),
              const SizedBox(height: 16),

              // Birth Date and Sex
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _birthDateController,
                      labelText: 'Birth Date',
                      fieldId: 'birth_date',
                      readOnly: true,
                      onTap: null,
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField<String>(
                      value: _sex,
                      labelText: 'Sex',
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                      ],
                      onChanged: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionHeader('Contact Information', Icons.contact_phone),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                labelText: 'Phone Number *',
                fieldId: 'phone_number',
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _addressController,
                labelText: 'Address',
                fieldId: 'address',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF27AE60),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          icon,
          color: const Color(0xFF27AE60),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  // Helper method to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? fieldId,
  }) {
    return TextFormField(
      key: fieldId != null ? Key(fieldId) : null,
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF27AE60), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
      enabled: false,
    );
  }

  // Helper method to build dropdown fields
  Widget _buildDropdownField<T>({
    required T? value,
    required String labelText,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF27AE60), width: 1),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dropdownColor: Colors.white,
      style: const TextStyle(
        color: Color(0xFF2C3E50),
        fontSize: 16,
      ),
    );
  }
}
