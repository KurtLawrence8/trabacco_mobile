import 'package:flutter/material.dart';
import '../services/coordinator_service.dart';
import 'package:intl/intl.dart';

class CoordinatorPendingRequestsScreen extends StatefulWidget {
  final String token;

  const CoordinatorPendingRequestsScreen({Key? key, required this.token})
      : super(key: key);

  @override
  State<CoordinatorPendingRequestsScreen> createState() =>
      _CoordinatorPendingRequestsScreenState();
}

class _CoordinatorPendingRequestsScreenState
    extends State<CoordinatorPendingRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = false;
  String _filterType = 'All';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _loading = true);
    try {
      final requests =
          await CoordinatorService.getPendingRequests(widget.token);
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load requests: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_filterType == 'All') return _requests;
    return _requests
        .where((req) => req['request_type'] == _filterType)
        .toList();
  }

  void _showRequestDetails(Map<String, dynamic> request) {
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
          return _buildRequestDetailSheet(request, scrollController);
        },
      ),
    );
  }

  Widget _buildRequestDetailSheet(
      Map<String, dynamic> request, ScrollController scrollController) {
    final technician = request['technician'] as Map<String, dynamic>?;
    final farmWorker = request['farm_worker'] as Map<String, dynamic>?;
    final supply = request['supply'] as Map<String, dynamic>?;
    final equipment = request['equipment'] as Map<String, dynamic>?;

    final technicianName =
        '${technician?['first_name'] ?? ''} ${technician?['last_name'] ?? ''}'
            .trim();
    final farmWorkerName =
        '${farmWorker?['first_name'] ?? ''} ${farmWorker?['last_name'] ?? ''}'
            .trim();

    final requestType = request['request_type'] ?? 'Unknown';
    Color typeColor = Colors.blue;
    IconData typeIcon = Icons.request_page;

    switch (requestType) {
      case 'Supply':
        typeColor = Colors.green;
        typeIcon = Icons.inventory;
        break;
      case 'Cash Advance':
        typeColor = Colors.orange;
        typeIcon = Icons.attach_money;
        break;
      case 'Equipment':
        typeColor = Colors.purple;
        typeIcon = Icons.construction;
        break;
    }

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

          // Title with type badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(typeIcon, color: typeColor),
              const SizedBox(width: 8),
              Text(
                '$requestType Request',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
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
                _buildInfoCard(
                    'Farm Worker', farmWorkerName, Icons.agriculture),
                _buildInfoCard(
                  'Date',
                  _formatDate(request['timestamp']),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 16),

                // Request-specific details
                if (requestType == 'Supply' && supply != null) ...[
                  _buildSectionCard(
                    'Supply Details',
                    supply['product_name'] ?? 'Unknown Product',
                    Icons.inventory,
                    typeColor,
                  ),
                  _buildSectionCard(
                    'Quantity',
                    '${request['quantity'] ?? 0} units',
                    Icons.numbers,
                    typeColor,
                  ),
                ],
                if (requestType == 'Cash Advance') ...[
                  _buildSectionCard(
                    'Amount',
                    '₱${_formatCurrency(request['amount'])}',
                    Icons.attach_money,
                    typeColor,
                  ),
                ],
                if (requestType == 'Equipment' && equipment != null) ...[
                  _buildSectionCard(
                    'Equipment',
                    equipment['equipment_name'] ?? 'Unknown Equipment',
                    Icons.construction,
                    typeColor,
                  ),
                  _buildSectionCard(
                    'Duration',
                    '${request['borrow_duration_days'] ?? 0} days',
                    Icons.access_time,
                    typeColor,
                  ),
                  if (request['expected_return_date'] != null)
                    _buildSectionCard(
                      'Expected Return',
                      _formatDate(request['expected_return_date']),
                      Icons.event_available,
                      typeColor,
                    ),
                ],

                _buildSectionCard(
                  'Description',
                  request['description'] ?? 'No description provided',
                  Icons.description,
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
                    _showRejectDialog(request);
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
                    _showApproveDialog(request);
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

  void _showApproveDialog(Map<String, dynamic> request) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to approve this request?'),
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
              await _approveRequest(request['id'], noteController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> request) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
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
                hintText: 'Explain why this request needs revision...',
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
              await _rejectRequest(request['id'], noteController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(int requestId, String note) async {
    try {
      print('📝 [AC MOBILE] Starting request approval...');
      print('📝 [AC MOBILE] Request ID: $requestId');
      print('📝 [AC MOBILE] Note: $note');
      
      await CoordinatorService.approveRequest(widget.token, requestId, note);
      
      print('✅ [AC MOBILE] Request approval successful!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchRequests();
      }
    } catch (e) {
      print('❌ [AC MOBILE] Error approving request: $e');
      print('❌ [AC MOBILE] Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(int requestId, String note) async {
    try {
      print('📝 [AC MOBILE] Starting request rejection...');
      print('📝 [AC MOBILE] Request ID: $requestId');
      print('📝 [AC MOBILE] Note: $note');
      
      await CoordinatorService.rejectRequest(widget.token, requestId, note);
      
      print('✅ [AC MOBILE] Request rejection successful!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _fetchRequests();
      }
    } catch (e) {
      print('❌ [AC MOBILE] Error rejecting request: $e');
      print('❌ [AC MOBILE] Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject request: $e')),
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

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0.00';
    final number = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat('#,##0.00').format(number);
  }

  IconData _getRequestIcon(String type) {
    switch (type) {
      case 'Supply':
        return Icons.inventory;
      case 'Cash Advance':
        return Icons.attach_money;
      case 'Equipment':
        return Icons.construction;
      default:
        return Icons.request_page;
    }
  }

  Color _getRequestColor(String type) {
    switch (type) {
      case 'Supply':
        return Colors.green;
      case 'Cash Advance':
        return Colors.orange;
      case 'Equipment':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'All',
                'Supply',
                'Cash Advance',
                'Equipment'
              ].map((type) {
                final isSelected = _filterType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _filterType = type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Request list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchRequests,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No Pending Requests',
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
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = _filteredRequests[index];
                          final requestType = request['request_type'] ?? 'Unknown';
                          final technician =
                              request['technician'] as Map<String, dynamic>?;
                          final technicianName =
                              '${technician?['first_name'] ?? ''} ${technician?['last_name'] ?? ''}'
                                  .trim();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: _getRequestColor(requestType)
                                    .withOpacity(0.1),
                                child: Icon(
                                  _getRequestIcon(requestType),
                                  color: _getRequestColor(requestType),
                                ),
                              ),
                              title: Text(
                                technicianName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(requestType),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(request['timestamp']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showRequestDetails(request),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }
}

