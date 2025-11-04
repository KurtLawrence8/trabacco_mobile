import 'package:flutter/material.dart';
import '../services/coordinator_service.dart';
import 'package:intl/intl.dart';

class CoordinatorPendingReportsScreen extends StatefulWidget {
  final String token;

  const CoordinatorPendingReportsScreen({Key? key, required this.token})
      : super(key: key);

  @override
  State<CoordinatorPendingReportsScreen> createState() =>
      _CoordinatorPendingReportsScreenState();
}

class _CoordinatorPendingReportsScreenState
    extends State<CoordinatorPendingReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _loading = true);
    try {
      final reports =
          await CoordinatorService.getPendingReports(widget.token);
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reports: $e')),
        );
      }
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _buildReportDetailSheet(report, scrollController);
        },
      ),
    );
  }

  Widget _buildReportDetailSheet(
      Map<String, dynamic> report, ScrollController scrollController) {
    final technician = report['technician'] as Map<String, dynamic>?;
    final farm = report['farm'] as Map<String, dynamic>?;
    final technicianName =
        '${technician?['first_name'] ?? ''} ${technician?['last_name'] ?? ''}'
            .trim();
    final farmName = farm?['name'] ?? farm?['farm_address'] ?? farm?['address'] ?? 'Unknown Farm';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            'Report Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                _buildInfoCard('Technician', technicianName, Icons.person),
                _buildInfoCard('Farm', farmName, Icons.location_on),
                _buildInfoCard(
                  'Date',
                  _formatDate(report['timestamp']),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  'Accomplishments',
                  report['accomplishments'] ?? 'N/A',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildSectionCard(
                  'Issues Observed',
                  report['issues_observed'] ?? 'N/A',
                  Icons.warning,
                  Colors.orange,
                ),
                _buildSectionCard(
                  'Disease Detected',
                  report['disease_detected'] ?? 'None',
                  Icons.healing,
                  Colors.red,
                ),
                if (report['disease_type'] != null)
                  _buildSectionCard(
                    'Disease Type',
                    report['disease_type'],
                    Icons.info,
                    Colors.red,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showRejectDialog(report);
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showApproveDialog(report);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: const TextStyle(fontSize: 12)),
        subtitle:
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSectionCard(
      String title, String content, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> report) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to approve this report?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Coordinator Notes',
                hintText: 'Add your review notes...',
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
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please add review notes')),
                );
                return;
              }
              Navigator.pop(context);
              await _approveReport(report['id'], noteController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> report) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Explain why this report needs revision...',
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
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please provide a rejection reason')),
                );
                return;
              }
              Navigator.pop(context);
              await _rejectReport(report['id'], noteController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveReport(int reportId, String note) async {
    try {
      print('📝 [AC MOBILE] Starting accomplishment report approval...');
      print('📝 [AC MOBILE] Report ID: $reportId');
      print('📝 [AC MOBILE] Note: $note');
      
      await CoordinatorService.approveReport(widget.token, reportId, note);
      
      print('✅ [AC MOBILE] Accomplishment report approval successful!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchReports(); // Refresh list
      }
    } catch (e) {
      print('❌ [AC MOBILE] Error approving accomplishment report: $e');
      print('❌ [AC MOBILE] Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve report: $e')),
        );
      }
    }
  }

  Future<void> _rejectReport(int reportId, String note) async {
    try {
      print('📝 [AC MOBILE] Starting accomplishment report rejection...');
      print('📝 [AC MOBILE] Report ID: $reportId');
      print('📝 [AC MOBILE] Note: $note');
      
      await CoordinatorService.rejectReport(widget.token, reportId, note);
      
      print('✅ [AC MOBILE] Accomplishment report rejection successful!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _fetchReports(); // Refresh list
      }
    } catch (e) {
      print('❌ [AC MOBILE] Error rejecting accomplishment report: $e');
      print('❌ [AC MOBILE] Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject report: $e')),
        );
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString()).toLocal();
      return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchReports,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No Pending Reports',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All reports have been reviewed',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    final technician =
                        report['technician'] as Map<String, dynamic>?;
                    final farm = report['farm'] as Map<String, dynamic>?;
                    final technicianName =
                        '${technician?['first_name'] ?? ''} ${technician?['last_name'] ?? ''}'
                            .trim();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          child: const Icon(Icons.description,
                              color: Colors.orange),
                        ),
                        title: Text(
                          technicianName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(farm?['name'] ?? farm?['farm_address'] ?? farm?['address'] ?? 'Unknown Farm'),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(report['timestamp']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showReportDetails(report),
                      ),
                    );
                  },
                ),
    );
  }
}

