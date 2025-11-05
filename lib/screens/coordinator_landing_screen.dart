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

  // Coordinator data
  Map<String, dynamic>? _coordinator;
  bool _loadingCoordinator = false;

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
      _fetchCoordinatorData();
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

  Future<void> _fetchCoordinatorData() async {
    if (!mounted) return;
    setState(() => _loadingCoordinator = true);
    try {
      final coordinatorData = await CoordinatorService.getCoordinatorDetails(
        widget.token,
        widget.coordinatorId,
      );
      if (mounted) {
        setState(() {
          _coordinator = coordinatorData;
          _loadingCoordinator = false;
        });
      }
    } catch (e) {
      print('Error fetching coordinator data: $e');
      if (mounted) {
        setState(() => _loadingCoordinator = false);
      }
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

  // ====================================================
  // BUILD COORDINATOR GREETING
  String _buildCoordinatorGreeting() {
    if (_loadingCoordinator) {
      return 'Hi Coordinator!';
    }

    if (_coordinator != null) {
      final firstName = _coordinator!['first_name'] ?? '';
      final lastName = _coordinator!['last_name'] ?? '';
      final middleName = _coordinator!['middle_name'];

      // Format: "Hi [LastName], [FirstName] [MiddleName]!"
      String fullName = lastName;
      if (firstName.isNotEmpty) {
        fullName += ', $firstName';
      }
      if (middleName != null && middleName.toString().isNotEmpty) {
        fullName += ' $middleName';
      }

      return 'Hi $fullName!';
    }

    return 'Hi Coordinator!';
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _fetchCoordinatorData(),
          _fetchStatistics(),
          _fetchNotifications(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // DASHBOARD METRICS SECTION
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard,
                        color: Color.fromARGB(255, 0, 0, 0), size: 20),
                    SizedBox(width: 8),
                    Text('Overview',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45))),
                  ],
                ),
                const SizedBox(height: 16),
                // Statistics Grid
                if (_loadingStats)
                  const Center(child: CircularProgressIndicator())
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _buildStatCard(
                        'Pending Reports',
                        _pendingReports.toString(),
                        Icons.description,
                        const Color(0xFFF59E0B),
                        () => setState(() => _selectedIndex = 1),
                      ),
                      _buildStatCard(
                        'Pending Requests',
                        _pendingRequests.toString(),
                        Icons.send_rounded,
                        const Color(0xFF3B82F6),
                        () => setState(() => _selectedIndex = 2),
                      ),
                      _buildStatCard(
                        'Planting Reports',
                        _pendingPlantingReports.toString(),
                        Icons.grain,
                        const Color(0xFF10B981),
                        () => setState(() => _selectedIndex = 3),
                      ),
                      _buildStatCard(
                        'Harvest Reports',
                        _pendingHarvestReports.toString(),
                        Icons.local_shipping,
                        const Color(0xFF8B4513),
                        () => setState(() => _selectedIndex = 4),
                      ),
                      _buildStatCard(
                        'Approved Today',
                        _approvedToday.toString(),
                        Icons.check_circle,
                        const Color(0xFF14B8A6),
                        null,
                      ),
                      _buildStatCard(
                        'Reviewed This Week',
                        _reviewedThisWeek.toString(),
                        Icons.calendar_today,
                        const Color(0xFF8B5CF6),
                        null,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),
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
            // Quick Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildQuickActionCard(
                  icon: Icons.description_rounded,
                  title: 'Review Reports',
                  subtitle: 'Review pending accomplishment reports',
                  color: const Color(0xFFF59E0B),
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _buildQuickActionCard(
                  icon: Icons.local_shipping,
                  title: 'Harvest Reports',
                  subtitle: 'Review pending harvest reports',
                  color: const Color(0xFF8B4513),
                  onTap: () => setState(() => _selectedIndex = 4),
                ),
                _buildQuickActionCard(
                  icon: Icons.send_rounded,
                  title: 'Review Requests',
                  subtitle: 'Review pending supply/cash/equipment requests',
                  color: const Color(0xFF3B82F6),
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _buildQuickActionCard(
                  icon: Icons.grain,
                  title: 'Planting Reports',
                  subtitle: 'Review pending planting reports',
                  color: const Color(0xFF10B981),
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // BUILD STAT CARD
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
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
                  // Arrow indicator for clickable cards
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
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
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          color: color.withOpacity(0.08),
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
              // Header with icon and arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
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
                  // Arrow indicator for clickable cards
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ],
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

  // ====================================================
  // BUILD APP BAR WITH HEADER
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
                  // Profile icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _buildCoordinatorGreeting(),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50)),
                        ),
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
                                    builder: (context) =>
                                        CoordinatorNotificationScreen(
                                      token: widget.token,
                                      coordinatorId: widget.coordinatorId,
                                    ),
                                  ),
                                ).then((_) => _fetchNotifications());
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
                      // LOGOUT BUTTON
                      const SizedBox(width: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout,
                              color: Colors.red, size: 16),
                          padding: EdgeInsets.zero,
                          onPressed: _handleLogout,
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

  // ====================================================
  // BUILD NAVIGATION ITEM
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (mounted && _selectedIndex != index) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF27AE60).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? const Color(0xFF27AE60)
                    : const Color(0xFF757575),
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF27AE60)
                      : const Color(0xFF757575),
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(),
      CoordinatorPendingReportsScreen(
        token: widget.token,
        onBack: () => setState(() => _selectedIndex = 0),
      ),
      CoordinatorPendingRequestsScreen(
        token: widget.token,
        onBack: () => setState(() => _selectedIndex = 0),
      ),
      CoordinatorPendingPlantingReportsScreen(
        token: widget.token,
        onBack: () => setState(() => _selectedIndex = 0),
      ),
      CoordinatorPendingHarvestReportsScreen(
        token: widget.token,
        onBack: () => setState(() => _selectedIndex = 0),
      ),
      CoordinatorProfileScreen(
        token: widget.token,
        coordinatorId: widget.coordinatorId,
        onBack: () => setState(() => _selectedIndex = 0),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0 ? _buildAppBar() : null,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        // ====================================================
        // GOOGLE-STYLE BOTTOM NAVIGATION BAR
        child: SafeArea(
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Home
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    index: 0,
                  ),
                ),
                // Reports
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.description_outlined,
                    activeIcon: Icons.description,
                    label: 'Reports',
                    index: 1,
                  ),
                ),
                // Requests
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.send_rounded,
                    activeIcon: Icons.send_rounded,
                    label: 'Requests',
                    index: 2,
                  ),
                ),
                // Planting
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.grain_outlined,
                    activeIcon: Icons.grain,
                    label: 'Planting',
                    index: 3,
                  ),
                ),
                // Harvest
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.local_shipping_outlined,
                    activeIcon: Icons.local_shipping,
                    label: 'Harvest',
                    index: 4,
                  ),
                ),
                // Profile
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    index: 5,
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
