import 'package:flutter/material.dart';
import 'schedule_page.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

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
                MaterialPageRoute(builder: (_) => ManageProfileScreen()),
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
                                            'Date: \\${s.date!.toLocal().toString().split(' ')[0]}'),
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
    return ManageProfileScreen();
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

// PLACEHOLDER SA MANAGEPROFILESCREEN
class ManageProfileScreen extends StatelessWidget {
  const ManageProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Manage Profile',
          style: TextStyle(fontSize: 20, color: Color(0xFF27AE60))),
    );
  }
}
