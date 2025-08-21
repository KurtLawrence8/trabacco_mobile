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
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    if (widget.farmWorkerId != 0) {
      _futureSchedules = _service.fetchSchedulesForFarmWorker(
          widget.farmWorkerId, widget.token);
    }
  }

  void _updateStatus(Schedule schedule, String status) async {
    try {
      await _service.updateScheduleStatus(schedule.id, status, widget.token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );
      setState(() {
        _futureSchedules = _service.fetchSchedulesForFarmWorker(
            widget.farmWorkerId, widget.token);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // GET TODAY'S DATE
    final todayDate = DateTime.now();
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('ERROR:  [${snapshot.error}'));
                }
                final schedules = snapshot.data ?? [];

                // Group schedules by their calendar date
                final Map<DateTime, List<Schedule>> dateToSchedules = {};
                for (final s in schedules) {
                  if (s.date == null) continue;
                  final key = DateTime(s.date!.year, s.date!.month, s.date!.day);
                  dateToSchedules.putIfAbsent(key, () => []); 
                  dateToSchedules[key]!.add(s);
                }

                final selectedKey = _selectedDay != null
                    ? DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
                    : DateTime(todayDate.year, todayDate.month, todayDate.day);
                final selectedSchedules = dateToSchedules[selectedKey] ?? [];

                return Column(
                  children: [
                    TableCalendar<Schedule>(
                      firstDay: DateTime.utc(2000, 1, 1),
                      lastDay: DateTime.utc(2100, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      eventLoader: (day) {
                        final key = DateTime(day.year, day.month, day.day);
                        return dateToSchedules[key] ?? const [];
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      onFormatChanged: (format) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 10, color: Color(0xFF2E5BFF)),
                          const SizedBox(width: 6),
                          const Text('Has activities'),
                          const Spacer(),
                          Text(
                            _selectedDay != null
                                ? _dateFormatter.format(_selectedDay!.toLocal())
                                : _dateFormatter.format(todayDate.toLocal()),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: selectedSchedules.isEmpty
                          ? const Center(child: Text('No activities for this day.'))
                          : ListView.builder(
                              itemCount: selectedSchedules.length,
                              itemBuilder: (context, index) {
                                final s = selectedSchedules[index];
                                return _buildScheduleCard(
                                  s,
                                  todayDate,
                                  (status) => _updateStatus(s, status),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // HELPER METHOD TO BUILD A SCHEDULE CARD FOR EACH ACTIVITY
  Widget _buildScheduleCard(
      Schedule s, DateTime todayDate, void Function(String)? onStatusChange) {
    // DETERMINE IF THIS SCHEDULE IS FOR TODAY
    final isToday = s.date != null &&
        s.date!.year == todayDate.year &&
        s.date!.month == todayDate.month &&
        s.date!.day == todayDate.day;
    // DETERMINE IF THIS SCHEDULE IS UPCOMING
    final isUpcoming = s.date != null && s.date!.isAfter(todayDate);
    final actionsEnabled = widget.userType == 'Technician';

    // SET COLORS BASED ON STATUS
    final isCompleted = s.status.toLowerCase() == 'completed';
    final isCancelled = s.status.toLowerCase() == 'cancelled';
    final cardColor = isToday
        ? K_TODAY_HIGHLIGHT
        : isUpcoming
            ? K_UPCOMING_DISABLED
            : null;
    final textColor = isUpcoming && !actionsEnabled || isCompleted || isCancelled ? K_DISABLED_TEXT : Colors.black;
    final iconCheckColor = actionsEnabled && !isCompleted && !isCancelled ? Colors.green : K_DISABLED_TEXT;
    final iconCancelColor = actionsEnabled && !isCompleted && !isCancelled ? Colors.red : K_DISABLED_TEXT;

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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
