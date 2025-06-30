class Schedule {
  final int id;
  final String title;
  final String description;
  final DateTime dateScheduled;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  Schedule({
    required this.id,
    required this.title,
    required this.description,
    required this.dateScheduled,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateScheduled: DateTime.parse(json['date_scheduled']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'],
    );
  }
} 