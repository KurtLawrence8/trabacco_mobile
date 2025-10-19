import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/equipment_service.dart';

class RequestListWidget extends StatefulWidget {
  final int farmWorkerId;
  final String token;
  const RequestListWidget(
      {Key? key, required this.farmWorkerId, required this.token})
      : super(key: key);

  @override
  State<RequestListWidget> createState() => _RequestListWidgetState();
}

class _RequestListWidgetState extends State<RequestListWidget> {
  late Future<List<RequestModel>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    print(
        'RequestListWidget: Initializing for Farmer ID: ${widget.farmWorkerId}');
    print('RequestListWidget: Token length: ${widget.token.length}');
    _requestsFuture = RequestService()
        .getRequestsForFarmWorker(widget.token, widget.farmWorkerId);
  }

  void _refresh() {
    setState(() {
      _requestsFuture = RequestService()
          .getRequestsForFarmWorker(widget.token, widget.farmWorkerId);
    });
  }

  void _editRequest(RequestModel request) async {
    final result = await showDialog(
      context: context,
      builder: (_) => EditRequestDialog(request: request, token: widget.token),
    );
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RequestModel>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        print(
            'RequestListWidget: Connection state: ${snapshot.connectionState}');
        print('RequestListWidget: Has data: ${snapshot.hasData}');
        print('RequestListWidget: Has error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('RequestListWidget: Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 24),
                Text(
                  'Error loading requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('RequestListWidget: No data or empty list');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Color(0xFFB0B0B0),
                ),
                Text(
                  'No requests found.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF808080),
                  ),
                ),
              ],
            ),
          );
        }
        final requests = snapshot.data!;

        // Group requests by date
        Map<String, List<RequestModel>> groupedRequests = {};
        for (var req in requests) {
          String dateKey = _formatDate(req.createdAt);
          if (!groupedRequests.containsKey(dateKey)) {
            groupedRequests[dateKey] = [];
          }
          groupedRequests[dateKey]!.add(req);
        }

        // Create list of date groups
        List<MapEntry<String, List<RequestModel>>> dateGroups = groupedRequests
            .entries
            .toList()
          ..sort((a, b) => b.key.compareTo(a.key)); // Sort by date descending

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
              top: 8, bottom: 20), // Add padding top and bottom
          itemCount: dateGroups.length,
          itemBuilder: (context, groupIndex) {
            final dateGroup = dateGroups[groupIndex];
            final date = dateGroup.key;
            final requestsForDate = dateGroup.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Padding(
                  padding: const EdgeInsets.only(
                      left: 8, right: 20, top: 0, bottom: 0),
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                // Requests for this date
                ...requestsForDate
                    .map((req) => _buildNotificationStyleRequest(req)),
                if (groupIndex < dateGroups.length - 1)
                  const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown Date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final requestDate = DateTime(date.year, date.month, date.day);

    if (requestDate == today) {
      return 'Today';
    } else if (requestDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
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

  Widget _buildNotificationStyleRequest(RequestModel req) {
    // More flexible status checking - allow editing for pending requests
    final status = req.status?.toLowerCase().trim() ?? '';
    final isPending = status == 'pending' || status == '' || status.isEmpty;

    // Debug logging to see actual status values
    print(
        'Request ID: ${req.id}, Status: "${req.status}", isPending: $isPending');

    // Get request type icon and color (matching technician landing screen)
    IconData typeIcon;
    Color typeColor;
    switch (req.type?.toLowerCase()) {
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

    // Get status color (matching technician landing screen)
    Color statusColor;
    switch (req.status?.toLowerCase()) {
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
        statusColor = Colors.grey[600] ?? Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200] ?? Colors.grey,
          width: 1,
        ),
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
                      _getRequestTypeDisplayName(req.type ?? ''),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Request No. ${req.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  req.status?.toUpperCase() ?? 'PENDING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
              // Show edit button for pending requests (allow editing)
              if (isPending || req.status == null || req.status!.isEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF27AE60).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _editRequest(req),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.edit,
                          color: Color(0xFF27AE60),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (req.reason != null && req.reason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              req.reason!,
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
                _formatRequestDate(req.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              if (req.type?.toLowerCase() == 'equipment' &&
                  req.equipmentName != null)
                Text(
                  req.equipmentName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (req.type?.toLowerCase() == 'supply' && req.supplyName != null)
                Text(
                  req.supplyName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (req.type?.toLowerCase() == 'cash_advance' &&
                  req.amount != null)
                Text(
                  '₱${req.amount!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          // Admin note (keep this at the bottom)
          if (req.adminNote != null && req.adminNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req.adminNote!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
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
}

class EditRequestDialog extends StatefulWidget {
  final RequestModel request;
  final String token;
  const EditRequestDialog(
      {Key? key, required this.request, required this.token})
      : super(key: key);

  @override
  State<EditRequestDialog> createState() => _EditRequestDialogState();
}

class _EditRequestDialogState extends State<EditRequestDialog> {
  late TextEditingController _amountController;
  late TextEditingController _quantityController;
  late TextEditingController _reasonController;
  late TextEditingController _durationController;
  late TextEditingController _returnDateController;
  late TextEditingController _supplySearchController;
  late TextEditingController _equipmentSearchController;
  int? _selectedSupplyId;
  int? _selectedEquipmentId;
  List<InventoryItem> _supplies = [];
  List<Equipment> _equipment = [];
  List<InventoryItem> _filteredSupplies = [];
  List<Equipment> _filteredEquipment = [];
  bool _loadingSupplies = false;
  bool _loadingEquipment = false;
  bool _isSupplyDropdownExpanded = false;
  bool _isEquipmentDropdownExpanded = false;

  @override
  void initState() {
    super.initState();

    // Debug original request data
    print('=== EDIT REQUEST INIT DEBUG ===');
    print('Request ID: ${widget.request.id}');
    print('Request Type: ${widget.request.type}');
    print('Original borrowDurationDays: ${widget.request.borrowDurationDays}');
    print('Original expectedReturnDate: ${widget.request.expectedReturnDate}');
    print('Original equipmentId: ${widget.request.equipmentId}');
    print('==============================');

    _amountController =
        TextEditingController(text: widget.request.amount?.toString() ?? '');
    _quantityController =
        TextEditingController(text: widget.request.quantity?.toString() ?? '');
    _reasonController =
        TextEditingController(text: widget.request.reason ?? '');
    _durationController = TextEditingController(
        text: widget.request.borrowDurationDays?.toString() ?? '');

    // Simplified date initialization - just use the original if available
    String initialDate = '';
    if (widget.request.expectedReturnDate != null &&
        widget.request.expectedReturnDate!.isNotEmpty) {
      // Try to parse and format for display, but fallback to original if parsing fails
      try {
        final date = DateTime.parse(widget.request.expectedReturnDate!);
        initialDate =
            '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}';
      } catch (e) {
        // If parsing fails, just use empty string to let user enter a new date
        initialDate = '';
      }
    }
    print('Initial date for controller: "$initialDate"');
    _returnDateController = TextEditingController(text: initialDate);
    _supplySearchController = TextEditingController();
    _equipmentSearchController = TextEditingController();

    _supplySearchController.addListener(_filterSupplies);
    _equipmentSearchController.addListener(_filterEquipment);

    if (widget.request.type == 'supply') {
      _fetchSupplies();
      _selectedSupplyId = widget.request.supplyId;
    } else if (widget.request.type == 'equipment') {
      _fetchEquipment();
      _selectedEquipmentId = widget.request.equipmentId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    _reasonController.dispose();
    _durationController.dispose();
    _returnDateController.dispose();
    _supplySearchController.dispose();
    _equipmentSearchController.dispose();
    super.dispose();
  }

  void _filterSupplies() {
    if (!mounted) return;
    final query = _supplySearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSupplies = List.from(_supplies);
      } else {
        _filteredSupplies = _supplies
            .where((supply) => supply.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _filterEquipment() {
    if (!mounted) return;
    final query = _equipmentSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEquipment = List.from(_equipment);
      } else {
        _filteredEquipment = _equipment
            .where((equipment) =>
                equipment.equipmentName.toLowerCase().contains(query) ||
                equipment.serialNumber.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _fetchSupplies() async {
    if (!mounted) return;
    setState(() => _loadingSupplies = true);
    try {
      final supplies = await InventoryService().getInventory(widget.token);
      if (mounted) {
        setState(() {
          _supplies = supplies;
          _filteredSupplies = List.from(supplies);
          _loadingSupplies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSupplies = false);
      }
    }
  }

  void _fetchEquipment() async {
    if (!mounted) return;
    setState(() => _loadingEquipment = true);
    try {
      final equipment =
          await EquipmentService().getAvailableEquipment(widget.token);
      if (mounted) {
        setState(() {
          _equipment = equipment;
          _filteredEquipment = List.from(equipment);
          _loadingEquipment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingEquipment = false);
      }
    }
  }

  void _save() async {
    // Validate that we have required data
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description/reason')),
      );
      return;
    }

    final updateData = <String, dynamic>{};

    // Always include description - for equipment requests, always include it
    final description = _reasonController.text.trim();

    // Always include description if it's not empty
    if (description.isNotEmpty) {
      updateData['description'] = description;
      print('Adding description to update data: "$description"');
    }

    if (widget.request.type == 'cash_advance') {
      final amount = double.tryParse(_amountController.text.trim());
      if (amount != null && amount > 0) {
        updateData['amount'] = amount;
      }
    }

    if (widget.request.type == 'supply') {
      if (_selectedSupplyId != null) {
        updateData['supply_id'] = _selectedSupplyId;
      }
      final quantity = int.tryParse(_quantityController.text.trim());
      if (quantity != null && quantity > 0) {
        updateData['quantity'] = quantity;
      }
    }

    if (widget.request.type == 'equipment') {
      // Equipment ID is required - always send the current or original equipment ID
      if (_selectedEquipmentId != null) {
        updateData['equipment_id'] = _selectedEquipmentId;
        print('Set equipment_id to update data: $_selectedEquipmentId');
      } else {
        // Use original equipment ID if not changed
        if (widget.request.equipmentId != null) {
          updateData['equipment_id'] = widget.request.equipmentId;
          print('Using original equipment_id: ${widget.request.equipmentId}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an equipment')),
          );
          return;
        }
      }

      // Handle borrow duration - always send current value for equipment requests
      final durationText = _durationController.text.trim();
      final originalDuration = widget.request.borrowDurationDays;
      print('Duration text from controller: "$durationText"');
      print('Original borrowDurationDays: $originalDuration');

      int? durationToSend;

      if (durationText.isNotEmpty) {
        final duration = int.tryParse(durationText);
        print('Parsed duration: $duration');
        if (duration != null && duration > 0) {
          durationToSend = duration;
          print('Will send duration: $durationToSend');
        } else {
          print(
              'Duration text is not a valid positive integer: "$durationText"');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid duration')),
          );
          return;
        }
      } else {
        // If empty, use original duration if available
        if (originalDuration != null && originalDuration > 0) {
          durationToSend = originalDuration;
          print('Duration field empty, using original: $durationToSend');
        } else {
          // For equipment requests, duration is required
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid duration')),
          );
          return;
        }
      }

      // Always send duration for equipment requests
      updateData['borrow_duration_days'] = durationToSend;
      print('Added borrow_duration_days to update data: $durationToSend');

      // Handle expected return date - always send current value for equipment requests
      final returnDateText = _returnDateController.text.trim();
      print('Return date text from controller: "$returnDateText"');
      print(
          'Original expectedReturnDate: ${widget.request.expectedReturnDate}');

      String? dateToSend;

      if (returnDateText.isNotEmpty) {
        // Try to format the date from MM-DD-YYYY to YYYY-MM-DD
        try {
          final formattedDate = _formatDateForApi(returnDateText);
          dateToSend = formattedDate;
          print('Formatted date for API: $formattedDate');
        } catch (e) {
          print('Error formatting return date "$returnDateText": $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid return date')),
          );
          return;
        }
      } else {
        // If empty, use original date if available
        if (widget.request.expectedReturnDate != null &&
            widget.request.expectedReturnDate!.isNotEmpty) {
          // Make sure the original date is in API format (YYYY-MM-DD)
          try {
            // If it's already in YYYY-MM-DD format, use it directly
            DateTime.parse(widget.request.expectedReturnDate!);
            dateToSend = widget.request.expectedReturnDate;
            print(
                'Using original expected_return_date (already API format): ${widget.request.expectedReturnDate}');
          } catch (e) {
            // If it's in a different format, try to parse and format it
            print(
                'Original date format needs conversion: ${widget.request.expectedReturnDate}');
            // For now, just use it as-is since we can't be sure of the original format
            dateToSend = widget.request.expectedReturnDate;
          }
        } else {
          // For equipment requests, return date can be optional if we have original
          print(
              'Warning: No return date provided and no original date available');
        }
      }

      // Always send return date for equipment requests
      if (dateToSend != null && dateToSend.isNotEmpty) {
        updateData['expected_return_date'] = dateToSend;
        print('Added expected_return_date to update data: $dateToSend');
      }
    }

    // Ensure we have something to update
    // For equipment requests, we should always have at least equipment_id and description
    if (updateData.isEmpty && widget.request.type != 'equipment') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      return;
    }

    // For equipment requests, we need at least equipment_id and description to proceed
    if (widget.request.type == 'equipment') {
      if (!updateData.containsKey('equipment_id') ||
          !updateData.containsKey('description')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Missing required equipment request data')),
        );
        return;
      }
    }

    // Check if request can be updated based on status
    final status = widget.request.status?.toLowerCase().trim() ?? '';
    if (status.isNotEmpty && status != 'pending' && status != 'requested') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Cannot update request with status: ${widget.request.status}')),
      );
      return;
    }

    // Debug logging
    print('=== MOBILE UPDATE DEBUG ===');
    print('Request ID: ${widget.request.id}');
    print('Request Status: "${widget.request.status}"');
    print('Request Type: ${widget.request.type}');
    print('Duration Controller Text: "${_durationController.text}"');
    print('Return Date Controller Text: "${_returnDateController.text}"');
    print('Reason Controller Text: "${_reasonController.text}"');
    print('Selected Equipment ID: $_selectedEquipmentId');
    print('Update Data: $updateData');
    print('Update Data Keys: ${updateData.keys.toList()}');
    print('=== CRITICAL FOR EQUIPMENT ===');
    if (widget.request.type == 'equipment') {
      print(
          'Equipment ID in update data: ${updateData.containsKey('equipment_id')}');
      print(
          'Duration in update data: ${updateData.containsKey('borrow_duration_days')}');
      print(
          'Return date in update data: ${updateData.containsKey('expected_return_date')}');
      print(
          'Description in update data: ${updateData.containsKey('description')}');
    }
    print('========================');

    try {
      await RequestService()
          .updateRequest(widget.token, widget.request.id, updateData);
      if (!mounted) return;

      print('=== UPDATE SUCCESS ===');
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Dispatch event to notify web app of request update
      print('=== DISPATCHING REQUEST UPDATED EVENT ===');
      // Note: This is a Flutter app, so we can't directly dispatch web events
      // The web app will detect changes through its own refresh mechanisms
    } catch (e) {
      print('=== MOBILE UPDATE ERROR ===');
      print('Error: $e');
      print('Error Type: ${e.runtimeType}');
      print('========================');

      String errorMessage = 'Failed to update request';
      if (e.toString().contains('Failed to update request')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('Network') ||
          e.toString().contains('Connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMessage = 'Session expired. Please login again.';
      } else {
        errorMessage = 'Update failed: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Helper method to convert MM-DD-YYYY format to YYYY-MM-DD (for API)
  String _formatDateForApi(String dateString) {
    print('Formatting date for API: "$dateString"');
    try {
      final trimmedString = dateString.trim();
      if (trimmedString.isEmpty) {
        print('Empty date string provided');
        throw Exception('Empty date string');
      }

      final parts = trimmedString.split('-');
      print('Date parts: $parts');

      if (parts.length == 3) {
        final month = parts[0].padLeft(2, '0');
        final day = parts[1].padLeft(2, '0');
        final year = parts[2];
        final result = '$year-$month-$day';
        print('Formatted date: "$result"');
        return result;
      } else {
        print(
            'Invalid date format - expected MM-DD-YYYY, got: "$dateString" with ${parts.length} parts');
        throw Exception('Invalid date format - expected MM-DD-YYYY');
      }
    } catch (e) {
      print('Error parsing date "$dateString": $e');
      throw e; // Re-throw to handle in calling code
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 24.0),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 950.0,
          maxHeight: (screenSize.height * 0.9).clamp(400.0, 700.0),
          minHeight: 400.0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Edit Request',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 20),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cash Advance Fields
                      if (widget.request.type == 'cash_advance') ...[
                        const Text(
                          'Cash Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter amount',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF27AE60)),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Supply Fields
                      if (widget.request.type == 'supply') ...[
                        const Text(
                          'Supply Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _loadingSupplies
                            ? Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300] ?? Colors.grey,
                                  ),
                                ),
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              )
                            : Builder(
                                builder: (context) {
                                  try {
                                    return _buildCustomSupplyDropdown();
                                  } catch (e) {
                                    print('Error building supply dropdown: $e');
                                    return Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red[300] ?? Colors.red,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Error loading supplies',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                        const SizedBox(height: 16),
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter quantity',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF27AE60)),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Equipment Fields
                      if (widget.request.type == 'equipment') ...[
                        const Text(
                          'Equipment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _loadingEquipment
                            ? Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300] ?? Colors.grey,
                                  ),
                                ),
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              )
                            : Builder(
                                builder: (context) {
                                  try {
                                    return _buildCustomEquipmentDropdown();
                                  } catch (e) {
                                    print(
                                        'Error building equipment dropdown: $e');
                                    return Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red[300] ?? Colors.red,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Error loading equipment',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                        const SizedBox(height: 16),
                        const Text(
                          'Borrow Duration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            // Auto-calculate return date when duration changes
                            if (value.isNotEmpty) {
                              final days = int.tryParse(value);
                              if (days != null && days > 0) {
                                final returnDate =
                                    DateTime.now().add(Duration(days: days));
                                _returnDateController.text =
                                    _formatDate(returnDate);
                              }
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter duration in days',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF27AE60)),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Expected Return Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _returnDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Select return date',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF27AE60)),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            suffixIcon: Icon(Icons.calendar_today,
                                color: Colors.grey[600], size: 18),
                          ),
                          onTap: () async {
                            if (!mounted) return;
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 7)),
                              firstDate:
                                  DateTime.now().add(const Duration(days: 1)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null && mounted) {
                              _returnDateController.text = _formatDate(date);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Reason/Description Field
                      const Text(
                        'Reason/Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          hintText: 'Enter reason/description',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF27AE60)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to format date as MM-DD-YYYY (for display)
  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month-$day-$year';
  }

  // Custom Supply Dropdown matching request_screen.dart style
  Widget _buildCustomSupplyDropdown() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (!mounted) return;
            setState(() {
              final wasExpanded = _isSupplyDropdownExpanded;
              _isSupplyDropdownExpanded = !_isSupplyDropdownExpanded;
              if (wasExpanded) {
                _supplySearchController.clear();
              }
            });
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedSupplyId != null && _supplies.isNotEmpty
                        ? _supplies.any((s) => s.id == _selectedSupplyId)
                            ? '${_supplies.firstWhere((s) => s.id == _selectedSupplyId).name} (Qty: ${_supplies.firstWhere((s) => s.id == _selectedSupplyId).quantity})'
                            : 'Select supply'
                        : 'Select supply',
                    style: TextStyle(
                      color: _selectedSupplyId != null &&
                              _supplies.isNotEmpty &&
                              _supplies.any((s) => s.id == _selectedSupplyId)
                          ? const Color(0xFF2C3E50)
                          : Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _isSupplyDropdownExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (_isSupplyDropdownExpanded && _supplies.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _supplySearchController,
                    decoration: InputDecoration(
                      hintText: 'Search supplies...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF27AE60)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _filteredSupplies.length,
                    itemBuilder: (context, index) {
                      final supply = _filteredSupplies[index];
                      return Column(
                        children: [
                          _buildSupplyOption(
                            supply: supply,
                            isSelected: _selectedSupplyId == supply.id,
                            onTap: () {
                              if (!mounted) return;
                              setState(() {
                                _selectedSupplyId = supply.id;
                                _isSupplyDropdownExpanded = false;
                              });
                            },
                          ),
                          if (index < _filteredSupplies.length - 1)
                            Divider(
                              height: 1,
                              color: Colors.grey[200],
                              thickness: 1,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Custom Equipment Dropdown matching request_screen.dart style
  Widget _buildCustomEquipmentDropdown() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (!mounted) return;
            setState(() {
              final wasExpanded = _isEquipmentDropdownExpanded;
              _isEquipmentDropdownExpanded = !_isEquipmentDropdownExpanded;
              if (wasExpanded) {
                _equipmentSearchController.clear();
              }
            });
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedEquipmentId != null && _equipment.isNotEmpty
                        ? _equipment.any((e) => e.id == _selectedEquipmentId)
                            ? '${_equipment.firstWhere((e) => e.id == _selectedEquipmentId).equipmentName} (${_equipment.firstWhere((e) => e.id == _selectedEquipmentId).serialNumber})'
                            : 'Select equipment'
                        : 'Select equipment',
                    style: TextStyle(
                      color: _selectedEquipmentId != null &&
                              _equipment.isNotEmpty &&
                              _equipment
                                  .any((e) => e.id == _selectedEquipmentId)
                          ? const Color(0xFF2C3E50)
                          : Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _isEquipmentDropdownExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (_isEquipmentDropdownExpanded && _equipment.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _equipmentSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search equipment...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF27AE60)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _filteredEquipment.length,
                    itemBuilder: (context, index) {
                      final equipment = _filteredEquipment[index];
                      return Column(
                        children: [
                          _buildEquipmentOption(
                            equipment: equipment,
                            isSelected: _selectedEquipmentId == equipment.id,
                            onTap: () {
                              if (!mounted) return;
                              setState(() {
                                _selectedEquipmentId = equipment.id;
                                _isEquipmentDropdownExpanded = false;
                              });
                            },
                          ),
                          if (index < _filteredEquipment.length - 1)
                            Divider(
                              height: 1,
                              color: Colors.grey[200],
                              thickness: 1,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Supply option builder matching request_screen.dart
  Widget _buildSupplyOption({
    required InventoryItem supply,
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
              Icons.inventory_2_outlined,
              color: Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supply.name,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF2C3E50)
                          : Colors.grey[600],
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Qty: ${supply.quantity}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
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
                    color: Colors.grey[400] ?? Colors.grey,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Equipment option builder matching request_screen.dart
  Widget _buildEquipmentOption({
    required Equipment equipment,
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
              Icons.settings_outlined,
              color: Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.equipmentName,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF2C3E50)
                          : Colors.grey[600],
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/N: ${equipment.serialNumber}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
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
                    color: Colors.grey[400] ?? Colors.grey,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
