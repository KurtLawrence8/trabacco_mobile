import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'request_list_widget.dart';
import 'request_screen.dart';
import 'technician_farms_screen.dart';

class FarmWorkerDetailScreen extends StatefulWidget {
  final FarmWorker farmWorker;
  final String token;
  const FarmWorkerDetailScreen(
      {Key? key, required this.farmWorker, required this.token})
      : super(key: key);

  @override
  State<FarmWorkerDetailScreen> createState() => _FarmWorkerDetailScreenState();
}

class _FarmWorkerDetailScreenState extends State<FarmWorkerDetailScreen> {
  Key requestListKey = UniqueKey();

  // Helper method to construct full image URL
  String _getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    // Sanitize the URL - replace any localhost references
    String sanitizedPath = imagePath.replaceAll(
        'localhost', 'navajowhite-chinchilla-897972.hostingersite.com');
    sanitizedPath = sanitizedPath.replaceAll(
        '127.0.0.1', 'navajowhite-chinchilla-897972.hostingersite.com');
    sanitizedPath = sanitizedPath.replaceAll('http://', 'https://');

    // If it's already a full URL, return as is
    if (sanitizedPath.startsWith('http')) {
      print('🌐 [DETAIL SCREEN] Already full URL (sanitized): $sanitizedPath');
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
    print('🌐 [DETAIL SCREEN] Constructed URL: $fullUrl');
    print('🌐 [DETAIL SCREEN] Original path: $imagePath');
    print('🌐 [DETAIL SCREEN] Sanitized path: $sanitizedPath');
    return fullUrl;
  }

  // Helper method to format birth date to MM-DD-YYYY
  String _formatBirthDate(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return '';

    try {
      // Try to parse the date - handle different possible formats
      DateTime parsedDate;

      // Check if it's already in a parseable format
      if (birthDate.contains('-')) {
        // ISO format or YYYY-MM-DD format
        parsedDate = DateTime.parse(birthDate);
      } else if (birthDate.contains('/')) {
        // Handle MM/DD/YYYY or DD/MM/YYYY formats
        final parts = birthDate.split('/');
        if (parts.length == 3) {
          // Assume MM/DD/YYYY format
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          parsedDate = DateTime(year, month, day);
        } else {
          return birthDate; // Return original if can't parse
        }
      } else {
        // Try direct parsing
        parsedDate = DateTime.parse(birthDate);
      }

      // Format to MM-DD-YYYY
      final month = parsedDate.month.toString().padLeft(2, '0');
      final day = parsedDate.day.toString().padLeft(2, '0');
      final year = parsedDate.year.toString();

      return '$month-$day-$year';
    } catch (e) {
      // If parsing fails, return the original string
      print('Error parsing birth date: $birthDate, error: $e');
      return birthDate;
    }
  }

  void _openRequestScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestScreen(
          farmWorker: widget.farmWorker,
          token: widget.token,
        ),
      ),
    );
    if (result == true) {
      setState(() {
        requestListKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.farmWorker;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with back button and title
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            color: const Color(0xFF27AE60),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 24),
                  padding: EdgeInsets.zero,
                ),
                const Expanded(
                  child: Text(
                    'Farmer Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farmer Details Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        const Text(
                          'Farmer Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Profile Section
                        Row(
                          children: [
                            // Profile picture
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8D5FF),
                                shape: BoxShape.circle,
                              ),
                              child: details.profilePicture != null &&
                                      details.profilePicture!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        _getImageUrl(details.profilePicture!),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              details.firstName[0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Color(0xFF6B21A8),
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        details.firstName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF6B21A8),
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            // Name and Basic Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${details.lastName}, ${details.firstName}${details.middleName != null && details.middleName!.isNotEmpty ? ' ${details.middleName}' : ''}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  if (details.sex != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sex: ${details.sex!}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Contact and Personal Details Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailRow(
                                label: 'Phone Number',
                                text: details.phoneNumber,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (details.birthDate != null)
                              Expanded(
                                child: _buildDetailRow(
                                  label: 'Birth Date',
                                  text: _formatBirthDate(details.birthDate!),
                                ),
                              ),
                          ],
                        ),
                        if (details.address != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            label: 'Address',
                            text: details.address!,
                          ),
                        ],

                        // ID Picture Section
                        if (details.idPicture != null &&
                            details.idPicture!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ID Picture',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                height: 240,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _getImageUrl(details.idPicture!),
                                    width: double.infinity,
                                    height: 240,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'ID Picture',
                                              style: TextStyle(
                                                color: Color(0xFF27AE60),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
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
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Farm Information Section
                  if (details.farms != null && details.farms!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Farm Information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFarmInfo(details.farms!.first),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 16),

                  // Create Request Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _openRequestScreen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Create Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Requests Section
                  Padding(
                    padding: const EdgeInsets.all(0),
                    child: Row(
                      children: [
                        const Text(
                          'Requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              requestListKey = UniqueKey();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27AE60),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF27AE60).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Refresh',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Request List
                  const SizedBox(height: 8), // Add proper spacing
                  SizedBox(
                    height: 400, // Keep height for better visibility
                    child: RequestListWidget(
                      key: requestListKey,
                      farmWorkerId: widget.farmWorker.id,
                      token: widget.token,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmInfo(dynamic farm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Farm Address
        _buildFarmDetailRow(
          label: 'Farm Address',
          value: farm['farm_address'] ?? 'Unknown Farm',
        ),

        // Farm Name
        if (farm['name'] != null && farm['name'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildFarmDetailRow(
            label: 'Name',
            value: farm['name'],
          ),
        ],

        // Farm Area
        if (farm['area'] != null || farm['farm_area'] != null) ...[
          const SizedBox(height: 12),
          _buildFarmDetailRow(
            label: 'Farm Area',
            value: '${(farm['area'] ?? farm['farm_area']).toString()} sqm',
          ),
        ],

        // Site Number
        if (farm['site_number'] != null &&
            farm['site_number'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildFarmDetailRow(
            label: 'Site Number',
            value: farm['site_number'],
          ),
        ],

        // Farmer Number
        if (farm['farmer_number'] != null &&
            farm['farmer_number'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildFarmDetailRow(
            label: 'Farmer Number',
            value: farm['farmer_number'],
          ),
        ],

        // Data Source
        if (farm['data_source'] != null &&
            farm['data_source'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildFarmDetailRow(
            label: 'Data Source',
            value: farm['data_source'].toString() == 'kmz_upload'
                ? 'KMZ Upload'
                : 'Manual Entry',
          ),
        ],

        const SizedBox(height: 20),

        // View Farm Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              try {
                // Navigate to technician farms screen with farm focus
                final farmId = farm['id'];

                // Debug: Print farm data to understand the issue
                print('🌾 [FARM DETAIL] Farm data: $farm');
                print(
                    '🌾 [FARM DETAIL] Farm ID type: ${farmId.runtimeType}, value: $farmId');

                // Ensure farmId is properly converted to int
                int? focusFarmId;
                if (farmId is int) {
                  focusFarmId = farmId;
                } else if (farmId is String) {
                  focusFarmId = int.tryParse(farmId);
                } else {
                  focusFarmId = null;
                }

                print('🌾 [FARM DETAIL] Converted focusFarmId: $focusFarmId');

                if (focusFarmId != null) {
                  print(
                      '🌾 [FARM DETAIL] Navigating to TechnicianFarmsScreen with focusFarmId: $focusFarmId');

                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TechnicianFarmsScreen(
                          focusFarmId: focusFarmId,
                        ),
                      ),
                    );
                  } catch (navError) {
                    print('🌾 [FARM DETAIL] Navigation error: $navError');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error opening farm: $navError'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  // Show error if farm ID is invalid
                  print('🌾 [FARM DETAIL] Invalid farm ID: $farmId');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid farm ID: $farmId'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                print('🌾 [FARM DETAIL] Error navigating to farm: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error opening farm: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'View Farm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFarmDetailRow({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
