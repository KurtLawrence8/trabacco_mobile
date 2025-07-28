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
      appBar: AppBar(
        title: const Text('Farm Worker Details'),
        backgroundColor: const Color(0xFF27AE60),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              const Color(0xFF27AE60).withOpacity(0.1),
                          child: const Icon(Icons.person,
                              size: 36, color: Color(0xFF27AE60)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${details.firstName} ${details.lastName}',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              if (details.sex != null)
                                Row(
                                  children: [
                                    Icon(Icons.wc,
                                        size: 18, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text('${details.sex}',
                                        style:
                                            TextStyle(color: Colors.grey[700])),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            color: Colors.blueGrey, size: 20),
                        const SizedBox(width: 8),
                        Text(details.phoneNumber,
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    if (details.address != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(details.address!,
                                  style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    ],
                    if (details.birthDate != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.cake,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(details.birthDate!,
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openRequestScreen,
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Create Request',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text('Requests',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222B45))),
            const SizedBox(height: 8),
            Expanded(
              child: RequestListWidget(
                key: requestListKey,
                farmWorkerId: widget.farmWorker.id,
                token: widget.token,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
