import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/equipment_service.dart';

class RequestScreen extends StatefulWidget {
  final FarmWorker farmWorker;
  final String token;
  const RequestScreen({Key? key, required this.farmWorker, required this.token})
      : super(key: key);

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  String _requestType = 'Farm supply'; //DITO RIN MAY CHANGES
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _supplyNameController =
      TextEditingController(); //DITO RIN MAY CHANGES
  final TextEditingController _amountController =
      TextEditingController(); //DITO RIN MAY CHANGES
  final TextEditingController _quantityController =
      TextEditingController(); //DITO RIN MAY CHANGES
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _returnDateController = TextEditingController();
  int? _selectedSupplyId;
  int? _selectedEquipmentId;
  List<InventoryItem> _supplies = [];
  List<Equipment> _equipment = [];
  bool _loadingSupplies = false;
  bool _loadingEquipment = false;
  bool _isDescriptionEnabled = false; //DITO RIN MAY CHANGES
  bool _isSubmitEnabled = false; //DITO RIN MAY CHANGES

  @override
  void initState() {
    super.initState();
    _fetchSupplies();
    _fetchEquipment();
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

  void _fetchEquipment() async {
    setState(() => _loadingEquipment = true);
    try {
      print('[RequestScreen] Fetching available equipment...');
      final equipment =
          await EquipmentService().getAvailableEquipment(widget.token);
      print('[RequestScreen] Fetched ${equipment.length} equipment items');
      setState(() => _equipment = equipment);

      if (equipment.isEmpty) {
        print('[RequestScreen] No available equipment found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No available equipment found. All equipment may be in use.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('[RequestScreen] Error fetching equipment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to load equipment: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _loadingEquipment = false);
  }

// DITO RIN MAY CHANGES
  void _checkSubmitEnabled() {
    setState(() {
      bool hasRequiredFields = false;
      if (_requestType == 'Farm supply') {
        hasRequiredFields = _selectedSupplyId != null &&
            _quantityController.text.isNotEmpty &&
            _reasonController.text.isNotEmpty;
      } else if (_requestType == 'Cash advance') {
        hasRequiredFields = _amountController.text.isNotEmpty &&
            _reasonController.text.isNotEmpty;
      } else if (_requestType == 'Equipment') {
        hasRequiredFields = _selectedEquipmentId != null &&
            _durationController.text.isNotEmpty &&
            _returnDateController.text.isNotEmpty &&
            _reasonController.text.isNotEmpty;
      }
      _isSubmitEnabled =
          _isDescriptionEnabled && _requestType.isNotEmpty && hasRequiredFields;
    });
  }

  void _submit() async {
    if (!_isSubmitEnabled) return;
    if (!_formKey.currentState!.validate()) return;
// HANGGANG DITO
    final requestData = {
      'farm_worker_id': widget.farmWorker.id,
      'technician_id': widget.farmWorker.technicianId,
      'request_type': _requestType == 'Farm supply'
          ? 'Supply'
          : _requestType == 'Cash advance'
              ? 'Cash Advance'
              : 'Equipment',
      'description': _reasonController.text,
      'status': 'Pending',
      'timestamp': DateTime.now().toIso8601String(),
      if (_requestType == 'Farm supply') 'supply_id': _selectedSupplyId,
      if (_requestType == 'Farm supply')
        'quantity': int.tryParse(_quantityController.text),
      if (_requestType == 'Cash advance')
        'amount': double.tryParse(_amountController.text),
      if (_requestType == 'Equipment') 'equipment_id': _selectedEquipmentId,
      if (_requestType == 'Equipment')
        'borrow_duration_days': int.tryParse(_durationController.text),
      if (_requestType == 'Equipment')
        'expected_return_date': _returnDateController.text,
    };

    print('Request data being sent: $requestData');
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
    // DITO RIN YUNG CHANGES HANNGANG SA LAST LINE NATO
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with back button and title
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: 10,
            ),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back,
                      color: Color(0xFF2C3E50), size: 24),
                  padding: EdgeInsets.zero,
                ),
                const Expanded(
                  child: Text(
                    'Request',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Farm Worker Information Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          // Profile picture
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8D5FF),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                widget.farmWorker.firstName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF6B21A8),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.farmWorker.firstName} ${widget.farmWorker.lastName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.farmWorker.address ??
                                      'Complete address',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.farmWorker.phoneNumber,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Request Type Field
                    const Text(
                      'Request type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ListTile(
                        title: Text(
                          _requestType,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey[600]),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Select Request Type'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text('Farm supply'),
                                    onTap: () {
                                      setState(
                                          () => _requestType = 'Farm supply');
                                      _checkSubmitEnabled();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: const Text('Cash advance'),
                                    onTap: () {
                                      setState(
                                          () => _requestType = 'Cash advance');
                                      _checkSubmitEnabled();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: const Text('Equipment'),
                                    onTap: () {
                                      setState(
                                          () => _requestType = 'Equipment');
                                      _checkSubmitEnabled();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Second Field - Changes based on request type
                    if (_requestType == 'Farm supply') ...[
                      // Supply Name Field
                      const Text(
                        'Supply name',
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
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            )
                          : DropdownButtonFormField<int>(
                              value: _selectedSupplyId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Select supply',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF27AE60)),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: _supplies
                                  .map((s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(
                                            '${s.name} (Qty: ${s.quantity})'),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _selectedSupplyId = val);
                                _supplyNameController.text = _supplies
                                    .firstWhere((s) => s.id == val)
                                    .name;
                                _checkSubmitEnabled();
                              },
                              validator: (val) {
                                if (val == null) return 'Select a supply';
                                return null;
                              },
                            ),
                      const SizedBox(height: 16),
                      // Quantity Field for Supply
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
                          hintText: 'Enter quantity (e.g. 5)',
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
                        onChanged: (value) => _checkSubmitEnabled(),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter quantity';
                          }
                          if (int.tryParse(val) == null) {
                            return 'Invalid quantity';
                          }
                          if (int.parse(val) <= 0) {
                            return 'Quantity must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ] else if (_requestType == 'Cash advance') ...[
                      // Cash Amount Field
                      const Text(
                        'Cash amount',
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
                          hintText: 'Enter amount (e.g. 1000)',
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
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) => _checkSubmitEnabled(),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter amount';
                          if (double.tryParse(val) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),
                    ] else if (_requestType == 'Equipment') ...[
                      // Equipment Selection Field
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
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            )
                          : DropdownButtonFormField<int>(
                              value: _selectedEquipmentId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Select equipment',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF27AE60)),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: _equipment
                                  .map((e) => DropdownMenuItem(
                                        value: e.id,
                                        child: Text(
                                            '${e.equipmentName} (${e.serialNumber})'),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _selectedEquipmentId = val);
                                _checkSubmitEnabled();
                              },
                              validator: (val) {
                                if (val == null) return 'Select equipment';
                                return null;
                              },
                            ),
                      const SizedBox(height: 16),
                      // Duration Field for Equipment
                      const Text(
                        'Borrow Duration (Days)',
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
                        decoration: InputDecoration(
                          hintText: 'Enter duration in days (e.g. 7)',
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
                        onChanged: (value) {
                          _checkSubmitEnabled();
                          // Auto-calculate return date
                          if (value.isNotEmpty) {
                            final days = int.tryParse(value);
                            if (days != null && days > 0) {
                              final returnDate =
                                  DateTime.now().add(Duration(days: days));
                              _returnDateController.text =
                                  '${returnDate.year}-${returnDate.month.toString().padLeft(2, '0')}-${returnDate.day.toString().padLeft(2, '0')}';
                            }
                          }
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter duration';
                          }
                          if (int.tryParse(val) == null) {
                            return 'Invalid duration';
                          }
                          if (int.parse(val) <= 0) {
                            return 'Duration must be greater than 0';
                          }
                          if (int.parse(val) > 365) {
                            return 'Duration cannot exceed 365 days';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Expected Return Date Field
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
                              color: Colors.grey[600]),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate:
                                DateTime.now().add(const Duration(days: 1)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            _returnDateController.text =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            _checkSubmitEnabled();
                          }
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Select return date';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

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
                      onChanged: (value) => _checkSubmitEnabled(),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter reason' : null,
                    ),
                    const SizedBox(height: 24),

                    // Request Summary Section
                    const Text(
                      'Request Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Request type', _requestType),
                          const SizedBox(height: 8),
                          if (_requestType == 'Farm supply') ...[
                            _buildSummaryRow(
                                'Supply name',
                                _supplyNameController.text.isEmpty
                                    ? 'Not selected'
                                    : _supplyNameController.text),
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                                'Quantity',
                                _quantityController.text.isEmpty
                                    ? 'Not entered'
                                    : _quantityController.text),
                          ] else if (_requestType == 'Cash advance')
                            _buildSummaryRow(
                                'Cash amount',
                                _amountController.text.isEmpty
                                    ? 'Not entered'
                                    : '₱${_amountController.text}')
                          else if (_requestType == 'Equipment') ...[
                            _buildSummaryRow(
                                'Equipment',
                                _selectedEquipmentId == null
                                    ? 'Not selected'
                                    : _equipment
                                        .firstWhere(
                                            (e) => e.id == _selectedEquipmentId)
                                        .equipmentName),
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                                'Duration',
                                _durationController.text.isEmpty
                                    ? 'Not entered'
                                    : '${_durationController.text} days'),
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                                'Return Date',
                                _returnDateController.text.isEmpty
                                    ? 'Not selected'
                                    : _returnDateController.text),
                          ],
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                              'Reason',
                              _reasonController.text.isEmpty
                                  ? 'Not provided'
                                  : _reasonController.text),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _isDescriptionEnabled,
                  onChanged: (value) {
                    setState(() => _isDescriptionEnabled = value ?? false);
                    _checkSubmitEnabled();
                  },
                  activeColor: const Color(0xFF27AE60),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'I confirm the request details are correct',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitEnabled ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubmitEnabled
                          ? const Color(0xFF27AE60)
                          : Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }
}
