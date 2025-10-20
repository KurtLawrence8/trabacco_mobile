import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart' as notification_service;
import '../services/schedule_notification_service.dart';
import '../services/firebase_messaging_service.dart';
import 'login_screen.dart';
import 'technician_report_screen.dart';
import 'schedule_page.dart';
import 'technician_profile_screen.dart';
import 'notification_screen.dart';

import 'package:provider/provider.dart';
import 'farm_worker_detail_screen.dart';
import 'technician_farms_screen.dart';
import 'request_screen.dart';
import 'all_requests_screen.dart';
import '../models/user_model.dart';
import '../services/farm_service.dart';
import '../models/farm.dart' as farm_models;

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
  int _unreadCount = 0;

  // Technician data
  Technician? _technician;
  bool _loadingTechnician = false;

  // Dashboard metrics
  int _totalAssignedFarmers = 0;
  double _totalFarmArea = 0.0;
  int _pendingRequests = 0;
  int _activeEquipment = 0;

  // Pending requests data
  List<RequestModel> _allRequests = [];
  bool _loadingRequests = false;
  Map<int, FarmWorker> _farmWorkersMap = {}; // For navigation to farmer details

  @override
  void initState() {
    super.initState();

    // FETCH FARM WORKERS ASSIGNED TO THIS SPECIFIC TECHNICIAN
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FarmWorkerProvider>(context, listen: false)
          .fetchFarmWorkers(widget.token, widget.technicianId);
      // Fetch notifications and technician data on app start
      _fetchNotifications();
      _fetchTechnicianData();
      _fetchDashboardMetrics();

      // Initialize Firebase messaging for push notifications
      _initializeFirebaseMessaging();

      // Start scheduled notifications for schedule-based reminders
      ScheduleNotificationService.startScheduledNotifications(
        widget.token,
        widget.technicianId,
      );

      // Fetch requests after a short delay to ensure farm workers are loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        _fetchAllRequests();
      });
    });
  }

  @override
  void dispose() {
    // Stop scheduled notifications when leaving the screen
    ScheduleNotificationService.stopScheduledNotifications();
    super.dispose();
  }

  // ====================================================
  // FIREBASE MESSAGING INITIALIZATION
  Future<void> _initializeFirebaseMessaging() async {
    try {
      print('🔥 [TECHNICIAN LANDING] Initializing Firebase messaging...');

      // Subscribe to schedule reminder notifications
      await FirebaseMessagingService.subscribeToScheduleNotifications();

      // Get and update FCM token
      final fcmToken = await FirebaseMessagingService.getFCMToken();
      if (fcmToken != null) {
        print(
            '🔥 [TECHNICIAN LANDING] FCM Token obtained: ${fcmToken.substring(0, 20)}...');
      }

      print(
          '🔥 [TECHNICIAN LANDING] ✅ Firebase messaging initialized successfully');
    } catch (e) {
      print(
          '🔥 [TECHNICIAN LANDING] ❌ Error initializing Firebase messaging: $e');
    }
  }

  // ====================================================
  // FETCH NOTIFICATIONS
  Future<void> _fetchNotifications() async {
    try {
      // Check and create schedule-based notifications first
      print('🔔 [TECHNICIAN LANDING] Checking schedule notifications...');
      print(
          '🔔 [TECHNICIAN LANDING] Token: ${widget.token.substring(0, 20)}..., Technician ID: ${widget.technicianId}');

      await ScheduleNotificationService.checkAndCreateScheduleNotifications(
        widget.token,
        widget.technicianId,
      );

      print('🔔 [TECHNICIAN LANDING] ✅ Schedule notification check completed');

      // Then get the updated notification count
      final unreadCount =
          await notification_service.NotificationService.getUnreadCount(
              widget.token,
              technicianId: widget.technicianId);

      if (mounted) {
        setState(() {
          _unreadCount = unreadCount;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  // ====================================================
  // FETCH TECHNICIAN DATA
  Future<void> _fetchTechnicianData() async {
    if (!mounted) return;
    setState(() => _loadingTechnician = true);
    try {
      final technician = await TechnicianService()
          .getTechnicianProfile(widget.token, widget.technicianId);
      if (mounted) {
        setState(() {
          _technician = technician;
          _loadingTechnician = false;
        });
      }
    } catch (e) {
      print('Error fetching technician data: $e');
      if (mounted) {
        setState(() => _loadingTechnician = false);
      }
    }
  }

  // ====================================================
  // FETCH DASHBOARD METRICS
  Future<void> _fetchDashboardMetrics() async {
    if (!mounted) return;
    try {
      // Get assigned farmers count from provider
      final provider = Provider.of<FarmWorkerProvider>(context, listen: false);
      if (mounted) {
        setState(() {
          _totalAssignedFarmers = provider.farmWorkers.length;
        });
      }

      // Fetch other metrics in parallel
      await Future.wait([
        _fetchTotalFarmArea(),
        _fetchPendingRequests(),
        _fetchActiveEquipment(),
      ]);
    } catch (e) {
      print('Error fetching dashboard metrics: $e');
    }
  }

  // ====================================================
  // FETCH TOTAL FARM AREA
  Future<void> _fetchTotalFarmArea() async {
    try {
      final farmService = FarmService();
      final List<farm_models.Farm> farms =
          await farmService.getFarmsByTechnician(widget.token);

      double totalArea = 0.0;
      for (final farm in farms) {
        totalArea += farm.area;
      }

      if (mounted) {
        setState(() {
          _totalFarmArea = totalArea;
        });
      }
    } catch (e) {
      print('Error fetching total farm area: $e');
      // Set to 0 if error occurs
      if (mounted) {
        setState(() {
          _totalFarmArea = 0.0;
        });
      }
    }
  }

  // ====================================================
  // FETCH PENDING REQUESTS
  Future<void> _fetchPendingRequests() async {
    try {
      final requestService = RequestService();
      final provider = Provider.of<FarmWorkerProvider>(context, listen: false);

      int totalPendingRequests = 0;

      // Get all assigned farm workers and their requests
      for (final farmWorker in provider.farmWorkers) {
        try {
          final requests = await requestService.getRequestsForFarmWorker(
              widget.token, farmWorker.id);

          // Count pending requests (assuming status values like 'Pending', 'pending', etc.)
          final pendingCount = requests
              .where((request) =>
                  request.status?.toLowerCase() == 'pending' ||
                  request.status?.toLowerCase() == 'requested')
              .length;

          totalPendingRequests += pendingCount;
        } catch (e) {
          print('Error fetching requests for farmer ${farmWorker.id}: $e');
          // Continue with other farmers even if one fails
        }
      }

      if (mounted) {
        setState(() {
          _pendingRequests = totalPendingRequests;
        });
      }
    } catch (e) {
      print('Error fetching pending requests: $e');
      // Set to 0 if error occurs
      if (mounted) {
        setState(() {
          _pendingRequests = 0;
        });
      }
    }
  }

  // ====================================================
  // FETCH ACTIVE EQUIPMENT
  Future<void> _fetchActiveEquipment() async {
    try {
      final requestService = RequestService();
      final provider = Provider.of<FarmWorkerProvider>(context, listen: false);

      int totalActiveEquipment = 0;

      // Get all assigned farm workers and their requests
      for (final farmWorker in provider.farmWorkers) {
        try {
          final requests = await requestService.getRequestsForFarmWorker(
              widget.token, farmWorker.id);

          // Count active equipment requests (approved/borrowed equipment)
          final activeEquipmentCount = requests.where((request) {
            // Only count equipment type requests
            if (request.type?.toLowerCase() != 'equipment') return false;

            // Count as active if status is approved, borrowed, or active (not pending, not returned)
            final status = request.status?.toLowerCase() ?? '';
            return status == 'approved' ||
                status == 'borrowed' ||
                status == 'active' ||
                status == 'completed' ||
                status == 'in use';
          }).length;

          totalActiveEquipment += activeEquipmentCount;
        } catch (e) {
          print(
              'Error fetching active equipment for farmer ${farmWorker.id}: $e');
          // Continue with other farmers even if one fails
        }
      }

      if (mounted) {
        setState(() {
          _activeEquipment = totalActiveEquipment;
        });
      }
    } catch (e) {
      print('Error fetching active equipment: $e');
      // Set to 0 if error occurs
      if (mounted) {
        setState(() {
          _activeEquipment = 0;
        });
      }
    }
  }

  // ====================================================
  // FETCH PENDING REQUESTS
  Future<void> _fetchAllRequests() async {
    if (!mounted) return;
    setState(() => _loadingRequests = true);

    try {
      final requestService = RequestService();
      final provider = Provider.of<FarmWorkerProvider>(context, listen: false);

      List<RequestModel> allRequests = [];

      // Check if farm workers are loaded
      if (provider.farmWorkers.isEmpty) {
        if (mounted) {
          setState(() {
            _allRequests = [];
            _loadingRequests = false;
          });
        }
        return;
      }

      // Get all assigned farm workers and their requests
      Map<int, FarmWorker> farmWorkersMap = {};
      for (final farmWorker in provider.farmWorkers) {
        farmWorkersMap[farmWorker.id] = farmWorker;
        try {
          final requests = await requestService.getRequestsForFarmWorker(
              widget.token, farmWorker.id);

          // Filter only pending requests
          final pendingRequests = requests.where((request) {
            final status = request.status?.toLowerCase() ?? '';
            return status == 'pending' || status == 'requested';
          }).toList();

          allRequests.addAll(pendingRequests);
        } catch (e) {
          print('Error fetching requests for farmer ${farmWorker.id}: $e');
          // Continue with other farmers even if one fails
        }
      }

      // Sort requests by creation date (newest first)
      allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _allRequests = allRequests;
          _farmWorkersMap = farmWorkersMap;
          _loadingRequests = false;
        });
      }
    } catch (e) {
      print('Error fetching all requests: $e');
      if (mounted) {
        setState(() {
          _loadingRequests = false;
        });
      }
    }
  }

  // ====================================================
  // BUILD TECHNICIAN GREETING
  String _buildTechnicianGreeting() {
    if (_loadingTechnician) {
      return 'Hi Technician!';
    }

    if (_technician != null) {
      final firstName = _technician!.firstName;
      final lastName = _technician!.lastName;
      final middleName = _technician!.middleName;

      // Format: "Hi [LastName], [FirstName] [MiddleName]!"
      String fullName = lastName;
      if (firstName.isNotEmpty) {
        fullName += ', $firstName';
      }
      if (middleName != null && middleName.isNotEmpty) {
        fullName += ' $middleName';
      }

      return 'Hi $fullName!';
    }

    return 'Hi Technician!';
  }

  // ====================================================
  // BUILD DASHBOARD METRICS
  Widget _buildDashboardMetrics() {
    return Consumer<FarmWorkerProvider>(
      builder: (context, provider, _) {
        // Update assigned farmers count and refresh pending requests when provider data changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && provider.farmWorkers.length != _totalAssignedFarmers) {
            setState(() {
              _totalAssignedFarmers = provider.farmWorkers.length;
            });
            // Refresh pending requests when farm workers change to get real-time updates
            _fetchPendingRequests();
          }
        });

        return Column(
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
            // Metrics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildMetricCard(
                  title: 'Total Assigned Farmers',
                  value: _totalAssignedFarmers.toString(),
                  icon: Icons.people_alt,
                  color: const Color(0xFF6366F1),
                ),
                _buildMetricCard(
                  title: 'Total Farm Area',
                  value: '${_totalFarmArea.toStringAsFixed(0)} sqm',
                  icon: Icons.agriculture,
                  color: const Color(0xFF10B981),
                ),
                _buildMetricCard(
                  title: 'Pending Requests',
                  value: _pendingRequests.toString(),
                  icon: Icons.pending_actions,
                  color: const Color(0xFFF59E0B),
                ),
                _buildMetricCard(
                  title: 'Active Equipment',
                  value: _activeEquipment.toString(),
                  icon: Icons.build,
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ====================================================
  // BUILD METRIC CARD
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container matching quick action card
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
    );
  }

  // ====================================================
  // BUILD NAVIGATION APP BAR
  PreferredSizeWidget _buildNavAppBar(String title) {
    // Titles that should have green background
    final greenBackgroundTitles = [
      'Reports',
      'Transplanting Schedules',
      'Request Submission'
    ];
    final shouldHaveGreenBackground = greenBackgroundTitles.contains(title);

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: shouldHaveGreenBackground
              ? Colors.white
              : const Color(0xFF2C3E50),
        ),
      ),
      backgroundColor: shouldHaveGreenBackground ? Colors.green : Colors.white,
      foregroundColor:
          shouldHaveGreenBackground ? Colors.white : const Color(0xFF2C3E50),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: shouldHaveGreenBackground
                ? Colors.white
                : const Color(0xFF2C3E50)),
        onPressed: () {
          if (mounted) {
            setState(() {
              _selectedIndex = 0; // Go back to dashboard
            });
            // Refresh pending requests when returning to dashboard for real-time updates
            _fetchPendingRequests();
          }
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
                  // Profile icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
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
                          _buildTechnicianGreeting(),
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
                                    builder: (_) => NotificationScreen(
                                      token: widget.token,
                                      technician: Technician(
                                        id: widget.technicianId,
                                        firstName: 'Technician',
                                        lastName: '',
                                        emailAddress: '',
                                        status: 'Active',
                                      ),
                                    ),
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
        // Refresh farm workers, notifications, technician data, and metrics
        Provider.of<FarmWorkerProvider>(context, listen: false)
            .fetchFarmWorkers(widget.token, widget.technicianId);
        await Future.wait([
          _fetchNotifications(),
          _fetchTechnicianData(),
          _fetchDashboardMetrics(),
          _fetchAllRequests(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
        child: Column(
          children: [
            // ====================================================
            // DASHBOARD METRICS SECTION
            _buildDashboardMetrics(),
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
                  title: 'Assigned Farmers',
                  subtitle: 'List of assigned Farmers',
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
                  subtitle: 'Submit Farmer request',
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
                        builder: (_) => NotificationScreen(
                          token: widget.token,
                          technician: Technician(
                            id: widget.technicianId,
                            firstName: 'Technician',
                            lastName: '',
                            emailAddress: '',
                            status: 'Active',
                          ),
                        ),
                      ),
                    ).then((_) {
                      // Refresh notifications when returning from notification screen
                      _fetchNotifications();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ====================================================
            // RECENT REQUESTS SECTION
            _buildRequestsSection(),
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

  // ====================================================
  // BUILD REQUESTS SECTION
  Widget _buildRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 8),
            const Text(
              'Pending Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222B45),
              ),
            ),
            const Spacer(),
            if (_allRequests.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllRequestsScreen(
                        token: widget.token,
                        technicianId: widget.technicianId,
                      ),
                    ),
                  ).then((_) {
                    // Refresh requests and dashboard metrics when returning from the screen
                    _fetchAllRequests();
                    _fetchDashboardMetrics(); // This will refresh pending requests count
                  });
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF27AE60),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingRequests)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
              ),
            ),
          )
        else if (_allRequests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.request_page,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No pending requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No pending requests from assigned farmers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Container(
            constraints: BoxConstraints(
              maxHeight: 400, // Set maximum height for scrolling
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _allRequests.length, // Show all pending requests
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = _allRequests[index];
                return _buildRequestCard(request);
              },
            ),
          ),
      ],
    );
  }

  // ====================================================
  // BUILD REQUEST CARD
  Widget _buildRequestCard(RequestModel request) {
    // Get request type icon and color
    IconData typeIcon;
    Color typeColor;

    switch (request.type?.toLowerCase()) {
      case 'equipment':
        typeIcon = Icons.build;
        typeColor = const Color(0xFFEF4444);
        break;
      case 'supply':
        typeIcon = Icons.inventory;
        typeColor = const Color(0xFF10B981);
        break;
      case 'cash_advance':
        typeIcon = Icons.credit_card;
        typeColor = const Color(0xFFF59E0B);
        break;
      default:
        typeIcon = Icons.request_page;
        typeColor = const Color(0xFF6366F1);
    }

    // Get status color
    Color statusColor;
    switch (request.status?.toLowerCase()) {
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'approved':
        statusColor = const Color(0xFF10B981);
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = Colors.grey[600]!;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to farmer details screen for the request's farmer
        final farmWorker = _farmWorkersMap[request.farmWorkerId];
        if (farmWorker != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FarmWorkerDetailScreen(
                farmWorker: farmWorker,
                token: widget.token,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getRequestTypeDisplayName(request.type ?? ''),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Request No. ${request.id} • ${_getFarmerName(request.farmWorkerId)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                request.reason!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatRequestDate(request.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                if (request.type?.toLowerCase() == 'equipment' &&
                    request.equipmentName != null)
                  Text(
                    request.equipmentName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (request.type?.toLowerCase() == 'supply' &&
                    request.supplyName != null)
                  Text(
                    request.supplyName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get display name for request type
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

  // Helper method to format request date
  String _formatRequestDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to get farmer name
  String _getFarmerName(int farmWorkerId) {
    final farmWorker = _farmWorkersMap[farmWorkerId];
    if (farmWorker != null) {
      return '${farmWorker.firstName} ${farmWorker.lastName}';
    }
    return 'Unknown Farmer';
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
        if (mounted) {
          setState(() {
            _selectedIndex = index;
          });
          // Refresh pending requests when navigating to dashboard for real-time updates
          if (index == 0) {
            _fetchPendingRequests();
          }
        }
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
        if (mounted) {
          setState(() {
            _selectedIndex = 2;
          });
        }
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
          : _selectedIndex == 1
              ? null // TransplantingSchedulesScreen has its own header
              : _selectedIndex == 2
                  ? _buildNavAppBar('Reports')
                  : _selectedIndex == 3
                      ? _buildNavAppBar('Profile')
                      : _selectedIndex == 4
                          ? null // RequestSubmissionScreen has its own header
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
  bool _disposed = false;

  List<FarmWorker> get farmWorkers => _farmWorkers;
  bool get loading => _loading;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      try {
        notifyListeners();
      } catch (e) {
        print('Error notifying listeners: $e');
      }
    }
  }

  // FETCH FARM WORKERS ASSIGNED TO SPECIFIC TECHNICIAN
  Future<void> fetchFarmWorkers(String token, int technicianId) async {
    if (_disposed) return;

    try {
      _loading = true;
      _error = null;

      // Defer the initial notification to avoid calling during build
      Future.microtask(() => _safeNotifyListeners());

      final service = FarmWorkerService();
      // THIS WILL NOW ONLY RETURN FARM WORKERS ASSIGNED TO THIS TECHNICIAN
      _farmWorkers = await service.getAssignedFarmWorkers(token, technicianId);
    } catch (e) {
      print('Error fetching farm workers: $e');
      _error = e.toString();
    } finally {
      if (!_disposed) {
        _loading = false;
        // Defer the final notification as well
        Future.microtask(() => _safeNotifyListeners());
      }
    }
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
      appBar: AppBar(title: const Text('All Farmer Schedules')),
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
  final TextEditingController _locationController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedLocation;
  bool _showFilterCard = false;
  bool _isGenderDropdownExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _locationController.dispose();
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
// BUILD DROPDOWN OPTION
  Widget _buildDropdownOption({
    required IconData icon,
    required String label,
    required String? value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? const Color(0xFF2C3E50) : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[400]!,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
                color: (widget.title == 'Assigned Farmers' ||
                        widget.title == 'Transplanting Schedules' ||
                        widget.title == 'Request Submission')
                    ? Colors.green
                    : Colors.white,
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
                      icon: Icon(Icons.arrow_back,
                          color: (widget.title == 'Assigned Farmers' ||
                                  widget.title == 'Transplanting Schedules' ||
                                  widget.title == 'Request Submission')
                              ? Colors.white
                              : const Color(0xFF2C3E50),
                          size: 24),
                      padding: EdgeInsets.zero,
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: (widget.title == 'Assigned Farmers' ||
                                  widget.title == 'Transplanting Schedules' ||
                                  widget.title == 'Request Submission')
                              ? Colors.white
                              : const Color(0xFF2C3E50),
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
                            hintText: 'Search Farmer',
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
                                (_selectedLocation != null &&
                                    _selectedLocation!.isNotEmpty))
                            ? Colors.green // Green when filters are applied
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_selectedStatus != null ||
                                  (_selectedLocation != null &&
                                      _selectedLocation!.isNotEmpty))
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
                              color: (_selectedStatus != null ||
                                      (_selectedLocation != null &&
                                          _selectedLocation!.isNotEmpty))
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
                              size: 64,
                              color: const Color(0xFFB0B0B0),
                            ),
                            Text(
                              farmWorkers.isEmpty
                                  ? widget.emptyStateTitle
                                  : 'No Farmers found',
                              style: const TextStyle(
                                fontSize: 14,
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
                                fontSize: 12,
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
          // BACKGROUND OVERLAY TO CLOSE FILTER WHEN TAPPED OUTSIDE
          if (_showFilterCard)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showFilterCard = false;
                    _isGenderDropdownExpanded = false;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          // ====================================================
          // FILTER CARD OVERLAY (APPEARS ON TOP WITH HIGHER Z-INDEX)
          if (_showFilterCard)
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  140, // POSITION BELOW SEARCH
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
                        // Gender Label
                        Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Gender Filter - Custom Dropdown
                        Column(
                          children: [
                            // Dropdown Header
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isGenderDropdownExpanded =
                                      !_isGenderDropdownExpanded;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedStatus != null
                                            ? _selectedStatus!
                                            : 'All Sex',
                                        style: TextStyle(
                                          color: _selectedStatus != null
                                              ? const Color(0xFF2C3E50)
                                              : Colors.grey[600],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _isGenderDropdownExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey[600],
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Dropdown Options
                            if (_isGenderDropdownExpanded) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // All Sex Option
                                    _buildDropdownOption(
                                      icon: Icons.all_inclusive,
                                      label: 'All Sex',
                                      value: null,
                                      isSelected: _selectedStatus == null,
                                      onTap: () {
                                        setState(() {
                                          _selectedStatus = null;
                                          _isGenderDropdownExpanded = false;
                                        });
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: Colors.grey[200],
                                      thickness: 1,
                                    ),
                                    // Male Option
                                    _buildDropdownOption(
                                      icon: Icons.male,
                                      label: 'Male',
                                      value: 'Male',
                                      isSelected: _selectedStatus == 'Male',
                                      onTap: () {
                                        setState(() {
                                          _selectedStatus = 'Male';
                                          _isGenderDropdownExpanded = false;
                                        });
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: Colors.grey[200],
                                      thickness: 1,
                                    ),
                                    // Female Option
                                    _buildDropdownOption(
                                      icon: Icons.female,
                                      label: 'Female',
                                      value: 'Female',
                                      isSelected: _selectedStatus == 'Female',
                                      onTap: () {
                                        setState(() {
                                          _selectedStatus = 'Female';
                                          _isGenderDropdownExpanded = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Location Label
                        Text(
                          'Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Location Filter
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: 'Enter city, province, or area',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            style: const TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation =
                                    value.isEmpty ? null : value;
                              });
                            },
                          ),
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
                                  _locationController.clear();
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
      title: 'Assigned Farmers',
      token: token,
      technicianId: technicianId,
      emptyStateTitle: 'No assigned Farmers',
      emptyStateSubtitle: 'Farmers will appear here when assigned',
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
      emptyStateTitle: 'No Farmers assigned',
      emptyStateSubtitle: 'Farmers will appear here when assigned',
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
      emptyStateTitle: 'No Farmers assigned',
      emptyStateSubtitle: 'Farmers will appear here when assigned',
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
