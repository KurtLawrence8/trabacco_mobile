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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadTechnicianData();
  }

  // Helper method to construct direct storage URL
  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Construct direct storage URL
    String baseUrl = ApiConfig.imageBaseUrl;
    return '$baseUrl/storage/$imagePath';
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

    if (_technician == null) {
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
                'No technician data available',
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
                            backgroundImage: _technician!.profilePicture != null
                                ? NetworkImage(
                                    _getImageUrl(_technician!.profilePicture))
                                : null,
                            child: _technician!.profilePicture == null
                                ? Icon(Icons.person,
                                    size: 35, color: Colors.grey[400])
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_technician!.firstName} ${_technician!.middleName ?? ""} ${_technician!.lastName}',
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
                          'Agricultural Technician',
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
                            _technician!.status,
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
                      _buildInfoRow('Email Address', _technician!.emailAddress),
                      if (_technician!.phoneNumber != null &&
                          _technician!.phoneNumber!.isNotEmpty)
                        _buildInfoRow(
                            'Phone Number', _technician!.phoneNumber!),
                      if (_technician!.address != null &&
                          _technician!.address!.isNotEmpty)
                        _buildInfoRow('Address', _technician!.address!),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Personal Information Card
                  _buildInfoCard(
                    title: 'PERSONAL INFORMATION',
                    children: [
                      _buildInfoRow('First Name', _technician!.firstName),
                      if (_technician!.middleName != null &&
                          _technician!.middleName!.isNotEmpty)
                        _buildInfoRow('Middle Name', _technician!.middleName!),
                      _buildInfoRow('Last Name', _technician!.lastName),
                      if (_technician!.birthDate != null)
                        _buildInfoRow(
                          'Birth Date',
                          _technician!.birthDate!
                              .toIso8601String()
                              .split('T')[0],
                        ),
                      if (_technician!.sex != null)
                        _buildInfoRow('Sex', _technician!.sex!),
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
                          child: _technician!.idPicture != null
                              ? Image.network(
                                  _getImageUrl(_technician!.idPicture!),
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
