import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/coordinator_service.dart';
import 'package:intl/intl.dart';

class CoordinatorPendingHarvestReportsScreen extends StatefulWidget {
  final String token;
  final VoidCallback? onBack;

  const CoordinatorPendingHarvestReportsScreen({
    Key? key,
    required this.token,
    this.onBack,
  }) : super(key: key);

  @override
  State<CoordinatorPendingHarvestReportsScreen> createState() =>
      _CoordinatorPendingHarvestReportsScreenState();
}

class _CoordinatorPendingHarvestReportsScreenState
    extends State<CoordinatorPendingHarvestReportsScreen> {
  List<Map<String, dynamic>> _pendingHarvestReports = [];
  bool _loading = false;
  final Map<int, bool> _technicianExpanded = {};
  final Map<int, bool> _farmerExpanded = {};

  @override
  void initState() {
    super.initState();
    _fetchPendingHarvestReports();
  }

  Future<void> _fetchPendingHarvestReports() async {
    setState(() => _loading = true);
    try {
      final reports =
          await CoordinatorService.getPendingHarvestReports(widget.token);
      setState(() {
        _pendingHarvestReports = reports;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load harvest reports: $e')),
        );
      }
    }
  }

  Future<void> _approveHarvestReport(int reportId, String note) async {
    try {
      print('📝 [AC MOBILE] Starting harvest report approval...');
      print('📝 [AC MOBILE] Report ID: $reportId');
      print('📝 [AC MOBILE] Note: $note');
      print('📝 [AC MOBILE] Token: ${widget.token.substring(0, 20)}...');

      await CoordinatorService.approveHarvestReport(
        widget.token,
        reportId,
        note,
      );

      print('✅ [AC MOBILE] Harvest report approval successful!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harvest report approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPendingHarvestReports();
      }
    } catch (e) {
      print('❌ [AC MOBILE] Error approving harvest report: $e');
      print('❌ [AC MOBILE] Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve harvest report: $e')),
        );
      }
    }
  }

  Future<void> _rejectHarvestReport(int reportId, String note) async {
    try {
      print('📝 [AC MOBILE] Starting harvest report rejection...');
      print('📝 [AC MOBILE] Report ID: $reportId');
      print('📝 [AC MOBILE] Note: $note');

      await CoordinatorService.rejectHarvestReport(
        widget.token,
        reportId,
        note,
      );

      print('✅ [AC MOBILE] Harvest report rejection successful!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harvest report rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _fetchPendingHarvestReports();
      }
    } catch (e) {
      print('❌ [AC MOBILE] Error rejecting harvest report: $e');
      print('❌ [AC MOBILE] Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject harvest report: $e')),
        );
      }
    }
  }

  void _showHarvestReportDetails(Map<String, dynamic> report) {
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
          return _buildHarvestReportDetailSheet(report, scrollController);
        },
      ),
    );
  }

  Widget _buildHarvestReportDetailSheet(
      Map<String, dynamic> report, ScrollController scrollController) {
    final technician = report['technician'] as Map<String, dynamic>?;
    final farm = report['farm'] as Map<String, dynamic>?;
    // Get farm worker - backend now provides it directly like planting reports
    final farmWorker = report['farm_worker'] as Map<String, dynamic>? ??
        farm?['farm_worker'] as Map<String, dynamic>? ??
        (farm?['farm_workers'] is List &&
                (farm?['farm_workers'] as List).isNotEmpty
            ? (farm?['farm_workers'] as List)[0] as Map<String, dynamic>?
            : null);

    final technicianName =
        '${technician?['first_name'] ?? ''} ${technician?['last_name'] ?? ''}'
            .trim();
    final farmAddress =
        farm?['farm_address'] ?? farm?['address'] ?? 'Unknown Farm';
    final farmerName = farmWorker != null
        ? '${farmWorker['first_name'] ?? ''} ${farmWorker['last_name'] ?? ''}'
            .trim()
        : 'N/A';

    // Extract additional fields
    final technicianEmail = technician?['email_address']?.toString();
    final technicianAddress = technician?['address']?.toString();
    final farmSiteNumber = farm?['site_number']?.toString();
    final farmFarmNumber = farm?['farm_number']?.toString();
    final farmArea = farm?['area'];
    final farmerPhone = farmWorker?['phone_number']?.toString();
    final farmerAddress = farmWorker?['address']?.toString();
    final actualYieldKg = report['actual_yield_kg'];
    final mortality = report['mortality'] ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
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
              'Harvest Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable content
          Expanded(
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final reportId = report['id'] as int? ?? 0;
                final isTechnicianExpanded =
                    _technicianExpanded[reportId] ?? false;
                final isFarmerExpanded = _farmerExpanded[reportId] ?? false;

                return ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Technician Information Card (Collapsible)
                    _buildCollapsibleCard(
                      title: 'Technician',
                      titleValue: technicianName,
                      icon: Icons.person_outline,
                      isExpanded: isTechnicianExpanded,
                      onTap: () {
                        setState(() {
                          _technicianExpanded[reportId] = !isTechnicianExpanded;
                        });
                        setSheetState(() {});
                      },
                      children: [
                        if (technicianEmail != null &&
                            technicianEmail.isNotEmpty)
                          _buildGroupedItem(
                            'Email',
                            technicianEmail,
                            Icons.email_outlined,
                          ),
                        if (technicianAddress != null &&
                            technicianAddress.isNotEmpty)
                          _buildGroupedItem(
                            'Address',
                            technicianAddress,
                            Icons.location_on_outlined,
                          ),
                      ],
                    ),

                    // Farm Information Card (Grouped)
                    _buildGroupedCard([
                      _buildGroupedItem(
                        'Farm Address',
                        farmAddress,
                        Icons.location_on_outlined,
                      ),
                      if (farmSiteNumber != null && farmSiteNumber.isNotEmpty)
                        _buildGroupedItem(
                          'Site Number',
                          farmSiteNumber,
                          Icons.numbers_outlined,
                        ),
                      if (farmFarmNumber != null && farmFarmNumber.isNotEmpty)
                        _buildGroupedItem(
                          'Farm Number',
                          farmFarmNumber,
                          Icons.numbers_outlined,
                        ),
                      if (farmArea != null)
                        _buildGroupedItem(
                          'Farm Size',
                          '${farmArea} sqm',
                          Icons.crop_free_outlined,
                        ),
                    ]),

                    // Farmer Information Card (Collapsible)
                    _buildCollapsibleCard(
                      title: 'Farmer',
                      titleValue: farmerName,
                      icon: Icons.person_outline,
                      isExpanded: isFarmerExpanded,
                      onTap: () {
                        setState(() {
                          _farmerExpanded[reportId] = !isFarmerExpanded;
                        });
                        setSheetState(() {});
                      },
                      children: [
                        if (farmerPhone != null && farmerPhone.isNotEmpty)
                          _buildGroupedItem(
                            'Phone Number',
                            farmerPhone,
                            Icons.phone_outlined,
                          ),
                        if (farmerAddress != null && farmerAddress.isNotEmpty)
                          _buildGroupedItem(
                            'Address',
                            farmerAddress,
                            Icons.location_on_outlined,
                          ),
                      ],
                    ),

                    _buildSingleItemCard(
                      'Harvest Date',
                      _formatDate(report['harvest_date']),
                      Icons.calendar_today_outlined,
                    ),

                    // Harvest Details Section
                    _buildSingleItemCard(
                      'Mortality',
                      '${_formatNumber(mortality)}',
                      Icons.warning_amber_outlined,
                    ),
                    _buildSingleItemCard(
                      'Initial Weight',
                      actualYieldKg != null
                          ? '${_formatNumber(actualYieldKg)} kg'
                          : '0 kg',
                      Icons.scale_outlined,
                    ),
                    if (report['notes'] != null &&
                        report['notes'].toString().isNotEmpty)
                      _buildSingleItemCard(
                        'Notes',
                        report['notes'].toString(),
                        Icons.note_outlined,
                      ),
                  ],
                );
              },
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
                          'Approve Harvest Report',
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
                            'Are you sure you want to approve this harvest report?',
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
                          await _approveHarvestReport(
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
                          'Reject Harvest Report',
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
                          await _rejectHarvestReport(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pending Harvest Reports',
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
        onRefresh: _fetchPendingHarvestReports,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _pendingHarvestReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No Pending Harvest Reports',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingHarvestReports.length,
                    itemBuilder: (context, index) {
                      final report = _pendingHarvestReports[index];
                      final farm = report['farm'] as Map<String, dynamic>?;
                      // Get farm worker - backend now provides it directly like planting reports
                      final farmWorker =
                          report['farm_worker'] as Map<String, dynamic>? ??
                              farm?['farm_worker'] as Map<String, dynamic>? ??
                              (farm?['farm_workers'] is List &&
                                      (farm?['farm_workers'] as List).isNotEmpty
                                  ? (farm?['farm_workers'] as List)[0]
                                      as Map<String, dynamic>?
                                  : null);
                      final farmerName = farmWorker != null
                          ? '${farmWorker['first_name'] ?? ''} ${farmWorker['last_name'] ?? ''}'
                              .trim()
                          : 'N/A';

                      final farmAddress = farm?['farm_address'] ??
                          farm?['address'] ??
                          'Unknown Farm';
                      final farmSiteNumber = farm?['site_number']?.toString();
                      final farmArea = farm?['area'];
                      final actualYieldKg = report['actual_yield_kg'];
                      final mortality = report['mortality'] ?? 0;
                      final submittedDate =
                          report['created_at'] ?? report['submitted_at'];

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
                              onTap: () => _showHarvestReportDetails(report),
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
                                        Icons.local_shipping_outlined,
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
                                          // Site Number (on top)
                                          if (farmSiteNumber != null &&
                                              farmSiteNumber.isNotEmpty) ...[
                                            Text(
                                              'Site Number: $farmSiteNumber',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                          // Farm Address (smaller)
                                          Text(
                                            farmAddress,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          // Farm Size (below farm address)
                                          if (farmArea != null) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Farm Size: ${farmArea} sqm',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          // Initial Weight (with label, highlighted)
                                          Text(
                                            'Initial Weight: ${actualYieldKg != null ? _formatNumber(actualYieldKg) : '0'} kg',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.brown,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Mortality
                                          Text(
                                            'Mortality: ${_formatNumber(mortality)}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Farmer name
                                          Text(
                                            'Farmer: $farmerName',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Date
                                          Text(
                                            _formatDate(report['harvest_date']),
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
          weight: 600,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[900],
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        isThreeLine: false,
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(height: 1, indent: 56, color: Colors.grey[200]),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupedItem(String label, String value, IconData icon) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(
        icon,
        color: Colors.grey[800],
        size: 24,
        weight: 600,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[900],
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
      isThreeLine: false,
    );
  }

  Widget _buildCollapsibleCard({
    required String title,
    required String titleValue,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Icon(
                icon,
                color: Colors.grey[800],
                size: 24,
                weight: 600,
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  titleValue,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[900],
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              trailing: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey[600],
                size: 24,
              ),
              isThreeLine: false,
            ),
          ),
          if (isExpanded && children.isNotEmpty) ...[
            Divider(height: 1, indent: 56, color: Colors.grey[200]),
            ...children,
          ],
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString()).toLocal();
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    return NumberFormat('#,###')
        .format(double.tryParse(number.toString())?.toInt() ?? 0);
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
}
