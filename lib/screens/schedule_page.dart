import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    if (widget.farmWorkerId != 0) {
      _futureSchedules = _service.fetchSchedulesForFarmWorker(
          widget.farmWorkerId, widget.token);
    }
  }

  void _updateStatus(Schedule schedule, String status) async {
    await _service.updateScheduleStatus(schedule.id, status, widget.token);
    setState(() {
      _futureSchedules = _service.fetchSchedulesForFarmWorker(
          widget.farmWorkerId, widget.token);
    });
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
                final finished =
                    schedules.where((s) => s.status == 'Completed').toList();
                final cancelled =
                    schedules.where((s) => s.status == 'Cancelled').toList();
                final today =
                    schedules.where((s) => s.status == 'Scheduled').toList();

                // BUILD THE SCHEDULE LIST
                return ListView(
                  children: [
                    if (today.isNotEmpty) ...[
                      const ListTile(
                        title: Text('ACTIVITIES',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...today.map((s) => _buildScheduleCard(
                          s, todayDate, (status) => _updateStatus(s, status))),
                    ],
                    if (finished.isNotEmpty) ...[
                      const ListTile(
                          title: Text('FINISHED',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      ...finished.map((s) => ListTile(
                            title: Text(s.activity),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (s.date != null)
                                  Text(
                                      'DATE:  [${s.date!.toLocal().toString().split(' ')[0]}'),
                                if (s.remarks != null && s.remarks!.isNotEmpty)
                                  Text('REMARKS:  [${s.remarks}'),
                              ],
                            ),
                          )),
                    ],
                    if (cancelled.isNotEmpty) ...[
                      const ListTile(
                          title: Text('CANCELLED',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      ...cancelled.map((s) => ListTile(
                            title: Text(s.activity),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (s.date != null)
                                  Text(
                                      'DATE:  [${s.date!.toLocal().toString().split(' ')[0]}'),
                                if (s.remarks != null && s.remarks!.isNotEmpty)
                                  Text('REMARKS:  [${s.remarks}'),
                              ],
                            ),
                          )),
                    ],
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

    // SET COLORS BASED ON STATUS
    final cardColor = isToday
        ? K_TODAY_HIGHLIGHT
        : isUpcoming
            ? K_UPCOMING_DISABLED
            : null;
    final textColor = isUpcoming ? K_DISABLED_TEXT : Colors.black;
    final iconCheckColor = isUpcoming ? K_DISABLED_TEXT : Colors.green;
    final iconCancelColor = isUpcoming ? K_DISABLED_TEXT : Colors.red;

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
              Text('DATE:  [${s.date!.toLocal().toString().split(' ')[0]}',
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
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check, color: iconCheckColor),
              onPressed:
                  isToday ? () => onStatusChange?.call('Completed') : null,
              tooltip: 'MARK AS FINISHED',
            ),
            IconButton(
              icon: Icon(Icons.cancel, color: iconCancelColor),
              onPressed:
                  isToday ? () => onStatusChange?.call('Cancelled') : null,
              tooltip: 'CANCEL',
            ),
          ],
        ),
      ),
    );
  }
}
