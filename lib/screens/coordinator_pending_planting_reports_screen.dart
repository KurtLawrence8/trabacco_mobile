import 'package:flutter/material.dart';
import '../services/coordinator_service.dart';
import 'package:intl/intl.dart';

class CoordinatorPendingPlantingReportsScreen extends StatefulWidget {
  final String token;

  const CoordinatorPendingPlantingReportsScreen({Key? key, required this.token})
      : super(key: key);

  @override
  State<CoordinatorPendingPlantingReportsScreen> createState() =>
      _CoordinatorPendingPlantingReportsScreenState();
}

class _CoordinatorPendingPlantingReportsScreenState
    extends State<CoordinatorPendingPlantingReportsScreen> {
  List<Map<String, dynamic>> _plantingReports = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchPlantingReports();
  }

  Future<void> _fetchPlantingReports() async {
    setState(() => _loading = true);
    try {
      final reports =
          await CoordinatorService.getPendingPlantingReports(widget.token);
      setState(() {
        _plantingReports = reports;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load planting reports: $e')),
        );
      }
    }
  }

  void _showPlantingReportDetails(Map<String, dynamic> report) {
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
          return _buildPlantingReportDetailSheet(report, scrollController);
        },
      ),
    );
  }

  Widget _buildPlantingReportDetailSheet(
      Map<String, dynamic> report, ScrollController scrollController) {
    final technician = report['technician'] as Map<String, dynamic>?;
    final farm = report['farm'] as Map<String, dynamic>?;
    final farmWorker = report['farm_worker'] as Map<String, dynamic>?;
    final laborers = report['laborers'] as List<dynamic>?;

    final technicianName =
        '${technician?['first_name'] ?? ''} ${technician?['last_name'] ?? ''}'
            .trim();
    final farmAddress = farm?['farm_address'] ?? farm?['address'] ?? 'Unknown Farm';
    final farmerName = farmWorker != null
        ? '${farmWorker['first_name'] ?? ''} ${farmWorker['last_name'] ?? ''}'.trim()
        : 'N/A';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.grass, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Planting Report',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                _buildInfoCard('Technician', technicianName, Icons.person),
                _buildInfoCard('Farm', farmAddress, Icons.location_on),
                _buildInfoCard('Farmer', farmerName, Icons.agriculture),
                _buildInfoCard(
                  'Planting Date',
                  _formatDate(report['planting_date']),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 16),

                // Planting details
                _buildSectionCard(
                  'Plants Planted',
                  '${_formatNumber(report['plants_planted'])} plants',
                  Icons.grass,
                  Colors.green,
                ),

                if (report['area_planted'] != null &&
                    double.tryParse(report['area_planted'].toString()) != null &&
                    double.parse(report['area_planted'].toString()) > 0)
                  _buildSectionCard(
                    'Area Planted',
                    '${report['area_planted']} hectares',
                    Icons.map,
                    Colors.blue,
                  ),

                if (report['seeds_used'] != null && 
                    int.tryParse(report['seeds_used'].toString()) != null &&
                    int.parse(report['seeds_used'].toString()) > 0)
                  _buildSectionCard(
                    'Seeds Used',
                    '${_formatNumber(report['seeds_used'])} seeds',
                    Icons.eco,
                    Colors.brown,
                  ),

                if (laborers != null && laborers.isNotEmpty)
                  _buildSectionCard(
                    'Laborers',
                    '${laborers.length} laborers involved',
                    Icons.groups,
                    Colors.purple,
                  ),

                if (report['notes'] != null && report['notes'].isNotEmpty)
                  _buildSectionCard(
                    'Notes',
                    report['notes'],
                    Icons.note,
                    Colors.grey,
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
        title: const Text('Approve Planting Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to approve this planting report?'),
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
              await _approvePlantingReport(report['id'], noteController.text);
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
        title: const Text('Reject Planting Report'),
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
              await _rejectPlantingReport(report['id'], noteController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePlantingReport(int reportId, String note) async {
    try {
      print('📝 [AC MOBILE] Starting planting report approval...');
      print('📝 [AC MOBILE] Report ID: $reportId');
      print('📝 [AC MOBILE] Note: $note');
      print('📝 [AC MOBILE] Token: ${widget.token.substring(0, 20)}...');
      
      await CoordinatorService.approvePlantingReport(
          widget.token, reportId, note);
      
      print('✅ [AC MOBILE] Planting report approval successful!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planting report approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPlantingReports();
      }
    } catch (e) {
      print('❌ [AC MOBILE] Error approving planting report: $e');
      print('❌ [AC MOBILE] Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve planting report: $e')),
        );
      }
    }
  }

  Future<void> _rejectPlantingReport(int reportId, String note) async {
    try {
      print('📝 [AC MOBILE] Starting planting report rejection...');
      print('📝 [AC MOBILE] Report ID: $reportId');
      print('📝 [AC MOBILE] Note: $note');
      
      await CoordinatorService.rejectPlantingReport(
          widget.token, reportId, note);
      
      print('✅ [AC MOBILE] Planting report rejection successful!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planting report rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _fetchPlantingReports();
      }
    } catch (e) {
      print('❌ [AC MOBILE] Error rejecting planting report: $e');
      print('❌ [AC MOBILE] Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject planting report: $e')),
        );
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString()).toLocal();
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    return NumberFormat('#,###').format(int.tryParse(number.toString()) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchPlantingReports,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plantingReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No Pending Planting Reports',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plantingReports.length,
                  itemBuilder: (context, index) {
                    final report = _plantingReports[index];
                    final technician =
                        report['technician'] as Map<String, dynamic>?;
                    final farm = report['farm'] as Map<String, dynamic>?;
                    final farmWorker = report['farm_worker'] as Map<String, dynamic>?;
                    final technicianName =
                        '${technician?['first_name'] ?? ''} ${technician?['last_name'] ?? ''}'
                            .trim();
                    final farmerName = farmWorker != null
                        ? '${farmWorker['first_name'] ?? ''} ${farmWorker['last_name'] ?? ''}'.trim()
                        : 'N/A';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child:
                              const Icon(Icons.grass, color: Colors.green),
                        ),
                        title: Text(
                          technicianName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(farm?['farm_address'] ?? farm?['address'] ?? 'Unknown Farm'),
                            const SizedBox(height: 2),
                            Text(
                              'Farmer: $farmerName',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatNumber(report['plants_planted'])} plants',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(report['planting_date']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showPlantingReportDetails(report),
                      ),
                    );
                  },
                ),
    );
  }
}

