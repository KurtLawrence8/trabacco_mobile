import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/report_service.dart';
import '../services/farm_service.dart';
import '../services/laborer_service.dart';
import '../services/coordinator_service.dart';
import '../models/farm.dart';
import '../models/laborer.dart';

class AccomplishmentFormScreen extends StatefulWidget {
  final String? token;
  final int? technicianId;
  final File? initialPhoto;
  final Position? initialPosition;
  final Farm? detectedFarm;

  const AccomplishmentFormScreen({
    Key? key,
    this.token,
    this.technicianId,
    this.initialPhoto,
    this.initialPosition,
    this.detectedFarm,
  }) : super(key: key);

  @override
  State<AccomplishmentFormScreen> createState() =>
      _AccomplishmentFormScreenState();
}

class _AccomplishmentFormScreenState extends State<AccomplishmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reportService = ReportService();
  final _farmService = FarmService();
  final _laborerService = LaborerService();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isLocationLoading = false;
  Position? _currentPosition;
  Farm? _selectedFarm;
  List<Farm> _farms = [];
  List<Farm> _filteredFarms = [];
  List<File> _photos = [];
  List<Laborer> _allLaborers = [];
  List<Laborer> _selectedLaborers = [];
  bool _isFarmDropdownExpanded = false;
  bool _isDiseaseDropdownExpanded = false;
  final TextEditingController _farmSearchController = TextEditingController();
  final TextEditingController _laborerSearchController =
      TextEditingController();

  final TextEditingController _accomplishmentsController =
      TextEditingController();
  final TextEditingController _issuesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _diseaseTypeController = TextEditingController();

  List<Laborer> _filteredLaborers = [];
  bool _isLoadingLaborers = false;
  String? _laborerErrorMessage;
  String _diseaseDetected = 'None';

  // Area Coordinator selection
  int? _selectedCoordinatorId;
  List<Map<String, dynamic>> _coordinators = [];
  bool _loadingCoordinators = false;

  @override
  void initState() {
    super.initState();
    _loadCoordinators();
    _loadFarms();
    _loadLaborers();

    // Add listeners for search controllers
    _farmSearchController.addListener(_filterFarms);
    _laborerSearchController.addListener(_filterLaborers);

    // If initial data is provided from camera, use it
    if (widget.initialPhoto != null) {
      _photos.add(widget.initialPhoto!);
    }

    if (widget.initialPosition != null) {
      _currentPosition = widget.initialPosition;
    } else {
      _getCurrentLocation();
    }

    if (widget.detectedFarm != null) {
      _selectedFarm = widget.detectedFarm;
    }
  }

  Future<void> _loadCoordinators() async {
    if (widget.token == null) return;

    setState(() {
      _loadingCoordinators = true;
    });

    try {
      final coordinators =
          await CoordinatorService.getActiveCoordinators(widget.token!);
      if (mounted) {
        setState(() {
          _coordinators = coordinators;
          _loadingCoordinators = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCoordinators = false;
        });
      }
    }
  }

  Future<void> _loadFarms() async {
    try {
      final farms = await _farmService.getFarmsByTechnician(widget.token!);
      if (mounted) {
        setState(() {
          _farms = farms;
          _filteredFarms = List.from(farms);
        });
      }
    } catch (e) {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _laborerErrorMessage = e.toString();
          _isLoadingLaborers = false;
        });
      }
    }
  }

  void _filterFarms() {
    final query = _farmSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFarms = List.from(_farms);
      } else {
        _filteredFarms = _farms.where((farm) {
          final farmName = farm.name?.toLowerCase() ?? '';
          final farmAddress = farm.farmAddress.toLowerCase();
          return farmName.contains(query) || farmAddress.contains(query);
        }).toList();
      }
    });
  }

  void _filterLaborers() {
    final query = _laborerSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLaborers = List.from(_allLaborers);
      } else {
        _filteredLaborers = _allLaborers.where((laborer) {
          final firstName = laborer.firstName.toLowerCase();
          final lastName = laborer.lastName.toLowerCase();
          final phoneNumber = laborer.phoneNumber?.toLowerCase() ?? '';
          return firstName.contains(query) ||
              lastName.contains(query) ||
              phoneNumber.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isLocationLoading = true;
      });
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLocationLoading = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLocationLoading = false;
            });
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _addPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
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
                                    // Filter laborers based on search query
                                    final query = value.toLowerCase();
                                    setDialogState(() {
                                      if (query.isEmpty) {
                                        _filteredLaborers =
                                            List.from(_allLaborers);
                                      } else {
                                        _filteredLaborers =
                                            _allLaborers.where((laborer) {
                                          final firstName =
                                              laborer.firstName.toLowerCase();
                                          final lastName =
                                              laborer.lastName.toLowerCase();
                                          final phoneNumber = laborer
                                                  .phoneNumber
                                                  ?.toLowerCase() ??
                                              '';
                                          return firstName.contains(query) ||
                                              lastName.contains(query) ||
                                              phoneNumber.contains(query);
                                        }).toList();
                                      }
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

  Widget _buildDiseaseOption({
    required String value,
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

  @override
  void dispose() {
    _farmSearchController.removeListener(_filterFarms);
    _laborerSearchController.removeListener(_filterLaborers);
    _farmSearchController.dispose();
    _accomplishmentsController.dispose();
    _issuesController.dispose();
    _descriptionController.dispose();
    _diseaseTypeController.dispose();
    _laborerSearchController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFarm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farm')),
      );
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final report = {
        'technician_id': widget.technicianId ?? 1,
        'farm_id': _selectedFarm!.id,
        'coordinator_id': _selectedCoordinatorId, // Added coordinator selection
        'farm_worker_ids':
            _selectedFarm!.farmWorkers.map((fw) => fw.id).toList(),
        'laborer_ids': _selectedLaborers.map((l) => l.id).toList(),
        'accomplishments': _accomplishmentsController.text,
        'issues_observed': _issuesController.text,
        'disease_detected': _diseaseDetected,
        'disease_type':
            _diseaseDetected == 'Yes' ? _diseaseTypeController.text : null,
        'description': _descriptionController.text,
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': _currentPosition?.latitude ?? 0.0,
        'longitude': _currentPosition?.longitude ?? 0.0,
      };

      if (widget.token == null) {
        throw Exception('No authentication token available');
      }

      await _reportService.createReport(
        report,
        widget.token!,
        images: _photos,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );

      // Navigate back to the main screen
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accomplishment Report'),
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
              // Area Coordinator Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Area Coordinator',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _loadingCoordinators
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Loading coordinators...'),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<int>(
                          value: _selectedCoordinatorId,
                          decoration: InputDecoration(
                            hintText: 'Select Area Coordinator',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF4CAF50), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          items: _coordinators.map((coordinator) {
                            final fullName =
                                '${coordinator['last_name']}, ${coordinator['first_name']}${coordinator['middle_name'] != null ? ' ${coordinator['middle_name']}' : ''}';
                            return DropdownMenuItem<int>(
                              value: coordinator['id'] as int,
                              child: Text(fullName),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedCoordinatorId = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an Area Coordinator';
                            }
                            return null;
                          },
                        ),
                ],
              ),
              const SizedBox(height: 20),

              // Farm Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Farm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      // Dropdown Header
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            final wasExpanded = _isFarmDropdownExpanded;
                            _isFarmDropdownExpanded = !_isFarmDropdownExpanded;
                            if (wasExpanded) {
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
                                child: TextField(
                                  controller: _farmSearchController,
                                  onChanged: (value) {
                                    // Filter is automatically triggered by the listener
                                    // added in initState
                                  },
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
                              Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 200),
                                child: _filteredFarms.isEmpty
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
                                        itemCount: _filteredFarms.length,
                                        itemBuilder: (context, index) {
                                          final farm = _filteredFarms[index];
                                          return Column(
                                            children: [
                                              _buildFarmOption(
                                                farm: farm,
                                                isSelected:
                                                    _selectedFarm != null &&
                                                        _selectedFarm!.id ==
                                                            farm.id,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedFarm = farm;
                                                    _isFarmDropdownExpanded =
                                                        false;
                                                  });
                                                },
                                              ),
                                              if (index <
                                                  _filteredFarms.length - 1)
                                                const Divider(
                                                  height: 1,
                                                  color: Color(0xFFE0E0E0),
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
                                            'Contact: ${fw.phoneNumber}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        if (fw.address != null &&
                                            fw.address!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Address: ${fw.address}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 20),
              ],

              // Location Info
              if (_isLocationLoading)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Getting location...'),
                    ],
                  ),
                )
              else if (_currentPosition != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isLocationLoading || _currentPosition != null)
                const SizedBox(height: 20),

              // Photos Section
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addPhoto,
                          icon: const Icon(Icons.add_a_photo, size: 18),
                          label: const Text('Add Photo'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_photos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.photo_camera,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No photos added yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap "Add Photo" to take pictures',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _photos.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFE9ECEF)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _photos[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Accomplishments
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCOMPLISHMENTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF27AE60),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _accomplishmentsController,
                    decoration: InputDecoration(
                      hintText: 'Describe what was accomplished...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF27AE60), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your accomplishments';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Issues Observed
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ISSUES OBSERVED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF27AE60),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _issuesController,
                    decoration: InputDecoration(
                      hintText: 'Describe any issues or concerns...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF27AE60), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter issues observed';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Laborers Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                          child: OutlinedButton(
                            onPressed: () => _showLaborerPicker(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF27AE60),
                              side: const BorderSide(color: Color(0xFF27AE60)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(_selectedLaborers.isEmpty
                                ? 'Add Laborers'
                                : 'Add More Laborers'),
                          ),
                        ),
                        if (_selectedLaborers.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedLaborers.clear();
                              });
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
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Disease Detection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DISEASE DETECTED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF27AE60),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      // Dropdown Header
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDiseaseDropdownExpanded =
                                !_isDiseaseDropdownExpanded;
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
                                  _diseaseDetected == 'None' ? 'None' : 'Yes',
                                  style: TextStyle(
                                    color: const Color(0xFF2C3E50),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                _isDiseaseDropdownExpanded
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
                      if (_isDiseaseDropdownExpanded) ...[
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
                              _buildDiseaseOption(
                                value: 'None',
                                label: 'None',
                                isSelected: _diseaseDetected == 'None',
                                onTap: () {
                                  setState(() {
                                    _diseaseDetected = 'None';
                                    _isDiseaseDropdownExpanded = false;
                                  });
                                },
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFE0E0E0),
                                thickness: 1,
                              ),
                              _buildDiseaseOption(
                                value: 'Yes',
                                label: 'Yes',
                                isSelected: _diseaseDetected == 'Yes',
                                onTap: () {
                                  setState(() {
                                    _diseaseDetected = 'Yes';
                                    _isDiseaseDropdownExpanded = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Disease Type (only shown if disease is detected)
              if (_diseaseDetected == 'Yes')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DISEASE TYPE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27AE60),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _diseaseTypeController,
                      decoration: InputDecoration(
                        hintText: 'Specify the type of disease...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
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
                          borderSide: const BorderSide(
                              color: Color(0xFF27AE60), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (_diseaseDetected == 'Yes' &&
                            (value == null || value.isEmpty)) {
                          return 'Please specify the disease type';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              if (_diseaseDetected == 'Yes') const SizedBox(height: 16),

              // Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF27AE60),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Additional details or notes...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF27AE60), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

