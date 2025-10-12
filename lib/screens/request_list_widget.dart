import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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
                  size: 80,
                  color: Color(0xFFB0B0B0),
                ),
                SizedBox(height: 24),
                Text(
                  'No requests found.',
                  style: TextStyle(
                    fontSize: 18,
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

  Widget _buildNotificationStyleRequest(RequestModel req) {
    // More flexible status checking - allow editing for pending requests
    final status = req.status?.toLowerCase().trim() ?? '';
    final isPending = status == 'pending' || status == '' || status.isEmpty;

    // Debug logging to see actual status values
    print(
        'Request ID: ${req.id}, Status: "${req.status}", isPending: $isPending');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: req.type == 'cash_advance'
                  ? Colors.green[100]
                  : req.type == 'equipment'
                      ? Colors.orange[100]
                      : Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              req.type == 'cash_advance'
                  ? Icons.account_balance_wallet_rounded
                  : req.type == 'equipment'
                      ? Icons.build_rounded
                      : Icons.inventory_2_rounded,
              color: req.type == 'cash_advance'
                  ? Colors.green[700]
                  : req.type == 'equipment'
                      ? Colors.orange[700]
                      : Colors.blue[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        req.type == 'cash_advance'
                            ? 'Cash Advance'
                            : req.type == 'equipment'
                                ? 'Equipment Request'
                                : 'Supply Request',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: req.status == 'approved'
                            ? Colors.green[100]
                            : req.status == 'rejected'
                                ? Colors.red[100]
                                : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        req.status?.toUpperCase() ?? 'PENDING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: req.status == 'approved'
                              ? Colors.green[800]
                              : req.status == 'rejected'
                                  ? Colors.red[800]
                                  : Colors.orange[800],
                        ),
                      ),
                    ),
                    // Show edit button for pending requests (allow editing)
                    if (isPending ||
                        req.status == null ||
                        req.status!.isEmpty) ...[
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
                const SizedBox(height: 4),
                // Amount, supply, or equipment
                if (req.type == 'cash_advance' && req.amount != null)
                  Text(
                    'Amount: ₱${req.amount!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  )
                else if (req.type == 'supply' && req.supplyName != null)
                  Text(
                    'Supply: ${req.supplyName}${req.quantity != null ? ' (Qty: ${req.quantity})' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  )
                else if (req.type == 'equipment' && req.equipmentName != null)
                  Text(
                    'Equipment: ${req.equipmentName}${req.borrowDurationDays != null ? ' (${req.borrowDurationDays} days)' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                const SizedBox(height: 4),
                // Description label
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                // Reason
                Text(
                  req.reason ?? 'No reason provided',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Admin note
                if (req.adminNote != null &&
                    req.adminNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
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
          ),
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
  int? _selectedSupplyId;
  List<InventoryItem> _supplies = [];
  bool _loadingSupplies = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.request.amount?.toString() ?? '');
    _quantityController =
        TextEditingController(text: widget.request.quantity?.toString() ?? '');
    _reasonController =
        TextEditingController(text: widget.request.reason ?? '');
    if (widget.request.type == 'supply') {
      _fetchSupplies();
      _selectedSupplyId = widget.request.supplyId;
    }
  }

  void _fetchSupplies() async {
    setState(() => _loadingSupplies = true);
    try {
      final supplies = await InventoryService().getInventory(widget.token);
      setState(() => _supplies = supplies);
    } catch (e) {}
    setState(() => _loadingSupplies = false);
  }

  void _save() async {
    final updateData = <String, dynamic>{
      'description': _reasonController.text,
    };
    if (widget.request.type == 'cash_advance') {
      updateData['amount'] = double.tryParse(_amountController.text);
    }
    if (widget.request.type == 'supply') {
      updateData['supply_id'] = _selectedSupplyId;
      updateData['quantity'] = int.tryParse(_quantityController.text);
    }

    // Debug logging
    print('=== MOBILE UPDATE DEBUG ===');
    print('Request ID: ${widget.request.id}');
    print('Request Status: "${widget.request.status}"');
    print('Update Data: $updateData');
    print('Request Type: ${widget.request.type}');
    print('========================');

    try {
      await RequestService()
          .updateRequest(widget.token, widget.request.id, updateData);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request updated!')));

      // Dispatch event to notify web app of request update
      print('=== DISPATCHING REQUEST UPDATED EVENT ===');
      // Note: This is a Flutter app, so we can't directly dispatch web events
      // The web app will detect changes through its own refresh mechanisms
    } catch (e) {
      print('=== MOBILE UPDATE ERROR ===');
      print('Error: $e');
      print('========================');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit Request',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF27AE60))),
            const SizedBox(height: 18),
            if (widget.request.type == 'cash_advance')
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            if (widget.request.type == 'supply') ...[
              _loadingSupplies
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _selectedSupplyId,
                      isExpanded: true,
                      items: _supplies
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${s.name} (Qty: ${s.quantity})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSupplyId = val),
                      decoration: InputDecoration(
                        labelText: 'Select Supply',
                        prefixIcon: const Icon(Icons.inventory_2),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter quantity';
                  if (int.tryParse(val) == null) return 'Invalid quantity';
                  if (int.parse(val) <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                prefixIcon: const Icon(Icons.edit_note),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:
                      Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
