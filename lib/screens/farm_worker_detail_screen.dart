import 'package:flutter/material.dart';
import '../models/user_model.dart';
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
            color: Color(0xFF27AE60),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  padding: EdgeInsets.zero,
                ),
                Expanded(
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
                SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farm Worker Information Card
                  Container(
                    padding: EdgeInsets.all(20),
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
                              decoration: BoxDecoration(
                                color: Color(0xFFE8D5FF),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  details.firstName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Color(0xFF6B21A8),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            // Name and Gender
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${details.firstName} ${details.lastName}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  if (details.sex != null) ...[
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.person_rounded,
                                            size: 20, color: Colors.grey[600]),
                                        SizedBox(width: 6),
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
                        SizedBox(height: 20),

                        // Contact and Personal Details
                        _buildDetailRow(
                          icon: Icons.phone_rounded,
                          iconColor: Colors.grey[600]!,
                          text: details.phoneNumber,
                        ),
                        if (details.address != null) ...[
                          SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.location_on_rounded,
                            iconColor: Colors.grey[600]!,
                            text: details.address!,
                          ),
                        ],
                        if (details.birthDate != null) ...[
                          SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.cake_rounded,
                            iconColor: Colors.grey[600]!,
                            text: details.birthDate!,
                          ),
                        ],

                        // Farm Information Section
                        if (details.farms != null &&
                            details.farms!.isNotEmpty) ...[
                          SizedBox(height: 20),
                          _buildFarmInfo(
                              details.farms!.first), // Show only first farm
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Create Request Button
                  Container(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _openRequestScreen,
                      icon: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        'Create Request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Requests Section
                  Padding(
                    padding: EdgeInsets.all(0),
                    child: Row(
                      children: [
                        Text(
                          'Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              requestListKey = UniqueKey();
                            });
                          },
                          icon: Icon(Icons.refresh, color: Color(0xFF27AE60)),
                          tooltip: 'Refresh requests',
                        ),
                      ],
                    ),
                  ),
                  // Request List
                  Transform.translate(
                    offset: Offset(0, -8), // Move up by 8 pixels
                    child: Container(
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
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Farm icon and title
          Row(
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
          SizedBox(height: 16),

          // Farm Address
          _buildFarmDetailRow(
            icon: Icons.location_on,
            label: 'Farm Address',
            value: farm['farm_address'] ?? 'Unknown Farm',
            iconColor: Color(0xFF27AE60),
          ),

          // Farm Size
          if (farm['farm_size'] != null) ...[
            SizedBox(height: 12),
            _buildFarmDetailRow(
              icon: Icons.straighten,
              label: 'Farm Size',
              value: '${farm['farm_size'].toString()} hectares',
              iconColor: Colors.grey[600]!,
            ),
          ],

          // Coordinates (simplified)
          if (coordinatesDisplay.isNotEmpty) ...[
            SizedBox(height: 12),
            _buildFarmDetailRow(
              icon: Icons.my_location,
              label: 'Coordinates',
              value: coordinatesDisplay,
              iconColor: Colors.grey[600]!,
            ),
          ],

          SizedBox(height: 16),

          // View Farm Button
          Container(
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
              icon: Icon(Icons.visibility, color: Colors.white, size: 16),
              label: Text(
                'View Farm',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF27AE60),
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
        SizedBox(width: 8),
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
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
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
}
