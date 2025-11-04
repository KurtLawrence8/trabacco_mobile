import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/coordinator_service.dart';
import '../services/notification_service.dart' as notification_service;
import 'login_screen.dart';
import 'coordinator_pending_reports_screen.dart';
import 'coordinator_pending_requests_screen.dart';
import 'coordinator_pending_planting_reports_screen.dart';
import 'coordinator_pending_harvest_reports_screen.dart';
import 'coordinator_profile_screen.dart';
import 'coordinator_notification_screen.dart';

class CoordinatorLandingScreen extends StatefulWidget {
  final String token;
  final int coordinatorId;

  const CoordinatorLandingScreen({
    Key? key,
    required this.token,
    required this.coordinatorId,
  }) : super(key: key);

  @override
  State<CoordinatorLandingScreen> createState() =>
      _CoordinatorLandingScreenState();
}

class _CoordinatorLandingScreenState extends State<CoordinatorLandingScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _unreadCount = 0;

  // Dashboard metrics
  int _pendingReports = 0;
  int _pendingRequests = 0;
  int _pendingPlantingReports = 0;
  int _pendingHarvestReports = 0;
  int _approvedToday = 0;
  int _reviewedThisWeek = 0;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStatistics();
      _fetchNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh notifications when app comes to foreground
      _fetchNotifications();
    }
  }

  Future<void> _fetchStatistics() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await CoordinatorService.getStatistics(widget.token);
      setState(() {
        _pendingReports = stats['pending_reports'] ?? 0;
        _pendingRequests = stats['pending_requests'] ?? 0;
        _pendingPlantingReports = stats['pending_planting_reports'] ?? 0;
        _pendingHarvestReports = stats['pending_harvest_reports'] ?? 0;
        _approvedToday = stats['approved_today'] ?? 0;
        _reviewedThisWeek = stats['reviewed_this_week'] ?? 0;
        _loadingStats = false;
      });
    } catch (e) {
      setState(() => _loadingStats = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load statistics: $e')),
        );
      }
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      // Get unread notification count for coordinator
      final unreadCount =
          await notification_service.NotificationService.getUnreadCount(
        widget.token,
        coordinatorId: widget.coordinatorId,
      );

      if (mounted) {
        setState(() {
          _unreadCount = unreadCount;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      // Silently fail for notifications
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = AuthService();
      await authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _fetchStatistics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'Area Coordinator Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Statistics Cards
            if (_loadingStats)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  // Pending Items Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Pending Reports',
                          _pendingReports.toString(),
                          Icons.description,
                          Colors.orange,
                          () => setState(() => _selectedIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Pending Requests',
                          _pendingRequests.toString(),
                          Icons.request_page,
                          Colors.blue,
                          () => setState(() => _selectedIndex = 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Planting Reports',
                          _pendingPlantingReports.toString(),
                          Icons.grass,
                          Colors.green,
                          () => setState(() => _selectedIndex = 3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Harvest Reports',
                          _pendingHarvestReports.toString(),
                          Icons.agriculture,
                          Colors.brown,
                          () => setState(() => _selectedIndex = 4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Approved Today',
                          _approvedToday.toString(),
                          Icons.check_circle,
                          Colors.teal,
                          null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Reviewed This Week',
                          _reviewedThisWeek.toString(),
                          Icons.calendar_today,
                          Colors.purple,
                          null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildQuickAction(
              'Review Reports',
              'Review pending accomplishment reports',
              Icons.description,
              Colors.orange,
              () => setState(() => _selectedIndex = 1),
            ),
            _buildQuickAction(
              'Review Harvest Reports',
              'Review pending harvest reports',
              Icons.agriculture,
              Colors.brown,
              () => setState(() => _selectedIndex = 4),
            ),
            _buildQuickAction(
              'Review Requests',
              'Review pending supply/cash/equipment requests',
              Icons.request_page,
              Colors.blue,
              () => setState(() => _selectedIndex = 2),
            ),
            _buildQuickAction(
              'Review Planting Reports',
              'Review pending planting reports',
              Icons.grass,
              Colors.green,
              () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool fullWidth = false,
  }) {
    final card = Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 32),
                  if (onTap != null)
                    Icon(Icons.arrow_forward, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    return fullWidth ? card : card;
  }

  Widget _buildQuickAction(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(),
      CoordinatorPendingReportsScreen(token: widget.token),
      CoordinatorPendingRequestsScreen(token: widget.token),
      CoordinatorPendingPlantingReportsScreen(token: widget.token),
      CoordinatorPendingHarvestReportsScreen(token: widget.token),
      CoordinatorProfileScreen(
        token: widget.token,
        coordinatorId: widget.coordinatorId,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Area Coordinator'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoordinatorNotificationScreen(
                        token: widget.token,
                        coordinatorId: widget.coordinatorId,
                      ),
                    ),
                  ).then((_) => _fetchNotifications());
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, size: 20),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description, size: 20),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page, size: 20),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grass, size: 20),
            label: 'Planting',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture, size: 20),
            label: 'Harvest',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 20),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
