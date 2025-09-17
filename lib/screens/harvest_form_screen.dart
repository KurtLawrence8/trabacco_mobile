import 'package:flutter/material.dart';
import '../services/harvest_service.dart';
import '../services/planting_service.dart';
import '../services/tobacco_variety_service.dart';
import '../services/farm_service.dart';
import '../models/tobacco_variety.dart';
import '../models/farm.dart';

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
  final _harvestService = HarvestService();
  final _plantingService = PlantingService();
  final _tobaccoVarietyService = TobaccoVarietyService();
  final _farmService = FarmService();
  bool _isLoading = false;
  bool _canSubmit = false;
  String _harvestStatusMessage = '';

  // Form controllers
  final TextEditingController _harvestDateController = TextEditingController();
  final TextEditingController _actualYieldController = TextEditingController();
  final TextEditingController _yieldPerPlantController =
      TextEditingController();
  final TextEditingController _seedsCountController = TextEditingController();
  final TextEditingController _harvestNotesController = TextEditingController();

  String _selectedQualityGrade = 'Standard';

  // Farm and variety selection
  List<Farm> _farms = [];
  List<TobaccoVariety> _tobaccoVarieties = [];
  Farm? _selectedFarm;
  TobaccoVariety? _selectedVariety;
  String _selectedVarietyId = '';
  String _selectedVarietyName = '';
  Map<String, dynamic>? _selectedPlantingData;

  @override
  void initState() {
    super.initState();
    _harvestDateController.text =
        DateTime.now().toIso8601String().split('T')[0];
    _enableHarvestSubmission(); // Enable harvest reporting immediately
    _loadTobaccoVarieties(); // Load tobacco varieties
    _loadFarms(); // Load farms
  }

  Future<void> _loadFarms() async {
    try {
      final farms = await _farmService.getFarmsByTechnician(widget.token!);
      setState(() {
        _farms = farms;
      });
    } catch (e) {
      print('Error loading farms: $e');
    }
  }

  Future<void> _loadTobaccoVarieties() async {
    try {
      final varieties =
          await _tobaccoVarietyService.getTobaccoVarieties(widget.token);
      setState(() {
        _tobaccoVarieties = varieties;
        // If we have planting data, try to match the variety
        if (_selectedVarietyId.isNotEmpty && varieties.isNotEmpty) {
          _selectedVariety = varieties.firstWhere(
            (v) => v.id.toString() == _selectedVarietyId,
            orElse: () => varieties.first,
          );
        } else if (varieties.isNotEmpty) {
          _selectedVariety = varieties.first;
        }
      });
    } catch (e) {
      print('Error loading tobacco varieties: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tobacco varieties: $e')),
      );
    }
  }

  Future<void> _loadPlantingData() async {
    if (_selectedFarm == null) return;

    try {
      final reports = await _plantingService.getFarmPlantingReports(
        token: widget.token!,
        farmId: _selectedFarm!.id,
        year: DateTime.now().year,
        technicianId: widget.technicianId,
      );

      setState(() {
        // Auto-select the most recent planting report for this farm
        if (reports.isNotEmpty) {
          _selectedPlantingData = reports.first;
          _selectedVarietyId =
              _selectedPlantingData!['tobacco_variety_id']?.toString() ?? '';
          _selectedVarietyName =
              _selectedPlantingData!['tobacco_variety_name']?.toString() ?? '';

          // Pre-fill seeds count from planting report
          if (_selectedPlantingData!['seeds_per_hectare'] != null) {
            _seedsCountController.text =
                _selectedPlantingData!['seeds_per_hectare'].toString();
          }

          // Update selected variety if we have varieties loaded
          if (_tobaccoVarieties.isNotEmpty && _selectedVarietyId.isNotEmpty) {
            _selectedVariety = _tobaccoVarieties.firstWhere(
              (v) => v.id.toString() == _selectedVarietyId,
              orElse: () => _tobaccoVarieties.first,
            );
          }

          print(
              'Auto-selected planting data: $_selectedVarietyName (ID: $_selectedVarietyId)');
        }
      });
    } catch (e) {
      print('Error loading planting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load planting data: $e')),
      );
    }
  }

  // Harvest reporting is now always enabled since we removed yield estimate dependency
  void _enableHarvestSubmission() {
    setState(() {
      _canSubmit = true;
      _harvestStatusMessage = 'Harvest reporting is enabled';
    });
  }

  Future<void> _submitHarvest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFarm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farm')),
      );
      return;
    }
    if (_selectedVariety == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tobacco variety')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final harvestData = {
        'farm_id': _selectedFarm!.id.toString(),
        'variety_id': _selectedVariety!.id.toString(),
        'harvest_date': _harvestDateController.text,
        'actual_yield_kg': double.parse(_actualYieldController.text),
        'actual_seeds_per_hectare': _seedsCountController.text.isNotEmpty
            ? int.parse(_seedsCountController.text)
            : null,
        'actual_yield_per_plant': _yieldPerPlantController.text.isNotEmpty
            ? double.parse(_yieldPerPlantController.text)
            : null,
        'quality_grade': _selectedQualityGrade,
        'harvest_notes': _harvestNotesController.text,
      };

      await _harvestService.submitHarvest(harvestData, widget.token!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harvest report submitted successfully')),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit harvest: ${e.toString()}')),
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
  void dispose() {
    _harvestDateController.dispose();
    _actualYieldController.dispose();
    _yieldPerPlantController.dispose();
    _seedsCountController.dispose();
    _harvestNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harvest Report'),
<<<<<<< HEAD
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
=======
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
>>>>>>> 054e128ad16d89dddff8f8e15df83dc9be38358b
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
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: const Color(0xFF27AE60),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Select Farm',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
                          child: Container(
                            width: double.infinity,
                            child: Text(
                              'Farm #${farm.id} - ${farm.farmAddress}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (Farm? farm) {
                        setState(() {
                          _selectedFarm = farm;
                        });
                        if (farm != null) {
                          _loadPlantingData();
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

              // Harvest Status Message
              if (_harvestStatusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: _canSubmit
                        ? const Color(0xFF27AE60).withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _canSubmit ? const Color(0xFF27AE60) : Colors.orange,
                  ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _canSubmit ? Icons.check_circle : Icons.info,
                        color: _canSubmit ? const Color(0xFF27AE60) : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _harvestStatusMessage,
                          style: TextStyle(
                            color: _canSubmit ? const Color(0xFF27AE60) : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Harvest Date
              TextFormField(
                controller: _harvestDateController,
                decoration: const InputDecoration(
                  labelText: 'Harvest Date',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _harvestDateController.text =
                        date.toIso8601String().split('T')[0];
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select harvest date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tobacco Variety Selection
              DropdownButtonFormField<TobaccoVariety>(
                value: _selectedVariety,
                decoration: const InputDecoration(
                  labelText: 'Tobacco Variety',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Select the tobacco variety for this harvest',
                ),
                items: _tobaccoVarieties.map((TobaccoVariety variety) {
                  return DropdownMenuItem<TobaccoVariety>(
                    value: variety,
                    child: Text(variety.varietyName),
                  );
                }).toList(),
                onChanged: (TobaccoVariety? newValue) {
                  setState(() {
                    _selectedVariety = newValue;
                    // Update seeds count if variety has default value
                    if (newValue != null &&
                        _seedsCountController.text.isEmpty) {
                      _seedsCountController.text =
                          newValue.defaultSeedsPerHectare.toString();
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
              const SizedBox(height: 16),

              // Seeds Count
              TextFormField(
                controller: _seedsCountController,
                decoration: const InputDecoration(
                  labelText: 'Seeds Count per Hectare',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Based on planting report or variety default',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter seeds count';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Yield per Plant
              TextFormField(
                controller: _yieldPerPlantController,
                decoration: const InputDecoration(
                  labelText: 'Yield per Plant (kg)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Average yield per individual plant',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter yield per plant';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Actual Yield
              TextFormField(
                controller: _actualYieldController,
                decoration: const InputDecoration(
                  labelText: 'Total Actual Yield (kg)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'Total harvest weight',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter actual yield';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quality Grade
              DropdownButtonFormField<String>(
                value: _selectedQualityGrade,
                decoration: const InputDecoration(
                  labelText: 'Quality Grade',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ['Premium', 'Standard', 'Low'].map((String grade) {
                  return DropdownMenuItem<String>(
                    value: grade,
                    child: Text(grade),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedQualityGrade = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Harvest Notes
              TextFormField(
                controller: _harvestNotesController,
                decoration: const InputDecoration(
                  labelText: 'Harvest Notes (Optional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: (_isLoading || !_canSubmit) ? null : _submitHarvest,
                style: ElevatedButton.styleFrom(
<<<<<<< HEAD
                  backgroundColor: Colors.green,
=======
                  backgroundColor: const Color(0xFF27AE60),
>>>>>>> 054e128ad16d89dddff8f8e15df83dc9be38358b
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                    : Text(
                        _canSubmit
                            ? 'Submit Harvest Report'
                            : 'Harvest Not Available',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
