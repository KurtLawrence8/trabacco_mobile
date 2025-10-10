import 'package:flutter/material.dart';
import '../services/harvest_service.dart';
import '../services/farm_service.dart';
import '../services/laborer_service.dart';
import '../models/farm.dart';
import '../models/laborer.dart';

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
  final _farmService = FarmService();
  final _laborerService = LaborerService();
  bool _isLoading = false;

  // Form controllers
  final TextEditingController _mortalityController = TextEditingController();
  final TextEditingController _initialKgController = TextEditingController();

  // Farm selection
  List<Farm> _farms = [];
  Farm? _selectedFarm;
  List<Laborer> _allLaborers = [];
  List<Laborer> _selectedLaborers = [];

  @override
  void initState() {
    super.initState();
    _loadFarms();
    _loadLaborers();
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

  Future<void> _submitHarvest() async {
    if (!_formKey.currentState!.validate()) return;
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
      final harvestData = {
        'farm_id': _selectedFarm!.id,
        'mortality': int.parse(_mortalityController.text),
        'initial_kg': double.parse(_initialKgController.text),
        'laborer_ids': _selectedLaborers.map((l) => l.id).toList(),
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
                child: _allLaborers.isEmpty
                    ? const Center(child: Text('No laborers available'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _allLaborers.length,
                        itemBuilder: (context, index) {
                          final laborer = _allLaborers[index];
                          final isSelected = _selectedLaborers.contains(laborer);

                          return CheckboxListTile(
                            title: Text('${laborer.firstName} ${laborer.lastName}'),
                            subtitle: laborer.phoneNumber != null
                                ? Text(laborer.phoneNumber!)
                                : null,
                            value: isSelected,
                            onChanged: (bool? selected) {
                              setDialogState(() {
                                if (selected == true) {
                                  if (!_selectedLaborers.contains(laborer)) {
                                    _selectedLaborers.add(laborer);
                                  }
                                } else {
                                  _selectedLaborers.remove(laborer);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
    _mortalityController.dispose();
    _initialKgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harvest Report'),
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
                            'Farm Workers (auto-included)',
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

              const SizedBox(height: 20),

              // Mortality
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
                      'Mortality',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mortalityController,
                      decoration: InputDecoration(
                        labelText: 'Number of Mortality',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.trending_down, color: Color(0xFFE74C3C)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter mortality count';
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
              const SizedBox(height: 20),

              // Initial KG
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
                      'Initial Harvest Weight',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _initialKgController,
                      decoration: InputDecoration(
                        labelText: 'Initial Weight (kg)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.scale, color: Color(0xFF27AE60)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter initial weight';
                        }
                        if (double.tryParse(value) == null) {
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
                onPressed: _isLoading ? null : _submitHarvest,
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
                        'Submit Harvest Report',
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
