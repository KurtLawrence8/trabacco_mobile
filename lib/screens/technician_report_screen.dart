import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';
import '../models/report_model.dart';

class TechnicianReportScreen extends StatefulWidget {
  const TechnicianReportScreen({Key? key}) : super(key: key);

  @override
  _TechnicianReportScreenState createState() => _TechnicianReportScreenState();
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
      final farms = await _reportService.getFarms();
      setState(() {
        _farms = farms;
        if (farms.isNotEmpty) {
          _selectedFarmId = farms[0]['id'].toString();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load farms: ${e.toString()}')),
      );
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
        'farm_id': _selectedFarmId,
        'accomplishments': _accomplishmentsController.text,
        'issues_observed': _issuesController.text,
        'disease_detected': _diseaseDetected,
        'disease_type':
            _diseaseDetected == 'Yes' ? _diseaseTypeController.text : null,
        'description': _descriptionController.text,
        'timestamp': _selectedDate.toIso8601String(),
      };

      await _reportService.createReport(report);

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Farm Selection
              DropdownButtonFormField<String>(
                value: _selectedFarmId,
                decoration: const InputDecoration(
                  labelText: 'Select Farm',
                  border: OutlineInputBorder(),
                ),
                items: _farms.map((farm) {
                  return DropdownMenuItem(
                    value: farm['id'].toString(),
                    child: Text(farm['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFarmId = value!;
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
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Accomplishments',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Issues Observed',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Disease Detected',
                  border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Disease Type',
                    border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Submit Report'),
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
