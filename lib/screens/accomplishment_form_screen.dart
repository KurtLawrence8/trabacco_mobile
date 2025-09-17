import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/report_service.dart';
import '../models/farm.dart';

class AccomplishmentFormScreen extends StatefulWidget {
  final String? token;
  final int? technicianId;
  final File photo;
  final Position position;
  final Farm? detectedFarm;

  const AccomplishmentFormScreen({
    Key? key,
    this.token,
    this.technicianId,
    required this.photo,
    required this.position,
    this.detectedFarm,
  }) : super(key: key);

  @override
  State<AccomplishmentFormScreen> createState() =>
      _AccomplishmentFormScreenState();
}

class _AccomplishmentFormScreenState extends State<AccomplishmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reportService = ReportService();
  bool _isLoading = false;

  final TextEditingController _accomplishmentsController =
      TextEditingController();
  final TextEditingController _issuesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _diseaseTypeController = TextEditingController();

  String _diseaseDetected = 'None';

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

    setState(() {
      _isLoading = true;
    });

    try {
      final report = {
        'technician_id': widget.technicianId ?? 1,
        'farm_id': widget.detectedFarm?.id ?? 1,
        'accomplishments': _accomplishmentsController.text,
        'issues_observed': _issuesController.text,
        'disease_detected': _diseaseDetected,
        'disease_type':
            _diseaseDetected == 'Yes' ? _diseaseTypeController.text : null,
        'description': _descriptionController.text,
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': widget.position.latitude,
        'longitude': widget.position.longitude,
      };

      if (widget.token == null) {
        throw Exception('No authentication token available');
      }

      await _reportService.createReport(
        report,
        widget.token!,
        images: [widget.photo],
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
              // Farm info with better styling
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                          color: Color(0xFF27AE60),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
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
                      widget.detectedFarm?.farmAddress ?? 'No farm detected',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    if (widget.detectedFarm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Farm Size: ${widget.detectedFarm!.farmSize} hectares',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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
}
