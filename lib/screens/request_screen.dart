import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/equipment_service.dart';
import 'login_screen.dart';

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
  final TextEditingController _supplySearchController = TextEditingController();
  final TextEditingController _equipmentSearchController =
      TextEditingController();
  int? _selectedSupplyId;
  int? _selectedEquipmentId;
  List<InventoryItem> _supplies = [];
  List<Equipment> _equipment = [];
  List<InventoryItem> _filteredSupplies = [];
  List<Equipment> _filteredEquipment = [];
  bool _loadingSupplies = false;
  bool _loadingEquipment = false;
  bool _isDescriptionEnabled = false; //DITO RIN MAY CHANGES
  bool _isSubmitEnabled = false; //DITO RIN MAY CHANGES
  bool _isRequestTypeDropdownExpanded = false;
  bool _isSupplyDropdownExpanded = false;
  bool _isEquipmentDropdownExpanded = false;

  @override
  void initState() {
    super.initState();
    _supplySearchController.addListener(_filterSupplies);
    _equipmentSearchController.addListener(_filterEquipment);
    _loadFormDraft();
    _fetchSupplies();
    _fetchEquipment();

    // Add listeners for auto-save
    _reasonController.addListener(_saveFormDraft);
    _quantityController.addListener(_saveFormDraft);
    _amountController.addListener(_saveFormDraft);
    _durationController.addListener(_saveFormDraft);
    _returnDateController.addListener(_saveFormDraft);
  }

  @override
  void dispose() {
    _supplySearchController.removeListener(_filterSupplies);
    _equipmentSearchController.removeListener(_filterEquipment);

    // Remove auto-save listeners
    _reasonController.removeListener(_saveFormDraft);
    _quantityController.removeListener(_saveFormDraft);
    _amountController.removeListener(_saveFormDraft);
    _durationController.removeListener(_saveFormDraft);
    _returnDateController.removeListener(_saveFormDraft);

    // Save final draft before disposing
    _saveFormDraft();

    _supplyNameController.dispose();
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
    setState(() => _loadingSupplies = true);
    try {
      final supplies = await InventoryService().getInventory(widget.token);
      print('Fetched supplies: $supplies');
      setState(() {
        _supplies = supplies;
        _filteredSupplies = List.from(supplies);
      });
    } catch (e) {
      print('Error fetching supplies: $e');
      if (mounted) {
        if (e.toString().contains('AUTHENTICATION_EXPIRED')) {
          // Redirect to login screen when authentication expires
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate to login after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          });
        }
      }
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
      setState(() {
        _equipment = equipment;
        _filteredEquipment = List.from(equipment);
      });

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
        if (e.toString().contains('AUTHENTICATION_EXPIRED')) {
          // Redirect to login screen when authentication expires
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate to login after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to load equipment: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        'expected_return_date': _formatDateForApi(_returnDateController.text),
    };

    print('Request data being sent: $requestData');
    try {
      await RequestService().createRequest(widget.token, requestData);
      if (!mounted) return;

      // Clear form draft on successful submission
      _clearFormDraft();

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request submitted!')));
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg
          .contains('Only one request per technician per Farmer per day')) {
        errorMsg = 'You can only submit one request per Farmer per day.';
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
            color: Colors.green,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 24),
                  padding: EdgeInsets.zero,
                ),
                const Expanded(
                  child: Text(
                    'Request',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

                    // Form Progress Indicator
                    _buildFormProgress(),
                    const SizedBox(height: 16),

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
                    // Request Type Custom Dropdown
                    Column(
                      children: [
                        // Dropdown Header
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isRequestTypeDropdownExpanded =
                                  !_isRequestTypeDropdownExpanded;
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _requestType,
                                    style: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _isRequestTypeDropdownExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Dropdown Options
                        if (_isRequestTypeDropdownExpanded) ...[
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
                                _buildRequestTypeOption(
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Farm supply',
                                  isSelected: _requestType == 'Farm supply',
                                  onTap: () {
                                    setState(() {
                                      _requestType = 'Farm supply';
                                      _isRequestTypeDropdownExpanded = false;
                                    });
                                    _checkSubmitEnabled();
                                    _saveFormDraft();
                                  },
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.grey[200],
                                  thickness: 1,
                                ),
                                _buildRequestTypeOption(
                                  icon: Icons.credit_card_outlined,
                                  label: 'Cash advance',
                                  isSelected: _requestType == 'Cash advance',
                                  onTap: () {
                                    setState(() {
                                      _requestType = 'Cash advance';
                                      _isRequestTypeDropdownExpanded = false;
                                    });
                                    _checkSubmitEnabled();
                                    _saveFormDraft();
                                  },
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.grey[200],
                                  thickness: 1,
                                ),
                                _buildRequestTypeOption(
                                  icon: Icons.settings_outlined,
                                  label: 'Equipment',
                                  isSelected: _requestType == 'Equipment',
                                  onTap: () {
                                    setState(() {
                                      _requestType = 'Equipment';
                                      _isRequestTypeDropdownExpanded = false;
                                    });
                                    _checkSubmitEnabled();
                                    _saveFormDraft();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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
                          : Column(
                              children: [
                                // Supply Dropdown Header
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      final wasExpanded =
                                          _isSupplyDropdownExpanded;
                                      _isSupplyDropdownExpanded =
                                          !_isSupplyDropdownExpanded;
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
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
                                            _selectedSupplyId != null &&
                                                    _supplies.isNotEmpty
                                                ? _supplies.any((s) =>
                                                        s.id ==
                                                        _selectedSupplyId)
                                                    ? '${_supplies.firstWhere((s) => s.id == _selectedSupplyId).name} (Qty: ${_supplies.firstWhere((s) => s.id == _selectedSupplyId).quantity})'
                                                    : 'Select supply'
                                                : 'Select supply',
                                            style: TextStyle(
                                              color: _selectedSupplyId !=
                                                          null &&
                                                      _supplies.isNotEmpty &&
                                                      _supplies.any((s) =>
                                                          s.id ==
                                                          _selectedSupplyId)
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
                                // Supply Dropdown Options
                                if (_isSupplyDropdownExpanded &&
                                    _supplies.isNotEmpty) ...[
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
                                        // Search field for supplies
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                    color: Color(0xFF27AE60)),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                            ),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(
                                              maxHeight: 160),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            padding: EdgeInsets.zero,
                                            itemCount: _filteredSupplies.length,
                                            itemBuilder: (context, index) {
                                              final supply =
                                                  _filteredSupplies[index];
                                              return Column(
                                                children: [
                                                  _buildSupplyOption(
                                                    supply: supply,
                                                    isSelected:
                                                        _selectedSupplyId ==
                                                            supply.id,
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedSupplyId =
                                                            supply.id;
                                                        _supplyNameController
                                                            .text = supply.name;
                                                        _isSupplyDropdownExpanded =
                                                            false;
                                                      });
                                                      _checkSubmitEnabled();
                                                      _saveFormDraft();
                                                    },
                                                  ),
                                                  if (index <
                                                      _filteredSupplies.length -
                                                          1)
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
                        onChanged: (value) {
                          _checkSubmitEnabled();
                          _onQuantityChanged(value);
                        },
                        validator: (val) => _validateSupplyQuantity(val),
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
                          : Column(
                              children: [
                                // Equipment Dropdown Header
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      final wasExpanded =
                                          _isEquipmentDropdownExpanded;
                                      _isEquipmentDropdownExpanded =
                                          !_isEquipmentDropdownExpanded;
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
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
                                            _selectedEquipmentId != null &&
                                                    _equipment.isNotEmpty
                                                ? _equipment.any((e) =>
                                                        e.id ==
                                                        _selectedEquipmentId)
                                                    ? '${_equipment.firstWhere((e) => e.id == _selectedEquipmentId).equipmentName} (${_equipment.firstWhere((e) => e.id == _selectedEquipmentId).serialNumber})'
                                                    : 'Select equipment'
                                                : 'Select equipment',
                                            style: TextStyle(
                                              color: _selectedEquipmentId !=
                                                          null &&
                                                      _equipment.isNotEmpty &&
                                                      _equipment.any((e) =>
                                                          e.id ==
                                                          _selectedEquipmentId)
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
                                // Equipment Dropdown Options
                                if (_isEquipmentDropdownExpanded &&
                                    _equipment.isNotEmpty) ...[
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
                                        // Search field for equipment
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: TextField(
                                            controller:
                                                _equipmentSearchController,
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                    color: Color(0xFF27AE60)),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                            ),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(
                                              maxHeight: 160),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            padding: EdgeInsets.zero,
                                            itemCount:
                                                _filteredEquipment.length,
                                            itemBuilder: (context, index) {
                                              final equipment =
                                                  _filteredEquipment[index];
                                              return Column(
                                                children: [
                                                  _buildEquipmentOption(
                                                    equipment: equipment,
                                                    isSelected:
                                                        _selectedEquipmentId ==
                                                            equipment.id,
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedEquipmentId =
                                                            equipment.id;
                                                        _isEquipmentDropdownExpanded =
                                                            false;
                                                      });
                                                      _checkSubmitEnabled();
                                                      _saveFormDraft();
                                                    },
                                                  ),
                                                  if (index <
                                                      _filteredEquipment
                                                              .length -
                                                          1)
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
                            ),
                      const SizedBox(height: 16),
                      // Duration Field for Equipment
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
                        onChanged: (value) {
                          _checkSubmitEnabled();
                          _validateEquipmentContext();
                          // Auto-calculate return date
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
                              color: Colors.grey[600], size: 18),
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
                            _returnDateController.text = _formatDate(date);
                            _checkSubmitEnabled();
                          }
                        },
                        validator: (val) => _validateReturnDate(val),
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

  Widget _buildRequestTypeOption({
    required IconData icon,
    required String label,
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
              icon,
              color: Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? const Color(0xFF2C3E50) : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
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
                    color: Colors.grey[400]!,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
                    color: Colors.grey[400]!,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
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
                      ),
                      _buildEquipmentStatusChip(equipment),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/N: ${equipment.serialNumber}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  if (equipment.category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Category: ${equipment.category}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (equipment.location != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Location: ${equipment.location}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
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
                    color: Colors.grey[400]!,
                    width: 2,
                  ),
                ),
              ),
          ],
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

  // Helper method to convert MM-DD-YYYY format to YYYY-MM-DD (for API)
  String _formatDateForApi(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final month = parts[0].padLeft(2, '0');
        final day = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (e) {
      print('Error parsing date: $dateString');
    }
    return dateString; // Return original if parsing fails
  }

  // Smart validation: Check supply quantity against available stock
  String? _validateSupplyQuantity(String? val) {
    if (val == null || val.isEmpty) {
      return 'Enter quantity';
    }
    if (int.tryParse(val) == null) {
      return 'Invalid quantity';
    }

    final requestedQty = int.parse(val);
    if (requestedQty <= 0) {
      return 'Quantity must be greater than 0';
    }

    // Smart validation: Check against available stock
    if (_selectedSupplyId != null) {
      try {
        final selectedSupply =
            _supplies.firstWhere((s) => s.id == _selectedSupplyId);
        if (requestedQty > selectedSupply.quantity) {
          return 'Only ${selectedSupply.quantity} available. You requested $requestedQty';
        }
      } catch (e) {
        // Supply not found, let it pass for now
        print('Selected supply not found: $e');
      }
    }

    return null;
  }

  // Smart error prevention with real-time quantity validation
  void _onQuantityChanged(String value) {
    final quantity = int.tryParse(value);
    if (quantity != null && _selectedSupplyId != null) {
      try {
        final selectedSupply =
            _supplies.firstWhere((s) => s.id == _selectedSupplyId);

        if (quantity > selectedSupply.quantity) {
          _showQuantityError(
              'Only ${selectedSupply.quantity} available. Maximum: ${selectedSupply.quantity}');
        }
      } catch (e) {
        print('Error validating quantity: $e');
      }
    }
  }

  void _showQuantityError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (_selectedSupplyId != null) {
                  try {
                    final selectedSupply =
                        _supplies.firstWhere((s) => s.id == _selectedSupplyId);
                    _quantityController.text =
                        selectedSupply.quantity.toString();
                    setState(() {});
                  } catch (e) {
                    print('Error setting max quantity: $e');
                  }
                }
              },
              child: const Text('Use maximum available'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Real-time form progress indicator
  Widget _buildFormProgress() {
    int completedFields = 0;
    int totalFields = 0;

    // Request type - always completed if form is open
    totalFields++;
    completedFields++;

    // Dynamic fields based on request type
    if (_requestType == 'Farm supply') {
      totalFields += 3; // supply, quantity, reason
      if (_selectedSupplyId != null) completedFields++;
      if (_quantityController.text.isNotEmpty) completedFields++;
      if (_reasonController.text.isNotEmpty) completedFields++;
    } else if (_requestType == 'Equipment') {
      totalFields += 4; // equipment, duration, return date, reason
      if (_selectedEquipmentId != null) completedFields++;
      if (_durationController.text.isNotEmpty) completedFields++;
      if (_returnDateController.text.isNotEmpty) completedFields++;
      if (_reasonController.text.isNotEmpty) completedFields++;
    } else if (_requestType == 'Cash advance') {
      totalFields += 2; // amount, reason
      if (_amountController.text.isNotEmpty) completedFields++;
      if (_reasonController.text.isNotEmpty) completedFields++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Form Progress',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: totalFields > 0 ? completedFields / totalFields : 0.0,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            completedFields == totalFields ? Colors.green : Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$completedFields of $totalFields fields completed',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Equipment availability status chip
  Widget _buildEquipmentStatusChip(Equipment equipment) {
    final isAvailable = equipment.status.toLowerCase() == 'available' ||
        equipment.status.toLowerCase() == 'in stock';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isAvailable ? 'Available' : 'In Use',
        style: TextStyle(
          color: isAvailable ? Colors.green[800] : Colors.red[800],
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Enhanced date validation with smart rules
  String? _validateReturnDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Select return date';
    }

    final returnDate = _parseDateForValidation(value);
    if (returnDate == null) {
      return 'Invalid date format';
    }

    final today = DateTime.now();
    final maxReturnDate = today.add(const Duration(days: 365));

    if (returnDate.isBefore(today.add(const Duration(days: 1)))) {
      return 'Return date must be at least 1 day from now';
    }

    if (returnDate.isAfter(maxReturnDate)) {
      return 'Return date cannot exceed 1 year from now';
    }

    // Check if it's reasonable based on borrow duration
    final borrowDays = int.tryParse(_durationController.text) ?? 0;
    if (borrowDays > 0) {
      final expectedDate = today.add(Duration(days: borrowDays));
      final daysDifference = (returnDate.difference(expectedDate).inDays).abs();

      if (daysDifference > 7 && borrowDays > 0) {
        return 'Return date seems inconsistent with borrow duration';
      }
    }

    return null;
  }

  // Equipment context validation based on borrow duration and equipment type
  void _validateEquipmentContext() {
    if (_selectedEquipmentId != null && _durationController.text.isNotEmpty) {
      final duration = int.tryParse(_durationController.text);

      try {
        final equipment =
            _equipment.firstWhere((e) => e.id == _selectedEquipmentId);

        if (duration != null && duration > 0) {
          // Check if duration is reasonable for this equipment type
          if (duration > 30) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Long rental period for ${equipment.equipmentName}. Consider shorter duration.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (duration > 14 &&
              (equipment.equipmentName.toLowerCase().contains('tractor') ||
                  equipment.equipmentName
                      .toLowerCase()
                      .contains('harvester'))) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Long duration for heavy equipment. Please confirm ${duration} days is appropriate.'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        print('Error validating equipment context: $e');
      }
    }
  }

  DateTime? _parseDateForValidation(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date for validation: $dateString');
    }
    return null;
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

  // Form persistence methods
  void _saveFormDraft() {
    final draft = {
      'requestType': _requestType,
      'selectedSupplyId': _selectedSupplyId,
      'selectedEquipmentId': _selectedEquipmentId,
      'quantity': _quantityController.text,
      'amount': _amountController.text,
      'duration': _durationController.text,
      'returnDate': _returnDateController.text,
      'reason': _reasonController.text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Save to shared preferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
          'request_draft_${widget.farmWorker.id}', json.encode(draft));
    });
  }

  void _loadFormDraft() {
    SharedPreferences.getInstance().then((prefs) {
      final draftString =
          prefs.getString('request_draft_${widget.farmWorker.id}');
      if (draftString != null) {
        try {
          final draft = json.decode(draftString);
          final timestamp = draft['timestamp'] ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;

          // Only load draft if it's less than 24 hours old
          if ((now - timestamp) < (24 * 60 * 60 * 1000)) {
            setState(() {
              _requestType = draft['requestType'] ?? 'Farm supply';
              _selectedSupplyId = draft['selectedSupplyId'];
              _selectedEquipmentId = draft['selectedEquipmentId'];
              _quantityController.text = draft['quantity'] ?? '';
              _amountController.text = draft['amount'] ?? '';
              _durationController.text = draft['duration'] ?? '';
              _returnDateController.text = draft['returnDate'] ?? '';
              _reasonController.text = draft['reason'] ?? '';
            });

            // Show draft recovery dialog
            _showDraftRecoveryDialog();
          } else {
            // Clear old draft
            prefs.remove('request_draft_${widget.farmWorker.id}');
          }
        } catch (e) {
          print('Error loading form draft: $e');
        }
      }
    });
  }

  void _showDraftRecoveryDialog() {
    // Only show if there's actually content to recover
    if (_quantityController.text.isNotEmpty ||
        _amountController.text.isNotEmpty ||
        _durationController.text.isNotEmpty ||
        _returnDateController.text.isNotEmpty ||
        _reasonController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Less border radius
              ),
              title: const Text('Recover Draft'),
              content: const Text(
                  'A previous draft was found. Do you want to continue where you left off?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetFormToFresh(); // Reset all form fields
                  },
                  child: const Text('Start Fresh'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _checkSubmitEnabled();
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  void _clearFormDraft() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('request_draft_${widget.farmWorker.id}');
    });
  }

  void _resetFormToFresh() {
    setState(() {
      // Reset request type to default
      _requestType = 'Farm supply';

      // Clear all selected values
      _selectedSupplyId = null;
      _selectedEquipmentId = null;

      // Clear all text controllers
      _quantityController.clear();
      _amountController.clear();
      _durationController.clear();
      _returnDateController.clear();
      _reasonController.clear();
      _supplyNameController.clear();
      _supplySearchController.clear();
      _equipmentSearchController.clear();

      // Close any expanded dropdowns
      _isRequestTypeDropdownExpanded = false;
      _isSupplyDropdownExpanded = false;
      _isEquipmentDropdownExpanded = false;

      // Update form state
      _checkSubmitEnabled();
    });

    // Clear the saved draft
    _clearFormDraft();
  }
}
