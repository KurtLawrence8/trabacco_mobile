import 'package:flutter/material.dart';
import '../models/distribution_model.dart';
import '../services/distribution_service.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class SupplyCashScreen extends StatefulWidget {
  final String token;
  final User? user;
  final int initialTabIndex;

  const SupplyCashScreen({
    super.key,
    required this.token,
    this.user,
    this.initialTabIndex = 0,
  });

  @override
  State<SupplyCashScreen> createState() => _SupplyCashScreenState();
}

class _SupplyCashScreenState extends State<SupplyCashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<SupplyDistribution>> _futureSupplyDistributions;
  late Future<List<CashDistribution>> _futureCashDistributions;
  final DistributionService _distributionService = DistributionService();

  // Search and filter state
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _showFilterCard = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    if (widget.user != null) {
      _futureSupplyDistributions = _distributionService
          .fetchSupplyDistributionsForFarmWorker(widget.user!.id, widget.token);
      _futureCashDistributions = _distributionService
          .fetchCashDistributionsForFarmWorker(widget.user!.id, widget.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                color: Colors.green,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 24),
                      padding: EdgeInsets.zero,
                    ),
                    Expanded(
                      child: Text(
                        'Supply & Cash Records',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
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
                            hintText: 'Search records...',
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
              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF27AE60),
                  unselectedLabelColor: const Color(0xFF6C757D),
                  indicatorColor: const Color(0xFF27AE60),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(
                      text: 'Supply Records',
                    ),
                    Tab(
                      text: 'Cash Records',
                    ),
                  ],
                ),
              ),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSupplyTab(),
                    _buildCashTab(),
                  ],
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
                              icon: Icons.cancel_outlined,
                              label: 'Cancelled',
                              value: 'Cancelled',
                              isSelected: _selectedStatusFilter == 'Cancelled',
                              onTap: () {
                                setState(() {
                                  _selectedStatusFilter = 'Cancelled';
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

  // Toggle filter card
  void _toggleFilterCard() {
    setState(() {
      _showFilterCard = !_showFilterCard;
    });
  }

  // Build filter option
  Widget _buildFilterOption({
    required IconData icon,
    required String label,
    required String value,
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

  Widget _buildSupplyTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadData();
        });
      },
      child: FutureBuilder<List<SupplyDistribution>>(
        future: _futureSupplyDistributions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(
                'Error loading supply records', snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              icon: Icons.inventory_outlined,
              title: 'No Supply Records Yet',
              subtitle: 'Your supply distributions will appear here',
            );
          } else {
            final distributions = snapshot.data!;
            final filteredDistributions =
                _filterSupplyDistributions(distributions);

            if (filteredDistributions.isEmpty) {
              return _buildEmptyState(
                icon: Icons.search_off,
                title: 'No Records Found',
                subtitle: 'Try adjusting your search or filter criteria',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDistributions.length,
              itemBuilder: (context, index) {
                final distribution = filteredDistributions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSupplyDistributionCard(distribution),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildCashTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadData();
        });
      },
      child: FutureBuilder<List<CashDistribution>>(
        future: _futureCashDistributions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(
                'Error loading cash records', snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              icon: Icons.attach_money,
              title: 'No Cash Records Yet',
              subtitle: 'Your cash distributions will appear here',
            );
          } else {
            final distributions = snapshot.data!;
            final filteredDistributions =
                _filterCashDistributions(distributions);

            if (filteredDistributions.isEmpty) {
              return _buildEmptyState(
                icon: Icons.search_off,
                title: 'No Records Found',
                subtitle: 'Try adjusting your search or filter criteria',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDistributions.length,
              itemBuilder: (context, index) {
                final distribution = filteredDistributions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCashDistributionCard(distribution),
                );
              },
            );
          }
        },
      ),
    );
  }

  // Helper methods for filtering
  List<SupplyDistribution> _filterSupplyDistributions(
      List<SupplyDistribution> distributions) {
    return distributions.where((distribution) {
      final matchesSearch = _searchQuery.isEmpty ||
          (distribution.inventory?.productName
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesStatus = _selectedStatusFilter == 'All' ||
          distribution.status.toLowerCase() ==
              _selectedStatusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<CashDistribution> _filterCashDistributions(
      List<CashDistribution> distributions) {
    return distributions.where((distribution) {
      final matchesSearch = _searchQuery.isEmpty ||
          'Cash Distribution'
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatusFilter == 'All' ||
          distribution.status.toLowerCase() ==
              _selectedStatusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  // Helper methods for UI states
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF27AE60),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading records...',
            style: TextStyle(
              color: Color(0xFF6C757D),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loadData();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                size: 48,
                color: const Color(0xFF27AE60).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6C757D),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getDistributionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'distributed':
        return const Color(0xFF27AE60);
      case 'pending':
        return const Color(0xFFFF9500);
      case 'cancelled':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF6C757D);
    }
  }

  IconData _getDistributionStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'distributed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildSupplyDistributionCard(SupplyDistribution distribution) {
    final statusColor = _getDistributionStatusColor(distribution.status);
    final statusIcon = _getDistributionStatusIcon(distribution.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
            // Add tap functionality if needed
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                            distribution.inventory?.productName ??
                                'Unknown Supply',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            distribution.inventory?.category ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6C757D),
                              fontWeight: FontWeight.w500,
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        distribution.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Details row
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.access_time,
                        DateFormat('MMM dd, yyyy').format(
                            DateTime.parse(distribution.dateDistributed)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailItem(
                        null,
                        'Quantity: ${distribution.quantity}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashDistributionCard(CashDistribution distribution) {
    final statusColor = _getDistributionStatusColor(distribution.status);
    final statusIcon = _getDistributionStatusIcon(distribution.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
            // Add tap functionality if needed
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                          const Text(
                            'Cash Advance',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        distribution.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Details row
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.access_time,
                        DateFormat('MMM dd, yyyy').format(
                            DateTime.parse(distribution.dateDistributed)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailItem(
                        null,
                        '₱${distribution.amount.toStringAsFixed(0)}',
                        isAmount: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData? icon, String text,
      {bool isAmount = false}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF6C757D),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF6C757D),
              fontWeight: isAmount ? FontWeight.w600 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
