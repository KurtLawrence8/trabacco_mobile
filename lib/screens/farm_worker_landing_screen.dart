import 'package:flutter/material.dart';
import 'schedule_page.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart' show FarmWorkerProfile;
import '../services/auth_service.dart' show FarmWorkerProfileService;
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class FarmWorkerLandingScreen extends StatefulWidget {
  final String token;
  const FarmWorkerLandingScreen({Key? key, required this.token})
      : super(key: key);

  @override
  State<FarmWorkerLandingScreen> createState() =>
      _FarmWorkerLandingScreenState();
}

class _FarmWorkerLandingScreenState extends State<FarmWorkerLandingScreen> {
  int _selectedIndex = 0;
  late Future<List<Schedule>> _futureSchedules;
  final ScheduleService _service = ScheduleService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        if (_user != null) {
          _futureSchedules =
              _service.fetchSchedulesForFarmWorker(_user!.id, widget.token);
        }
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF27AE60),
      elevation: 2,
      title: const Row(
        children: [
          Icon(Icons.agriculture, color: Colors.white),
          SizedBox(width: 8),
          Text('Tabacco',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF27AE60)),
          ),
          onSelected: (value) async {
            if (value == 'profile') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FarmWorkerManageProfileScreen()),
              );
            } else if (value == 'logout') {
              await AuthService().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Color(0xFF27AE60)),
                  SizedBox(width: 8),
                  Text('Manage Profile')
                ],
              ),
            ),
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
        const SizedBox(width: 12),
      ],
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildDashboard() {
    final DateFormat dateFormatter = DateFormat('MM/dd/yyyy');
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Welcome, Farm Worker!',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222B45))),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Schedules",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2E5BFF))),
                const SizedBox(height: 8),
                FutureBuilder<List<Schedule>>(
                  future: _futureSchedules,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: \\${snapshot.error}'));
                    }
                    final schedules = snapshot.data ?? [];
                    if (schedules.isEmpty) {
                      return const Text('No schedules found.',
                          style: TextStyle(color: Colors.grey));
                    }
                    final preview = schedules.take(3).toList();
                    return Column(
                      children: preview
                          .map((s) => Card(
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text(s.activity,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (s.date != null)
                                        Text(
                                            'Date: \\${dateFormatter.format(s.date!.toLocal())}'),
                                      if (s.remarks != null &&
                                          s.remarks!.isNotEmpty)
                                        Text('Remarks: \\${s.remarks}'),
                                      if (s.numLaborers != null)
                                        Text('Laborers: \\${s.numLaborers}'),
                                      if (s.unit != null && s.unit!.isNotEmpty)
                                        Text('Unit: \\${s.unit}'),
                                      if (s.budget != null)
                                        Text('Budget: \\${s.budget}'),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      if (_user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SchedulePage(
                              userType: 'Farmer',
                              token: widget.token,
                              farmWorkerId: _user!.id,
                              farmWorkerName: _user!.name,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('View All',
                        style: TextStyle(color: Color(0xFF2E5BFF))),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_user != null)
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFFF8F9FA),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle,
                          size: 40, color: Color(0xFF27AE60)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_user!.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222B45))),
                          if (_user!.email != null)
                            Text(_user!.email!,
                                style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_user!.roles != null && _user!.roles!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.badge,
                            size: 18, color: Color(0xFF27AE60)),
                        const SizedBox(width: 6),
                        Text(_user!.roles!.join(', '),
                            style: const TextStyle(color: Color(0xFF27AE60))),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSchedule() {
    if (_user != null && _user!.id != 0) {
      return SchedulePage(
        userType: 'Farmer',
        token: widget.token,
        farmWorkerId: _user!.id,
        farmWorkerName: _user!.name,
      );
    } else {
      return const Center(child: Text('Please log in as a valid farm worker.'));
    }
  }

  Widget _buildNotifications() {
    return const Center(
      child: Text('Notifications',
          style: TextStyle(fontSize: 20, color: Color(0xFF222B45))),
    );
  }

  Widget _buildReports() {
    return const Center(
      child: Text('Reports',
          style: TextStyle(fontSize: 20, color: Color(0xFF222B45))),
    );
  }

  Widget _buildManageProfile() {
    return FarmWorkerManageProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(),
      _buildSchedule(),
      _buildNotifications(),
      _buildReports(),
      _buildManageProfile(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF27AE60),
            unselectedItemColor: const Color(0xFF8F9BB3),
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            elevation: 0,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.event_note),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Notification',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Report',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FarmWorkerManageProfileScreen extends StatefulWidget {
  const FarmWorkerManageProfileScreen({super.key});

  @override
  State<FarmWorkerManageProfileScreen> createState() =>
      _FarmWorkerManageProfileScreenState();
}

class _FarmWorkerManageProfileScreenState
    extends State<FarmWorkerManageProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmWorkerService = FarmWorkerProfileService();
  bool _loading = false;
  bool _editing = false;
  FarmWorkerProfile? _farmWorker;

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _birthDateController;
  String? _sex;
  String? _status;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadFarmWorkerData();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _birthDateController = TextEditingController();
  }

  Future<void> _loadFarmWorkerData() async {
    setState(() => _loading = true);
    try {
      final token = await AuthService().getToken();
      final user = await AuthService().getCurrentUser();
      print('Token available: ${token != null}');
      print('User ID: ${user?.id}');
      print('API Base URL: ${ApiConfig.baseUrl}');

      if (token != null && user != null) {
        // Test API connection first
        final isApiReachable =
            await _farmWorkerService.testApiConnection(token);
        print('API reachable: $isApiReachable');

        final farmWorker =
            await _farmWorkerService.getFarmWorkerProfile(token, user.id);
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
          _status = farmWorker.status;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to load farm worker data - No token available')),
        );
      }
    } catch (e) {
      print('Error loading farm worker data: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      if (e.toString().contains('Exception:')) {
        print('Exception message: ${e.toString().split('Exception:')[1]}');
      }
      // Fallback: Show sample data for development/testing
      setState(() {
        _farmWorker = FarmWorkerProfile(
          id: 1,
          firstName: 'Sample',
          lastName: 'Farm Worker',
          middleName: 'M.',
          birthDate: DateTime(1990, 1, 1),
          sex: 'Male',
          phoneNumber: '+1234567890',
          address: '123 Farm Street, Farm City',
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
        _status = _farmWorker!.status;
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
      final user = await AuthService().getCurrentUser();
      if (token != null && user != null) {
        final updateData = <String, dynamic>{};

        // Only add non-null and non-empty values
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
        if (_status != null && _status!.isNotEmpty) {
          updateData['status'] = _status;
        }

        print('Sending update data: $updateData');

        final updatedFarmWorker = await _farmWorkerService
            .updateFarmWorkerProfile(token, user.id, updateData);

        setState(() {
          _farmWorker = updatedFarmWorker;
          _editing = false;
        });

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
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image picker not implemented in this demo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_farmWorker == null) {
      return const Center(child: Text('No farm worker data available'));
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
                  backgroundImage: _farmWorker!.profilePicture != null
                      ? NetworkImage(_farmWorker!.profilePicture!)
                      : null,
                  child: _farmWorker!.profilePicture == null
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
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                _farmWorker!.idPicture != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _farmWorker!.idPicture!,
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
                      _loadFarmWorkerData(); // Reload original data
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
