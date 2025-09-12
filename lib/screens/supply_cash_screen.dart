import 'package:flutter/material.dart';
import '../models/distribution_model.dart';
import '../services/distribution_service.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class SupplyCashScreen extends StatefulWidget {
  final String token;
  final User? user;
  
  const SupplyCashScreen({
    Key? key,
    required this.token,
    this.user,
  }) : super(key: key);

  @override
  State<SupplyCashScreen> createState() => _SupplyCashScreenState();
}

class _SupplyCashScreenState extends State<SupplyCashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<SupplyDistribution>> _futureSupplyDistributions;
  late Future<List<CashDistribution>> _futureCashDistributions;
  final DistributionService _distributionService = DistributionService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Supply & Cash Records'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF27AE60),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF27AE60),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.inventory_rounded),
              text: 'Supply Records',
            ),
            Tab(
              icon: Icon(Icons.attach_money_rounded),
              text: 'Cash Records',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSupplyTab(),
          _buildCashTab(),
        ],
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
                    'Error loading supply records',
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
                    Icons.inventory_outlined,
                    size: 64,
                    color: const Color(0xFF4CAF50).withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Supply Records Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your supply distributions will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final distributions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: distributions.length,
              itemBuilder: (context, index) {
                final distribution = distributions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
                    'Error loading cash records',
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
                    Icons.attach_money_outlined,
                    size: 64,
                    color: const Color(0xFF4CAF50).withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Cash Records Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your cash distributions will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final distributions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: distributions.length,
              itemBuilder: (context, index) {
                final distribution = distributions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCashDistributionCard(distribution),
                );
              },
            );
          }
        },
      ),
    );
  }

  Color _getDistributionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'distributed':
        return const Color(0xFF4CAF50);
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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
                  distribution.inventory?.productName ?? 'Unknown Supply',
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
                  distribution.status.toUpperCase(),
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
            'Category: ${distribution.inventory?.category ?? 'N/A'}',
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
                DateFormat('MMM dd, yyyy').format(DateTime.parse(distribution.dateDistributed)),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.inventory,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Qty: ${distribution.quantity}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashDistributionCard(CashDistribution distribution) {
    final statusColor = _getDistributionStatusColor(distribution.status);
    final statusIcon = _getDistributionStatusIcon(distribution.status);
    
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
                  'Cash Distribution',
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
                  distribution.status.toUpperCase(),
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
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, yyyy').format(DateTime.parse(distribution.dateDistributed)),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.attach_money,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '₱${distribution.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
