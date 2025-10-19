import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'farm_worker_detail_screen.dart';
import 'technician_landing_screen.dart';

class AllRequestsScreen extends StatefulWidget {
  final String token;
  final int technicianId;

  const AllRequestsScreen({
    Key? key,
    required this.token,
    required this.technicianId,
  }) : super(key: key);

  @override
  State<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

class _AllRequestsScreenState extends State<AllRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<RequestModel> _allRequests = [];
  List<RequestModel> _filteredRequests = [];
  Map<int, FarmWorker> _farmWorkersMap = {};
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedType;
  bool _showFilterCard = false;
  bool _isStatusDropdownExpanded = false;
  bool _isTypeDropdownExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchAllRequests();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  Future<void> _fetchAllRequests() async {
    setState(() => _loading = true);
    try {
      final requestService = RequestService();
      final provider = Provider.of<FarmWorkerProvider>(context, listen: false);

      List<RequestModel> allRequests = [];
      Map<int, FarmWorker> farmWorkersMap = {};

      // Ensure farm workers are loaded
      await provider.fetchFarmWorkers(widget.token, widget.technicianId);

      if (provider.farmWorkers.isNotEmpty) {
        for (final farmWorker in provider.farmWorkers) {
          farmWorkersMap[farmWorker.id] = farmWorker;
          try {
            final requests = await requestService.getRequestsForFarmWorker(
                widget.token, farmWorker.id);

            // Get ALL requests (not just pending ones)
            allRequests.addAll(requests);
          } catch (e) {
            print('Error fetching requests for farmer ${farmWorker.id}: $e');
          }
        }
      }

      // Sort requests by creation date (newest first)
      allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _allRequests = allRequests;
          _farmWorkersMap = farmWorkersMap;
          _loading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      print('Error fetching all requests: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRequests = _allRequests.where((request) {
        // Search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            request.reason?.toLowerCase().contains(_searchQuery) == true ||
            _getFarmerName(request.farmWorkerId)
                .toLowerCase()
                .contains(_searchQuery) ||
            request.id.toString().contains(_searchQuery) ||
            request.type?.toLowerCase().contains(_searchQuery) == true;

        // Status filter
        bool matchesStatus = _selectedStatus == null ||
            request.status?.toLowerCase() == _selectedStatus?.toLowerCase();

        // Type filter
        bool matchesType = _selectedType == null ||
            request.type?.toLowerCase() == _selectedType?.toLowerCase();

        return matchesSearch && matchesStatus && matchesType;
      }).toList();
    });
  }

  void _toggleFilterCard() {
    setState(() {
      _showFilterCard = !_showFilterCard;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedType = null;
      _searchController.clear();
      _searchQuery = '';
      _showFilterCard = false;
      _isStatusDropdownExpanded = false;
      _isTypeDropdownExpanded = false;
    });
    _applyFilters();
  }

  String _getFarmerName(int farmWorkerId) {
    final farmWorker = _farmWorkersMap[farmWorkerId];
    if (farmWorker != null) {
      return '${farmWorker.firstName} ${farmWorker.lastName}';
    }
    return 'Unknown Farmer';
  }

  Widget _buildDropdownOption({
    required IconData icon,
    required String label,
    required String? value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? const Color(0xFF2C3E50) : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[400]!,
                    width: 2,
                  ),
                ),
              ),
          ],
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
          'All Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search and Filter Section
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF9E9E9E),
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search requests, farmers, or IDs...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 22,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            (_selectedStatus != null || _selectedType != null)
                                ? Colors.green
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              (_selectedStatus != null || _selectedType != null)
                                  ? Colors.green
                                  : const Color(0xFF9E9E9E),
                          width: 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _toggleFilterCard,
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.filter_list_rounded,
                              color: (_selectedStatus != null ||
                                      _selectedType != null)
                                  ? Colors.white
                                  : const Color(0xFF9E9E9E),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Results count
              if (!_loading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  width: double.infinity,
                  child: Text(
                    '${_filteredRequests.length} of ${_allRequests.length} requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // Requests List
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredRequests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _allRequests.isEmpty
                                      ? 'No requests found'
                                      : 'No requests match your filters',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _allRequests.isEmpty
                                      ? 'Requests will appear here from assigned farmers'
                                      : 'Try adjusting your search or filter criteria',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchAllRequests,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _filteredRequests.length,
                              itemBuilder: (context, index) {
                                final request = _filteredRequests[index];
                                return _buildRequestCard(request);
                              },
                            ),
                          ),
              ),
            ],
          ),
          // Filter Overlay
          if (_showFilterCard)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showFilterCard = false;
                    _isStatusDropdownExpanded = false;
                    _isTypeDropdownExpanded = false;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          if (_showFilterCard)
            Positioned(
              top: MediaQuery.of(context).padding.top + 140,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Filter Options',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _toggleFilterCard,
                              child: Icon(
                                Icons.close,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Status Filter
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isStatusDropdownExpanded =
                                  !_isStatusDropdownExpanded;
                              _isTypeDropdownExpanded = false;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedStatus?.toUpperCase() ??
                                        'ALL STATUS',
                                    style: TextStyle(
                                      color: _selectedStatus != null
                                          ? const Color(0xFF2C3E50)
                                          : Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _isStatusDropdownExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isStatusDropdownExpanded) ...[
                          const SizedBox(height: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildDropdownOption(
                                  icon: Icons.all_inclusive,
                                  label: 'All Status',
                                  value: null,
                                  isSelected: _selectedStatus == null,
                                  onTap: () {
                                    setState(() {
                                      _selectedStatus = null;
                                      _isStatusDropdownExpanded = false;
                                    });
                                    _applyFilters();
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                _buildDropdownOption(
                                  icon: Icons.pending_actions,
                                  label: 'Pending',
                                  value: 'pending',
                                  isSelected: _selectedStatus == 'pending',
                                  onTap: () {
                                    setState(() {
                                      _selectedStatus = 'pending';
                                      _isStatusDropdownExpanded = false;
                                    });
                                    _applyFilters();
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                _buildDropdownOption(
                                  icon: Icons.check_circle,
                                  label: 'Approved',
                                  value: 'approved',
                                  isSelected: _selectedStatus == 'approved',
                                  onTap: () {
                                    setState(() {
                                      _selectedStatus = 'approved';
                                      _isStatusDropdownExpanded = false;
                                    });
                                    _applyFilters();
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                _buildDropdownOption(
                                  icon: Icons.cancel,
                                  label: 'Rejected',
                                  value: 'rejected',
                                  isSelected: _selectedStatus == 'rejected',
                                  onTap: () {
                                    setState(() {
                                      _selectedStatus = 'rejected';
                                      _isStatusDropdownExpanded = false;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Type Filter
                        Text(
                          'Request Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isTypeDropdownExpanded =
                                  !_isTypeDropdownExpanded;
                              _isStatusDropdownExpanded = false;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedType?.toUpperCase() ?? 'ALL TYPES',
                                    style: TextStyle(
                                      color: _selectedType != null
                                          ? const Color(0xFF2C3E50)
                                          : Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _isTypeDropdownExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isTypeDropdownExpanded) ...[
                          const SizedBox(height: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildDropdownOption(
                                  icon: Icons.all_inclusive,
                                  label: 'All Types',
                                  value: null,
                                  isSelected: _selectedType == null,
                                  onTap: () {
                                    setState(() {
                                      _selectedType = null;
                                      _isTypeDropdownExpanded = false;
                                    });
                                    _applyFilters();
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                _buildDropdownOption(
                                  icon: Icons.inventory,
                                  label: 'Supply',
                                  value: 'supply',
                                  isSelected: _selectedType == 'supply',
                                  onTap: () {
                                    setState(() {
                                      _selectedType = 'supply';
                                      _isTypeDropdownExpanded = false;
                                    });
                                    _applyFilters();
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                _buildDropdownOption(
                                  icon: Icons.build,
                                  label: 'Equipment',
                                  value: 'equipment',
                                  isSelected: _selectedType == 'equipment',
                                  onTap: () {
                                    setState(() {
                                      _selectedType = 'equipment';
                                      _isTypeDropdownExpanded = false;
                                    });
                                    _applyFilters();
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                _buildDropdownOption(
                                  icon: Icons.credit_card,
                                  label: 'Cash Advance',
                                  value: 'cash_advance',
                                  isSelected: _selectedType == 'cash_advance',
                                  onTap: () {
                                    setState(() {
                                      _selectedType = 'cash_advance';
                                      _isTypeDropdownExpanded = false;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _clearFilters,
                              child: Text(
                                'Clear All',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _toggleFilterCard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    // Get request type icon and color
    IconData typeIcon;
    Color typeColor;

    switch (request.type?.toLowerCase()) {
      case 'equipment':
        typeIcon = Icons.build;
        typeColor = const Color(0xFFEF4444);
        break;
      case 'supply':
        typeIcon = Icons.inventory;
        typeColor = const Color(0xFF10B981);
        break;
      case 'cash_advance':
        typeIcon = Icons.credit_card;
        typeColor = const Color(0xFFF59E0B);
        break;
      default:
        typeIcon = Icons.request_page;
        typeColor = const Color(0xFF6366F1);
    }

    // Get status color
    Color statusColor;
    switch (request.status?.toLowerCase()) {
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'approved':
        statusColor = const Color(0xFF10B981);
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = Colors.grey[600]!;
    }

    return GestureDetector(
      onTap: () {
        final farmWorker = _farmWorkersMap[request.farmWorkerId];
        if (farmWorker != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FarmWorkerDetailScreen(
                farmWorker: farmWorker,
                token: widget.token,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
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
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getRequestTypeDisplayName(request.type ?? ''),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Request No. ${request.id} • ${_getFarmerName(request.farmWorkerId)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status?.toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                request.reason!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatRequestDate(request.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                if (request.type?.toLowerCase() == 'equipment' &&
                    request.equipmentName != null)
                  Text(
                    request.equipmentName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (request.type?.toLowerCase() == 'supply' &&
                    request.supplyName != null)
                  Text(
                    request.supplyName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (request.type?.toLowerCase() == 'cash_advance' &&
                    request.amount != null)
                  Text(
                    '₱${request.amount!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRequestTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'equipment':
        return 'Equipment Request';
      case 'supply':
        return 'Supply Request';
      case 'cash_advance':
        return 'Cash Advance Request';
      default:
        return 'Request';
    }
  }

  String _formatRequestDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
