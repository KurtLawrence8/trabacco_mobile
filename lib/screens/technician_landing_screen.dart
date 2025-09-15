import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'technician_report_screen.dart';
import 'schedule_page.dart';
import 'technician_profile_screen.dart';

import 'package:provider/provider.dart';
import 'farm_worker_detail_screen.dart';
import 'technician_farms_screen.dart';
import '../config/api_config.dart';
import 'request_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Notification state
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();

    // FETCH FARM WORKERS ASSIGNED TO THIS SPECIFIC TECHNICIAN
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FarmWorkerProvider>(context, listen: false)
          .fetchFarmWorkers(widget.token, widget.technicianId);
      // Fetch notifications on app start
      _fetchNotifications();
    });
  }

  // ====================================================
  // FETCH NOTIFICATIONS
  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data['data'] ?? []);
          _unreadCount =
              _notifications.where((n) => n['read_at'] == null).length;
        });
      } else {
        print('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  // ====================================================
  // BUILD NAVIGATION APP BAR
  PreferredSizeWidget _buildNavAppBar(String title) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2C3E50),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
        onPressed: () {
          setState(() {
            _selectedIndex = 0; // Go back to dashboard
          });
        },
      ),
    );
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
          padding: const EdgeInsets.all(12),
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
                        const Text('Hi Technician!',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50))),
                        const SizedBox(height: 2),
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
                      Stack(
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
                                    builder: (_) => NotificationsScreen(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.notifications_outlined,
                                  color: Colors.grey[700], size: 16),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          // Unread count badge
                          if (_unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  _unreadCount > 99
                                      ? '99+'
                                      : _unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // ====================================================
                      // POPUP MENU BUTTON
                      const SizedBox(width: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255),
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.person,
                              color: Color.fromARGB(255, 180, 180, 180),
                              size: 16),
                          padding: EdgeInsets.zero,
                          onSelected: (value) async {
                            if (value == 'logout') {
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh farm workers and notifications
        Provider.of<FarmWorkerProvider>(context, listen: false)
            .fetchFarmWorkers(widget.token, widget.technicianId);
        await _fetchNotifications();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
        child: Column(
          children: [
            // ====================================================
            // QUICK ACTIONS SECTION
            const Row(
              children: [
                Icon(Icons.rocket_launch,
                    color: Color.fromARGB(255, 0, 0, 0), size: 20),
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
              physics: const NeverScrollableScrollPhysics(),
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
                  color: const Color(0xFF6366F1), // Indigo
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
                  color: const Color(0xFF10B981), // Emerald
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
                  color: const Color(0xFFF59E0B), // Amber
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
                  color: const Color(0xFFEF4444), // Red
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TechnicianReportScreen(
                          token: widget.token,
                          technicianId: widget.technicianId,
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
                  color: const Color(0xFF3B82F6), // Blue
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TechnicianFarmsScreen(),
                      ),
                    );
                  },
                ),
// ====================================================
// NOTIFICATIONS
                _buildQuickActionCard(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notifications',
                  subtitle: _unreadCount > 0
                      ? '$_unreadCount unread notifications'
                      : 'View all notifications',
                  color: const Color(0xFF8B5CF6), // Violet
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(),
                      ),
                    ).then((_) {
                      // Refresh notifications when returning from notification screen
                      _fetchNotifications();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
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
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
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
    return TechnicianReportScreen(
        token: widget.token, technicianId: widget.technicianId);
  }

  Widget _buildManageProfile() {
    return TechnicianProfileScreen(technicianId: widget.technicianId);
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
  Widget _buildCenterReportButton() {
    final isSelected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = 2;
        });
      },
      // ====================================================
      // CENTER REPORT BUTTON
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular icon with green outline
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF27AE60) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF27AE60)
                    : const Color(0xFF8F9BB3),
                width: 2,
              ),
            ),
            child: Icon(
              isSelected ? Icons.assessment : Icons.assessment_outlined,
              color: isSelected ? Colors.white : const Color(0xFF8F9BB3),
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          // Label
          Text(
            'Report',
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF27AE60)
                  : const Color(0xFF8F9BB3),
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
      RequestSubmissionScreen(
        token: widget.token,
        technicianId: widget.technicianId,
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? _buildAppBar()
          : _selectedIndex == 2
              ? _buildNavAppBar('Reports')
              : _selectedIndex == 3
                  ? _buildNavAppBar('Profile')
                  : null,
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
                // Center Report Button (special circular button)
                _buildCenterReportButton(),
                // Request
                _buildNavItem(
                  icon: Icons.send_outlined,
                  activeIcon: Icons.send,
                  label: 'Request',
                  index: 4,
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
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF2C3E50), size: 24),
                      padding: EdgeInsets.zero,
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // SEARCH AND FILTER SECTION
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                            color: const Color(0xFF9E9E9E),
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
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (_selectedStatus != null ||
                                _selectedLocation != null)
                            ? const Color.fromARGB(255, 33, 168, 33)
                            : const Color.fromARGB(163, 128, 255, 149),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _toggleFilterCard,
                        icon: Icon(Icons.tune,
                            color: (_selectedStatus != null ||
                                    _selectedLocation != null)
                                ? Colors.white
                                : const Color.fromARGB(255, 49, 168, 33),
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
                      return const Center(child: CircularProgressIndicator());
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
                              color: const Color(0xFFB0B0B0),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              farmWorkers.isEmpty
                                  ? widget.emptyStateTitle
                                  : 'No farm workers found',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF505050),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              farmWorkers.isEmpty
                                  ? widget.emptyStateSubtitle
                                  : 'Try adjusting your search or filter criteria',
                              style: const TextStyle(
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredFarmWorkers.length,
                      itemBuilder: (context, index) {
                        final fw = filteredFarmWorkers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Profile picture
                              Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(104, 217, 154, 254),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    fw.firstName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 118, 31, 165),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${fw.firstName} ${fw.lastName}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      fw.address ?? "No address provided",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      fw.phoneNumber,
                                      style: const TextStyle(
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          const Text(
                            'Filter Options',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _toggleFilterCard,
                            child: Icon(Icons.close,
                                color: Colors.grey[600], size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        style: const TextStyle(
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
                                const SizedBox(width: 8),
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
                                const SizedBox(width: 8),
                                const Text('Male'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Row(
                              children: [
                                Icon(Icons.female,
                                    color: Colors.grey[600], size: 16),
                                const SizedBox(width: 8),
                                const Text('Female'),
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
                      const SizedBox(height: 12),
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
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
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
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 14,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value.isEmpty ? null : value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
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
                            child: const Text('Apply'),
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
        SizedBox(
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
            child: const Text(
              'Request',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
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
              foregroundColor: const Color(0xFF2C3E50),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
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
        SizedBox(
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
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
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
        SizedBox(
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
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
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
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF27AE60),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF8F8F8),
        child: const Center(
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

// ====================================================
// NOTIFICATION SERVICE
class NotificationService {
  static String get _baseUrl => ApiConfig.baseUrl;

  // Fetch notifications
  static Future<List<Map<String, dynamic>>> fetchNotifications(
      String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception(
            'Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  // Mark notification as read
  static Future<bool> markAsRead(String token, int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notifications/$notificationId/mark-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read
  static Future<bool> markAllAsRead(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get unread count
  static Future<int> getUnreadCount(String token) async {
    try {
      final notifications = await fetchNotifications(token);
      return notifications.where((n) => n['read_at'] == null).length;
    } catch (e) {
      return 0;
    }
  }
}
