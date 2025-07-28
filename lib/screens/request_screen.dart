import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class RequestScreen extends StatefulWidget {
  final FarmWorker farmWorker;
  final String token;
  const RequestScreen({Key? key, required this.farmWorker, required this.token})
      : super(key: key);

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  String _requestType = 'cash_advance';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  int? _selectedSupplyId;
  List<InventoryItem> _supplies = [];
  bool _loadingSupplies = false;

  @override
  void initState() {
    super.initState();
    _fetchSupplies();
  }

  void _fetchSupplies() async {
    setState(() => _loadingSupplies = true);
    try {
      final supplies = await InventoryService().getInventory(widget.token);
      print('Fetched supplies: $supplies');
      setState(() => _supplies = supplies);
    } catch (e) {
      print('Error fetching supplies: $e');
    }
    setState(() => _loadingSupplies = false);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final requestData = {
      'farm_worker_id': widget.farmWorker.id,
      'technician_id': widget.farmWorker.technicianId,
      'type': _requestType,
      'reason': _reasonController.text,
      if (_requestType == 'cash_advance')
        'amount': double.tryParse(_amountController.text),
      if (_requestType == 'supply') 'supply_id': _selectedSupplyId,
      if (_requestType == 'supply')
        'amount': double.tryParse(_amountController.text),
    };
    try {
      await RequestService().createRequest(widget.token, requestData);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request submitted!')));
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains(
          'Only one request per technician per farm worker per day')) {
        errorMsg = 'You can only submit one request per farm worker per day.';
      } else if (errorMsg.contains('Not enough inventory')) {
        errorMsg = 'Not enough inventory for this supply.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Create Request'),
          backgroundColor: const Color(0xFF27AE60)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Request Type',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAFBF3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _requestType = 'cash_advance'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _requestType == 'cash_advance'
                                    ? const Color(0xFF27AE60)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.attach_money,
                                        color: _requestType == 'cash_advance'
                                            ? Colors.white
                                            : const Color(0xFF27AE60)),
                                    const SizedBox(width: 6),
                                    Text('Cash Advance',
                                        style: TextStyle(
                                            color:
                                                _requestType == 'cash_advance'
                                                    ? Colors.white
                                                    : const Color(0xFF27AE60),
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _requestType = 'supply'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _requestType == 'supply'
                                    ? const Color(0xFF27AE60)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2,
                                        color: _requestType == 'supply'
                                            ? Colors.white
                                            : const Color(0xFF27AE60)),
                                    const SizedBox(width: 6),
                                    Text('Supply',
                                        style: TextStyle(
                                            color: _requestType == 'supply'
                                                ? Colors.white
                                                : const Color(0xFF27AE60),
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_requestType == 'cash_advance') ...[
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter amount';
                        if (double.tryParse(val) == null) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_requestType == 'supply') ...[
                    _loadingSupplies
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _selectedSupplyId,
                            items: _supplies
                                .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(
                                          '${s.name} (Qty: ${s.quantity})'),
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
                            validator: (val) {
                              if (val == null) return 'Select a supply';
                              return null;
                            },
                          ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: const Icon(Icons.numbers),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter quantity';
                        final num = double.tryParse(val);
                        if (num == null || num <= 0) {
                          return 'Enter a valid quantity (>0)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                  ],
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      prefixIcon: const Icon(Icons.edit_note),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter reason' : null,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('Submit Request',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
