import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  State<FarmWorkerProfileScreen> createState() => _FarmWorkerProfileScreenState();
}

class _FarmWorkerProfileScreenState extends State<FarmWorkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmWorkerService = FarmWorkerProfileService();
  final _imagePicker = ImagePicker();
  
  bool _loading = false;
  bool _editing = false;
  FarmWorkerProfile? _farmWorker;
  File? _selectedProfileImage;
  File? _selectedIdImage;

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
    String testUrl = 'http://localhost:8000/storage/profile_pictures/PSD9axEdnjBXtEhEUSq3JcVfjoy5zSxJF3NlhLrS.jpg';
    print('🧪 [URL TEST] Full URL test: ${_getImageUrl(testUrl)}');
    
    // Test with relative path
    String testPath = 'profile_pictures/PSD9axEdnjBXtEhEUSq3JcVfjoy5zSxJF3NlhLrS.jpg';
    print('🧪 [URL TEST] Relative path test: ${_getImageUrl(testPath)}');
    
    // Test with storage path
    String testStoragePath = 'storage/profile_pictures/PSD9axEdnjBXtEhEUSq3JcVfjoy5zSxJF3NlhLrS.jpg';
    print('🧪 [URL TEST] Storage path test: ${_getImageUrl(testStoragePath)}');
  }

  // Helper method to construct full image URL
  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    
    // Sanitize the URL - replace any localhost references
    String sanitizedPath = imagePath.replaceAll('localhost', 'navajowhite-chinchilla-897972.hostingersite.com');
    sanitizedPath = sanitizedPath.replaceAll('127.0.0.1', 'navajowhite-chinchilla-897972.hostingersite.com');
    sanitizedPath = sanitizedPath.replaceAll('http://', 'https://');
    
    // If it's already a full URL, return as is
    if (sanitizedPath.startsWith('http')) {
      print('🌐 [IMAGE URL] Already full URL (sanitized): $sanitizedPath');
      return sanitizedPath;
    }
    
    // Always use the hosting URL, never localhost
    String baseUrl = ApiConfig.imageBaseUrl;
    
    // Remove leading slash if present and clean up the path
    String cleanPath = sanitizedPath.startsWith('/') ? sanitizedPath.substring(1) : sanitizedPath;
    
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
      print('Farm Worker ID: ${widget.farmWorkerId}');
      print('API Base URL: ${ApiConfig.baseUrl}');

      if (token != null) {
        // Test API connection first
        final isApiReachable = await _farmWorkerService.testApiConnection(token);
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
        print('🖼️ [PROFILE] Profile Picture URL: ${farmWorker.profilePicture}');
        print('🖼️ [PROFILE] ID Picture URL: ${farmWorker.idPicture}');
        print('🖼️ [PROFILE] Image Base URL: ${ApiConfig.imageBaseUrl}');
        if (farmWorker.profilePicture != null) {
          print('🖼️ [PROFILE] Full Profile Picture URL: ${_getImageUrl(farmWorker.profilePicture)}');
        }
        if (farmWorker.idPicture != null) {
          print('🖼️ [PROFILE] Full ID Picture URL: ${_getImageUrl(farmWorker.idPicture)}');
        }
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load farm worker data - No token available')),
        );
      }
    } catch (e) {
      print('Error loading farm worker data: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      
      // Fallback: Show sample data for development/testing
      setState(() {
        _farmWorker = FarmWorkerProfile(
          id: widget.farmWorkerId,
          firstName: 'Sample',
          lastName: 'Farm Worker',
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = await AuthService().getToken();
      if (token != null) {
        // Try to upload images using multipart form data with profile update
        bool hasImages = _selectedProfileImage != null || _selectedIdImage != null;
        
        if (hasImages) {
          setState(() => _loading = true);
          try {
            // Create multipart request for profile update with images
            final url = ApiConfig.getUrl('/farm-workers/${widget.farmWorkerId}');
            final request = http.MultipartRequest('PATCH', Uri.parse(url));
            
            // Add headers
            request.headers.addAll(ApiConfig.getHeaders(token: token));
            request.headers.remove('Content-Type'); // Let multipart set this
            
            // Add form fields
            final updateData = <String, dynamic>{};
            if (_firstNameController.text.isNotEmpty) {
              updateData['first_name'] = _firstNameController.text;
            }
            if (_lastNameController.text.isNotEmpty) {
              updateData['last_name'] = _lastNameController.text;
            }
            if (_middleNameController.text.isNotEmpty) {
              updateData['middle_name'] = _middleNameController.text;
            }
            if (_phoneController.text.isNotEmpty) {
              updateData['phone_number'] = _phoneController.text;
            }
            if (_addressController.text.isNotEmpty) {
              updateData['address'] = _addressController.text;
            }
            if (_birthDateController.text.isNotEmpty) {
              updateData['birth_date'] = _birthDateController.text;
            }
            if (_sex != null && _sex!.isNotEmpty) {
              updateData['sex'] = _sex;
            }
            
            updateData.forEach((key, value) {
              if (value != null && value.toString().isNotEmpty) {
                request.fields[key] = value.toString();
              }
            });
            
            // Add profile picture if selected
            if (_selectedProfileImage != null) {
              final imageBytes = await _selectedProfileImage!.readAsBytes();
              request.files.add(http.MultipartFile.fromBytes(
                'profile_picture',
                imageBytes,
                filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ));
            }
            
            // Add ID picture if selected
            if (_selectedIdImage != null) {
              final imageBytes = await _selectedIdImage!.readAsBytes();
              request.files.add(http.MultipartFile.fromBytes(
                'id_picture',
                imageBytes,
                filename: 'id_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ));
            }
            
            print('Uploading farm worker profile with images to: $url');
            print('Fields: ${request.fields}');
            print('Files: ${request.files.length}');
            
            final streamedResponse = await request.send();
            final response = await http.Response.fromStream(streamedResponse);
            
            print('Response status: ${response.statusCode}');
            print('Response body: ${response.body}');
            
            if (response.statusCode == 200 || response.statusCode == 201) {
              json.decode(response.body);
              print('Farm worker profile updated with images successfully');
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile and images updated successfully!'),
                  backgroundColor: Color(0xFF27AE60),
                ),
              );
              
              // Clear selected images and reload profile data
              setState(() {
                _selectedProfileImage = null;
                _selectedIdImage = null;
              });
              
              // Reload profile data from server
              await _loadFarmWorkerData();
              
              // Exit edit mode and force UI refresh
              setState(() {
                _editing = false;
              });
              
              print('Farm worker profile images cleared and data reloaded');
              print('Profile picture URL: ${_farmWorker?.profilePicture}');
              print('ID picture URL: ${_farmWorker?.idPicture}');
              return; // Exit early since we handled the update
            } else {
              final errorBody = json.decode(response.body);
              final errorMessage = errorBody['message'] ?? 'Failed to update profile with images (${response.statusCode})';
              print('Error response: $errorMessage');
              throw Exception(errorMessage);
            }
          } catch (e) {
            print('Error uploading farm worker profile with images: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload images: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
            // Continue to regular profile update without images
          } finally {
            setState(() => _loading = false);
          }
        }

        // Update profile data
        final updateData = <String, dynamic>{};

        // ONLY ADD NON-NULL AND NON-EMPTY VALUES
        if (_firstNameController.text.isNotEmpty) {
          updateData['first_name'] = _firstNameController.text;
        }
        if (_lastNameController.text.isNotEmpty) {
          updateData['last_name'] = _lastNameController.text;
        }
        if (_middleNameController.text.isNotEmpty) {
          updateData['middle_name'] = _middleNameController.text;
        }
        if (_phoneController.text.isNotEmpty) {
          updateData['phone_number'] = _phoneController.text;
        }
        if (_addressController.text.isNotEmpty) {
          updateData['address'] = _addressController.text;
        }
        if (_birthDateController.text.isNotEmpty) {
          updateData['birth_date'] = _birthDateController.text;
        }
        if (_sex != null && _sex!.isNotEmpty) {
          updateData['sex'] = _sex;
        }

        print('Sending update data: $updateData');

        final updatedFarmWorker = await _farmWorkerService
            .updateFarmWorkerProfile(token, widget.farmWorkerId, updateData);

        setState(() {
          _farmWorker = updatedFarmWorker;
          _editing = false;
          _selectedProfileImage = null;
          _selectedIdImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _farmWorker?.birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );

        if (image != null) {
          setState(() {
            if (isProfile) {
              _selectedProfileImage = File(image.path);
            } else {
              _selectedIdImage = File(image.path);
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isProfile ? 'Profile picture selected' : 'ID picture selected'),
              backgroundColor: const Color(0xFF27AE60),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
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
                'No farm worker data available',
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
        actions: [
          if (!_editing)
            IconButton(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit, color: Color(0xFF27AE60)),
              tooltip: 'Edit Profile',
            ),
        ],
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
                  border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.2), width: 1),
                ),
                child: Column(
                  children: [
                    // Profile Picture Section
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: _selectedProfileImage != null
                              ? (kIsWeb 
                                  ? null // For web, we'll show fallback for now
                                  : FileImage(_selectedProfileImage!) as ImageProvider?)
                              : (_farmWorker!.profilePicture != null && _farmWorker!.profilePicture!.isNotEmpty
                                  ? NetworkImage(_getImageUrl(_farmWorker!.profilePicture!)) as ImageProvider?
                                  : null),
                          child: (_selectedProfileImage == null && 
                                  (_farmWorker!.profilePicture == null || _farmWorker!.profilePicture!.isEmpty))
                              ? const Icon(Icons.person, size: 50, color: Color(0xFF27AE60))
                              : null,
                        ),
                        if (_editing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _pickImage(true),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF27AE60),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
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
                      'Farm Worker',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_editing)
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.photo_camera, size: 18),
                        label: const Text('Change Profile Picture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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
                        child: _selectedIdImage != null
                            ? (kIsWeb 
                                ? Container(
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
                                          'ID Picture Selected',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Image.file(
                                    _selectedIdImage!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ))
                            : _farmWorker!.idPicture != null
                                ? Image.network(
                                    _getImageUrl(_farmWorker!.idPicture!),
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
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
                    if (_editing)
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(false),
                        icon: const Icon(Icons.upload, size: 18),
                        label: const Text('Upload ID Picture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      labelText: 'Last Name *',
                      fieldId: 'last_name',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                      onTap: _editing ? _pickBirthDate : null,
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
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      onChanged: _editing ? (v) => setState(() => _sex = v) : null,
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

              // Action Buttons
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_editing) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _saveProfile,
                          icon: _loading 
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save, size: 18),
                          label: Text(_loading ? 'Saving...' : 'Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27AE60),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : () {
                            setState(() {
                              _editing = false;
                              _selectedProfileImage = null;
                              _selectedIdImage = null;
                            });
                            _loadFarmWorkerData(); // Reload original data
                          },
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF27AE60),
                            side: const BorderSide(color: Color(0xFF27AE60), width: 1),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
      enabled: _editing,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dropdownColor: Colors.white,
      style: const TextStyle(
        color: Color(0xFF2C3E50),
        fontSize: 16,
      ),
    );
  }
}
