import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/harvest_service.dart';
import '../services/farm_service.dart';
import '../services/laborer_service.dart';
import '../models/farm.dart';
import '../models/laborer.dart';

class HarvestFormScreen extends StatefulWidget {
  final String? token;
  final int? technicianId;

  const HarvestFormScreen({
    Key? key,
    this.token,
    this.technicianId,
  }) : super(key: key);

  @override
  State<HarvestFormScreen> createState() => _HarvestFormScreenState();
}

class _HarvestFormScreenState extends State<HarvestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mortalityController = TextEditingController();
  final _initialKgController = TextEditingController();
  final _farmSearchController = TextEditingController();
  final _laborerSearchController = TextEditingController();

  final _harvestService = HarvestService();
  final _farmService = FarmService();
  final _laborerService = LaborerService();

  List<Farm> _farms = [];
  List<Farm> _filteredFarms = [];
  Farm? _selectedFarm;
  List<Laborer> _allLaborers = [];
  List<Laborer> _filteredLaborers = [];
  List<Laborer> _selectedLaborers = [];
  bool _isLoading = false;
  bool _isLoadingFarms = false;
  bool _isLoadingLaborers = false;
  String? _errorMessage;
  String? _farmErrorMessage;
  String? _laborerErrorMessage;
  bool _isFarmDropdownExpanded = false;
  final FocusNode _farmDropdownFocusNode = FocusNode();
  final FocusNode _mortalityFocusNode = FocusNode();
  final FocusNode _initialKgFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _farmSearchController.addListener(_filterFarms);
    _laborerSearchController.addListener(_filterLaborers);
    _mortalityController.addListener(_saveDraft);
    _initialKgController.addListener(_saveDraft);
    _loadDraft();
    _loadFarms();
    _loadLaborers();
  }

  Future<void> _loadFarms() async {
    if (mounted) {
      setState(() {
        _isLoadingFarms = true;
        _farmErrorMessage = null;
      });
    }

    try {
      final farms = await _farmService.getFarmsByTechnician(widget.token!);
      if (mounted) {
        setState(() {
          _farms = farms;
          _filteredFarms = List.from(farms);
          _isLoadingFarms = false;
        });
        _restoreDraftAfterDataLoad();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _farmErrorMessage = 'Failed to load farms. Tap to retry.';
          _isLoadingFarms = false;
        });
      }
    }
  }

  Future<void> _loadLaborers() async {
    if (mounted) {
      setState(() {
        _isLoadingLaborers = true;
        _laborerErrorMessage = null;
      });
    }

    try {
      final laborers = await _laborerService.getAllLaborers(widget.token!);
      if (mounted) {
        setState(() {
          _allLaborers = laborers;
          _filteredLaborers = List.from(laborers);
          _isLoadingLaborers = false;
        });
        _restoreDraftAfterDataLoad();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _laborerErrorMessage = 'Failed to load laborers. Tap to retry.';
          _isLoadingLaborers = false;
        });
      }
    }
  }

  void _filterItems<T>({
    required TextEditingController searchController,
    required List<T> sourceList,
    required void Function(List<T>) setFilteredList,
    required bool Function(T item, String query) filterFunction,
  }) {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        setFilteredList(List.from(sourceList));
      } else {
        setFilteredList(
            sourceList.where((item) => filterFunction(item, query)).toList());
      }
    });
  }

  void _filterFarms() {
    _filterItems<Farm>(
      searchController: _farmSearchController,
      sourceList: _farms,
      setFilteredList: (filtered) => _filteredFarms = filtered,
      filterFunction: (farm, query) {
        final farmName = farm.name?.toLowerCase() ?? '';
        final farmAddress = farm.farmAddress.toLowerCase();
        return farmName.contains(query) || farmAddress.contains(query);
      },
    );
  }

  void _filterLaborers() {
    _filterItems<Laborer>(
      searchController: _laborerSearchController,
      sourceList: _allLaborers,
      setFilteredList: (filtered) => _filteredLaborers = filtered,
      filterFunction: (laborer, query) {
        final searchableText =
            '${laborer.firstName} ${laborer.lastName} ${laborer.phoneNumber ?? ''}'
                .toLowerCase();
        return searchableText.contains(query);
      },
    );
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = {
        'selectedFarmId': _selectedFarm?.id,
        'mortality': _mortalityController.text,
        'initialKg': _initialKgController.text,
        'selectedLaborerIds': _selectedLaborers.map((l) => l.id).toList(),
      };
      await prefs.setString('harvest_form_draft', jsonEncode(draft));
    } catch (e) {
      // Silently fail for draft saving
    }
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftString = prefs.getString('harvest_form_draft');
      if (draftString != null && mounted) {
        final draft = jsonDecode(draftString) as Map<String, dynamic>;

        setState(() {
          _mortalityController.text = draft['mortality'] ?? '';
          _initialKgController.text = draft['initialKg'] ?? '';

          // Load selected farm and laborers if available - will be handled after data is loaded
        });
      }
    } catch (e) {
      // Silently fail for draft loading
    }
  }

  Future<void> _restoreDraftAfterDataLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftString = prefs.getString('harvest_form_draft');
      if (draftString != null && mounted) {
        final draft = jsonDecode(draftString) as Map<String, dynamic>;

        setState(() {
          // Restore selected farm
          if (draft['selectedFarmId'] != null && _selectedFarm == null) {
            final farmId = draft['selectedFarmId'];
            try {
              final farm = _farms.firstWhere((f) => f.id == farmId);
              _selectedFarm = farm;
            } catch (e) {
              // Farm not found, keep null
            }
          }

          // Restore selected laborers
          if (draft['selectedLaborerIds'] != null &&
              _selectedLaborers.isEmpty) {
            final laborerIds = List<int>.from(draft['selectedLaborerIds']);
            final restoredLaborers =
                _allLaborers.where((l) => laborerIds.contains(l.id)).toList();
            _selectedLaborers = restoredLaborers;
          }
        });
      }
    } catch (e) {
      // Silently fail for draft restoration
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('harvest_form_draft');
    } catch (e) {
      // Silently fail
    }
  }

  Widget _buildInfoRowNoIcon(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF27AE60),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Confirm Submission',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please review before submitting',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Content - Made scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRowNoIcon(
                          'Farm',
                          _selectedFarm?.name ??
                              _selectedFarm?.farmAddress ??
                              'N/A'),
                      const SizedBox(height: 16),
                      _buildInfoRowNoIcon(
                          'Mortality', _mortalityController.text),
                      const SizedBox(height: 16),
                      _buildInfoRowNoIcon(
                          'Initial Weight (kg)', _initialKgController.text),
                      const SizedBox(height: 16),
                      _buildInfoRowNoIcon('Additional Laborers',
                          _selectedLaborers.length.toString()),
                      if (_selectedFarm?.farmWorkers.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        _buildInfoRowNoIcon('Farmers (auto-included)',
                            _selectedFarm!.farmWorkers.length.toString()),
                      ],
                      const SizedBox(height: 16),
                      _buildInfoRowNoIcon('Total People',
                          '${(_selectedFarm?.farmWorkers.length ?? 0) + _selectedLaborers.length}'),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _submitHarvest();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitHarvest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final harvestData = {
        'farm_id': _selectedFarm!.id,
        'mortality': int.parse(_mortalityController.text),
        'initial_kg': double.parse(_initialKgController.text),
        'laborer_ids': _selectedLaborers.map((l) => l.id).toList(),
      };

      final response =
          await _harvestService.submitHarvest(harvestData, widget.token!);

      if (!mounted) return;

      if (response['success'] == true) {
        await _clearDraft(); // Clear draft on successful submission
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Harvest report submitted successfully')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        final errorMessage = response['message'] ?? 'Failed to submit harvest';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Check if it's a duplicate submission error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('already') ||
          errorString.contains('duplicate') ||
          errorString.contains('exist')) {
        _showDuplicateSubmissionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit harvest: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDuplicateSubmissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with warning icon
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFE74C3C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Duplicate Submission',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Report already exists for this farm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.warning_amber_outlined,
                        color: Color(0xFFE74C3C),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A harvest report has already been submitted for this farm.',
                      style: TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Action button
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text('Got it'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLaborerPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFE0E0E0), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Laborers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _laborerSearchController.clear();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.grey[600],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Flexible(
                      child: Container(
                        height: 400,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Search field for laborers
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  8.0, 16.0, 8.0, 16.0),
                              child: Semantics(
                                label: 'Search laborers',
                                textField: true,
                                child: TextField(
                                  controller: _laborerSearchController,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      // This triggers the StatefulBuilder to rebuild
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search laborers...',
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
                                          color: Color(0xFF27AE60)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            // Laborers list
                            Expanded(
                              child: _isLoadingLaborers
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF27AE60)),
                                      ),
                                    )
                                  : _laborerErrorMessage != null
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.red[400],
                                                size: 48,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _laborerErrorMessage!,
                                                style: TextStyle(
                                                  color: Colors.red[700],
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                onPressed: _loadLaborers,
                                                icon: const Icon(Icons.refresh,
                                                    size: 16),
                                                label: const Text('Retry'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFF27AE60),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                                  textStyle: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _allLaborers.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'No laborers available',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : ListView.separated(
                                              padding: EdgeInsets.zero,
                                              itemCount:
                                                  _filteredLaborers.length,
                                              separatorBuilder:
                                                  (context, index) => Divider(
                                                height: 1,
                                                color: Colors.grey[200],
                                              ),
                                              itemBuilder: (context, index) {
                                                final laborer =
                                                    _filteredLaborers[index];
                                                final isSelected =
                                                    _selectedLaborers
                                                        .contains(laborer);
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 8,
                                                      horizontal: 4),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setDialogState(() {
                                                        if (isSelected) {
                                                          _selectedLaborers
                                                              .remove(laborer);
                                                        } else {
                                                          _selectedLaborers
                                                              .add(laborer);
                                                        }
                                                      });
                                                      setState(
                                                          () {}); // Update parent widget
                                                      _saveDraft(); // Save draft when selection changes
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 20,
                                                          height: 20,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color: isSelected
                                                                  ? const Color(
                                                                      0xFF27AE60)
                                                                  : Colors.grey[
                                                                      400]!,
                                                              width: 2,
                                                            ),
                                                            color: isSelected
                                                                ? const Color(
                                                                    0xFF27AE60)
                                                                : Colors
                                                                    .transparent,
                                                          ),
                                                          child: isSelected
                                                              ? const Center(
                                                                  child: Icon(
                                                                    Icons.check,
                                                                    size: 14,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                )
                                                              : null,
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                '${laborer.firstName} ${laborer.lastName}',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: isSelected
                                                                      ? const Color(
                                                                          0xFF2C3E50)
                                                                      : Colors.grey[
                                                                          700],
                                                                ),
                                                              ),
                                                              if (laborer
                                                                      .phoneNumber !=
                                                                  null) ...[
                                                                const SizedBox(
                                                                    height: 2),
                                                                Text(
                                                                  laborer
                                                                      .phoneNumber!,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                            .grey[
                                                                        500],
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Footer with buttons
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _laborerSearchController.clear();
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _laborerSearchController.clear();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27AE60),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 16,
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
            );
          },
        );
      },
    );
  }

  Widget _buildFarmOption({
    required Farm farm,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.name != null && farm.name!.isNotEmpty
                        ? farm.name!
                        : farm.farmAddress,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF2C3E50)
                          : Colors.grey[600],
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (farm.name != null && farm.name!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      farm.farmAddress,
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

  @override
  void dispose() {
    _farmSearchController.removeListener(_filterFarms);
    _laborerSearchController.removeListener(_filterLaborers);
    _mortalityController.removeListener(_saveDraft);
    _initialKgController.removeListener(_saveDraft);
    _farmSearchController.dispose();
    _laborerSearchController.dispose();
    _mortalityController.dispose();
    _initialKgController.dispose();
    _farmDropdownFocusNode.dispose();
    _mortalityFocusNode.dispose();
    _initialKgFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harvest Report'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Farm Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
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
                    Semantics(
                      label: 'Select farm dropdown',
                      hint: 'Choose a farm from the available list',
                      child: Text(
                        'Select Farm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        // Custom Dropdown Button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isFarmDropdownExpanded =
                                  !_isFarmDropdownExpanded;
                              if (_isFarmDropdownExpanded) {
                                _farmSearchController.clear();
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
                                Expanded(
                                  child: Text(
                                    _selectedFarm != null
                                        ? '${_selectedFarm!.farmAddress}${_selectedFarm!.name != null && _selectedFarm!.name!.isNotEmpty ? " - ${_selectedFarm!.name}" : ""}'
                                        : 'Choose a farm',
                                    style: TextStyle(
                                      color: _selectedFarm != null
                                          ? const Color(0xFF2C3E50)
                                          : Colors.grey[500],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                Icon(
                                  _isFarmDropdownExpanded
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
                        if (_isFarmDropdownExpanded) ...[
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
                                // Search field for farms
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Semantics(
                                    label: 'Search farms',
                                    textField: true,
                                    child: TextField(
                                      controller: _farmSearchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search farms...',
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
                                                horizontal: 12, vertical: 8),
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                Container(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: _isLoadingFarms
                                      ? const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Color(0xFF27AE60)),
                                            ),
                                          ),
                                        )
                                      : _farmErrorMessage != null
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.error_outline,
                                                    color: Colors.red[400],
                                                    size: 48,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _farmErrorMessage!,
                                                    style: TextStyle(
                                                      color: Colors.red[700],
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  ElevatedButton.icon(
                                                    onPressed: _loadFarms,
                                                    icon: const Icon(
                                                        Icons.refresh,
                                                        size: 16),
                                                    label: const Text('Retry'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF27AE60),
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 8),
                                                      textStyle:
                                                          const TextStyle(
                                                              fontSize: 12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : _filteredFarms.isEmpty
                                              ? const Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Center(
                                                    child: Text(
                                                      'No farms available',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  shrinkWrap: true,
                                                  padding: EdgeInsets.zero,
                                                  itemCount:
                                                      _filteredFarms.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final farm =
                                                        _filteredFarms[index];
                                                    return Column(
                                                      children: [
                                                        _buildFarmOption(
                                                          farm: farm,
                                                          isSelected:
                                                              _selectedFarm !=
                                                                      null &&
                                                                  _selectedFarm!
                                                                          .id ==
                                                                      farm.id,
                                                          onTap: () {
                                                            setState(() {
                                                              _selectedFarm =
                                                                  farm;
                                                              _isFarmDropdownExpanded =
                                                                  false;
                                                            });
                                                            _saveDraft();
                                                          },
                                                        ),
                                                        if (index <
                                                            _filteredFarms
                                                                    .length -
                                                                1)
                                                          const Divider(
                                                            height: 1,
                                                            color: Color(
                                                                0xFFE0E0E0),
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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Farm Workers Info (from selected farm)
              if (_selectedFarm != null &&
                  _selectedFarm!.farmWorkers.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF27AE60).withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.05),
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
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF27AE60),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Farmers (auto-included)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _selectedFarm!.farmWorkers
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final fw = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index <
                                        _selectedFarm!.farmWorkers.length - 1
                                    ? 8
                                    : 0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF27AE60)
                                          .withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${fw.firstName} ${fw.lastName}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        if (fw.phoneNumber != null &&
                                            fw.phoneNumber!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Contact: ${fw.phoneNumber!}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                        if (fw.address != null &&
                                            fw.address!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Address: ${fw.address!}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedFarm != null &&
                    _selectedFarm!.farmWorkers.isNotEmpty)
                  const SizedBox(height: 20),
              ],

              // Combined Laborers and Input Fields Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Laborers Section
                    const Text(
                      'Laborers Involved',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedLaborers.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedLaborers.map((laborer) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27AE60).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF27AE60).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${laborer.firstName} ${laborer.lastName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF27AE60),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedLaborers.remove(laborer);
                                    });
                                    _saveDraft();
                                  },
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF27AE60),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            label: 'Add laborers to the harvest report',
                            button: true,
                            child: OutlinedButton(
                              onPressed: () => _showLaborerPicker(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF27AE60),
                                side:
                                    const BorderSide(color: Color(0xFF27AE60)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(_selectedLaborers.isEmpty
                                  ? 'Add Laborers'
                                  : 'Add More Laborers'),
                            ),
                          ),
                        ),
                        if (_selectedLaborers.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Semantics(
                            label: 'Clear all selected laborers',
                            button: true,
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedLaborers.clear();
                                });
                                _saveDraft();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[600],
                                side: BorderSide(color: Colors.red[300]!),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Clear All'),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFE0E0E0), height: 1),
                    const SizedBox(height: 24),

                    // Mortality Section
                    const Text(
                      'Mortality',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Number of mortality',
                      hint: 'Enter the number of mortality',
                      textField: true,
                      child: TextFormField(
                        controller: _mortalityController,
                        focusNode: _mortalityFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Enter number of mortality',
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _saveDraft();
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter mortality count';
                          }
                          final number = int.tryParse(value);
                          if (number == null) {
                            return 'Please enter a valid number';
                          }
                          if (number < 0) {
                            return 'Number cannot be negative';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFE0E0E0), height: 1),
                    const SizedBox(height: 24),

                    // Initial Harvest Weight Section
                    const Text(
                      'Initial Harvest Weight',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Initial harvest weight in kg',
                      hint: 'Enter the initial harvest weight in kilograms',
                      textField: true,
                      child: TextFormField(
                        controller: _initialKgController,
                        focusNode: _initialKgFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Enter initial weight (kg)',
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _saveDraft();
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter initial weight';
                          }
                          final number = double.tryParse(value);
                          if (number == null) {
                            return 'Please enter a valid number';
                          }
                          if (number <= 0) {
                            return 'Weight must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              Semantics(
                label: 'Submit harvest report',
                hint: 'Tap to submit the harvest report with current form data',
                button: true,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (!_formKey.currentState!.validate()) return;
                          if (_selectedFarm == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select a farm')),
                            );
                            return;
                          }
                          _showConfirmationDialog();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Harvest Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
