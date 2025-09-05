import 'package:flutter/material.dart';
import '../services/offline_first_service.dart';

/// Widget to display sync status and pending items
class SyncStatusWidget extends StatefulWidget {
  final String token;
  final VoidCallback? onSyncComplete;

  const SyncStatusWidget({
    Key? key,
    required this.token,
    this.onSyncComplete,
  }) : super(key: key);

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final OfflineFirstService _offlineService = OfflineFirstService();
  bool _isOnline = true;
  int _pendingItems = 0;
  bool _isSyncing = false;
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    // Check status every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _checkStatus();
        _startPeriodicCheck();
      }
    });
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    
    final isOnline = await _offlineService.isOnline();
    final pendingItems = await _offlineService.getPendingItemsCount();
    final lastSync = await _offlineService.getLastSyncTimestamp();
    
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
        _pendingItems = pendingItems;
        _lastSync = lastSync;
      });
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
    });

    try {
      final results = await _offlineService.syncAllPendingData(widget.token);
      
      if (mounted) {
        // Show success message
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
        
        // Refresh status
        await _checkStatus();
        
        // Notify parent
        widget.onSyncComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border(
          top: BorderSide(
            color: _isOnline ? Colors.green.shade200 : Colors.orange.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          
          // Status text
          Expanded(
            child: Text(
              _isOnline 
                ? (_pendingItems > 0 
                    ? 'Online - $_pendingItems items pending sync'
                    : 'Online - All synced')
                : 'Offline - Data saved locally',
              style: TextStyle(
                color: _isOnline ? Colors.green.shade700 : Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Sync button (only show if there are pending items and online)
          if (_isOnline && _pendingItems > 0)
            TextButton.icon(
              onPressed: _isSyncing ? null : _syncNow,
              icon: _isSyncing 
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 16),
              label: Text(
                _isSyncing ? 'Syncing...' : 'Sync Now',
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          
          // Last sync info
          if (_lastSync != null && _isOnline)
            Tooltip(
              message: 'Last sync: ${_formatLastSync(_lastSync!)}',
              child: Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Compact sync status indicator for app bars
class CompactSyncIndicator extends StatefulWidget {
  final String token;

  const CompactSyncIndicator({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<CompactSyncIndicator> createState() => _CompactSyncIndicatorState();
}

class _CompactSyncIndicatorState extends State<CompactSyncIndicator> {
  final OfflineFirstService _offlineService = OfflineFirstService();
  bool _isOnline = true;
  int _pendingItems = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    
    final isOnline = await _offlineService.isOnline();
    final pendingItems = await _offlineService.getPendingItemsCount();
    
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
        _pendingItems = pendingItems;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _isOnline ? Colors.green : Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        
        // Pending count badge
        if (_pendingItems > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _pendingItems.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
