import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/coordinator_service.dart';
import '../config/api_config.dart';

class CoordinatorProfileScreen extends StatefulWidget {
  final String token;
  final int coordinatorId;
  final VoidCallback? onBack;

  const CoordinatorProfileScreen({
    Key? key,
    required this.token,
    required this.coordinatorId,
    this.onBack,
  }) : super(key: key);

  @override
  State<CoordinatorProfileScreen> createState() =>
      _CoordinatorProfileScreenState();
}

class _CoordinatorProfileScreenState extends State<CoordinatorProfileScreen> {
  Map<String, dynamic>? _coordinator;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCoordinatorData();
  }

  Future<void> _loadCoordinatorData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final coordinatorData = await CoordinatorService.getCoordinatorDetails(
        widget.token,
        widget.coordinatorId,
      );

      setState(() {
        _coordinator = coordinatorData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatBirthDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  // Helper method to construct direct storage URL
  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Construct full URL for Laravel storage
    // Use imageBaseUrl (without /api) for storage files
    String baseUrl = ApiConfig.imageBaseUrl;

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
  ImageProvider? _getImageProvider(String? networkImageUrl) {
    if (networkImageUrl != null && networkImageUrl.isNotEmpty) {
      return NetworkImage(_getImageUrl(networkImageUrl));
    }
    return null;
  }

  Widget _buildInfoTile(String label, String? value, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          icon,
          color: Colors.grey[800],
          size: 24,
          weight: 600,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            value ?? 'N/A',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[900],
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        isThreeLine: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.green,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: RefreshIndicator(
          onRefresh: _loadCoordinatorData,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null && _coordinator == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Failed to Load Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage ?? 'Unknown error',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadCoordinatorData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header Card
                          Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide.none,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: _getImageProvider(
                                        _coordinator?['profile_picture_url'] ??
                                            _coordinator?['profile_picture'],
                                      ),
                                      child: _getImageProvider(
                                                _coordinator?[
                                                        'profile_picture_url'] ??
                                                    _coordinator?[
                                                        'profile_picture'],
                                              ) ==
                                              null
                                          ? Icon(
                                              Icons.person_outline,
                                              size: 50,
                                              color: Colors.grey[700],
                                              weight: 600,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '${_coordinator?['first_name'] ?? ''} ${_coordinator?['middle_name'] ?? ''} ${_coordinator?['last_name'] ?? ''}'
                                          .trim()
                                          .replaceAll(RegExp(r'\s+'), ' '),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[900],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Area Coordinator',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (_coordinator?['status'] ??
                                                    'Active') ==
                                                'Active'
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: (_coordinator?['status'] ??
                                                      'Active') ==
                                                  'Active'
                                              ? Colors.green
                                              : Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _coordinator?['status'] ?? 'Active',
                                        style: TextStyle(
                                          color: (_coordinator?['status'] ??
                                                      'Active') ==
                                                  'Active'
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Personal Information Section
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),

                          _buildInfoTile(
                            'Email',
                            _coordinator?['email_address'],
                            Icons.email_outlined,
                          ),
                          _buildInfoTile(
                            'Phone Number',
                            _coordinator?['phone_number'],
                            Icons.phone_outlined,
                          ),
                          if (_coordinator?['birth_date'] != null)
                            _buildInfoTile(
                              'Birth Date',
                              _formatBirthDate(_coordinator?['birth_date']),
                              Icons.cake_outlined,
                            ),
                          if (_coordinator?['sex'] != null)
                            _buildInfoTile(
                              'Sex',
                              _coordinator?['sex'],
                              Icons.person_outline,
                            ),

                          const SizedBox(height: 8),

                          // Address Section
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: Text(
                              'Address',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),

                          _buildInfoTile(
                            'Barangay',
                            _coordinator?['barangay'],
                            Icons.location_city_outlined,
                          ),
                          _buildInfoTile(
                            'Municipality/City',
                            _coordinator?['municipality'],
                            Icons.location_on_outlined,
                          ),
                          _buildInfoTile(
                            'Province',
                            _coordinator?['province'],
                            Icons.map_outlined,
                          ),

                          const SizedBox(height: 8),

                          // ID Document Section
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: Text(
                              'Identification Document',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),

                          // ID Picture Card
                          Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide.none,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      color: Colors.grey[50],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: (_coordinator?['id_picture_url'] !=
                                                      null &&
                                                  (_coordinator?['id_picture_url']
                                                              ?.toString() ??
                                                          '')
                                                      .isNotEmpty) ||
                                              (_coordinator?['id_picture'] !=
                                                      null &&
                                                  (_coordinator?['id_picture']
                                                              ?.toString() ??
                                                          '')
                                                      .isNotEmpty)
                                          ? Image.network(
                                              _getImageUrl(
                                                _coordinator?[
                                                        'id_picture_url'] ??
                                                    _coordinator?['id_picture'],
                                              ),
                                              width: double.infinity,
                                              height: 200,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .image_not_supported_outlined,
                                                        size: 48,
                                                        color: Colors.grey[400],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Unable to load ID document',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
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
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
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
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
