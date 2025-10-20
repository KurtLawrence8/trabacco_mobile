import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class TechnicianProfileScreen extends StatefulWidget {
  final int technicianId;

  const TechnicianProfileScreen({
    super.key,
    required this.technicianId,
  });

  @override
  State<TechnicianProfileScreen> createState() =>
      _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _technicianService = TechnicianService();

  bool _loading = false;
  Technician? _technician;

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _birthDateController;
  String? _sex;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadTechnicianData();
  }

  // Helper method to construct full image URL
  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Construct full URL for Laravel storage
    // Try different approaches for web compatibility
    String baseUrl;
    if (kIsWeb) {
      // For web, try both localhost and 127.0.0.1
      baseUrl = 'https://navajowhite-chinchilla-897972.hostingersite.com'; // Try localhost first
    } else {
      baseUrl = 'https://navajowhite-chinchilla-897972.hostingersite.com';
    }

    // Remove leading slash if present and clean up the path
    String cleanPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    // Ensure the path starts with storage/
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }

    return '$baseUrl/$cleanPath';
  }

  // Helper method to get image provider that works on web and mobile
  ImageProvider? _getImageProvider(
      dynamic selectedImage, Uint8List? selectedImageBytes, String? networkImageUrl) {
    if (selectedImage != null) {
      // For web, we need to use bytes instead of File
      if (kIsWeb) {
        // On web, we'll need to load the image bytes first
        // For now, return null to show fallback icon
        return null;
      } else {
        return null; // Removed FileImage since we removed dart:io
      }
    } else if (networkImageUrl != null && networkImageUrl.isNotEmpty) {
      return NetworkImage(_getImageUrl(networkImageUrl));
    }
    return null;
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _birthDateController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadTechnicianData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final token = await AuthService().getToken();
      print('Token available: ${token != null}');
      print('Technician ID: ${widget.technicianId}');
      print('API Base URL: ${ApiConfig.baseUrl}');

      if (token != null) {
        // Test API connection first
        final isApiReachable =
            await _technicianService.testApiConnection(token);
        print('API reachable: $isApiReachable');

        final technician = await _technicianService.getTechnicianProfile(
            token, widget.technicianId);
        if (!mounted) return;
        setState(() {
          _technician = technician;
          _firstNameController.text = technician.firstName;
          _lastNameController.text = technician.lastName;
          _middleNameController.text = technician.middleName ?? '';
          _emailController.text = technician.emailAddress;
          _phoneController.text = technician.phoneNumber ?? '';
          _addressController.text = technician.address ?? '';
          _birthDateController.text =
              technician.birthDate?.toIso8601String().split('T')[0] ?? '';
          _sex = technician.sex;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to load technician data - No token available')),
        );
      }
    } catch (e) {
      print('Error loading technician data: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');

      // Fallback: Show sample data for development/testing
      if (!mounted) return;
      setState(() {
        _technician = Technician(
          id: widget.technicianId,
          firstName: 'Sample',
          lastName: 'Technician',
          middleName: 'M.',
          birthDate: DateTime(1990, 1, 1),
          sex: 'Male',
          emailAddress: 'sample@example.com',
          phoneNumber: '+1234567890',
          address: '123 Sample Street, Sample City',
          status: 'Active',
          profilePicture: null,
          idPicture: null,
        );
        _firstNameController.text = _technician!.firstName;
        _lastNameController.text = _technician!.lastName;
        _middleNameController.text = _technician!.middleName ?? '';
        _emailController.text = _technician!.emailAddress;
        _phoneController.text = _technician!.phoneNumber ?? '';
        _addressController.text = _technician!.address ?? '';
        _birthDateController.text =
            _technician!.birthDate?.toIso8601String().split('T')[0] ?? '';
        _sex = _technician!.sex;
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

    if (_technician == null) {
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
                'No technician data available',
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
                onPressed: _loadTechnicianData,
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
                          backgroundImage: _getImageProvider(
                              null,
                              null,
                              _technician!.profilePicture),
                          child: _getImageProvider(
                                      null,
                                      null,
                                      _technician!.profilePicture) ==
                                  null
                              ? const Icon(Icons.person,
                                  size: 50, color: Color(0xFF27AE60))
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_technician!.firstName} ${_technician!.lastName}',
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _technician!.emailAddress,
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
                        child: _technician!.idPicture != null
                                ? Image.network(
                                    _getImageUrl(_technician!.idPicture!),
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
                controller: _emailController,
                labelText: 'Email Address *',
                fieldId: 'email_address',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                fieldId: 'phone_number',
                keyboardType: TextInputType.phone,
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
