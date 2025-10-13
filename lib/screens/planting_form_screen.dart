import 'package:flutter/material.dart';
import '../services/planting_service.dart';
import '../services/farm_service.dart';
import '../services/laborer_service.dart';
import '../models/farm.dart';
import '../models/laborer.dart';

class PlantingFormScreen extends StatefulWidget {
  final String? token;
  final int? technicianId;

  const PlantingFormScreen({
    Key? key,
    this.token,
    this.technicianId,
  }) : super(key: key);

  @override
  State<PlantingFormScreen> createState() => _PlantingFormScreenState();
}

class _PlantingFormScreenState extends State<PlantingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plantsPlantedController = TextEditingController();

  final _plantingService = PlantingService();
  final _farmService = FarmService();
  final _laborerService = LaborerService();

  List<Farm> _farms = [];
  Farm? _selectedFarm;
  List<Laborer> _allLaborers = [];
  List<Laborer> _selectedLaborers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFarms();
    _loadLaborers();
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
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load farms: $e';
        });
      }
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

  Future<void> _submitPlantingReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFarm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farm')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final plantingData = {
        'farm_id': _selectedFarm!.id,
        'plants_planted': int.parse(_plantsPlantedController.text),
        'laborer_ids': _selectedLaborers.map((l) => l.id).toList(),
      };

      final response = await _plantingService.submitPlantingReport(
        token: widget.token,
        plantingData: plantingData,
      );

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Planting report submitted successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    response['message'] ?? 'Failed to submit planting report')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting planting report: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Planting Report'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Farm Selection
                    Container(
                      padding: const EdgeInsets.all(16.0),
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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            hint: const Text('Choose a farm'),
                            isExpanded: true,
                            items: _farms.map((farm) {
                              return DropdownMenuItem<Farm>(
                                value: farm,
                                child: Container(
                                  width: double.infinity,
                                  child: Text(
                                    '${farm.farmAddress}${farm.name != null && farm.name!.isNotEmpty ? " - ${farm.name}" : ""}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (Farm? farm) {
                              if (mounted) {
                                setState(() {
                                  _selectedFarm = farm;
                                });
                              }
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
                    if (_selectedFarm != null &&
                        _selectedFarm!.farmWorkers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF27AE60).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person,
                                    color: Color(0xFF27AE60), size: 18),
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
                                  padding:
                                      const EdgeInsets.only(left: 26, top: 4),
                                  child: Text(
                                    '• ${fw.firstName} ${fw.lastName}',
                                    style: const TextStyle(
                                        fontSize: 13, color: Color(0xFF495057)),
                                  ),
                                ))),
                          ],
                        ),
                      ),
                    if (_selectedFarm != null &&
                        _selectedFarm!.farmWorkers.isNotEmpty)
                      const SizedBox(height: 20),

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
                              Icon(Icons.people,
                                  color: Color(0xFF27AE60), size: 20),
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
                                  backgroundColor:
                                      const Color(0xFF27AE60).withOpacity(0.1),
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

                    const SizedBox(height: 20),

                    // Plants Planted
                    Container(
                      padding: const EdgeInsets.all(16.0),
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
                            'Plants Planted',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _plantsPlantedController,
                            decoration: InputDecoration(
                              labelText: 'Number of Plants Planted',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.grass,
                                  color: Color(0xFF27AE60)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter number of plants planted';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitPlantingReport,
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
                              'Submit Planting Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
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
                          final isSelected =
                              _selectedLaborers.contains(laborer);
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
    _plantsPlantedController.dispose();
    super.dispose();
  }
}
