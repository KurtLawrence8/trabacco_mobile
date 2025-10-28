import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';

// ADD CONSTANTS FOR COLORS AT THE TOP
const Color K_TODAY_HIGHLIGHT = Color(0xFFFFF9C4); // LIGHT YELLOW
const Color K_UPCOMING_DISABLED = Color(0xFFEEEEEE); // LIGHT GREY
const Color K_DISABLED_TEXT = Color(0xFF9E9E9E);

class SchedulePage extends StatefulWidget {
  final String userType; // 'Technician' or 'Farmer'
  final String token;
  final int farmWorkerId;
  final String farmWorkerName;
  const SchedulePage(
      {Key? key,
      required this.userType,
      required this.token,
      required this.farmWorkerId,
      required this.farmWorkerName})
      : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late Future<List<Schedule>> _futureSchedules;
  final ScheduleService _service = ScheduleService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final DateFormat _dateFormatter = DateFormat('MM/dd/yyyy');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    print('[SchedulePage] [initState] Initializing SchedulePage');
    print('[SchedulePage] [initState] User type: ${widget.userType}');
    print('[SchedulePage] [initState] Farmer ID: ${widget.farmWorkerId}');
    print('[SchedulePage] [initState] Farmer name: ${widget.farmWorkerName}');
    print('[SchedulePage] [initState] Token: ${widget.token}');

    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _searchController.addListener(_onSearchChanged);

    if (widget.farmWorkerId != 0) {
      print(
          '[SchedulePage] [initState] Fetching schedules for Farmer ID: ${widget.farmWorkerId}');
      _futureSchedules = _service.fetchSchedulesForFarmWorker(
          widget.farmWorkerId, widget.token);
    } else {
      print(
          '[SchedulePage] [initState] No Farmer ID provided, skipping schedule fetch');
    }
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
    });

    // Navigate to search result if there's a query
    if (_searchQuery.isNotEmpty) {
      _futureSchedules.then((schedules) {
        final filtered = _filterSchedules(schedules);
        if (filtered.isNotEmpty) {
          _navigateToSearchResult(filtered);
        }
      });
    }
  }

  List<Schedule> _filterSchedules(List<Schedule> schedules) {
    if (_searchQuery.isEmpty) return schedules;
    return schedules.where((schedule) {
      return schedule.activity.toLowerCase().contains(_searchQuery) ||
          (schedule.remarks?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  void _navigateToSearchResult(List<Schedule> schedules) {
    if (_searchQuery.isNotEmpty && schedules.isNotEmpty) {
      final firstMatch = schedules.first;
      if (firstMatch.date != null) {
        setState(() {
          _selectedDay = firstMatch.date!;
          _focusedDay = firstMatch.date!;
        });
      }
    }
  }

  void _updateStatus(Schedule schedule, String status) async {
    print(
        '[SchedulePage] [_updateStatus] Updating schedule ID: ${schedule.id} to status: $status');

    try {
      await _service.updateScheduleStatus(schedule.id, status, widget.token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );
      setState(() {
        print(
            '[SchedulePage] [_updateStatus] Refreshing schedules after status update');
        _futureSchedules = _service.fetchSchedulesForFarmWorker(
            widget.farmWorkerId, widget.token);
      });
    } catch (e) {
      print('[SchedulePage] [_updateStatus] ERROR updating status: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

<<<<<<< HEAD
=======

>>>>>>> d8d2949 (fixed merge conflict)
  // Helper functions to get unit and budget from laborers array
  String? _getScheduleUnit(Schedule schedule) {
    if (schedule.laborers != null && schedule.laborers!.isNotEmpty) {
      final laborer = schedule.laborers![0];
      if (laborer is Map<String, dynamic>) {
        return laborer['unit'] as String?;
      }
    }
    return null;
  }

  double? _getScheduleBudget(Schedule schedule) {
    if (schedule.laborers != null && schedule.laborers!.isNotEmpty) {
      final laborer = schedule.laborers![0];
      if (laborer is Map<String, dynamic>) {
        return (laborer['budget'] as num?)?.toDouble();
      }
    }
    return null;
  }

  // Helper function to get laborer names from laborers array
  String _getLaborerNames(Schedule schedule) {
    if (schedule.laborers != null && schedule.laborers!.isNotEmpty) {
      List<String> names = [];
      for (var laborer in schedule.laborers!) {
        if (laborer is Map<String, dynamic>) {
          final laborerData = laborer['laborer'];
          if (laborerData is Map<String, dynamic>) {
            final firstName = laborerData['first_name']?.toString() ?? '';
            final lastName = laborerData['last_name']?.toString() ?? '';
            if (firstName.isNotEmpty || lastName.isNotEmpty) {
              names.add('${firstName.trim()} ${lastName.trim()}'.trim());
            }
          }
        }
      }
      return names.join(', ');
    }
    return '';
  }

  // Helper function to get laborer names as a list
  List<String> _getLaborerNamesList(Schedule schedule) {
    if (schedule.laborers != null && schedule.laborers!.isNotEmpty) {
      List<String> names = [];
      for (var laborer in schedule.laborers!) {
        if (laborer is Map<String, dynamic>) {
          final laborerData = laborer['laborer'];
          if (laborerData is Map<String, dynamic>) {
            final firstName = laborerData['first_name']?.toString() ?? '';
            final lastName = laborerData['last_name']?.toString() ?? '';
            if (firstName.isNotEmpty || lastName.isNotEmpty) {
              names.add('${firstName.trim()} ${lastName.trim()}'.trim());
            }
          }
        }
      }
      return names;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    try {
      // GET TODAY'S DATE
      final todayDate = DateTime.now();
      print('[SchedulePage] [build] Building SchedulePage UI');
      print('[SchedulePage] [build] Farmer ID: ${widget.farmWorkerId}');
      print('[SchedulePage] [build] Today\'s date: $todayDate');

      return GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            child: widget.farmWorkerId == 0
                ? _buildEmptyState('Please select a Farmer to view schedules')
                : FutureBuilder<List<Schedule>>(
                    future: _futureSchedules,
                    builder: (context, snapshot) {
                      print(
                          '[SchedulePage] [build] FutureBuilder state: ${snapshot.connectionState}');
                      print(
                          '[SchedulePage] [build] FutureBuilder has error: ${snapshot.hasError}');
                      if (snapshot.hasError) {
                        print(
                            '[SchedulePage] [build] FutureBuilder error: ${snapshot.error}');
                        print(
                            '[SchedulePage] [build] FutureBuilder error stack trace: ${snapshot.stackTrace}');
                      }
                      print(
                          '[SchedulePage] [build] FutureBuilder has data: ${snapshot.hasData}');

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        print(
                            '[SchedulePage] [build] Showing loading indicator');
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF4CAF50),
                                  strokeWidth: 3,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading schedules...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF2C3E50),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        print(
                            '[SchedulePage] [build] Showing error: ${snapshot.error}');
                        print(
                            '[SchedulePage] [build] Error type: ${snapshot.error.runtimeType}');
                        print(
                            '[SchedulePage] [build] Error stack trace: ${snapshot.stackTrace}');

                        // Display detailed error information
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 64, color: Colors.red),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Error Loading Schedules',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Error Type: ${snapshot.error.runtimeType}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.red.shade700),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Error Details: ${snapshot.error}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        // This will trigger a rebuild and retry
                                      });
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final schedules = snapshot.data ?? [];
                      print(
                          '[SchedulePage] [build] Received ${schedules.length} schedules');

                      // Filter out schedules with invalid data
                      final validSchedules = schedules
                          .where((s) => s.activity.isNotEmpty && s.date != null)
                          .toList();
                      print(
                          '[SchedulePage] [build] Valid schedules: ${validSchedules.length}');

                      // Show empty state if no valid schedules - NO CALENDAR
                      if (validSchedules.isEmpty) {
                        print(
                            '[SchedulePage] [build] No valid schedules, showing empty state');
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: _buildEmptyState('No schedule yet assigned'),
                        );
                      }

                      if (validSchedules.isNotEmpty) {
                        print(
                            '[SchedulePage] [build] First valid schedule: ${validSchedules.first}');
                        print(
                            '[SchedulePage] [build] First valid schedule ID: ${validSchedules.first.id} (type: ${validSchedules.first.id.runtimeType})');
                        print(
                            '[SchedulePage] [build] First valid schedule Farmer ID: ${validSchedules.first.farmWorkerId} (type: ${validSchedules.first.farmWorkerId.runtimeType})');
                      }

                      // Group valid schedules by their calendar date
                      final Map<DateTime, List<Schedule>> dateToSchedules = {};
                      try {
                        for (final s in validSchedules) {
                          print(
                              '[SchedulePage] [build] Processing schedule ID: ${s.id} (type: ${s.id.runtimeType})');
                          if (s.date == null) {
                            print(
                                '[SchedulePage] [build] Skipping schedule with null date: ${s.id}');
                            continue;
                          }
                          final key = DateTime(
                              s.date!.year, s.date!.month, s.date!.day);
                          dateToSchedules.putIfAbsent(key, () => []);
                          dateToSchedules[key]!.add(s);
                        }

                        print(
                            '[SchedulePage] [build] Grouped schedules into ${dateToSchedules.length} dates');

                        // Double check: if no dates have schedules, show empty state
                        if (dateToSchedules.isEmpty) {
                          print(
                              '[SchedulePage] [build] No grouped schedules, showing empty state');
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: _buildEmptyState('No schedule yet assigned'),
                          );
                        }
                      } catch (e) {
                        print(
                            '[SchedulePage] [build] ERROR grouping schedules: $e');
                        print(
                            '[SchedulePage] [build] Error type: ${e.runtimeType}');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              const Text(
                                'Error Processing Schedules',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('Error Type: ${e.runtimeType}',
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 8),
                              Text('Error Details: $e',
                                  style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        );
                      }

                      final selectedKey = _selectedDay != null
                          ? DateTime(_selectedDay!.year, _selectedDay!.month,
                              _selectedDay!.day)
                          : DateTime(
                              todayDate.year, todayDate.month, todayDate.day);
                      final selectedSchedules =
                          dateToSchedules[selectedKey] ?? [];

                      print(
                          '[SchedulePage] [build] Selected date: $selectedKey');
                      print(
                          '[SchedulePage] [build] Schedules for selected date: ${selectedSchedules.length}');

                      return Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            // Search Bar
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search schedules...',
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey.shade600),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear,
                                              color: Colors.grey.shade600),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                              ),
                            ),
                            // Calendar with padding and container
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: TableCalendar<Schedule>(
                                    firstDay: DateTime.utc(2000, 1, 1),
                                    lastDay: DateTime.utc(2100, 12, 31),
                                    focusedDay: _focusedDay,
                                    selectedDayPredicate: (day) =>
                                        isSameDay(_selectedDay, day),
                                    calendarFormat: _calendarFormat,
                                    startingDayOfWeek: StartingDayOfWeek.monday,
                                    eventLoader: (day) {
                                      final key = DateTime(
                                          day.year, day.month, day.day);
                                      final events = dateToSchedules[key] ?? [];
                                      if (events.isNotEmpty) {
                                        print(
                                            '[SchedulePage] [build] Calendar event loader: ${events.length} events for $key');
                                      }
                                      return events;
                                    },
                                    onDaySelected: (selectedDay, focusedDay) {
                                      print(
                                          '[SchedulePage] [build] Day selected: $selectedDay');
                                      setState(() {
                                        _selectedDay = selectedDay;
                                        _focusedDay = focusedDay;
                                      });
                                    },
                                    onPageChanged: (focusedDay) {
                                      print(
                                          '[SchedulePage] [build] Calendar page changed to: $focusedDay');
                                      _focusedDay = focusedDay;
                                    },
                                    onFormatChanged: (format) {
                                      print(
                                          '[SchedulePage] [build] Calendar format changed to: $format');
                                      setState(() {
                                        _calendarFormat = format;
                                      });
                                    },
                                    headerStyle: HeaderStyle(
                                      formatButtonVisible: true,
                                      titleCentered: true,
                                      formatButtonShowsNext: false,
                                      formatButtonDecoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      formatButtonTextStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12, // Reduced from 14
                                        fontWeight: FontWeight.w600,
                                      ),
                                      titleTextStyle: const TextStyle(
                                        fontSize: 16, // Reduced from 20
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                      leftChevronIcon: const Icon(
                                        Icons.chevron_left,
                                        color: Color(0xFF4CAF50),
                                        size: 24, // Reduced from 28
                                      ),
                                      rightChevronIcon: const Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF4CAF50),
                                        size: 24, // Reduced from 28
                                      ),
                                    ),
                                    calendarStyle: CalendarStyle(
                                      // Today styling
                                      todayDecoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50)
                                            .withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      todayTextStyle: const TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      // Selected day styling
                                      selectedDecoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                      selectedTextStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      // Marker styling (for events)
                                      markersMaxCount: 3,
                                      markerDecoration: const BoxDecoration(
                                        color: Color(0xFF2196F3),
                                        shape: BoxShape.circle,
                                      ),
                                      markerMargin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      // Weekend styling
                                      weekendTextStyle: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                      // Outside month styling
                                      outsideTextStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    calendarBuilders: CalendarBuilders(
                                      // Custom marker builder for better event display
                                      markerBuilder: (context, day, events) {
                                        if (events.isNotEmpty) {
                                          return Positioned(
                                            bottom: 2,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children:
                                                  events.take(3).map((event) {
                                                final schedule = event;
                                                Color markerColor;
                                                switch (schedule.status
                                                    .toLowerCase()) {
                                                  case 'completed':
                                                    markerColor =
                                                        const Color(0xFF4CAF50);
                                                    break;
                                                  case 'cancelled':
                                                    markerColor =
                                                        const Color(0xFFF44336);
                                                    break;
                                                  case 'in_progress':
                                                    markerColor =
                                                        const Color(0xFF2196F3);
                                                    break;
                                                  default:
                                                    markerColor =
                                                        const Color(0xFFFF9800);
                                                }
                                                return Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(horizontal: 1),
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: markerColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          );
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Selected Date Container
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Date header
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_month_rounded,
                                            size: 16, // Reduced from 18
                                            color: Colors.grey.shade600),
                                        const SizedBox(
                                            width: 6), // Reduced spacing
                                        Text(
                                          'Selected Date',
                                          style: TextStyle(
                                            fontSize: 12, // Reduced from 14
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _selectedDay != null
                                              ? _dateFormatter.format(
                                                  _selectedDay!.toLocal())
                                              : _dateFormatter
                                                  .format(todayDate.toLocal()),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12, // Reduced from 14
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Status legend
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _buildLegendItem(
                                            'Pending', const Color(0xFFFF9800)),
                                        _buildLegendItem('In Progress',
                                            const Color(0xFF2196F3)),
                                        _buildLegendItem('Completed',
                                            const Color(0xFF4CAF50)),
                                        _buildLegendItem('Cancelled',
                                            const Color(0xFFF44336)),
                                        _buildLegendItem(
                                            'Future', const Color(0xFF9C27B0)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Activity section header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Text(
                                    selectedSchedules.length == 1
                                        ? 'Activity'
                                        : 'Activities',
                                    style: const TextStyle(
                                      fontSize: 16, // Reduced from 20
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            selectedSchedules.isEmpty
                                ? _buildEmptyState('No activities for this day')
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: selectedSchedules.length,
                                    itemBuilder: (context, index) {
                                      try {
                                        final s = selectedSchedules[index];
                                        print(
                                            '[SchedulePage] [build] Building schedule card for index $index: ${s.id}');
                                        return _buildScheduleCard(
                                          s,
                                          todayDate,
                                          (status) => _updateStatus(s, status),
                                        );
                                      } catch (e) {
                                        print(
                                            '[SchedulePage] [build] ERROR building schedule card at index $index: $e');
                                        return Card(
                                          color: Colors.red.shade50,
                                          child: ListTile(
                                            title: Text(
                                              'Error displaying schedule',
                                              style: TextStyle(
                                                  color: Colors.red.shade700),
                                            ),
                                            subtitle: Text(
                                              'Error: $e',
                                              style: TextStyle(
                                                  color: Colors.red.shade600),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('[SchedulePage] [build] EXCEPTION during build: $e');
      print('[SchedulePage] [build] Stack trace: $stackTrace');
      return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'An error occurred while building the schedule page',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // This will trigger a rebuild
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // HELPER METHOD TO BUILD A SCHEDULE CARD FOR EACH ACTIVITY
  Widget _buildScheduleCard(
      Schedule s, DateTime todayDate, void Function(String)? onStatusChange) {
    print(
        '[SchedulePage] [_buildScheduleCard] Building card for schedule ID: ${s.id}');

    // DETERMINE IF THIS SCHEDULE IS FOR TODAY
    final isToday = s.date != null &&
        s.date!.year == todayDate.year &&
        s.date!.month == todayDate.month &&
        s.date!.day == todayDate.day;
    final isPast = s.date != null && s.date!.isBefore(todayDate) && !isToday;
    final isFuture = s.date != null && s.date!.isAfter(todayDate);
    final actionsEnabled = widget.userType == 'Technician';

    // SET COLORS BASED ON STATUS
    final isCompleted = s.status.toLowerCase() == 'completed';
    final isCancelled = s.status.toLowerCase() == 'cancelled';

    // CANNOT COMPLETE FUTURE SCHEDULES - only allow completion for today or past dates
    final canComplete =
        actionsEnabled && !isCompleted && !isCancelled && !isFuture;

    // START CARD DESIGN
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              // Header with activity and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.activity,
                      style: TextStyle(
                        fontSize: 14, // Further reduced from 16
                        fontWeight: FontWeight.bold,
                        color: isPast
                            ? Colors.grey.shade600
                            : const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  _buildStatusChip(s.status, isToday, isPast, isFuture),
                ],
              ),
              const SizedBox(height: 12),

              // Date and details
              Row(
                children: [
                  Text(
                    'DATE: ',
                    style: TextStyle(
                      fontSize: 12, // Reduced from 14
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    s.date != null ? _dateFormatter.format(s.date!) : 'No date',
                    style: const TextStyle(
                      fontSize: 14, // Reduced from 16
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              if (s.remarks != null && s.remarks!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REMARKS: ',
                      style: TextStyle(
                        fontSize: 12, // Reduced from 14
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.remarks!,
                        style: const TextStyle(
                          fontSize: 13, // Reduced from 15
                          color: Color(0xFF34495E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Additional details row
              if (s.laborerId != null ||
                  _getScheduleUnit(s) != null ||
                  _getScheduleBudget(s) != null ||
                  _getLaborerNames(s).isNotEmpty) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Laborers display
                    if (_getLaborerNames(s).isNotEmpty) ...[
                      Text(
                        'Laborers:',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._getLaborerNamesList(s).map((name) => Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 2),
                            child: Text(
                              '• $name',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2C3E50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )),
                      const SizedBox(height: 8),
                    ],
                    // Unit row
                    if (_getScheduleUnit(s) != null) ...[
                      Row(
                        children: [
                          Text(
                            'Unit: ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2C3E50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getScheduleUnit(s)!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2C3E50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Budget row
                    if (_getScheduleBudget(s) != null) ...[
                      Row(
                        children: [
                          Text(
                            'Budget: ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2C3E50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₱${_getScheduleBudget(s)!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2C3E50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Legacy laborer assigned display (fallback)
                    if (s.laborerId != null && _getLaborerNames(s).isEmpty) ...[
                      Text(
                        'Laborer assigned',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Action buttons for technicians
              if (actionsEnabled && !isCompleted && !isCancelled) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 16),

                // Show different UI based on whether it's a future schedule
                if (isFuture) ...[
                  // Future schedule - show info message instead of buttons
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This schedule is for a future date. You can only complete it on or after ${s.date != null ? _dateFormatter.format(s.date!) : "the scheduled date"}.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Today or past schedule - show action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: canComplete
                              ? () => _showConfirmationDialog(
<<<<<<< HEAD
                                    context,
                                    'Complete Task',
                                    'Are you sure you want to complete "${s.activity}"?',
                                    'Complete',
                                    const Color(0xFF4CAF50),
                                    () => onStatusChange?.call('Completed'),
                                  )
=======
                                context,
                                'Complete Task',
                                'Are you sure you want to complete "${s.activity}"?',
                                'Complete',
                                const Color(0xFF4CAF50),
                                () => onStatusChange?.call('Completed'),
                              )
>>>>>>> d8d2949 (fixed merge conflict)
                              : null,
                          icon: const Icon(Icons.check_circle, size: 20),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canComplete
                                ? const Color(0xFF4CAF50)
                                : Colors.grey.shade300,
                            foregroundColor: canComplete
                                ? Colors.white
                                : Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: canComplete ? 2 : 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showConfirmationDialog(
                            context,
                            'Cancel Task',
                            'Are you sure you want to cancel "${s.activity}"?',
                            'Cancel Task',
                            const Color(0xFFE74C3C),
                            () => onStatusChange?.call('Cancelled'),
                          ),
                          icon: const Icon(Icons.cancel, size: 20),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE74C3C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
<<<<<<< HEAD
=======

>>>>>>> d8d2949 (fixed merge conflict)
            ],
          ),
        ),
      ),
    );
    // END CARD DESIGN
  }

  Widget _buildStatusChip(
      String status, bool isToday, bool isPast, bool isFuture) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    // For future schedules, show a different color to indicate they can't be completed yet
    if (isFuture &&
        (status.toLowerCase() == 'pending' ||
            status.toLowerCase() == 'scheduled')) {
      backgroundColor = const Color(0xFF9C27B0); // Purple for future schedules
      textColor = Colors.white;
      icon = Icons.schedule;
    } else {
      switch (status.toLowerCase()) {
        case 'completed':
          backgroundColor = const Color(0xFF4CAF50);
          textColor = Colors.white;
          icon = Icons.check_circle;
          break;
        case 'cancelled':
          backgroundColor = const Color(0xFFE74C3C);
          textColor = Colors.white;
          icon = Icons.cancel;
          break;
        case 'in_progress':
        case 'in progress':
          backgroundColor = const Color(0xFF2196F3);
          textColor = Colors.white;
          icon = Icons.play_circle;
          break;
        case 'pending':
        case 'scheduled':
          backgroundColor = const Color(0xFFFF9800);
          textColor = Colors.white;
          icon = Icons.schedule;
          break;
        default:
          backgroundColor = Colors.grey.shade400;
          textColor = Colors.white;
          icon = Icons.help;
      }
    }

    if (isPast) {
      backgroundColor = backgroundColor.withOpacity(0.6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4), // Reduced padding
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16), // Reduced border radius
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor), // Reduced icon size
          const SizedBox(width: 3), // Reduced spacing
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10, // Reduced font size
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.3, // Reduced letter spacing
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    String confirmButtonText,
    Color confirmColor,
    VoidCallback onConfirm,
  ) {
    // Dismiss keyboard before showing dialog
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            // Dismiss keyboard when dialog is dismissed
            FocusScope.of(context).unfocus();
            // Add a small delay to ensure keyboard is fully dismissed
            await Future.delayed(const Duration(milliseconds: 100));
            return true;
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  confirmButtonText == 'Complete'
                      ? Icons.check_circle
                      : Icons.warning,
                  color: confirmColor,
                  size: 24, // Reduced size
                ),
                const SizedBox(width: 12),
                Expanded(
                  // Added to prevent overflow
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18, // Reduced from 20
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 14), // Reduced from 16
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Dismiss keyboard when canceling
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                  // Add a small delay to ensure keyboard is fully dismissed
                  await Future.delayed(const Duration(milliseconds: 100));
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14, // Reduced from 16
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Dismiss keyboard when confirming
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                  // Add a small delay to ensure keyboard is fully dismissed
                  await Future.delayed(const Duration(milliseconds: 100));
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10), // Reduced padding
                ),
                child: Text(
                  confirmButtonText,
                  style: const TextStyle(
                    fontSize: 14, // Reduced from 16
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Additional keyboard dismissal when dialog is closed
      FocusScope.of(context).unfocus();
    });
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, // Reduced size
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4), // Reduced spacing
        Text(
          label,
          style: TextStyle(
            fontSize: 10, // Reduced font size
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500, // Reduced weight
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message == 'No activities for this day'
                ? 'No activities for this day'
                : 'No schedule yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (message != 'No activities for this day') ...[
            const SizedBox(height: 8),
            Text(
              'Schedules will appear here when assigned',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
