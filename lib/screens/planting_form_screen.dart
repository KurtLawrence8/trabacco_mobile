import 'package:flutter/material.dart';
import '../services/planting_service.dart';
import '../services/tobacco_variety_service.dart';
import '../services/farm_service.dart';
import '../models/tobacco_variety.dart';
import '../models/farm.dart';

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
  final _areaPlantedController = TextEditingController();
  final _plantsPerHectareController = TextEditingController();
  final _seedsUsedController = TextEditingController();
  final _notesController = TextEditingController();

  final _plantingService = PlantingService();
  final _tobaccoVarietyService = TobaccoVarietyService();
  final _farmService = FarmService();

  List<TobaccoVariety> _tobaccoVarieties = [];
  List<Farm> _farms = [];
  TobaccoVariety? _selectedVariety;
  Farm? _selectedFarm;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTobaccoVarieties();
    _loadFarms();
  }

  Future<void> _loadTobaccoVarieties() async {
    try {
      final varieties =
          await _tobaccoVarietyService.getTobaccoVarieties(widget.token);
      setState(() {
        _tobaccoVarieties = varieties;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tobacco varieties: $e';
      });
    }
  }

  Future<void> _loadFarms() async {
    try {
      final farms = await _farmService.getFarmsByTechnician(widget.token!);
      setState(() {
        _farms = farms;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load farms: $e';
      });
    }
  }

  Future<void> _submitPlantingReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVariety == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tobacco variety')),
      );
      return;
    }
    if (_selectedFarm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farm')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final plantingData = {
        'farm_id': _selectedFarm!.id,
        'tobacco_variety_id': _selectedVariety!.id,
        'technician_id': widget.technicianId ?? 1,
        'farm_worker_id': _selectedFarm!.farmWorkers.isNotEmpty
            ? _selectedFarm!.farmWorkers.first.id
            : null,
        'planting_date': DateTime.now().toIso8601String().split('T')[0],
        'area_planted': double.parse(_areaPlantedController.text),
        'plants_per_hectare': double.parse(_plantsPerHectareController.text),
        'seeds_used': int.parse(_seedsUsedController.text),
        'notes': _notesController.text,
        'location_address': _selectedFarm!.farmAddress, // Add farm address
        'status': 'pending',
        'report_status': 'submitted',
      };

      final response = await _plantingService.submitPlantingReport(
        token: widget.token,
        plantingData: plantingData,
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Planting report submitted successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  response['message'] ?? 'Failed to submit planting report')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting planting report: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
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
                            items: _farms.map((farm) {
                              return DropdownMenuItem<Farm>(
                                value: farm,
                                child: Text(
                                  'Farm #${farm.id} - ${farm.farmAddress}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (Farm? farm) {
                              setState(() {
                                _selectedFarm = farm;
                                // Auto-fill area planted with farm size
                                if (farm != null) {
                                  _areaPlantedController.text =
                                      farm.farmSize.toString();
                                }
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

                    // Tobacco Variety Selection
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tobacco Variety',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<TobaccoVariety>(
                            value: _selectedVariety,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            hint: const Text('Choose tobacco variety'),
                            items: _tobaccoVarieties.map((variety) {
                              return DropdownMenuItem<TobaccoVariety>(
                                value: variety,
                                child: Text(variety.varietyName),
                              );
                            }).toList(),
                            onChanged: (TobaccoVariety? variety) {
                              setState(() {
                                _selectedVariety = variety;
                                if (variety != null) {
                                  _plantsPerHectareController.text =
                                      variety.defaultSeedsPerHectare.toString();
                                  _seedsUsedController.text =
                                      variety.defaultSeedsPerHectare.toString();
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a tobacco variety';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Planting Details
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Planting Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Area Planted
                          TextFormField(
                            controller: _areaPlantedController,
                            decoration: const InputDecoration(
                              labelText: 'Area Planted (hectares)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.landscape),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter area planted';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Plants per Hectare
                          TextFormField(
                            controller: _plantsPerHectareController,
                            decoration: const InputDecoration(
                              labelText: 'Plants per Hectare',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.grass),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter plants per hectare';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Seeds Used
                          TextFormField(
                            controller: _seedsUsedController,
                            decoration: const InputDecoration(
                              labelText: 'Seeds Used',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.eco),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter seeds used';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Notes
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                            ),
                            maxLines: 3,
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

  @override
  void dispose() {
    _areaPlantedController.dispose();
    _plantsPerHectareController.dispose();
    _seedsUsedController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
