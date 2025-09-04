import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'request_list_widget.dart';
import 'request_screen.dart';

class FarmWorkerDetailScreen extends StatefulWidget {
  final FarmWorker farmWorker;
  final String token;
  const FarmWorkerDetailScreen(
      {Key? key, required this.farmWorker, required this.token})
      : super(key: key);

  @override
  State<FarmWorkerDetailScreen> createState() => _FarmWorkerDetailScreenState();
}

class _FarmWorkerDetailScreenState extends State<FarmWorkerDetailScreen> {
  Key requestListKey = UniqueKey();

  void _openRequestScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestScreen(
          farmWorker: widget.farmWorker,
          token: widget.token,
        ),
      ),
    );
    if (result == true) {
      setState(() {
        requestListKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.farmWorker;
    return Scaffold(
      //CHANGES STARTS HERE NA PART HANGGANG LAST LINE
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with back button and title
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: 10,
            ),
            color: Color(0xFF27AE60),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  padding: EdgeInsets.zero,
                ),
                Expanded(
                  child: Text(
                    'Farm Worker Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farm Worker Information Card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Section
                        Row(
                          children: [
                            // Profile picture
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Color(0xFFE8D5FF),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  details.firstName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Color(0xFF6B21A8),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            // Name and Gender
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${details.firstName} ${details.lastName}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  if (details.sex != null) ...[
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.person_rounded,
                                            size: 24, color: Colors.grey[600]),
                                        SizedBox(width: 6),
                                        Text(
                                          details.sex!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Contact and Personal Details
                        _buildDetailRow(
                          icon: Icons.phone_rounded,
                          iconColor: Colors.grey[600]!,
                          text: details.phoneNumber,
                        ),
                        if (details.address != null) ...[
                          SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.location_on_rounded,
                            iconColor: Colors.grey[600]!,
                            text: details.address!,
                          ),
                        ],
                        if (details.birthDate != null) ...[
                          SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.cake_rounded,
                            iconColor: Colors.grey[600]!,
                            text: details.birthDate!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Create Request Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _openRequestScreen,
                      icon: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        'Create Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Requests Section
                  Padding(
                    padding: EdgeInsets.all(0),
                    child: Row(
                      children: [
                        Text(
                          'Requests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              requestListKey = UniqueKey();
                            });
                          },
                          icon: Icon(Icons.refresh, color: Color(0xFF27AE60)),
                          tooltip: 'Refresh requests',
                        ),
                      ],
                    ),
                  ),

                  // Request List
                  Container(
                    height: 400, // Increased height for better visibility
                    child: RequestListWidget(
                      key: requestListKey,
                      farmWorkerId: widget.farmWorker.id,
                      token: widget.token,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }
}
