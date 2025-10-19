import 'package:flutter/material.dart';
import 'camera_report_screen.dart';
import 'planting_form_screen.dart';
import 'harvest_form_screen.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class TechnicianReportScreen extends StatefulWidget {
  final String? token;
  final int? technicianId;
  const TechnicianReportScreen({Key? key, this.token, this.technicianId})
      : super(key: key);

  @override
  State<TechnicianReportScreen> createState() => _TechnicianReportScreenState();
}

class _TechnicianReportScreenState extends State<TechnicianReportScreen> {
  Technician? _technician;
  bool _loadingTechnician = false;

  @override
  void initState() {
    super.initState();
    _fetchTechnicianData();
  }

  Future<void> _fetchTechnicianData() async {
    if (widget.token == null || widget.technicianId == null) return;

    setState(() => _loadingTechnician = true);
    try {
      final technician = await TechnicianService()
          .getTechnicianProfile(widget.token!, widget.technicianId!);
      if (mounted) {
        setState(() {
          _technician = technician;
          _loadingTechnician = false;
        });
      }
    } catch (e) {
      print('Error fetching technician data: $e');
      if (mounted) {
        setState(() => _loadingTechnician = false);
      }
    }
  }

  String _getTechnicianName() {
    if (_loadingTechnician) {
      return 'Loading...';
    }

    if (_technician != null) {
      final firstName = _technician!.firstName;
      final lastName = _technician!.lastName;
      final middleName = _technician!.middleName;

      String fullName = lastName;
      if (firstName.isNotEmpty) {
        fullName += ', $firstName';
      }
      if (middleName != null && middleName.isNotEmpty) {
        fullName += ' $middleName';
      }
      return fullName;
    }

    return 'Technician';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Compact Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assessment, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Report Center',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Choose a report type to submit',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _getTechnicianName(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Report Options Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                mainAxisSpacing: 12,
                childAspectRatio: 3.2,
                children: [
                  // Accomplishment Report
                  _buildReportCard(
                    icon: Icons.camera_alt,
                    title: 'Accomplishment Report',
                    subtitle: 'Daily field reports with photos',
                    color: const Color(0xFF3498DB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraReportScreen(
                            token: widget.token,
                            technicianId: widget.technicianId,
                            reportType: 'accomplishment',
                          ),
                        ),
                      );
                    },
                  ),

                  // Planting Report
                  _buildReportCard(
                    icon: Icons.eco,
                    title: 'Planting Report',
                    subtitle: 'Record planting details and conditions',
                    color: const Color(0xFF27AE60),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlantingFormScreen(
                            token: widget.token,
                            technicianId: widget.technicianId,
                          ),
                        ),
                      );
                    },
                  ),

                  // Harvest Report
                  _buildReportCard(
                    icon: Icons.agriculture,
                    title: 'Harvest Report',
                    subtitle: 'Record harvest data and quality',
                    color: const Color(0xFFE67E22),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HarvestFormScreen(
                            token: widget.token,
                            technicianId: widget.technicianId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
