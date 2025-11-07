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

  // Search and filter state
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _showFilterCard = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Fetch notifications on app start
    _fetchNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        final unreadCount =
            await notification_service.NotificationService.getUnreadCount(
                widget.token,
                farmWorkerId: _user!.id // Use farm worker ID for filtering
                );

        setState(() {
          _unreadCount = unreadCount;
        });
      }
    } catch (e) {
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
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                        Text('Hi ${_user?.name ?? 'Farm Worker'}!',
                            style: const TextStyle(
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
                                          firstName:
                                              _user!.name.split(' ').first,
                                          lastName:
                                              _user!.name.split(' ').length > 1
                                                  ? _user!.name
                                                      .split(' ')
                                                      .skip(1)
                                                      .join(' ')
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
                          onPressed: () async {
                            await AuthService().logout();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
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
                  icon: Icons.calendar_month_rounded,
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
                  icon: Icons.list_alt_rounded,
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
                          initialTabIndex: 0, // Supply Records tab
                        ),
                      ),
                    );
                  },
                ),
// ====================================================
// CASH DISTRIBUTIONS
                _buildQuickActionCard(
                  icon: Icons.credit_card_rounded,
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
                          initialTabIndex: 1, // Cash Records tab
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
      return const Center(child: Text('Please log in as a valid Farmer.'));
    }
  }

  Widget _buildRequests() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Search and Filter Section
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
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search requests...',
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
                        color: _selectedStatusFilter != 'All'
                            ? Colors.green // Green when filters are applied
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedStatusFilter != 'All'
                              ? Colors
                                  .green // Green border when filters are applied
                              : const Color(0xFF9E9E9E),
                          width: 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _toggleFilterCard,
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.filter_list_rounded,
                              color: _selectedStatusFilter != 'All'
                                  ? Colors
                                      .white // White icon when filters are applied
                                  : const Color(0xFF9E9E9E),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _futureRequests == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4CAF50),
                        ),
                      )
                    : FutureBuilder<List<RequestModel>>(
                        future: _futureRequests,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.request_page_outlined,
                                    size: 64,
                                    color: const Color(0xFF4CAF50)
                                        .withOpacity(0.6),
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
                            final filteredRequests = _filterRequests(requests);

                            if (filteredRequests.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Requests Found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Try adjusting your search or filter criteria',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: filteredRequests.length,
                              itemBuilder: (context, index) {
                                final request = filteredRequests[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildRequestCard(request),
                                );
                              },
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
          // Background overlay to close filter when tapped outside
          if (_showFilterCard)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showFilterCard = false;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          // Filter card overlay
          if (_showFilterCard)
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  140, // Position below search
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  // Prevent tap from propagating to background overlay
                },
                child: Material(
                  elevation: 0,
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
                        // Status Filter
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Status Filter Options
                        Column(
                          children: [
                            _buildFilterOption(
                              icon: Icons.all_inclusive,
                              label: 'All',
                              value: 'All',
                              isSelected: _selectedStatusFilter == 'All',
                              onTap: () {
                                setState(() {
                                  _selectedStatusFilter = 'All';
                                  _showFilterCard = false;
                                });
                              },
                            ),
                            Divider(
                                height: 1,
                                color: Colors.grey[200],
                                thickness: 1),
                            _buildFilterOption(
                              icon: Icons.check_circle_outline,
                              label: 'Approved',
                              value: 'Approved',
                              isSelected: _selectedStatusFilter == 'Approved',
                              onTap: () {
                                setState(() {
                                  _selectedStatusFilter = 'Approved';
                                  _showFilterCard = false;
                                });
                              },
                            ),
                            Divider(
                                height: 1,
                                color: Colors.grey[200],
                                thickness: 1),
                            _buildFilterOption(
                              icon: Icons.schedule,
                              label: 'Pending',
                              value: 'Pending',
                              isSelected: _selectedStatusFilter == 'Pending',
                              onTap: () {
                                setState(() {
                                  _selectedStatusFilter = 'Pending';
                                  _showFilterCard = false;
                                });
                              },
                            ),
                            Divider(
                                height: 1,
                                color: Colors.grey[200],
                                thickness: 1),
                            _buildFilterOption(
                              icon: Icons.local_shipping,
                              label: 'Distributed',
                              value: 'Distributed',
                              isSelected:
                                  _selectedStatusFilter == 'Distributed',
                              onTap: () {
                                setState(() {
                                  _selectedStatusFilter = 'Distributed';
                                  _showFilterCard = false;
                                });
                              },
                            ),
                            Divider(
                                height: 1,
                                color: Colors.grey[200],
                                thickness: 1),
                            _buildFilterOption(
                              icon: Icons.cancel_outlined,
                              label: 'Rejected',
                              value: 'Rejected',
                              isSelected: _selectedStatusFilter == 'Rejected',
                              onTap: () {
                                setState(() {
                                  _selectedStatusFilter = 'Rejected';
                                  _showFilterCard = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStatusFilter = 'All';
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
            ),
        ],
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
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle card tap if needed
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getRequestTypeDisplayName(
                                request.type ?? 'Unknown'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM dd, yyyy')
                                .format(request.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (request.status ?? 'unknown').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Equipment name (for equipment requests)
                if (request.type?.toLowerCase() == 'equipment' &&
                    request.equipmentName != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Equipment',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.equipmentName!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C3E50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Details row
                Row(
                  children: [
                    if (request.amount != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₱${request.amount!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (request.quantity != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Quantity: ${request.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Expected return date for equipment
                if (request.type?.toLowerCase() == 'equipment' &&
                    request.expectedReturnDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Expected Return: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(request.expectedReturnDate!))}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9C27B0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                // Description
                if (request.reason != null && request.reason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.reason!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C3E50),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Admin note
                if (request.adminNote != null &&
                    request.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Note',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.adminNote!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4CAF50),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
          width: 60, // Fixed width for consistent highlight size
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  icon: Icons.calendar_month_rounded,
                  activeIcon: Icons.calendar_month,
                  label: 'Schedule',
                  index: 1,
                ),
                // Requests
                _buildNavItem(
                  icon: Icons.list_alt_rounded,
                  activeIcon: Icons.list_alt,
                  label: 'Requests',
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

  // Helper methods for search and filtering
  void _toggleFilterCard() {
    setState(() {
      _showFilterCard = !_showFilterCard;
    });
  }

  Widget _buildFilterOption({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.green : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.green : const Color(0xFF2C3E50),
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  size: 20,
                  color: Colors.green,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<RequestModel> _filterRequests(List<RequestModel> requests) {
    return requests.where((request) {
      final matchesSearch = _searchQuery.isEmpty ||
          (request.type?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (request.reason?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesStatus = _selectedStatusFilter == 'All' ||
          (request.status?.toLowerCase() ==
              _selectedStatusFilter.toLowerCase());
      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _getRequestTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'equipment':
        return 'Equipment Request';
      case 'supply':
        return 'Supply Request';
      case 'cash_advance':
        return 'Cash Advance Request';
      default:
        return 'Request';
    }
  }
}

