import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';

class TechnicianReportScreen extends StatefulWidget {
  final String? token;
  final int? technicianId;
  const TechnicianReportScreen({Key? key, this.token, this.technicianId}) : super(key: key);

  @override
  State<TechnicianReportScreen> createState() => _TechnicianReportScreenState();
}

class _TechnicianReportScreenState extends State<TechnicianReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reportService = ReportService();
  bool _isLoading = false;

  // Form controllers
  final TextEditingController _accomplishmentsController =
      TextEditingController();
  final TextEditingController _issuesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _diseaseTypeController = TextEditingController();

  // Selected values
  String _selectedFarmId = '';
  String _diseaseDetected = 'None';
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _farms = [];

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    try {
      if (widget.token == null) {
        throw Exception('No authentication token available');
      }
      print('Loading farms with token: ${widget.token!.substring(0, 10)}...');
      final farms = await _reportService.getFarms(widget.token!);
      print('Loaded ${farms.length} farms');
      if (mounted) {
        setState(() {
          _farms = farms;
          if (farms.isNotEmpty && farms[0]['id'] != null) {
            _selectedFarmId = farms[0]['id'].toString();
            print('Selected farm: ${farms[0]['name']} (ID: ${farms[0]['id']})');
          } else {
            _selectedFarmId = '';
            print('No valid farms found');
          }
        });
      }
    } catch (e) {
      print('Error loading farms: $e');
      if (mounted) {
        // Show error but also provide fallback data for testing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load farms: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Add fallback data for testing if API is not available
        setState(() {
          _farms = [
            {'id': 1, 'name': 'Sample Farm 1'},
            {'id': 2, 'name': 'Sample Farm 2'},
          ];
          _selectedFarmId = '1';
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final report = {
        'technician_id': widget.technicianId ?? 1,
        // Use a hardcoded farm_id that exists in your tbl_farms table
        'farm_id': 1, // Change this to an actual farm ID from your tbl_farms table
        'accomplishments': _accomplishmentsController.text,
        'issues_observed': _issuesController.text,
        'disease_detected': _diseaseDetected,
        'disease_type':
            _diseaseDetected == 'Yes' ? _diseaseTypeController.text : null,
        'description': _descriptionController.text,
        'timestamp': _selectedDate.toIso8601String(),
      };

      if (widget.token == null) {
        throw Exception('No authentication token available');
      }
      print('Submitting report with technician_id: ${widget.technicianId}');
      print('Report data: $report');
      await _reportService.createReport(report, widget.token!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );

      // Clear form
      _accomplishmentsController.clear();
      _issuesController.clear();
      _descriptionController.clear();
      _diseaseTypeController.clear();
      _diseaseDetected = 'None';
      _selectedDate = DateTime.now();
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
        title: const Text('Submit Daily Report'),
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
              // Farm Selection
              _farms.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            const Text(
                              'Loading farms...',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Token: ${widget.token?.substring(0, 10) ?? 'None'}...',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'Technician ID: ${widget.technicianId ?? 'None'}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedFarmId.isEmpty ? null : _selectedFarmId,
                      decoration: InputDecoration(
                        labelText: 'Select Farm',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _farms.where((farm) => farm['id'] != null).map((farm) {
                        final farmId = farm['id']!.toString();
                        final farmName = farm['name']?.toString() ?? 'Unknown Farm';
                        return DropdownMenuItem(
                          value: farmId,
                          child: Text(farmName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFarmId = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a farm';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),

              // Date Selection
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
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

  @override
  void dispose() {
    _accomplishmentsController.dispose();
    _issuesController.dispose();
    _descriptionController.dispose();
    _diseaseTypeController.dispose();
    super.dispose();
  }
}
