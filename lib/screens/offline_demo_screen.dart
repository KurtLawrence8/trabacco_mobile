import 'package:flutter/material.dart';
import '../services/offline_first_service.dart';
import '../widgets/sync_status_widget.dart';

/// Demo screen showing offline functionality
class OfflineDemoScreen extends StatefulWidget {
  final String token;

  const OfflineDemoScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<OfflineDemoScreen> createState() => _OfflineDemoScreenState();
}

class _OfflineDemoScreenState extends State<OfflineDemoScreen> {
  final OfflineFirstService _offlineService = OfflineFirstService();
  bool _isOnline = true;
  int _pendingItems = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final isOnline = await _offlineService.isOnline();
    final pendingItems = await _offlineService.getPendingItemsCount();
    
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
        _pendingItems = pendingItems;
      });
    }
  }

  Future<void> _testOfflineReport() async {
    try {
      final reportData = {
        'farm_id': 1,
        'title': 'Test Offline Report',
        'description': 'This is a test report created while offline',
        'status': 'Pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await _offlineService.createReport(reportData, widget.token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Report saved successfully'),
            backgroundColor: result['offline'] == true ? Colors.orange : Colors.green,
          ),
        );
        
        await _checkStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testOfflineRequest() async {
    try {
      final requestData = {
        'technician_id': 1,
        'farm_worker_id': 1,
        'type': 'supply',
        'reason': 'Test offline request',
        'supply_id': 1,
        'quantity': 5,
      };

      await _offlineService.createRequest(widget.token, requestData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _checkStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testOfflineProfileUpdate() async {
    try {
      final updateData = {
        'name': 'Updated Name ${DateTime.now().millisecondsSinceEpoch}',
        'phone': '1234567890',
      };

      final result = await _offlineService.updateProfile(
        'FarmWorker',
        1,
        updateData,
        widget.token,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Profile update saved successfully'),
            backgroundColor: result['offline'] == true ? Colors.orange : Colors.green,
          ),
        );
        
        await _checkStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testOfflineScheduleUpdate() async {
    try {
      await _offlineService.updateScheduleStatus(1, 'Completed', widget.token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule update saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _checkStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncNow() async {
    try {
      final results = await _offlineService.syncAllPendingData(widget.token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync completed: ${results['reports_synced']} reports, '
              '${results['requests_synced']} requests, '
              '${results['profile_updates_synced']} profile updates, '
              '${results['schedule_updates_synced']} schedule updates synced',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        await _checkStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Demo'),
        actions: [
          CompactSyncIndicator(token: widget.token),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Sync status widget
          SyncStatusWidget(
            token: widget.token,
            onSyncComplete: _checkStatus,
          ),
          
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connection Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _isOnline ? Icons.wifi : Icons.wifi_off,
                                color: _isOnline ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(_isOnline ? 'Online' : 'Offline'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Pending items: $_pendingItems'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Test buttons
                  Text(
                    'Test Offline Functionality',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: _testOfflineReport,
                    icon: const Icon(Icons.description),
                    label: const Text('Create Test Report'),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: _testOfflineRequest,
                    icon: const Icon(Icons.request_quote),
                    label: const Text('Create Test Request'),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: _testOfflineProfileUpdate,
                    icon: const Icon(Icons.person),
                    label: const Text('Update Profile'),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: _testOfflineScheduleUpdate,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Update Schedule'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sync button
                  if (_pendingItems > 0)
                    ElevatedButton.icon(
                      onPressed: _isOnline ? _syncNow : null,
                      icon: const Icon(Icons.sync),
                      label: Text('Sync Now ($_pendingItems items)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Info text
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How it works:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• When online: Data is sent directly to the server\n'
                            '• When offline: Data is saved locally and synced later\n'
                            '• All data is automatically synced when internet is available\n'
                            '• You can manually sync using the "Sync Now" button',
                          ),
                        ],
                      ),
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
}
