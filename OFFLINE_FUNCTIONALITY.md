# Offline-First Functionality

This document explains the offline-first functionality implemented in the Trabacco Mobile app.

## Overview

The app now supports **offline-first** data storage, meaning:
- Data is saved locally when offline
- Data is automatically synced when internet is available
- Users can continue working without internet connection
- No data loss when connection is intermittent

## How It Works

### 1. **Offline Detection**
- Uses `connectivity_plus` package to detect network status
- Tests actual internet connectivity (not just WiFi connection)
- Automatically switches between online and offline modes

### 2. **Local Storage**
- Uses `SharedPreferences` for storing pending data
- Data is stored with metadata (timestamps, offline IDs)
- Supports multiple data types: reports, requests, profile updates, schedule updates

### 3. **Automatic Sync**
- Syncs data when internet becomes available
- Retries failed syncs automatically
- Removes synced data from local storage
- Shows sync status to users

## Supported Operations

### ✅ **Reports**
- Create reports with images
- Saved locally when offline
- Synced when online

### ✅ **Requests**
- Create supply/cash advance requests
- Saved locally when offline
- Synced when online

### ✅ **Profile Updates**
- Update farm worker/technician profiles
- Saved locally when offline
- Synced when online

### ✅ **Schedule Updates**
- Mark schedules as completed/cancelled
- Saved locally when offline
- Synced when online

## Implementation

### Services

#### `OfflineStorageService`
- Handles local storage operations
- Manages pending data queues
- Performs sync operations

#### `OfflineFirstService`
- Wraps existing services with offline capabilities
- Provides unified API for offline-first operations
- Handles online/offline logic

### Widgets

#### `SyncStatusWidget`
- Shows connection status
- Displays pending items count
- Provides manual sync button
- Shows last sync timestamp

#### `CompactSyncIndicator`
- Compact version for app bars
- Shows connection status and pending count

## Usage Examples

### Basic Usage

```dart
// Create offline-first service
final offlineService = OfflineFirstService();

// Create report (works online or offline)
final result = await offlineService.createReport(reportData, token);

// Check if offline
if (result['offline'] == true) {
  print('Data saved offline - will sync later');
}

// Manual sync
final results = await offlineService.syncAllPendingData(token);
print('Synced: ${results['reports_synced']} reports');
```

### Adding Sync Status to Screen

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Screen'),
        actions: [
          CompactSyncIndicator(token: token),
        ],
      ),
      body: Column(
        children: [
          // Full sync status widget
          SyncStatusWidget(
            token: token,
            onSyncComplete: () {
              // Refresh data after sync
              setState(() {});
            },
          ),
          
          // Your content here
          Expanded(child: YourContent()),
        ],
      ),
    );
  }
}
```

## Configuration

### Dependencies Added
```yaml
dependencies:
  connectivity_plus: ^5.0.2
```

### Service Integration
All existing services now use offline-first approach:
- `ReportService.createReport()` - Uses offline-first
- `RequestService.createRequest()` - Uses offline-first  
- `ScheduleService.updateScheduleStatus()` - Uses offline-first
- Profile update methods - Use offline-first

## Data Flow

### Online Mode
1. User performs action
2. Data sent directly to server
3. Success/error response shown
4. Data not stored locally

### Offline Mode
1. User performs action
2. Data saved to local storage
3. Success message shown (with offline indicator)
4. Data queued for sync

### Sync Process
1. App detects internet connection
2. Retrieves pending data from local storage
3. Sends data to server in batches
4. Removes synced data from local storage
5. Updates UI with sync results

## Error Handling

### Network Errors
- Automatically falls back to offline mode
- Shows appropriate error messages
- Retries sync when connection restored

### Sync Errors
- Individual items can fail without affecting others
- Failed items remain in local storage
- Error details logged for debugging

### Data Validation
- Same validation rules apply online and offline
- Invalid data rejected before saving locally
- Server validation still performed during sync

## Benefits

### For Users
- ✅ No data loss when offline
- ✅ Can work without internet
- ✅ Automatic sync when online
- ✅ Clear status indicators
- ✅ Manual sync option

### For Developers
- ✅ Minimal code changes required
- ✅ Transparent offline handling
- ✅ Easy to add new offline operations
- ✅ Comprehensive error handling
- ✅ Detailed logging

## Testing

### Test Offline Functionality
1. Turn off WiFi/mobile data
2. Create reports, requests, etc.
3. Verify data saved locally
4. Turn on internet
5. Verify data synced automatically

### Test Sync Status
1. Use the `OfflineDemoScreen` for testing
2. Create test data while offline
3. Check pending items count
4. Test manual sync functionality

## Future Enhancements

### Planned Features
- [ ] Background sync service
- [ ] Conflict resolution for concurrent edits
- [ ] Offline data encryption
- [ ] Sync progress indicators
- [ ] Data compression for large files
- [ ] Selective sync (sync only important data)

### Advanced Features
- [ ] Offline data analytics
- [ ] Sync scheduling
- [ ] Data versioning
- [ ] Multi-device sync
- [ ] Offline data export/import

## Troubleshooting

### Common Issues

#### Data Not Syncing
- Check internet connection
- Verify server is running
- Check authentication token
- Review error logs

#### High Memory Usage
- Clear old pending data
- Reduce image sizes
- Implement data cleanup

#### Sync Failures
- Check network stability
- Verify server endpoints
- Review data format
- Check authentication

### Debug Information
- All operations logged with timestamps
- Sync results include detailed counts
- Error messages include context
- Network status monitored continuously

## Conclusion

The offline-first functionality provides a robust solution for mobile data management, ensuring users can work effectively regardless of network conditions while maintaining data integrity and providing a seamless user experience.
