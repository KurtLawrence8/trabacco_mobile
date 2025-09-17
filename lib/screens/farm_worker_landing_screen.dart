import 'package:flutter/material.dart';
import 'schedule_page.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart' as notification_service;
import '../models/user_model.dart';
import '../services/auth_service.dart' show RequestService;
import 'supply_cash_screen.dart';
import 'farm_worker_profile_screen.dart';
import 'notification_screen.dart';
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
  Future<List<RequestModel>>? _futureRequests;
  final RequestService _requestService = RequestService();
  User? _user;

  // Notification state
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Fetch notifications on app start
    _fetchNotifications();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        if (_user != null) {
          _futureRequests =
              _requestService.getRequestsForFarmWorker(widget.token, _user!.id);
        }
      });
    }
  }

  // ====================================================
  // FETCH NOTIFICATIONS
  Future<void> _fetchNotifications() async {
    try {
      if (_user != null) {
        final unreadCount = await notification_service.NotificationService.getUnreadCount(
          widget.token, 
          farmWorkerId: _user!.id // Use farm worker ID for filtering
        );
        
        setState(() {
          _unreadCount = unreadCount;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  // ====================================================
  // BUILD APP BAR
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
                        const Text('Hi Farm Worker!',
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
                                if (_user != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NotificationScreen(
                                        token: widget.token,
                                        technician: Technician(
                                          id: _user!.id,
                                          firstName: _user!.name.split(' ').first,
                                          lastName: _user!.name.split(' ').length > 1 
                                              ? _user!.name.split(' ').skip(1).join(' ')
                                              : '',
                                          emailAddress: _user!.email ?? '',
                                          status: 'Active',
                                        ),
                                      ),
                                    ),
                                  );
                                }
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
        // Refresh data
        _loadUser();
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
                  icon: Icons.calendar_today_rounded,
                  title: 'My Schedules',
                  subtitle: 'View my work schedules',
                  color: const Color(0xFF10B981), // Emerald
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1; // Switch to Schedule tab
                    });
                  },
                ),
// ====================================================
// REQUESTS
                _buildQuickActionCard(
                  icon: Icons.request_quote_rounded,
                  title: 'My Requests',
                  subtitle: 'View my submitted requests',
                  color: const Color(0xFFF59E0B), // Amber
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2; // Switch to Requests tab
                    });
                  },
                ),
// ====================================================
// SUPPLY DISTRIBUTIONS
                _buildQuickActionCard(
                  icon: Icons.inventory_rounded,
                  title: 'Supply Records',
                  subtitle: 'View supply distributions',
                  color: const Color(0xFF3B82F6), // Blue
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupplyCashScreen(
                          token: widget.token,
                          user: _user,
                        ),
                      ),
                    );
                  },
                ),
// ====================================================
// CASH DISTRIBUTIONS
                _buildQuickActionCard(
                  icon: Icons.attach_money_rounded,
                  title: 'Cash Records',
                  subtitle: 'View cash distributions',
                  color: const Color(0xFF8B5CF6), // Violet
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupplyCashScreen(
                          token: widget.token,
                          user: _user,
                        ),
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
                  color: const Color(0xFFEF4444), // Red
                  onTap: () {
                    if (_user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationScreen(
                            token: widget.token,
                            technician: Technician(
                              id: _user!.id,
                              firstName: _user!.name.split(' ').first,
                              lastName: _user!.name.split(' ').length > 1 
                                  ? _user!.name.split(' ').skip(1).join(' ')
                                  : '',
                              emailAddress: _user!.email ?? '',
                              status: 'Active',
                            ),
                          ),
                        ),
                      ).then((_) {
                        // Refresh notifications when returning from notification screen
                        _fetchNotifications();
                      });
                    }
                  },
                ),
// ====================================================
// PROFILE
                _buildQuickActionCard(
                  icon: Icons.person_rounded,
                  title: 'My Profile',
                  subtitle: 'Manage my profile',
                  color: const Color(0xFF6366F1), // Indigo
                  onTap: () {
                    setState(() {
                      _selectedIndex = 3; // Switch to Profile tab
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

  Widget _buildRequests() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      body: _futureRequests == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : FutureBuilder<List<RequestModel>>(
              future: _futureRequests,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.request_page_outlined,
                          size: 64,
                          color: const Color(0xFF4CAF50).withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Requests Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your requests will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final requests = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRequestCard(request),
                      );
                    },
                  );
                }
              },
            ),
    );
  }

  Widget _buildManageProfile() {
    if (_user == null) {
      return const Center(
        child: Text('Loading user data...'),
      );
    }

    return FarmWorkerProfileScreen(
      farmWorkerId: _user!.id,
    );
  }

  Color _getRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'pending':
        return Colors.orange;
      case 'distributed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRequestStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'distributed':
        return Icons.local_shipping;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildRequestCard(RequestModel request) {
    final statusColor = _getRequestStatusColor(request.status ?? 'unknown');
    final statusIcon = _getRequestStatusIcon(request.status ?? 'unknown');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  request.type ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (request.status ?? 'unknown').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.reason ?? 'No description',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, yyyy').format(request.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              if (request.amount != null) ...[
                Icon(
                  Icons.attach_money,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '₱${request.amount!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              if (request.quantity != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.inventory,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Qty: ${request.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
          if (request.adminNote != null && request.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.note,
                    size: 14,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin Note: ${request.adminNote}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4CAF50),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    double iconSize = 24;
    if (index == 1) {
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(),
      _buildSchedule(),
      _buildRequests(),
      _buildManageProfile(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? _buildAppBar()
          : _selectedIndex == 1
              ? _buildNavAppBar('Schedule')
              : _selectedIndex == 2
                  ? _buildNavAppBar('Requests')
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

