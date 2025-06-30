import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SchedulePage extends StatefulWidget {
  final String userType; // 'Technician' or 'Farmer'
  final String token;
  const SchedulePage({Key? key, required this.userType, required this.token}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late Future<List<Schedule>> _futureSchedules;
  final ScheduleService _service = ScheduleService();

  @override
  void initState() {
    super.initState();
    _futureSchedules = _service.fetchTodaySchedules(widget.token);
  }

  void _updateStatus(Schedule schedule, String status) async {
    await _service.updateScheduleStatus(schedule.id, status, widget.token);
    setState(() {
      _futureSchedules = _service.fetchTodaySchedules(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userType} Schedule'),
      ),
      body: FutureBuilder<List<Schedule>>(
        future: _futureSchedules,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: [${snapshot.error}'));
          final schedules = snapshot.data ?? [];
          final finished = schedules.where((s) => s.status == 'Completed').toList();
          final cancelled = schedules.where((s) => s.status == 'Cancelled').toList();
          final today = schedules.where((s) => s.status == 'Scheduled').toList();

          return ListView(
            children: [
              if (today.isNotEmpty) ...[
                ListTile(title: Text('Today\'s Activities', style: TextStyle(fontWeight: FontWeight.bold))),
                ...today.map((s) => Card(
                  child: ListTile(
                    title: Text(s.title),
                    subtitle: Text('${s.description}\n${s.startTime} - ${s.endTime}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () => _updateStatus(s, 'Completed'),
                          tooltip: 'Mark as Finished',
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _updateStatus(s, 'Cancelled'),
                          tooltip: 'Cancel',
                        ),
                      ],
                    ),
                  ),
                )),
              ],
              if (finished.isNotEmpty) ...[
                ListTile(title: Text('Finished', style: TextStyle(fontWeight: FontWeight.bold))),
                ...finished.map((s) => ListTile(
                  title: Text(s.title),
                  subtitle: Text('${s.description}\n${s.startTime} - ${s.endTime}'),
                )),
              ],
              if (cancelled.isNotEmpty) ...[
                ListTile(title: Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold))),
                ...cancelled.map((s) => ListTile(
                  title: Text(s.title),
                  subtitle: Text('${s.description}\n${s.startTime} - ${s.endTime}'),
                )),
              ],
            ],
          );
        },
      ),
    );
  }
} 