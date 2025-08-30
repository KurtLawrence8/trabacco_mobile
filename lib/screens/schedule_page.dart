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

  @override
  void initState() {
    super.initState();
    print('[SchedulePage] [initState] Initializing SchedulePage');
    print('[SchedulePage] [initState] User type: ${widget.userType}');
    print('[SchedulePage] [initState] Farm worker ID: ${widget.farmWorkerId}');
    print(
        '[SchedulePage] [initState] Farm worker name: ${widget.farmWorkerName}');
    print('[SchedulePage] [initState] Token: ${widget.token}');

    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;

    if (widget.farmWorkerId != 0) {
      print(
          '[SchedulePage] [initState] Fetching schedules for farm worker ID: ${widget.farmWorkerId}');
      _futureSchedules = _service.fetchSchedulesForFarmWorker(
          widget.farmWorkerId, widget.token);
    } else {
      print(
          '[SchedulePage] [initState] No farm worker ID provided, skipping schedule fetch');
    }
  }

  void _updateStatus(Schedule schedule, String status) async {
    print(
        '[SchedulePage] [_updateStatus] Updating schedule ID: ${schedule.displayId} to status: $status');

    // Don't allow status updates for template schedules
    if (schedule.isTemplate) {
      print(
          '[SchedulePage] [_updateStatus] Cannot update template schedule status');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot update template schedule status')),
      );
      return;
    }

    try {
      await _service.updateScheduleStatus(schedule.id!, status, widget.token);
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

  @override
  Widget build(BuildContext context) {
    try {
      // GET TODAY'S DATE
      final todayDate = DateTime.now();
      print('[SchedulePage] [build] Building SchedulePage UI');
      print('[SchedulePage] [build] Farm worker ID: ${widget.farmWorkerId}');
      print('[SchedulePage] [build] Today\'s date: $todayDate');

      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.farmWorkerName} Schedule'),
        ),
        body: widget.farmWorkerId == 0
            ? const Center(
                child: Text('PLEASE SELECT A FARM WORKER TO VIEW SCHEDULES.'))
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
                    print('[SchedulePage] [build] Showing loading indicator');
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print(
                        '[SchedulePage] [build] Showing error: ${snapshot.error}');
                    print(
                        '[SchedulePage] [build] Error type: ${snapshot.error.runtimeType}');
                    print(
                        '[SchedulePage] [build] Error stack trace: ${snapshot.stackTrace}');

                    // Display detailed error information
                    return Center(
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
                                  fontSize: 16, color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error Details: ${snapshot.error}',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.red.shade600),
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
                    );
                  }

                  final schedules = snapshot.data ?? [];
                  print(
                      '[SchedulePage] [build] Received ${schedules.length} schedules');

                  if (schedules.isNotEmpty) {
                    print(
                        '[SchedulePage] [build] First schedule: ${schedules.first}');
                    print(
                        '[SchedulePage] [build] First schedule ID: ${schedules.first.displayId} (type: ${schedules.first.id?.runtimeType})');
                    print(
                        '[SchedulePage] [build] First schedule farm worker ID: ${schedules.first.farmWorkerId} (type: ${schedules.first.farmWorkerId.runtimeType})');
                  }

                  // Group schedules by their calendar date
                  final Map<DateTime, List<Schedule>> dateToSchedules = {};
                  try {
                    for (final s in schedules) {
                      print(
                          '[SchedulePage] [build] Processing schedule ID: ${s.displayId} (type: ${s.id?.runtimeType})');
                      if (s.date == null) {
                        print(
                            '[SchedulePage] [build] Skipping schedule with null date: ${s.displayId}');
                        continue;
                      }
                      final key =
                          DateTime(s.date!.year, s.date!.month, s.date!.day);
                      dateToSchedules.putIfAbsent(key, () => []);
                      dateToSchedules[key]!.add(s);
                    }

                    print(
                        '[SchedulePage] [build] Grouped schedules into ${dateToSchedules.length} dates');
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
                  final selectedSchedules = dateToSchedules[selectedKey] ?? [];

                  print('[SchedulePage] [build] Selected date: $selectedKey');
                  print(
                      '[SchedulePage] [build] Schedules for selected date: ${selectedSchedules.length}');

                  return Column(
                    children: [
                      TableCalendar<Schedule>(
                        firstDay: DateTime.utc(2000, 1, 1),
                        lastDay: DateTime.utc(2100, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        calendarFormat: _calendarFormat,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        eventLoader: (day) {
                          final key = DateTime(day.year, day.month, day.day);
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
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                        ),
                        calendarStyle: const CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Color(0xFFBBDEFB),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Color(0xFF27AE60),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: Color(0xFF2E5BFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 10, color: Color(0xFF2E5BFF)),
                            const SizedBox(width: 6),
                            const Text('Has activities'),
                            const Spacer(),
                            Text(
                              _selectedDay != null
                                  ? _dateFormatter
                                      .format(_selectedDay!.toLocal())
                                  : _dateFormatter.format(todayDate.toLocal()),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: selectedSchedules.isEmpty
                            ? const Center(
                                child: Text('No activities for this day.'))
                            : ListView.builder(
                                itemCount: selectedSchedules.length,
                                itemBuilder: (context, index) {
                                  try {
                                    final s = selectedSchedules[index];
                                    print(
                                        '[SchedulePage] [build] Building schedule card for index $index: ${s.displayId}');
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
                      ),
                    ],
                  );
                },
              ),
      );
    } catch (e, stackTrace) {
      print('[SchedulePage] [build] EXCEPTION during build: $e');
      print('[SchedulePage] [build] Stack trace: $stackTrace');
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.farmWorkerName} Schedule'),
        ),
        body: Center(
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
      );
    }
  }

  // HELPER METHOD TO BUILD A SCHEDULE CARD FOR EACH ACTIVITY
  Widget _buildScheduleCard(
      Schedule s, DateTime todayDate, void Function(String)? onStatusChange) {
    print(
        '[SchedulePage] [_buildScheduleCard] Building card for schedule ID: ${s.displayId}');
    print('[SchedulePage] [_buildScheduleCard] Schedule date: ${s.date}');
    print(
        '[SchedulePage] [_buildScheduleCard] Schedule activity: ${s.activity}');
    print('[SchedulePage] [_buildScheduleCard] Schedule status: ${s.status}');

    // DETERMINE IF THIS SCHEDULE IS FOR TODAY
    final isToday = s.date != null &&
        s.date!.year == todayDate.year &&
        s.date!.month == todayDate.month &&
        s.date!.day == todayDate.day;
    // DETERMINE IF THIS SCHEDULE IS UPCOMING
    final isUpcoming = s.date != null && s.date!.isAfter(todayDate);
    final actionsEnabled = widget.userType == 'Technician';

    print('[SchedulePage] [_buildScheduleCard] Is today: $isToday');
    print('[SchedulePage] [_buildScheduleCard] Is upcoming: $isUpcoming');
    print(
        '[SchedulePage] [_buildScheduleCard] Actions enabled: $actionsEnabled');

    // SET COLORS BASED ON STATUS
    final isCompleted = s.status.toLowerCase() == 'completed';
    final isCancelled = s.status.toLowerCase() == 'cancelled';
    final cardColor = isToday
        ? K_TODAY_HIGHLIGHT
        : isUpcoming
            ? K_UPCOMING_DISABLED
            : null;
    final textColor =
        isUpcoming && !actionsEnabled || isCompleted || isCancelled
            ? K_DISABLED_TEXT
            : Colors.black;
    final iconCheckColor = actionsEnabled && !isCompleted && !isCancelled
        ? Colors.green
        : K_DISABLED_TEXT;
    final iconCancelColor = actionsEnabled && !isCompleted && !isCancelled
        ? Colors.red
        : K_DISABLED_TEXT;

    // RETURN THE CARD WIDGET
    return Card(
      color: cardColor,
      child: ListTile(
        title: Text(
          s.activity,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s.date != null)
              Text('DATE:  [${_dateFormatter.format(s.date!.toLocal())}',
                  style: TextStyle(color: textColor)),
            if (s.remarks != null && s.remarks!.isNotEmpty)
              Text('REMARKS:  [${s.remarks}',
                  style: TextStyle(color: textColor)),
            if (s.numLaborers != null)
              Text('LABORERS:  [${s.numLaborers}',
                  style: TextStyle(color: textColor)),
            if (s.unit != null && s.unit!.isNotEmpty)
              Text('UNIT:  [${s.unit}', style: TextStyle(color: textColor)),
            if (s.budget != null)
              Text('BUDGET:  [${s.budget}', style: TextStyle(color: textColor)),
            const SizedBox(height: 6),
            Row(
              children: [
                if (s.status.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFE8F5E9)
                          : isCancelled
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? const Color(0xFF2E7D32)
                            : isCancelled
                                ? const Color(0xFFC62828)
                                : const Color(0xFF1565C0),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: widget.userType == 'Technician'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: iconCheckColor),
                    onPressed: actionsEnabled && !isCompleted && !isCancelled
                        ? () => onStatusChange?.call('Completed')
                        : null,
                    tooltip: 'MARK AS FINISHED',
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel, color: iconCancelColor),
                    onPressed: actionsEnabled && !isCompleted && !isCancelled
                        ? () => onStatusChange?.call('Cancelled')
                        : null,
                    tooltip: 'CANCEL',
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
