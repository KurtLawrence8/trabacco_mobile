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
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: 10,
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
                    'Farm Worker Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farm Worker Information Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Section
                        Row(
                          children: [
                            // Profile picture
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8D5FF),
                                shape: BoxShape.circle,
                              ),
                              child: details.profilePicture != null &&
                                      details.profilePicture!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        _getImageUrl(details.profilePicture!),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              details.firstName[0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Color(0xFF6B21A8),
                                                fontSize: 24,
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
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            // Name and Gender
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${details.firstName} ${details.lastName}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  if (details.sex != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.person_rounded,
                                            size: 20, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          details.sex!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Contact and Personal Details
                        _buildDetailRow(
                          icon: Icons.phone_rounded,
                          iconColor: Colors.grey[600]!,
                          text: details.phoneNumber,
                        ),
                        if (details.address != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.location_on_rounded,
                            iconColor: Colors.grey[600]!,
                            text: details.address!,
                          ),
                        ],
                        if (details.birthDate != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.cake_rounded,
                            iconColor: Colors.grey[600]!,
                            text: details.birthDate!,
                          ),
                        ],

                        // Farm Information Section
                        if (details.farms != null &&
                            details.farms!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildFarmInfo(
                              details.farms!.first), // Show only first farm
                        ],

                        // ID Picture Section
                        if (details.idPicture != null &&
                            details.idPicture!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildIdPictureSection(details.idPicture!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Request Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _openRequestScreen,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Create Request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Requests Section
                  Padding(
                    padding: const EdgeInsets.all(0),
                    child: Row(
                      children: [
                        const Text(
                          'Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              requestListKey = UniqueKey();
                            });
                          },
                          icon: const Icon(Icons.refresh,
                              color: Color(0xFF27AE60)),
                          tooltip: 'Refresh requests',
                        ),
                      ],
                    ),
                  ),
                  // Request List
                  Transform.translate(
                    offset: const Offset(0, -8), // Move up by 8 pixels
                    child: SizedBox(
                      height: 400, // Increased height for better visibility
                      child: RequestListWidget(
                        key: requestListKey,
                        farmWorkerId: widget.farmWorker.id,
                        token: widget.token,
                      ),
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
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFarmInfo(dynamic farm) {
    // Parse coordinates to show only lat, lng
    String coordinatesDisplay = '';
    if (farm['coordinates'] != null) {
      try {
        // Try to parse as JSON array first
        if (farm['coordinates'].toString().startsWith('[')) {
          final coords = farm['coordinates'].toString();
          // Extract first two numbers (lat, lng)
          final regex = RegExp(r'-?\d+\.?\d*');
          final matches = regex.allMatches(coords);
          if (matches.length >= 2) {
            final lat = matches.elementAt(0).group(0);
            final lng = matches.elementAt(1).group(0);
            coordinatesDisplay = '$lat, $lng';
          }
        } else {
          // Simple comma-separated format
          final coords = farm['coordinates'].toString().split(',');
          if (coords.length >= 2) {
            coordinatesDisplay = '${coords[0].trim()}, ${coords[1].trim()}';
          }
        }
      } catch (e) {
        coordinatesDisplay = farm['coordinates'].toString();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Farm icon and title
          const Row(
            children: [
              Icon(Icons.agriculture, color: Color(0xFF27AE60), size: 20),
              SizedBox(width: 8),
              Text(
                'Farm Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Farm Address
          _buildFarmDetailRow(
            icon: Icons.location_on,
            label: 'Farm Address',
            value: farm['farm_address'] ?? 'Unknown Farm',
            iconColor: const Color(0xFF27AE60),
          ),

          // Farm Area
          if (farm['area'] != null || farm['farm_area'] != null) ...[
            const SizedBox(height: 12),
            _buildFarmDetailRow(
              icon: Icons.straighten,
              label: 'Farm Area',
              value: '${(farm['area'] ?? farm['farm_area']).toString()} sqm',
              iconColor: Colors.grey[600]!,
            ),
          ],

          // Coordinates (simplified)
          if (coordinatesDisplay.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildFarmDetailRow(
              icon: Icons.my_location,
              label: 'Coordinates',
              value: coordinatesDisplay,
              iconColor: Colors.grey[600]!,
            ),
          ],

          const SizedBox(height: 16),

          // View Farm Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to technician farms screen with farm focus
                final farmId = farm['id'];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TechnicianFarmsScreen(
                      focusFarmId: farmId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility, color: Colors.white, size: 16),
              label: const Text(
                'View Farm',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdPictureSection(String idPictureUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ID icon and title
          const Row(
            children: [
              Icon(Icons.credit_card, color: Color(0xFF27AE60), size: 20),
              SizedBox(width: 8),
              Text(
                'ID Picture',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
              child: Image.network(
                _getImageUrl(idPictureUrl),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
