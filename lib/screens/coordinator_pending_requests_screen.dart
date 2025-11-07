import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/coordinator_service.dart';
import 'package:intl/intl.dart';

class CoordinatorPendingRequestsScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;

  const CoordinatorPendingRequestsScreen({
    Key? key,
    required this.token,
    this.onBack,
  }) : super(key: key);

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

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5), // Light grey background like Google settings
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '$requestType Request',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildSingleItemCard(
                  'Technician',
                  technicianName,
                  Icons.person_outline,
                ),
                _buildSingleItemCard(
                  'Farm Worker',
                  farmWorkerName,
                  Icons.person_outline,
                ),
                _buildSingleItemCard(
                  'Date',
                  _formatDate(request['timestamp']),
                  Icons.calendar_today_outlined,
                ),

                // Request-specific details
                if (requestType == 'Supply' && supply != null) ...[
                  _buildSingleItemCard(
                    'Supply',
                    supply['product_name'] ?? 'Unknown Product',
                    Icons.inventory_2_outlined,
                  ),
                  _buildSingleItemCard(
                    'Quantity',
                    '${request['quantity'] ?? 0} units',
                    Icons.numbers_outlined,
                  ),
                ],
                if (requestType == 'Cash Advance') ...[
                  _buildSingleItemCard(
                    'Amount',
                    '₱${_formatCurrency(request['amount'])}',
                    Icons.credit_card_outlined,
                  ),
                ],
                if (requestType == 'Equipment' && equipment != null) ...[
                  _buildSingleItemCard(
                    'Equipment',
                    equipment['equipment_name'] ?? 'Unknown Equipment',
                    Icons.construction_outlined,
                  ),
                  _buildSingleItemCard(
                    'Duration',
                    '${request['borrow_duration_days'] ?? 0} days',
                    Icons.access_time_outlined,
                  ),
                  if (request['expected_return_date'] != null)
                    _buildSingleItemCard(
                      'Expected Return',
                      _formatDate(request['expected_return_date']),
                      Icons.event_available_outlined,
                    ),
                ],

                if (request['description'] != null &&
                    request['description'].toString().isNotEmpty)
                  _buildSingleItemCard(
                    'Description',
                    request['description'].toString(),
                    Icons.note_outlined,
                  ),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showRejectDialog(request);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[800],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showApproveDialog(request);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleItemCard(String label, String value, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          icon,
          color: Colors.grey[800],
          size: 24,
          weight: 600, // Semi-bold icon
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500, // Semi-bold
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[900],
              fontWeight: FontWeight.w500, // Semi-bold
              height: 1.4,
            ),
          ),
        ),
        isThreeLine: false,
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> request) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Approve Request',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.grey[600],
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Are you sure you want to approve this request?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Label above input
                          Text(
                            'Coordinator Notes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              hintText: 'Add your review notes...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.green, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (noteController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please add review notes')),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          await _approveRequest(
                              request['id'], noteController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> request) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Reject Request',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.grey[600],
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Please provide a reason for rejection:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Label above input
                          Text(
                            'Rejection Reason',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              hintText:
                                  'Explain why this request needs revision...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (noteController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please provide a rejection reason')),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          await _rejectRequest(
                              request['id'], noteController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveRequest(int requestId, String note) async {
    try {

      await CoordinatorService.approveRequest(widget.token, requestId, note);


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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(int requestId, String note) async {
    try {

      await CoordinatorService.rejectRequest(widget.token, requestId, note);


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
      // Convert to Philippine time (UTC+8)
      final utcDateTime = DateTime.parse(date.toString()).toUtc();
      final phDateTime = utcDateTime.add(const Duration(hours: 8));
      return DateFormat('MMM dd, yyyy hh:mm a').format(phDateTime);
    } catch (e) {
      return date.toString();
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0.00';
    final number = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat('#,##0.00').format(number);
  }

  String _formatSubmissionDate(dynamic date) {
    if (date == null) return '';
    try {
      // Convert to Philippine time (UTC+8)
      final utcDateTime = DateTime.parse(date.toString()).toUtc();
      final phDateTime = utcDateTime.add(const Duration(hours: 8));

      // Get current Philippine time
      final nowUtc = DateTime.now().toUtc();
      final nowPh = nowUtc.add(const Duration(hours: 8));
      final difference = nowPh.difference(phDateTime);

      // Format time in 12-hour format
      final timeFormat = DateFormat('h:mm a').format(phDateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago at $timeFormat';
        }
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago at $timeFormat';
      } else if (difference.inDays == 1) {
        return 'Yesterday at $timeFormat';
      } else if (difference.inDays < 7) {
        return '${DateFormat('MMM dd').format(phDateTime)} at $timeFormat';
      } else if (phDateTime.year == nowPh.year) {
        return '${DateFormat('MMM dd').format(phDateTime)} at $timeFormat';
      } else {
        return '${DateFormat('MMM dd, yyyy').format(phDateTime)} at $timeFormat';
      }
    } catch (e) {
      return '';
    }
  }

  IconData _getRequestIcon(String type) {
    switch (type) {
      case 'Supply':
        return Icons.inventory;
      case 'Cash Advance':
        return Icons.credit_card;
      case 'Equipment':
        return Icons.construction;
      default:
        return Icons.request_page;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pending Requests',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.green,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    ['All', 'Supply', 'Cash Advance', 'Equipment'].map((type) {
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
                            final requestType =
                                request['request_type'] ?? 'Unknown';
                            final technician =
                                request['technician'] as Map<String, dynamic>?;
                            final technicianName =
                                '${technician?['first_name'] ?? ''} ${technician?['last_name'] ?? ''}'
                                    .trim();
                            final submittedDate =
                                request['created_at'] ?? request['timestamp'];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Submission date outside card (Facebook notification style)
                                if (submittedDate != null &&
                                    _formatSubmissionDate(submittedDate)
                                        .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 4,
                                    ),
                                    child: Text(
                                      _formatSubmissionDate(submittedDate),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                // Card
                                Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: Colors.grey[100],
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showRequestDetails(request),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Icon on the left
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _getRequestIcon(requestType),
                                              color: Colors.grey[700],
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Content in the middle
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Request Type
                                                Text(
                                                  requestType,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Technician name
                                                Text(
                                                  'Technician: $technicianName',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Date
                                                Text(
                                                  _formatDate(
                                                      request['timestamp']),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Arrow on the right
                                          const Icon(
                                            Icons.chevron_right,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

