import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/harvest_service.dart';
import '../models/farm.dart';

class HarvestFormScreen extends StatefulWidget {
  final String? token;
  final int? technicianId;
  final File photo;
  final Position position;
  final Farm? detectedFarm;

  const HarvestFormScreen({
    Key? key,
    this.token,
    this.technicianId,
    required this.photo,
    required this.position,
    this.detectedFarm,
  }) : super(key: key);

  @override
  State<HarvestFormScreen> createState() => _HarvestFormScreenState();
}

class _HarvestFormScreenState extends State<HarvestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _harvestService = HarvestService();
  bool _isLoading = false;
  bool _canSubmit = false;
  String _harvestStatusMessage = '';

  // Form controllers
  final TextEditingController _harvestDateController = TextEditingController();
  final TextEditingController _actualYieldController = TextEditingController();
  final TextEditingController _gradeAPercentageController =
      TextEditingController();
  final TextEditingController _gradeBPercentageController =
      TextEditingController();
  final TextEditingController _gradeCPercentageController =
      TextEditingController();
  final TextEditingController _gradeDPercentageController =
      TextEditingController();
  final TextEditingController _harvestNotesController = TextEditingController();

  String _selectedYieldEstimateId = '';
  List<Map<String, dynamic>> _yieldEstimates = [];

  @override
  void initState() {
    super.initState();
    _harvestDateController.text =
        DateTime.now().toIso8601String().split('T')[0];
    _loadYieldEstimates();
  }

  Future<void> _loadYieldEstimates() async {
    try {
      final estimates = await _harvestService.getYieldEstimates(widget.token!);
      setState(() {
        _yieldEstimates = estimates;

        // Auto-select yield estimate that matches the detected farm
        if (widget.detectedFarm != null && estimates.isNotEmpty) {
          final matchingEstimate = estimates.firstWhere(
            (estimate) => estimate['farm']?['id'] == widget.detectedFarm!.id,
            orElse: () => estimates.first,
          );

          if (matchingEstimate['id'] != null) {
            _selectedYieldEstimateId = matchingEstimate['id'].toString();
            print(
                'Auto-selected yield estimate for detected farm: ${matchingEstimate['tobacco_variety_name']} (ID: ${matchingEstimate['id']})');
            // Auto-check harvest status
            _checkHarvestStatus(_selectedYieldEstimateId);
          } else {
            _selectedYieldEstimateId = '';
            print('No valid yield estimates found for detected farm');
          }
        } else if (estimates.isNotEmpty && estimates[0]['id'] != null) {
          _selectedYieldEstimateId = estimates[0]['id'].toString();
          print(
              'Selected first yield estimate: ${estimates[0]['tobacco_variety_name']} (ID: ${estimates[0]['id']})');
        } else {
          _selectedYieldEstimateId = '';
          print('No valid yield estimates found');
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load yield estimates: $e')),
      );
    }
  }

  Future<void> _checkHarvestStatus(String yieldEstimateId) async {
    try {
      final status = await _harvestService.checkHarvestStatus(
          yieldEstimateId, widget.token!);
      setState(() {
        _canSubmit = status['enabled'] ?? false;
        _harvestStatusMessage = status['message'] ?? '';
      });
    } catch (e) {
      setState(() {
        _canSubmit = false;
        _harvestStatusMessage = 'Error checking harvest status: $e';
      });
    }
  }

  Future<void> _submitHarvest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final harvestData = {
        'farm_yield_estimate_id': _selectedYieldEstimateId,
        'harvest_date': _harvestDateController.text,
        'actual_yield_kg': double.parse(_actualYieldController.text),
        'quality_grade_a_percentage':
            double.parse(_gradeAPercentageController.text),
        'quality_grade_b_percentage':
            double.parse(_gradeBPercentageController.text),
        'quality_grade_c_percentage':
            double.parse(_gradeCPercentageController.text),
        'quality_grade_d_percentage':
            double.parse(_gradeDPercentageController.text),
        'harvest_notes': _harvestNotesController.text,
      };

      await _harvestService.submitHarvest(
          harvestData, widget.token!, widget.photo);

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

  String _getDetectedFarmVariety() {
    if (widget.detectedFarm == null) return 'No variety';

    // Find the yield estimate that matches the detected farm
    final matchingEstimate = _yieldEstimates.firstWhere(
      (estimate) => estimate['farm']?['id'] == widget.detectedFarm!.id,
      orElse: () => <String, dynamic>{},
    );

    return matchingEstimate['tobacco_variety_name']?.toString() ??
        'No Yield Estimate';
  }

  bool _hasYieldEstimateForDetectedFarm() {
    if (widget.detectedFarm == null) return false;

    return _yieldEstimates.any(
      (estimate) => estimate['farm']?['id'] == widget.detectedFarm!.id,
    );
  }

  String _getDetectedFarmWorkerName() {
    if (widget.detectedFarm == null ||
        widget.detectedFarm!.farmWorkers.isEmpty) {
      return 'No farm worker assigned';
    }

    final firstWorker = widget.detectedFarm!.farmWorkers.first;
    return '${firstWorker.firstName} ${firstWorker.lastName}'.trim();
  }

  @override
  void dispose() {
    _harvestDateController.dispose();
    _actualYieldController.dispose();
    _gradeAPercentageController.dispose();
    _gradeBPercentageController.dispose();
    _gradeCPercentageController.dispose();
    _gradeDPercentageController.dispose();
    _harvestNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harvest Report'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo preview
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    widget.photo,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Farm info
              if (widget.detectedFarm != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Farm Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.detectedFarm!.farmAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Farm Size: ${widget.detectedFarm!.farmSize} hectares',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Detected Farm Information Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Farm Information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.detectedFarm != null) ...[
                      Text(
                        widget.detectedFarm!.farmAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getDetectedFarmVariety()} (${widget.detectedFarm!.farmSize} ha)',
                        style: TextStyle(
                          fontSize: 14,
                          color: _hasYieldEstimateForDetectedFarm()
                              ? Colors.orange
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Farm Worker: ${_getDetectedFarmWorkerName()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!_hasYieldEstimateForDetectedFarm()) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No yield estimate found for this farm. Please contact admin to create a yield estimate first.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'No farm detected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Harvest Status Message
              if (_harvestStatusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _canSubmit
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _canSubmit ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _canSubmit ? Icons.check_circle : Icons.info,
                        color: _canSubmit ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _harvestStatusMessage,
                          style: TextStyle(
                            color: _canSubmit ? Colors.green : Colors.orange,
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
                  fillColor: Color(0xFFF8F9FA),
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

              // Actual Yield
              TextFormField(
                controller: _actualYieldController,
                decoration: const InputDecoration(
                  labelText: 'Actual Yield (kg)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
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

              // Quality Grades
              const Text(
                'Quality Grade Percentages',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gradeAPercentageController,
                      decoration: const InputDecoration(
                        labelText: 'Grade A %',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8F9FA),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final val = double.tryParse(value);
                        if (val == null || val < 0 || val > 100) {
                          return '0-100';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _gradeBPercentageController,
                      decoration: const InputDecoration(
                        labelText: 'Grade B %',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8F9FA),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final val = double.tryParse(value);
                        if (val == null || val < 0 || val > 100) {
                          return '0-100';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gradeCPercentageController,
                      decoration: const InputDecoration(
                        labelText: 'Grade C %',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8F9FA),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final val = double.tryParse(value);
                        if (val == null || val < 0 || val > 100) {
                          return '0-100';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _gradeDPercentageController,
                      decoration: const InputDecoration(
                        labelText: 'Grade D %',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8F9FA),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final val = double.tryParse(value);
                        if (val == null || val < 0 || val > 100) {
                          return '0-100';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Harvest Notes
              TextFormField(
                controller: _harvestNotesController,
                decoration: const InputDecoration(
                  labelText: 'Harvest Notes (Optional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: (_isLoading ||
                        !_canSubmit ||
                        !_hasYieldEstimateForDetectedFarm())
                    ? null
                    : _submitHarvest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
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
                        !_hasYieldEstimateForDetectedFarm()
                            ? 'No Yield Estimate Available'
                            : _canSubmit
                                ? 'Submit Harvest Report'
                                : 'Harvest Not Yet Available',
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
