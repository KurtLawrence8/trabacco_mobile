import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/coordinator_service.dart';

class CoordinatorProfileScreen extends StatefulWidget {
  final String token;
  final int coordinatorId;

  const CoordinatorProfileScreen({
    Key? key,
    required this.token,
    required this.coordinatorId,
  }) : super(key: key);

  @override
  State<CoordinatorProfileScreen> createState() =>
      _CoordinatorProfileScreenState();
}

class _CoordinatorProfileScreenState extends State<CoordinatorProfileScreen> {
  Map<String, dynamic>? _coordinator;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCoordinatorData();
  }

  Future<void> _loadCoordinatorData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final coordinatorData = await CoordinatorService.getCoordinatorDetails(
        widget.token,
        widget.coordinatorId,
      );

      setState(() {
        _coordinator = coordinatorData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatBirthDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  Widget _buildInfoTile(String label, String? value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        subtitle: Text(
          value ?? 'N/A',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCoordinatorData,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _coordinator == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to Load Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Unknown error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadCoordinatorData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_coordinator?['first_name'] ?? ''} ${_coordinator?['middle_name'] ?? ''} ${_coordinator?['last_name'] ?? ''}'
                                  .trim()
                                  .replaceAll(RegExp(r'\s+'), ' '),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Area Coordinator',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (_coordinator?['status'] ?? 'Active') ==
                                        'Active'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      (_coordinator?['status'] ?? 'Active') ==
                                              'Active'
                                          ? Colors.green
                                          : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _coordinator?['status'] ?? 'Active',
                                style: TextStyle(
                                  color:
                                      (_coordinator?['status'] ?? 'Active') ==
                                              'Active'
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Personal Information Section
                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),

                      _buildInfoTile(
                        'Email',
                        _coordinator?['email_address'],
                        Icons.email,
                      ),
                      _buildInfoTile(
                        'Phone Number',
                        _coordinator?['phone_number'],
                        Icons.phone,
                      ),
                      if (_coordinator?['birth_date'] != null)
                        _buildInfoTile(
                          'Birth Date',
                          _formatBirthDate(_coordinator?['birth_date']),
                          Icons.cake,
                        ),
                      if (_coordinator?['sex'] != null)
                        _buildInfoTile(
                          'Sex',
                          _coordinator?['sex'],
                          Icons.person_outline,
                        ),

                      const SizedBox(height: 24),

                      // Address Section
                      Text(
                        'Address',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),

                      _buildInfoTile(
                        'Barangay',
                        _coordinator?['barangay'],
                        Icons.location_city,
                      ),
                      _buildInfoTile(
                        'Municipality/City',
                        _coordinator?['municipality'],
                        Icons.location_on,
                      ),
                      _buildInfoTile(
                        'Province',
                        _coordinator?['province'],
                        Icons.map,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
