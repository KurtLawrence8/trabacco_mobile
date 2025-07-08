import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'technician_report_screen.dart';
import 'schedule_page.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import 'farm_worker_detail_screen.dart';
import 'request_list_widget.dart';
import '../services/auth_service.dart';

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
  late Future<List<Schedule>> _futureSchedules;
  final ScheduleService _service = ScheduleService();

  @override
  void initState() {
    super.initState();
    _futureSchedules = _service.fetchTodaySchedules(widget.token);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FarmWorkerProvider>(context, listen: false)
          .fetchFarmWorkers(widget.token, widget.technicianId);
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF27AE60),
      elevation: 2,
      title: Row(
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
                children: [
                  Icon(Icons.settings, color: Color(0xFF27AE60)),
                  SizedBox(width: 8),
                  Text('Manage Profile')
                ],
              ),
            ),
            PopupMenuItem(
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
        SizedBox(width: 12),
      ],
      iconTheme: IconThemeData(color: Colors.white),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Welcome, Technician!',
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
                Text("Assigned Farm Workers",
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
                                  title: Text(
                                      '\\${fw.firstName} \\${fw.lastName}',
                                      style: TextStyle(
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
                Divider(),
                Text("Today's Schedules",
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
                      return const Text('No schedules for today.',
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
                                  title: Text(
                                    s.title,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Date: \\${s.dateScheduled.toLocal().toString().split(' ')[0]}'),
                                      Text('Activity: \\${s.title}'),
                                      Text('Status: \\${s.status}'),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: s.status == 'Completed' ? Colors.green : Colors.orange,
                                    ),
                                    onPressed: s.status == 'Completed'
                                        ? null
                                        : () async {
                                            await _service.updateScheduleStatus(s.id, 'Completed', widget.token);
                                            setState(() {
                                              _futureSchedules = _service.fetchTodaySchedules(widget.token);
                                            });
                                          },
                                    child: Text(s.status == 'Completed' ? 'Done' : 'Mark as Done'),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SchedulePage(
                              userType: 'Technician', token: widget.token),
                        ),
                      );
                    },
                    child: Text('View All',
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
    return SchedulePage(userType: 'Technician', token: widget.token);
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
          return Center(
              child: Text('No notifications found.',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => SizedBox(height: 14),
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
                    SizedBox(height: 8),
                    Text(n.body, style: TextStyle(fontSize: 15)),
                    SizedBox(height: 8),
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
    return Center(
      child: Text('Reports',
          style: TextStyle(fontSize: 20, color: Color(0xFF222B45))),
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
      child: Text('Manage Profile',
          style: TextStyle(fontSize: 20, color: Color(0xFF27AE60))),
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

  Future<void> fetchFarmWorkers(String token, int technicianId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final service = FarmWorkerService();
      _farmWorkers = await service.getAssignedFarmWorkers(token, technicianId);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }
}
