import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/report_service.dart';
import '../services/farm_service.dart';
import '../services/laborer_service.dart';
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
  List<File> _photos = [];
  List<Laborer> _allLaborers = [];
  List<Laborer> _selectedLaborers = [];

  final TextEditingController _accomplishmentsController =
      TextEditingController();
  final TextEditingController _issuesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _diseaseTypeController = TextEditingController();

  String _diseaseDetected = 'None';

  @override
  void initState() {
    super.initState();
    _loadFarms();
    _loadLaborers();
    
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

  Future<void> _loadFarms() async {
    try {
      final farms = await _farmService.getFarmsByTechnician(widget.token!);
      if (mounted) {
        setState(() {
          _farms = farms;
        });
      }
    } catch (e) {
      print('Error loading farms: $e');
    }
  }

  Future<void> _loadLaborers() async {
    try {
      final laborers = await _laborerService.getAllLaborers(widget.token!);
      if (mounted) {
        setState(() {
          _allLaborers = laborers;
        });
      }
    } catch (e) {
      print('Error loading laborers: $e');
    }
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
      print('Error getting location: $e');
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
            return AlertDialog(
              title: const Text('Select Laborers'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: _allLaborers.isEmpty
                    ? const Center(child: Text('No laborers available'))
                    : ListView.builder(
                        itemCount: _allLaborers.length,
                        itemBuilder: (context, index) {
                          final laborer = _allLaborers[index];
                          final isSelected = _selectedLaborers.contains(laborer);
                          return CheckboxListTile(
                            title: Text(
                              '${laborer.firstName} ${laborer.lastName}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: laborer.phoneNumber != null
                                ? Text(laborer.phoneNumber!)
                                : null,
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  if (!_selectedLaborers.contains(laborer)) {
                                    _selectedLaborers.add(laborer);
                                  }
                                } else {
                                  _selectedLaborers.remove(laborer);
                                }
                              });
                              setState(() {}); // Update parent widget
                            },
                            activeColor: const Color(0xFF27AE60),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _accomplishmentsController.dispose();
    _issuesController.dispose();
    _descriptionController.dispose();
    _diseaseTypeController.dispose();
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
        'farm_worker_ids': _selectedFarm!.farmWorkers.map((fw) => fw.id).toList(),
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
                    const Text(
                      'Select Farm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Farm>(
                      value: _selectedFarm,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Choose a farm'),
                      isExpanded: true,
                      items: _farms.map((farm) {
                        return DropdownMenuItem<Farm>(
                          value: farm,
                          child: Text(
                            'Farm #${farm.id} - ${farm.farmAddress}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (Farm? farm) {
                        setState(() {
                          _selectedFarm = farm;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a farm';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Farm Workers Info (from selected farm)
              if (_selectedFarm != null && _selectedFarm!.farmWorkers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: Color(0xFF27AE60), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Farmers (auto-included)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF27AE60),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...(_selectedFarm!.farmWorkers.map((fw) => Padding(
                        padding: const EdgeInsets.only(left: 26, top: 4),
                        child: Text(
                          '• ${fw.firstName} ${fw.lastName}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF495057)),
                        ),
                      ))),
                    ],
                  ),
                ),
              if (_selectedFarm != null && _selectedFarm!.farmWorkers.isNotEmpty)
                const SizedBox(height: 20),

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
                      const Icon(Icons.location_on, color: Colors.green, size: 20),
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
                                  border:
                                      Border.all(color: const Color(0xFFE9ECEF)),
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
              TextFormField(
                controller: _accomplishmentsController,
                decoration: InputDecoration(
                  labelText: 'Accomplishments',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your accomplishments';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Issues Observed
              TextFormField(
                controller: _issuesController,
                decoration: InputDecoration(
                  labelText: 'Issues Observed',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter issues observed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Laborers Selection
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
                    const Row(
                      children: [
                        Icon(Icons.people, color: Color(0xFF27AE60), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Laborers Involved',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectedLaborers.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedLaborers.map((laborer) {
                          return Chip(
                            label: Text(
                              '${laborer.firstName} ${laborer.lastName}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedLaborers.remove(laborer);
                              });
                            },
                            backgroundColor: const Color(0xFF27AE60).withOpacity(0.1),
                            deleteIconColor: const Color(0xFF27AE60),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showLaborerPicker(),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(_selectedLaborers.isEmpty
                          ? 'Add Laborers'
                          : 'Add More Laborers'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF27AE60),
                        side: const BorderSide(color: Color(0xFF27AE60)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Disease Detection
              DropdownButtonFormField<String>(
                value: _diseaseDetected,
                decoration: InputDecoration(
                  labelText: 'Disease Detected',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: const [
                  DropdownMenuItem(value: 'None', child: Text('None')),
                  DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                ],
                onChanged: (value) {
                  setState(() {
                    _diseaseDetected = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Disease Type (only shown if disease is detected)
              if (_diseaseDetected == 'Yes')
                TextFormField(
                  controller: _diseaseTypeController,
                  decoration: InputDecoration(
                    labelText: 'Disease Type',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (_diseaseDetected == 'Yes' &&
                        (value == null || value.isEmpty)) {
                      return 'Please specify the disease type';
                    }
                    return null;
                  },
                ),
              if (_diseaseDetected == 'Yes') const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
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
