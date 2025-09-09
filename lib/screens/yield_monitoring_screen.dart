import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/yield_monitoring_service.dart';
import '../models/farm.dart';

class YieldMonitoringScreen extends StatefulWidget {
  final String? token;
  final int? technicianId;
  final File? photo;
  final Position? position;
  final Farm? detectedFarm;

  const YieldMonitoringScreen({
    Key? key,
    this.token,
    this.technicianId,
    this.photo,
    this.position,
    this.detectedFarm,
  }) : super(key: key);

  @override
  State<YieldMonitoringScreen> createState() => _YieldMonitoringScreenState();
}

class _YieldMonitoringScreenState extends State<YieldMonitoringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _yieldMonitoringService = YieldMonitoringService();
  bool _isLoading = false;

  // Form controllers
  final TextEditingController _actualSeedsPlantedController =
      TextEditingController();
  final TextEditingController _plantCountPercentageController =
      TextEditingController();
  final TextEditingController _issuesEncounteredController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Selected values
  String _selectedYieldEstimateId = '';
  String _growthStatus = 'Good';
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _yieldEstimates = [];

  // Growth status options
  final List<String> _growthStatusOptions = [
    'Excellent',
    'Good',
    'Average',
    'Poor',
    'Critical',
  ];

  @override
  void initState() {
    super.initState();
    _loadYieldEstimates();
  }

  Future<void> _loadYieldEstimates() async {
    try {
      if (widget.token == null) {
        throw Exception('No authentication token available');
      }
      print(
          'Loading yield estimates with token: ${widget.token!.substring(0, 10)}...');
      final yieldEstimates =
          await _yieldMonitoringService.getYieldEstimates(widget.token!);
      print('Loaded ${yieldEstimates.length} yield estimates');
      if (mounted) {
        setState(() {
          _yieldEstimates = yieldEstimates;

          // Auto-select yield estimate that matches the detected farm
          if (widget.detectedFarm != null && yieldEstimates.isNotEmpty) {
            final matchingEstimate = yieldEstimates.firstWhere(
              (estimate) => estimate['farm']?['id'] == widget.detectedFarm!.id,
              orElse: () => yieldEstimates.first,
            );

            if (matchingEstimate['id'] != null) {
              _selectedYieldEstimateId = matchingEstimate['id'].toString();
              print(
                  'Auto-selected yield estimate for detected farm: ${matchingEstimate['tobacco_variety_name']} (ID: ${matchingEstimate['id']})');
            } else {
              _selectedYieldEstimateId = '';
              print('No valid yield estimates found for detected farm');
            }
          } else if (yieldEstimates.isNotEmpty &&
              yieldEstimates[0]['id'] != null) {
            _selectedYieldEstimateId = yieldEstimates[0]['id'].toString();
            print(
                'Selected first yield estimate: ${yieldEstimates[0]['tobacco_variety_name']} (ID: ${yieldEstimates[0]['id']})');
          } else {
            _selectedYieldEstimateId = '';
            print('No valid yield estimates found');
          }
        });
      }
    } catch (e) {
      print('Error loading yield estimates: $e');
      if (mounted) {
        // Show error but also provide fallback data for testing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load yield estimates: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Add fallback data for testing if API is not available
        setState(() {
          _yieldEstimates = [
            {
              'id': 1,
              'tobacco_variety_name': 'Virginia Gold',
              'farm': {
                'id': widget.detectedFarm?.id ?? 1,
                'farm_address': 'Sample Farm 1',
                'farm_size': 2.5
              }
            },
            {
              'id': 2,
              'tobacco_variety_name': 'Burley',
              'farm': {
                'id': widget.detectedFarm?.id ?? 2,
                'farm_address': 'Sample Farm 2',
                'farm_size': 1.8
              }
            },
          ];
          _selectedYieldEstimateId = '1';
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitYieldMonitoring() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final monitoringData = {
        'farm_yield_estimate_id': int.parse(_selectedYieldEstimateId),
        'monitoring_date': _selectedDate.toIso8601String().split('T')[0],
        'actual_seeds_planted': _actualSeedsPlantedController.text.isNotEmpty
            ? int.parse(_actualSeedsPlantedController.text)
            : null,
        'plant_count_percentage':
            _plantCountPercentageController.text.isNotEmpty
                ? double.parse(_plantCountPercentageController.text)
                : null,
        'growth_status': _growthStatus,
        'issues_encountered': _issuesEncounteredController.text.isNotEmpty
            ? _issuesEncounteredController.text
            : null,
        'notes':
            _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      if (widget.token == null) {
        throw Exception('No authentication token available');
      }
      print(
          'Submitting yield monitoring with technician_id: ${widget.technicianId}');
      print('Monitoring data: $monitoringData');
      await _yieldMonitoringService.createYieldMonitoring(
        monitoringData,
        widget.token!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Yield monitoring submitted successfully')),
      );

      // Clear form
      _actualSeedsPlantedController.clear();
      _plantCountPercentageController.clear();
      _issuesEncounteredController.clear();
      _notesController.clear();
      _growthStatus = 'Good';
      _selectedDate = DateTime.now();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to submit yield monitoring: ${e.toString()}')),
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
        title: const Text('Yield Monitoring'),
        backgroundColor: const Color(0xFF27AE60),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Preview (if available)
              if (widget.photo != null) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.photo!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Farm info (if available)
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
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFF27AE60),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Detected Farm',
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
                const SizedBox(height: 16),
              ],

              // Yield Estimate Selection
              _yieldEstimates.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            const Text(
                              'Loading yield estimates...',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Token: ${widget.token?.substring(0, 10) ?? 'None'}...',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'Technician ID: ${widget.technicianId ?? 'None'}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
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
                                    ? Colors.blue
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
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning,
                                        color: Colors.red, size: 16),
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

              // Date Selection
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Monitoring Date',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  child: Text(
                    DateFormat('MMMM d, y').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Actual Seeds Planted (Optional)
              TextFormField(
                controller: _actualSeedsPlantedController,
                decoration: InputDecoration(
                  labelText: 'Actual Seeds Planted (Optional)',
                  hintText: 'Enter actual number if different from target',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (int.parse(value) < 0) {
                      return 'Number must be positive';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Plant Count Percentage (Optional)
              TextFormField(
                controller: _plantCountPercentageController,
                decoration: InputDecoration(
                  labelText: 'Plant Count Percentage (Optional)',
                  hintText: 'e.g., 95.5 for 95.5%',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final percentage = double.tryParse(value);
                    if (percentage == null) {
                      return 'Please enter a valid number';
                    }
                    if (percentage < 0 || percentage > 100) {
                      return 'Percentage must be between 0 and 100';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Growth Status
              DropdownButtonFormField<String>(
                value: _growthStatus,
                decoration: InputDecoration(
                  labelText: 'Growth Status',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _growthStatusOptions.map((status) {
                  Color statusColor;
                  switch (status) {
                    case 'Excellent':
                      statusColor = Colors.green;
                      break;
                    case 'Good':
                      statusColor = Colors.lightGreen;
                      break;
                    case 'Average':
                      statusColor = Colors.orange;
                      break;
                    case 'Poor':
                      statusColor = Colors.red;
                      break;
                    case 'Critical':
                      statusColor = Colors.red[800]!;
                      break;
                    default:
                      statusColor = Colors.grey;
                  }

                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _growthStatus = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select growth status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Issues Encountered (Optional)
              TextFormField(
                controller: _issuesEncounteredController,
                decoration: InputDecoration(
                  labelText: 'Issues Encountered (Optional)',
                  hintText:
                      'Describe any problems found (disease, pests, weather, etc.)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Notes (Optional)
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Any additional observations or comments',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: (_isLoading || !_hasYieldEstimateForDetectedFarm())
                    ? null
                    : _submitYieldMonitoring,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
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
                        _hasYieldEstimateForDetectedFarm()
                            ? 'Submit Yield Monitoring'
                            : 'No Yield Estimate Available',
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
    _actualSeedsPlantedController.dispose();
    _plantCountPercentageController.dispose();
    _issuesEncounteredController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
