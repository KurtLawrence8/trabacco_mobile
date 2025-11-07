import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/coordinator_service.dart';
import 'package:intl/intl.dart';

class CoordinatorPendingReportsScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;

  const CoordinatorPendingReportsScreen({
    Key? key,
    required this.token,
    this.onBack,
  }) : super(key: key);

  @override
  State<CoordinatorPendingReportsScreen> createState() =>
      _CoordinatorPendingReportsScreenState();
}

class _CoordinatorPendingReportsScreenState
    extends State<CoordinatorPendingReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _loading = true);
    try {
      final reports = await CoordinatorService.getPendingReports(widget.token);
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reports: $e')),
        );
      }
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _buildReportDetailSheet(report, scrollController);
        },
      ),
    );
  }

  Widget _buildReportDetailSheet(
      Map<String, dynamic> report, ScrollController scrollController) {
    final technician = report['technician'] as Map<String, dynamic>?;
    final farm = report['farm'] as Map<String, dynamic>?;
    final technicianName =
        '${technician?['first_name'] ?? ''} ${technician?['last_name'] ?? ''}'
            .trim();
    final farmName = farm?['name'] ??
        farm?['farm_address'] ??
        farm?['address'] ??
        'Unknown Farm';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5), // Light grey background like Google settings
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Report Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildSingleItemCard(
                  'Technician',
                  technicianName,
                  Icons.person_outline,
                ),
                _buildSingleItemCard(
                  'Farm',
                  farmName,
                  Icons.location_on_outlined,
                ),
                _buildSingleItemCard(
                  'Date',
                  _formatDate(report['timestamp']),
                  Icons.calendar_today_outlined,
                ),
                _buildSingleItemCard(
                  'Accomplishments',
                  report['accomplishments'] ?? 'N/A',
                  Icons.check_circle_outline,
                ),
                _buildSingleItemCard(
                  'Issues Observed',
                  report['issues_observed'] ?? 'N/A',
                  Icons.warning_amber_outlined,
                ),
                _buildSingleItemCard(
                  'Disease Detected',
                  report['disease_detected'] ?? 'None',
                  Icons.healing_outlined,
                ),
                if (report['disease_type'] != null)
                  _buildSingleItemCard(
                    'Disease Type',
                    report['disease_type'].toString(),
                    Icons.info_outline,
                  ),
                // Images section
                if (report['image_urls'] != null &&
                    (report['image_urls'] as List).isNotEmpty)
                  _buildImagesSection(report['image_urls'] as List),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showRejectDialog(report);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[800],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showApproveDialog(report);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleItemCard(String label, String value, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          icon,
          color: Colors.grey[800],
          size: 24,
          weight: 600, // Semi-bold icon
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500, // Semi-bold
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[900],
              fontWeight: FontWeight.w500, // Semi-bold
              height: 1.4,
            ),
          ),
        ),
        isThreeLine: false,
      ),
    );
  }

  Widget _buildImagesSection(List imageUrls) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  color: Colors.grey[800],
                  size: 24,
                  weight: 600,
                ),
                const SizedBox(width: 12),
                Text(
                  'Images (${imageUrls.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = imageUrls[index];
                  return GestureDetector(
                    onTap: () => _showImageViewer(imageUrls, index),
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageViewer(List imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: imageUrls.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 64,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${initialIndex + 1} / ${imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> report) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Approve Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.grey[600],
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Are you sure you want to approve this report?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Label above input
                          Text(
                            'Coordinator Notes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              hintText: 'Add your review notes...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.green, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (noteController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please add review notes')),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          await _approveReport(
                              report['id'], noteController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> report) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Reject Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.grey[600],
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Please provide a reason for rejection:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Label above input
                          Text(
                            'Rejection Reason',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              hintText:
                                  'Explain why this report needs revision...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (noteController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please provide a rejection reason')),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          await _rejectReport(
                              report['id'], noteController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveReport(int reportId, String note) async {
    try {

      await CoordinatorService.approveReport(widget.token, reportId, note);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchReports(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve report: $e')),
        );
      }
    }
  }

  Future<void> _rejectReport(int reportId, String note) async {
    try {

      await CoordinatorService.rejectReport(widget.token, reportId, note);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _fetchReports(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject report: $e')),
        );
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      // Convert to Philippine time (UTC+8)
      final utcDateTime = DateTime.parse(date.toString()).toUtc();
      final phDateTime = utcDateTime.add(const Duration(hours: 8));
      return DateFormat('MMM dd, yyyy hh:mm a').format(phDateTime);
    } catch (e) {
      return date.toString();
    }
  }

  String _formatSubmissionDate(dynamic date) {
    if (date == null) return '';
    try {
      // Convert to Philippine time (UTC+8)
      final utcDateTime = DateTime.parse(date.toString()).toUtc();
      final phDateTime = utcDateTime.add(const Duration(hours: 8));

      // Get current Philippine time
      final nowUtc = DateTime.now().toUtc();
      final nowPh = nowUtc.add(const Duration(hours: 8));
      final difference = nowPh.difference(phDateTime);

      // Format time in 12-hour format
      final timeFormat = DateFormat('h:mm a').format(phDateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago at $timeFormat';
        }
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago at $timeFormat';
      } else if (difference.inDays == 1) {
        return 'Yesterday at $timeFormat';
      } else if (difference.inDays < 7) {
        return '${DateFormat('MMM dd').format(phDateTime)} at $timeFormat';
      } else if (phDateTime.year == nowPh.year) {
        return '${DateFormat('MMM dd').format(phDateTime)} at $timeFormat';
      } else {
        return '${DateFormat('MMM dd, yyyy').format(phDateTime)} at $timeFormat';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pending Reports',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.green,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No Pending Reports',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All reports have been reviewed',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      final technician =
                          report['technician'] as Map<String, dynamic>?;
                      final farm = report['farm'] as Map<String, dynamic>?;
                      final technicianName =
                          '${technician?['first_name'] ?? ''} ${technician?['last_name'] ?? ''}'
                              .trim();
                      final farmAddress = farm?['name'] ??
                          farm?['farm_address'] ??
                          farm?['address'] ??
                          'Unknown Farm';
                      final submittedDate =
                          report['created_at'] ?? report['timestamp'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Submission date outside card (Facebook notification style)
                          if (submittedDate != null &&
                              _formatSubmissionDate(submittedDate).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 4,
                              ),
                              child: Text(
                                _formatSubmissionDate(submittedDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          // Card
                          Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.grey[100],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _showReportDetails(report),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon on the left
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.description_outlined,
                                        color: Colors.grey[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Content in the middle
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Technician name
                                          Text(
                                            technicianName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Farm address
                                          Text(
                                            farmAddress,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Date
                                          Text(
                                            _formatDate(report['timestamp']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Arrow on the right
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}

