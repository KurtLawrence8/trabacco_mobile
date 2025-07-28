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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No requests found.'));
        }
        final requests = snapshot.data!;
        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final req = requests[i];
            final isPending =
                (req.status?.toLowerCase().trim() ?? '') == 'pending';
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          req.type == 'cash_advance'
                              ? Icons.attach_money
                              : Icons.inventory_2,
                          color: req.type == 'cash_advance'
                              ? Colors.green
                              : Colors.blue,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          req.type == 'cash_advance'
                              ? 'Cash Advance'
                              : 'Supply',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: req.status == 'approved'
                                ? Colors.green[100]
                                : req.status == 'rejected'
                                    ? Colors.red[100]
                                    : Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            req.status!.toUpperCase(),
                            style: TextStyle(
                              color: req.status == 'approved'
                                  ? Colors.green[800]
                                  : req.status == 'rejected'
                                      ? Colors.red[800]
                                      : Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isPending)
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFF27AE60)),
                            tooltip: 'Edit',
                            onPressed: () => _editRequest(req),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (req.type == 'cash_advance' && req.amount != null)
                      Row(
                        children: [
                          Icon(Icons.payments,
                              size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text('Amount: ₱${req.amount!.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    if (req.type == 'supply' && req.supplyName != null)
                      Row(
                        children: [
                          Icon(Icons.inventory,
                              size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text('Supply: ${req.supplyName}',
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.edit_note,
                            size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(req.reason ?? '-',
                                style: const TextStyle(fontSize: 15))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(req.createdAt.toString() ?? '',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700])),
                      ],
                    ),
                    if (req.adminNote != null &&
                        req.adminNote!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                req.adminNote!,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.blue[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
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
  late TextEditingController _reasonController;
  int? _selectedSupplyId;
  List<InventoryItem> _supplies = [];
  bool _loadingSupplies = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.request.amount?.toString() ?? '');
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
    }
    try {
      await RequestService()
          .updateRequest(widget.token, widget.request.id, updateData);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request updated!')));
    } catch (e) {
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
            if (widget.request.type == 'supply')
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
