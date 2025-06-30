import 'package:flutter/material.dart';
import 'schedule_page.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class FarmWorkerLandingScreen extends StatefulWidget {
  final String token;
  const FarmWorkerLandingScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<FarmWorkerLandingScreen> createState() => _FarmWorkerLandingScreenState();
}

class _FarmWorkerLandingScreenState extends State<FarmWorkerLandingScreen> {
  int _selectedIndex = 0;
  late Future<List<Schedule>> _futureSchedules;
  final ScheduleService _service = ScheduleService();

  @override
  void initState() {
    super.initState();
    _futureSchedules = _service.fetchTodaySchedules(widget.token);
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF27AE60),
      elevation: 2,
      title: Row(
        children: [
          Icon(Icons.agriculture, color: Colors.white),
          SizedBox(width: 8),
          Text('Tabacco', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: CircleAvatar(
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
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [Icon(Icons.settings, color: Color(0xFF27AE60)), SizedBox(width: 8), Text('Manage Profile')],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('Logout')],
              ),
            ),
          ],
        ),
        SizedBox(width: 12),
      ],
      iconTheme: IconThemeData(color: Colors.white),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Welcome, Farm Worker!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF222B45))),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Schedules", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2E5BFF))),
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
                      return const Text('No schedules for today.', style: TextStyle(color: Colors.grey));
                    }
                    final preview = schedules.take(3).toList();
                    return Column(
                      children: preview.map((s) => Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(s.title, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${s.description}\n${s.startTime} - ${s.endTime}'),
                        ),
                      )).toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SchedulePage(userType: 'Farmer', token: widget.token),
                        ),
                      );
                    },
                    child: Text('View All', style: TextStyle(color: Color(0xFF2E5BFF))),
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
    return SchedulePage(userType: 'Farmer', token: widget.token);
  }

  Widget _buildNotifications() {
    return Center(
      child: Text('Notifications', style: TextStyle(fontSize: 20, color: Color(0xFF222B45))),
    );
  }

  Widget _buildReports() {
    return Center(
      child: Text('Reports', style: TextStyle(fontSize: 20, color: Color(0xFF222B45))),
    );
  }

  Widget _buildManageProfile() {
    return ManageProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildDashboard(),
      _buildSchedule(),
      _buildNotifications(),
      _buildReports(),
      _buildManageProfile(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF27AE60),
            unselectedItemColor: Color(0xFF8F9BB3),
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

// Placeholder for ManageProfileScreen
class ManageProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Manage Profile', style: TextStyle(fontSize: 20, color: Color(0xFF27AE60))),
    );
  }
}
