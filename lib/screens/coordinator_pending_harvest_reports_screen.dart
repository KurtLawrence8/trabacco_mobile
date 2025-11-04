import 'package:flutter/material.dart';
import '../services/coordinator_service.dart';

class CoordinatorPendingHarvestReportsScreen extends StatefulWidget {
  final String token;

  const CoordinatorPendingHarvestReportsScreen({Key? key, required this.token})
      : super(key: key);

  @override
  State<CoordinatorPendingHarvestReportsScreen> createState() =>
      _CoordinatorPendingHarvestReportsScreenState();
}

class _CoordinatorPendingHarvestReportsScreenState
    extends State<CoordinatorPendingHarvestReportsScreen> {
  List<Map<String, dynamic>> _pendingHarvestReports = [];
  bool _loading = true;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPendingHarvestReports();
  }

  Future<void> _fetchPendingHarvestReports() async {
    try {
      setState(() => _loading = true);
      final harvestReports =
          await CoordinatorService.getPendingHarvestReports(widget.token);
      if (mounted) {
        setState(() {
          _pendingHarvestReports = harvestReports;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load harvest reports: $e')),
        );
      }
    }
  }

  Future<void> _approveHarvest(int harvestId) async {
    try {
      print('📝 [AC MOBILE] Starting harvest report approval...');
      print('📝 [AC MOBILE] Harvest ID: $harvestId');
      print('📝 [AC MOBILE] Note: ${_noteController.text}');
      
      await CoordinatorService.approveHarvestReport(
        widget.token,
        harvestId,
        _noteController.text,
      );
      
      print('✅ [AC MOBILE] Harvest report approval successful!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harvest report approved!')),
        );
        _noteController.clear();
        _fetchPendingHarvestReports();
      }
    } catch (e) {
      print('❌ [AC MOBILE] Error approving harvest report: $e');
      print('❌ [AC MOBILE] Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e')),
        );
      }
    }
  }

  Future<void> _rejectHarvest(int harvestId) async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for rejection')),
      );
      return;
    }

    try {
      print('📝 [AC MOBILE] Starting harvest report rejection...');
      print('📝 [AC MOBILE] Harvest ID: $harvestId');
      print('📝 [AC MOBILE] Note: ${_noteController.text}');
      
      await CoordinatorService.rejectHarvestReport(
        widget.token,
        harvestId,
        _noteController.text,
      );
      
      print('✅ [AC MOBILE] Harvest report rejection successful!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harvest report rejected')),
        );
        _noteController.clear();
        _fetchPendingHarvestReports();
      }
    } catch (e) {
      print('❌ [AC MOBILE] Error rejecting harvest report: $e');
      print('❌ [AC MOBILE] Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e')),
        );
      }
    }
  }

  void _showReviewDialog(Map<String, dynamic> harvest) {
    _noteController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Harvest Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm: ${harvest['farm']?['farm_address'] ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Mortality: ${harvest['mortality'] ?? 0}'),
            Text('Initial Kg: ${harvest['actual_yield_kg'] ?? 0} kg'),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Coordinator Note (Optional)',
                hintText: 'Add your comments here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectHarvest(harvest['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveHarvest(harvest['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Pending Harvest Reports'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingHarvestReports,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingHarvestReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.agriculture,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No pending harvest reports',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPendingHarvestReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingHarvestReports.length,
                    itemBuilder: (context, index) {
                      final harvest = _pendingHarvestReports[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _showReviewDialog(harvest),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.brown.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.agriculture,
                                        color: Colors.brown,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            harvest['farm']?['farm_address'] ??
                                                'Unknown Farm',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'By: ${harvest['technician']?['first_name'] ?? ''} ${harvest['technician']?['last_name'] ?? ''}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Details
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildDetailRow(
                                        'Mortality',
                                        '${harvest['mortality'] ?? 0}',
                                        Icons.warning_amber,
                                        Colors.orange,
                                      ),
                                      const Divider(height: 16),
                                      _buildDetailRow(
                                        'Initial Weight',
                                        '${harvest['actual_yield_kg'] ?? 0} kg',
                                        Icons.scale,
                                        Colors.blue,
                                      ),
                                      const Divider(height: 16),
                                      _buildDetailRow(
                                        'Harvest Date',
                                        harvest['harvest_date'] ?? 'N/A',
                                        Icons.calendar_today,
                                        Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Action button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _showReviewDialog(harvest),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Review Report'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

