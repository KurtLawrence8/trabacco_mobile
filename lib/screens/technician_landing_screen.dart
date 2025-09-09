import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'camera_report_screen.dart';
import 'schedule_page.dart';

import 'package:provider/provider.dart';
import 'farm_worker_detail_screen.dart';
import 'technician_farms_screen.dart';
import '../models/user_model.dart' show Technician;
import '../services/auth_service.dart' show TechnicianService;
import '../config/api_config.dart';
import 'request_screen.dart';
import 'notification_screen.dart';

class TechnicianLandingScreen extends StatefulWidget {
  final String token;
  final int technicianId;
  const TechnicianLandingScreen(
      {Key? key, required this.token, required this.technicianId})
      : super(key: key);

  @override
  State<TechnicianLandingScreen> createState() =>
      _TechnicianLandingScreenState();
}

class _TechnicianLandingScreenState extends State<TechnicianLandingScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // FETCH FARM WORKERS ASSIGNED TO THIS SPECIFIC TECHNICIAN
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FarmWorkerProvider>(context, listen: false)
          .fetchFarmWorkers(widget.token, widget.technicianId);
    });
  }

  // ====================================================
  // BUILD APP BAR
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100 + MediaQuery.of(context).padding.top),
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ====================================================
              // GREETING ROW
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Hi Technician!',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50))),
                        SizedBox(height: 2),
                        Text('May you always in a good condition',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  // ====================================================
                  // NOTIFICATIONS ROW
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        // ====================================================
                        // NOTIFICATIONS BUTTON
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotificationScreen(
                                  token: widget.token,
                                  technician: Technician(
                                    id: widget.technicianId,
                                    firstName: 'Technician',
                                    lastName: 'User',
                                    emailAddress: 'technician@example.com',
                                    phoneNumber: '',
                                    status: 'active',
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.notifications_outlined,
                              color: Colors.grey[700], size: 16),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      // ====================================================
                      // POPUP MENU BUTTON
                      SizedBox(width: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.person,
                              color: Colors.grey[700], size: 16),
                          padding: EdgeInsets.zero,
                          onSelected: (value) async {
                            if (value == 'profile') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ManageProfileScreen(
                                        technicianId: widget.technicianId)),
                              );
                            } else if (value == 'logout') {
                              await AuthService().logout();
                              if (!mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          // ====================================================
                          // POPUP MENU ITEM BUILDER
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.settings,
                                      color: Color(0xFF27AE60)),
                                  SizedBox(width: 8),
                                  Text('Manage Profile')
                                ],
                              ),
                            ),
                            // ====================================================
                            // LOGOUT BUTTON
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Logout')
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              // ====================================================
              // SEARCH BAR ROW
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF9E9E9E),
                          width: 1.0,
                        ),
                      ),
                      // ====================================================
                      // SEARCH BAR
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'farm worker, farm add...',
                          hintStyle:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.grey[600], size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  // ====================================================
                  // FILTER BUTTON
                  SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(0xFFE8D5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Filter functionality
                      },
                      icon:
                          Icon(Icons.tune, color: Color(0xFF6B21A8), size: 20),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
      child: Column(
        children: [
          // ====================================================
          // QUICK ACTIONS SECTION
          Row(
            children: [
              Icon(Icons.rocket_launch, color: Color(0xFFFFC107), size: 20),
              SizedBox(width: 8),
              Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222B45))),
            ],
          ),
          const SizedBox(height: 16),
// ====================================================
          // QUICK ACTIONS GRID
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
// ====================================================
              _buildQuickActionCard(
                icon: Icons.people_alt_rounded,
                title: 'Assigned Farm workers',
                subtitle: 'List of assigned farm workers',
                color: Color(0xFF6366F1), // Indigo
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignedFarmWorkersScreen(
                        token: widget.token,
                        technicianId: widget.technicianId,
                      ),
                    ),
                  );
                },
              ),
// ====================================================
// TRANSPLANTING SCHEDULES
              _buildQuickActionCard(
                icon: Icons.calendar_today_rounded,
                title: 'Transplanting schedules',
                subtitle: 'List of schedule activities',
                color: Color(0xFF10B981), // Emerald
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransplantingSchedulesScreen(
                        token: widget.token,
                        technicianId: widget.technicianId,
                      ),
                    ),
                  );
                },
              ),
// ====================================================
// REQUEST SUBMISSION
              _buildQuickActionCard(
                icon: Icons.send_rounded,
                title: 'Request Submission',
                subtitle: 'Submit farm worker request',
                color: Color(0xFFF59E0B), // Amber
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestSubmissionScreen(
                        token: widget.token,
                        technicianId: widget.technicianId,
                      ),
                    ),
                  );
                },
              ),
// ====================================================
// REPORT SUBMISSION
              _buildQuickActionCard(
                icon: Icons.assessment_rounded,
                title: 'Report submission',
                subtitle: 'Submit farm progress report',
                color: Color(0xFFEF4444), // Red
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CameraReportScreen(
                        token: widget.token,
                        technicianId: widget.technicianId,
                        showCloseButton: true, // Show X button for quick action
                      ),
                    ),
                  );
                },
              ),
// ====================================================
// FARM MAP
              _buildQuickActionCard(
                icon: Icons.map_rounded,
                title: 'Farm Map',
                subtitle: 'View assigned farm locations',
                color: Color(0xFF3B82F6), // Blue
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TechnicianFarmsScreen(),
                    ),
                  );
                },
              ),
// ====================================================
// NOTIFICATIONS
              _buildQuickActionCard(
                icon: Icons.notifications_active_rounded,
                title: 'Notifications',
                subtitle: 'View all notifications',
                color: Color(0xFF8B5CF6), // Violet
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationScreen(
                        token: widget.token,
                        technician: Technician(
                          id: widget.technicianId,
                          firstName: 'Technician',
                          lastName: 'User',
                          emailAddress: 'technician@example.com',
                          phoneNumber: '',
                          status: 'active',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

// ====================================================
// BUILD QUICK ACTION CARD
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08), // Light background color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Simple icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchedule() {
    // Navigate to transplanting schedules screen
    return TransplantingSchedulesScreen(
      token: widget.token,
      technicianId: widget.technicianId,
    );
  }

// ====================================================
// BUILD REPORTS
  Widget _buildReports() {
    return CameraReportScreen(
        token: widget.token,
        technicianId: widget.technicianId,
        showCloseButton: false); // No X button for navigation bar
  }

  Widget _buildManageProfile() {
    return ManageProfileScreen(technicianId: widget.technicianId);
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    double iconSize = 24;
    if (index == 1 || index == 2) {
      iconSize = 22;
    }
// ====================================================
// BUILD NAV ITEM
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? const Color(0xFF27AE60)
                  : const Color(0xFF8F9BB3),
              size: iconSize,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF27AE60)
                    : const Color(0xFF8F9BB3),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ====================================================
// BUILD CENTER REQUEST BUTTON
  Widget _buildCenterRequestButton() {
    return GestureDetector(
      onTap: () {
        // Navigate to request submission
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestSubmissionScreen(
              token: widget.token,
              technicianId: widget.technicianId,
            ),
          ),
        );
      },
      // ====================================================
      // CENTER REQUEST BUTTON
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR-style icon with blue outline
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.green,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.send_rounded,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          // Label
          const Text(
            'Request',
            style: TextStyle(
              color: Color(0xFF8F9BB3),
              fontSize: 10,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

// ====================================================
// BUILD TECHNICIAN LANDING SCREEN
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(),
      _buildSchedule(),
      _buildReports(),
      _buildManageProfile(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? _buildAppBar()
          : null, // Only show app bar for home tab
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        // ====================================================
        // BOTTOM NAVIGATION BAR
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Home
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                ),
                // Schedule
                _buildNavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: 'Schedule',
                  index: 1,
                ),
                // Center Request Button (like GCash QR)
                _buildCenterRequestButton(),
                // Report
                _buildNavItem(
                  icon: Icons.assessment_outlined,
                  activeIcon: Icons.assessment,
                  label: 'Report',
                  index: 2,
                ),
                // Profile
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================================
// MANAGE PROFILE SCREEN
class ManageProfileScreen extends StatefulWidget {
  final int technicianId;
  const ManageProfileScreen({super.key, required this.technicianId});

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

// ====================================================
// MANAGE PROFILE SCREEN STATE
class _ManageProfileScreenState extends State<ManageProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _technicianService = TechnicianService();
  bool _loading = false;
  bool _editing = false;
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
  String? _status;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadTechnicianData();
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

  Future<void> _loadTechnicianData() async {
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
          _status = technician.status;
          _loading = false;
        });
      } else {
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
      if (e.toString().contains('Exception:')) {
        print('Exception message: ${e.toString().split('Exception:')[1]}');
      }
      // Fallback: Show sample data for development/testing
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
        _status = _technician!.status;
        _loading = false;
      });
// ====================================================
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using sample data. API error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

// ====================================================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = await AuthService().getToken();
      if (token != null) {
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
        if (_emailController.text.isNotEmpty) {
          updateData['email_address'] = _emailController.text;
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
        if (_status != null && _status!.isNotEmpty) {
          updateData['status'] = _status;
        }
// ====================================================
        print('Sending update data: $updateData');

        final updatedTechnician = await _technicianService
            .updateTechnicianProfile(token, widget.technicianId, updateData);

        setState(() {
          _technician = updatedTechnician;
          _editing = false;
        });
// ====================================================
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

// ====================================================
// PICK BIRTH DATE
  Future<void> _pickBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _technician?.birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

// ====================================================
// PICK IMAGE
  Future<void> _pickImage(bool isProfile) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image picker not implemented in this demo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_technician == null) {
      return const Center(child: Text('No technician data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _technician!.profilePicture != null
                      ? NetworkImage(_technician!.profilePicture!)
                      : null,
                  child: _technician!.profilePicture == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _editing ? () => _pickImage(true) : null,
                  child: const Text('Change Profile Picture'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Personal Information Section
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                    enabled: _editing,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                    enabled: _editing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _middleNameController,
              decoration: const InputDecoration(
                labelText: 'Middle Name',
                border: OutlineInputBorder(),
              ),
              enabled: _editing,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _birthDateController,
                    decoration: const InputDecoration(
                      labelText: 'Birth Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: _editing ? _pickBirthDate : null,
                    enabled: _editing,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sex,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged:
                        _editing ? (v) => setState(() => _sex = v) : null,
                    decoration: const InputDecoration(
                      labelText: 'Sex',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contact Information Section
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              enabled: _editing,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              enabled: _editing,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: _editing,
            ),
            const SizedBox(height: 24),

            // Status Section
            const Text(
              'Account Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: _editing ? (v) => setState(() => _status = v) : null,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // ID Picture Section
            const Text(
              'ID Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _technician!.idPicture != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _technician!.idPicture!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image, size: 40),
                      ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _editing ? () => _pickImage(false) : null,
                  child: const Text('Upload ID Picture'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_editing)
                  ElevatedButton(
                    onPressed: () => setState(() => _editing = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Edit Profile'),
                  ),
                if (_editing) ...[
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _editing = false);
                      _loadTechnicianData(); // Reload original data
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FarmWorkerProvider with ChangeNotifier {
  List<FarmWorker> _farmWorkers = [];
  bool _loading = false;
  String? _error;

  List<FarmWorker> get farmWorkers => _farmWorkers;
  bool get loading => _loading;
  String? get error => _error;

  // FETCH FARM WORKERS ASSIGNED TO SPECIFIC TECHNICIAN
  Future<void> fetchFarmWorkers(String token, int technicianId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final service = FarmWorkerService();
      // THIS WILL NOW ONLY RETURN FARM WORKERS ASSIGNED TO THIS TECHNICIAN
      _farmWorkers = await service.getAssignedFarmWorkers(token, technicianId);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }
}

// ====================================================
// ALL FARM WORKER SCHEDULES PAGE
class AllFarmWorkerSchedulesPage extends StatelessWidget {
  final List farmWorkers;
  final String token;
  const AllFarmWorkerSchedulesPage(
      {Key? key, required this.farmWorkers, required this.token})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Farm Worker Schedules')),
      body: ListView.builder(
        itemCount: farmWorkers.length,
        itemBuilder: (context, index) {
          final fw = farmWorkers[index];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text("${fw.firstName} ${fw.lastName}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(fw.phoneNumber),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SchedulePage(
                      userType: 'Technician',
                      token: token,
                      farmWorkerId: fw.id,
                      farmWorkerName: "${fw.firstName} ${fw.lastName}",
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// DITO RIN MAY CHANGES HANNGANG SA LAST LINE NATO
// Reusable Farm Worker List Widget
class FarmWorkerListWidget extends StatefulWidget {
  final String title;
  final String token;
  final int technicianId;
  final List<Widget> Function(FarmWorker) actionButtons;
  final String emptyStateTitle;
  final String emptyStateSubtitle;
  final IconData emptyStateIcon;

  const FarmWorkerListWidget({
    Key? key,
    required this.title,
    required this.token,
    required this.technicianId,
    required this.actionButtons,
    required this.emptyStateTitle,
    required this.emptyStateSubtitle,
    required this.emptyStateIcon,
  }) : super(key: key);

  @override
  State<FarmWorkerListWidget> createState() => _FarmWorkerListWidgetState();
}

// ====================================================
// FARM WORKER LIST WIDGET STATE
class _FarmWorkerListWidgetState extends State<FarmWorkerListWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedLocation;
  bool _showFilterCard = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

// ====================================================
// FILTER FARM WORKERS
  List<FarmWorker> _filterFarmWorkers(List<FarmWorker> farmWorkers) {
    return farmWorkers.where((fw) {
      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          fw.firstName.toLowerCase().contains(_searchQuery) ||
          fw.lastName.toLowerCase().contains(_searchQuery) ||
          fw.phoneNumber.toLowerCase().contains(_searchQuery) ||
          (fw.address?.toLowerCase().contains(_searchQuery) ?? false);

      bool matchesStatus = _selectedStatus == null || fw.sex == _selectedStatus;

      // Location filter (based on address)
      bool matchesLocation = _selectedLocation == null ||
          (fw.address
                  ?.toLowerCase()
                  .contains(_selectedLocation!.toLowerCase()) ??
              false);

      return matchesSearch && matchesStatus && matchesLocation;
    }).toList();
  }

// ====================================================
// TOGGLE FILTER CARD
  void _toggleFilterCard() {
    setState(() {
      _showFilterCard = !_showFilterCard;
    });
  }

// ====================================================
// BUILD FARM WORKER LIST WIDGET
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Header with back button and title
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  bottom: 10,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Navigate to home screen instead of just going back
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TechnicianLandingScreen(
                              token: widget.token,
                              technicianId: widget.technicianId,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                      icon: Icon(Icons.arrow_back,
                          color: Color(0xFF2C3E50), size: 24),
                      padding: EdgeInsets.zero,
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              // SEARCH AND FILTER SECTION
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF9E9E9E),
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search Farm Worker',
                            hintStyle: TextStyle(
                                color: Colors.grey[500], fontSize: 16),
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey[600], size: 22),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color: Colors.grey[600]),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (_selectedStatus != null ||
                                _selectedLocation != null)
                            ? Color.fromARGB(255, 33, 168, 33)
                            : Color.fromARGB(163, 128, 255, 149),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _toggleFilterCard,
                        icon: Icon(Icons.tune,
                            color: (_selectedStatus != null ||
                                    _selectedLocation != null)
                                ? Colors.white
                                : Color.fromARGB(255, 49, 168, 33),
                            size: 22),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              // ====================================================
              // LIST CONTENT
              Expanded(
                child: Consumer<FarmWorkerProvider>(
                  builder: (context, provider, _) {
                    if (provider.loading) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (provider.error != null) {
                      return Center(child: Text('Error: ${provider.error}'));
                    }
                    final farmWorkers = provider.farmWorkers;
                    final filteredFarmWorkers = _filterFarmWorkers(farmWorkers);
                    if (filteredFarmWorkers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.emptyStateIcon,
                              size: 80,
                              color: Color(0xFFB0B0B0),
                            ),
                            SizedBox(height: 24),
                            Text(
                              farmWorkers.isEmpty
                                  ? widget.emptyStateTitle
                                  : 'No farm workers found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF505050),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              farmWorkers.isEmpty
                                  ? widget.emptyStateSubtitle
                                  : 'Try adjusting your search or filter criteria',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF808080),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    // ====================================================
                    // BUILD FARM WORKER LIST
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredFarmWorkers.length,
                      itemBuilder: (context, index) {
                        final fw = filteredFarmWorkers[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Profile picture
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(104, 217, 154, 254),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    fw.firstName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 118, 31, 165),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${fw.firstName} ${fw.lastName}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      fw.address ?? "No address provided",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      fw.phoneNumber,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Action buttons (customizable)
                              Column(
                                children: widget.actionButtons(fw),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // ====================================================
          // FILTER CARD OVERLAY (APPEARS ON TOP WITH HIGHER Z-INDEX)
          if (_showFilterCard)
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  140, // POSITION BELOW SEARCH
              left: 20,
              right: 20,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFFE0E0E0),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          SizedBox(width: 8),
                          Text(
                            'Filter Options',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: _toggleFilterCard,
                            child: Icon(Icons.close,
                                color: Colors.grey[600], size: 20),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Gender Filter
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        style: TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 14,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.all_inclusive,
                                    color: Colors.grey[600], size: 16),
                                SizedBox(width: 8),
                                Text('All Gender',
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Male',
                            child: Row(
                              children: [
                                Icon(Icons.male,
                                    color: Colors.grey[600], size: 16),
                                SizedBox(width: 8),
                                Text('Male'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Row(
                              children: [
                                Icon(Icons.female,
                                    color: Colors.grey[600], size: 16),
                                SizedBox(width: 8),
                                Text('Female'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                      SizedBox(height: 12),
                      // Location Filter
                      TextFormField(
                        initialValue: _selectedLocation ?? '',
                        decoration: InputDecoration(
                          labelText: 'Location (Address)',
                          labelStyle: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          hintText: 'Enter city, province, or area',
                          hintStyle:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                        style: TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 14,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value.isEmpty ? null : value;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedStatus = null;
                                _selectedLocation = null;
                              });
                            },
                            child: Text(
                              'Clear All',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _toggleFilterCard,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ====================================================
// ASSIGNED FARM WORKERS SCREEN
class AssignedFarmWorkersScreen extends StatelessWidget {
  final String token;
  final int technicianId;

  const AssignedFarmWorkersScreen({
    Key? key,
    required this.token,
    required this.technicianId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FarmWorkerListWidget(
      title: 'Assigned Farm Workers',
      token: token,
      technicianId: technicianId,
      emptyStateTitle: 'No assigned farm workers',
      emptyStateSubtitle: 'Farm workers will appear here when assigned',
      emptyStateIcon: Icons.people_outline,
      actionButtons: (fw) => [
        Container(
          width: 80,
          height: 32,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestScreen(
                    token: token,
                    farmWorker: fw,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'Request',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: 80,
          height: 32,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FarmWorkerDetailScreen(
                    farmWorker: fw,
                    token: token,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF2C3E50),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'View',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ====================================================
// TRANSPLANTING SCHEDULES SCREEN
class TransplantingSchedulesScreen extends StatelessWidget {
  final String token;
  final int technicianId;

  const TransplantingSchedulesScreen({
    Key? key,
    required this.token,
    required this.technicianId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FarmWorkerListWidget(
      title: 'Transplanting Schedules',
      token: token,
      technicianId: technicianId,
      emptyStateTitle: 'No farm workers assigned',
      emptyStateSubtitle: 'Farm workers will appear here when assigned',
      emptyStateIcon: Icons.calendar_today_outlined,
      actionButtons: (fw) => [
        Container(
          width: 100,
          height: 32,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SchedulePage(
                    userType: 'Technician',
                    token: token,
                    farmWorkerId: fw.id,
                    farmWorkerName: "${fw.firstName} ${fw.lastName}",
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF27AE60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'View Schedule',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ====================================================
// REQUEST SUBMISSION SCREEN
class RequestSubmissionScreen extends StatelessWidget {
  final String token;
  final int technicianId;

  const RequestSubmissionScreen({
    Key? key,
    required this.token,
    required this.technicianId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FarmWorkerListWidget(
      title: 'Request Submission',
      token: token,
      technicianId: technicianId,
      emptyStateTitle: 'No farm workers assigned',
      emptyStateSubtitle: 'Farm workers will appear here when assigned',
      emptyStateIcon: Icons.message_outlined,
      actionButtons: (fw) => [
        Container(
          width: 100,
          height: 32,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestScreen(
                    token: token,
                    farmWorker: fw,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF27AE60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              'Send Request',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ====================================================
// NOTIFICATIONS SCREEN
class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Color(0xFF27AE60),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Color(0xFFF8F8F8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 80,
                color: Color(0xFFB0B0B0),
              ),
              SizedBox(height: 24),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF505050),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You\'ll see notifications here when they arrive',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF808080),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
