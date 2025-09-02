import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'technician_report_screen.dart';
import 'schedule_page.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import 'package:provider/provider.dart';
import 'farm_worker_detail_screen.dart';
import 'technician_farms_screen.dart';
import '../models/user_model.dart' show NotificationModel, Technician;
import '../services/auth_service.dart' show TechnicianService;
import '../config/api_config.dart';

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
    // _futureSchedules = _service.fetchTodaySchedules(widget.token); // Removed
    // _futureFarmWorkersWithTodaySchedules = _service.fetchFarmWorkersWithTodaySchedules(widget.token); // Only use if backend is implemented

    // FETCH FARM WORKERS ASSIGNED TO THIS SPECIFIC TECHNICIAN
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FarmWorkerProvider>(context, listen: false)
          .fetchFarmWorkers(widget.token, widget.technicianId);
    });
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
                    builder: (_) =>
                        ManageProfileScreen(technicianId: widget.technicianId)),
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
      ],
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Welcome, Technician!',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222B45))),
        const SizedBox(height: 16),
        // Button to view farms of assigned farm workers
        ElevatedButton.icon(
          icon: Icon(Icons.map, color: Colors.white),
          label: Text('View My Workers\' Farms on Map/List'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF27AE60),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TechnicianFarmsScreen(),
              ),
            );
          },
        ),
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
                const Text("Assigned Farm Workers",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2E5BFF))),
                const SizedBox(height: 8),
                Consumer<FarmWorkerProvider>(
                  builder: (context, provider, _) {
                    if (provider.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.error != null) {
                      return Center(child: Text('Error: \\${provider.error}'));
                    }
                    final farmWorkers = provider.farmWorkers;
                    if (farmWorkers.isEmpty) {
                      return const Text('No assigned farm workers.',
                          style: TextStyle(color: Colors.grey));
                    }
                    return Column(
                      children: farmWorkers
                          .map((fw) => Card(
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text("${fw.firstName} ${fw.lastName}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(fw.phoneNumber),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FarmWorkerDetailScreen(
                                            farmWorker: fw,
                                            token: widget.token),
                                      ),
                                    );
                                  },
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text("Today's Schedules",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2E5BFF))),
                const SizedBox(height: 8),
                Consumer<FarmWorkerProvider>(
                  builder: (context, provider, _) {
                    if (provider.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.error != null) {
                      return Center(child: Text('Error: \\${provider.error}'));
                    }
                    final farmWorkers = provider.farmWorkers;
                    if (farmWorkers.isEmpty) {
                      return const Text('No assigned farm workers.',
                          style: TextStyle(color: Colors.grey));
                    }
                    return Column(
                      children: farmWorkers
                          .map((fw) => Card(
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text("${fw.firstName} ${fw.lastName}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(fw.phoneNumber),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SchedulePage(
                                          userType: 'Technician',
                                          token: widget.token,
                                          farmWorkerId: fw.id,
                                          farmWorkerName:
                                              "${fw.firstName} ${fw.lastName}",
                                        ),
                                      ),
                                    );
                                  },
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
                      final provider = Provider.of<FarmWorkerProvider>(context,
                          listen: false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllFarmWorkerSchedulesPage(
                            farmWorkers: provider.farmWorkers,
                            token: widget.token,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All',
                        style: TextStyle(color: Color(0xFF2E5BFF))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchedule() {
    // Show a message instead of calling with ID 0
    return const Center(
        child: Text('Please select a farm worker to view schedules.'));
  }

  Widget _buildNotifications() {
    return FutureBuilder<List<NotificationModel>>(
      future: NotificationService().getNotifications(widget.token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return const Center(
              child: Text('No notifications found.',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final n = notifications[i];
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: n.title.contains('Rejected')
                                ? Colors.red
                                : Colors.green)),
                    const SizedBox(height: 8),
                    Text(n.body, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 8),
                    Text('Received: ${n.createdAt.toLocal()}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReports() {
    return TechnicianReportScreen(
        token: widget.token, technicianId: widget.technicianId);
  }

  Widget _buildManageProfile() {
    return ManageProfileScreen(technicianId: widget.technicianId);
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

class ManageProfileScreen extends StatefulWidget {
  final int technicianId;
  const ManageProfileScreen({super.key, required this.technicianId});

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

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

        print('Sending update data: $updateData');

        final updatedTechnician = await _technicianService
            .updateTechnicianProfile(token, widget.technicianId, updateData);

        setState(() {
          _technician = updatedTechnician;
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
