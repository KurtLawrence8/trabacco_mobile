import 'package:flutter/material.dart';
import '../models/laborer.dart';
import '../models/schedule.dart';
import '../services/laborer_service.dart';
import '../services/schedule_service.dart';

class LaborerAssignmentDialog extends StatefulWidget {
  final Schedule schedule;
  final int farmWorkerId;
  final String token;
  final Function(Schedule) onScheduleUpdated;

  const LaborerAssignmentDialog({
    Key? key,
    required this.schedule,
    required this.farmWorkerId,
    required this.token,
    required this.onScheduleUpdated,
  }) : super(key: key);

  @override
  State<LaborerAssignmentDialog> createState() =>
      _LaborerAssignmentDialogState();
}

class _LaborerAssignmentDialogState extends State<LaborerAssignmentDialog> {
  final LaborerService _laborerService = LaborerService();
  final ScheduleService _scheduleService = ScheduleService();

  // Form controllers
  final _unitController = TextEditingController();
  final _budgetController = TextEditingController();

  // State variables
  bool _isLoading = false;
  List<Laborer> _selectedLaborers = []; // Changed to support multiple selection
  List<Laborer> _laborers = [];
  String _searchQuery = '';

  // New laborer forms list
  List<Map<String, String>> _newLaborers = [];

  @override
  void initState() {
    super.initState();
    _loadLaborers();
    _addNewLaborerForm(); // Add one empty form initially
  }

  @override
  void dispose() {
    _unitController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadLaborers() async {
    setState(() => _isLoading = true);
    try {
      final laborers = await _laborerService.getLaborersByFarmWorker(
        widget.farmWorkerId,
        widget.token,
      );
      setState(() {
        _laborers = laborers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load laborers: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addNewLaborerForm() {
    setState(() {
      _newLaborers.add({
        'firstName': '',
        'middleName': '',
        'lastName': '',
        'phoneNumber': '',
      });
    });
  }

  void _removeNewLaborerForm(int index) {
    setState(() {
      _newLaborers.removeAt(index);
    });
  }

  void _updateNewLaborerField(int index, String field, String value) {
    setState(() {
      _newLaborers[index][field] = value;
    });
  }

  bool _hasValidLaborers() {
    // Check if we have at least one selected existing laborer or one valid new laborer
    bool hasSelectedLaborers = _selectedLaborers.isNotEmpty;
    bool hasValidNewLaborers = _newLaborers.any((laborer) =>
        laborer['firstName']!.trim().isNotEmpty &&
        laborer['middleName']!.trim().isNotEmpty &&
        laborer['lastName']!.trim().isNotEmpty);

    return hasSelectedLaborers || hasValidNewLaborers;
  }

  Future<void> _assignMultipleLaborers() async {
    if (!_hasValidLaborers()) {
      _showErrorSnackBar(
          'Please select at least one existing laborer or add at least one new laborer');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Prepare existing laborer IDs
      final existingLaborerIds =
          _selectedLaborers.map((laborer) => laborer.id).toList();

      // Prepare new laborers data
      final newLaborers = _newLaborers
          .where((laborer) =>
              laborer['firstName']!.trim().isNotEmpty &&
              laborer['middleName']!.trim().isNotEmpty &&
              laborer['lastName']!.trim().isNotEmpty)
          .map((laborer) => <String, String?>{
                'first_name': laborer['firstName']!.trim(),
                'middle_name': laborer['middleName']!.trim(),
                'last_name': laborer['lastName']!.trim(),
                'phone_number': laborer['phoneNumber']!.trim().isEmpty
                    ? null
                    : laborer['phoneNumber']!.trim(),
              })
          .toList();

      // Use the new multiple laborer assignment API
      final result = await _scheduleService.assignMultipleLaborersAndComplete(
        scheduleId: widget.schedule.id!,
        existingLaborerIds:
            existingLaborerIds.isNotEmpty ? existingLaborerIds : null,
        newLaborers: newLaborers.isNotEmpty ? newLaborers : null,
        unit: _unitController.text.trim().isEmpty
            ? null
            : _unitController.text.trim(),
        budget: _budgetController.text.trim().isEmpty
            ? null
            : double.tryParse(_budgetController.text.trim()),
        token: widget.token,
      );

      widget.onScheduleUpdated(result['schedule']);

      final totalAssigned = result['total_assigned'] as int;
      _showSuccessSnackBar(
          'Schedule completed with $totalAssigned laborer(s) assigned');

      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Failed to assign laborers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Assign Laborer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Schedule info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule: ${widget.schedule.activity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (widget.schedule.date != null)
                            Text(
                              'Date: ${widget.schedule.date!.day}/${widget.schedule.date!.month}/${widget.schedule.date!.year}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Multiple laborer assignment section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade600, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Assign Multiple Laborers',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can select existing laborers and/or add new ones. Mix and match as needed.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Existing laborers section
                    _buildExistingLaborerSelection(),

                    const SizedBox(height: 20),

                    // New laborers section
                    _buildNewLaborerForm(),

                    const SizedBox(height: 20),

                    // Unit and Budget fields (common for both)
                    _buildUnitAndBudgetFields(),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _assignMultipleLaborers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Assign & Complete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewLaborerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'New Laborers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _addNewLaborerForm,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              tooltip: 'Add Another Laborer',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of new laborer forms
        ...List.generate(_newLaborers.length, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Laborer ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_newLaborers.length > 1)
                      IconButton(
                        onPressed: () => _removeNewLaborerForm(index),
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                        iconSize: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Name fields
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) =>
                            _updateNewLaborerField(index, 'firstName', value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Middle Name *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) =>
                            _updateNewLaborerField(index, 'middleName', value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Last Name *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) =>
                            _updateNewLaborerField(index, 'lastName', value),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Phone number
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) =>
                      _updateNewLaborerField(index, 'phoneNumber', value),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExistingLaborerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Existing Laborers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_selectedLaborers.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedLaborers.length} selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Search field
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search laborers...',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () => setState(() => _searchQuery = ''),
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
        ),

        const SizedBox(height: 12),

        // Laborers list
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildLaborersList(),
        ),
      ],
    );
  }

  Widget _buildLaborersList() {
    final filteredLaborers = _searchQuery.isEmpty
        ? _laborers
        : _laborers
            .where((laborer) =>
                laborer.fullName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (laborer.phoneNumber?.contains(_searchQuery) ?? false))
            .toList();

    if (filteredLaborers.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No laborers available'
              : 'No laborers found matching "$_searchQuery"',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredLaborers.length,
      itemBuilder: (context, index) {
        final laborer = filteredLaborers[index];
        final isSelected =
            _selectedLaborers.any((selected) => selected.id == laborer.id);

        return ListTile(
          title: Text(laborer.fullName),
          subtitle:
              laborer.phoneNumber != null ? Text(laborer.phoneNumber!) : null,
          leading: CircleAvatar(
            backgroundColor:
                isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            child: Icon(
              isSelected ? Icons.check : Icons.person,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
          selected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedLaborers
                    .removeWhere((selected) => selected.id == laborer.id);
              } else {
                _selectedLaborers.add(laborer);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildUnitAndBudgetFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
