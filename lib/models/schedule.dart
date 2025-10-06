class Schedule {
  final int? id;
  final int? farmWorkerId;
  final DateTime? transplantingDate;
  final int? datr;
  final DateTime? date;
  final String activity;
  final String? remarks;
  final int? laborerId; // Changed from numLaborers to laborerId (legacy field)
  final List<dynamic>?
      laborers; // New field for multiple laborers with unit/budget/extra
  final String status;

  Schedule({
    this.id,
    this.farmWorkerId,
    this.transplantingDate,
    this.datr,
    this.date,
    required this.activity,
    this.remarks,
    this.laborerId,
    this.laborers,
    required this.status,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as int?,
      farmWorkerId: json['farm_worker_id'] as int?,
      transplantingDate: json['transplanting_date'] != null
          ? DateTime.tryParse(json['transplanting_date'].toString())
          : null,
      datr: json['datr'] as int?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      activity: json['activity']?.toString() ?? '',
      remarks: json['remarks']?.toString(),
      laborerId: json['laborer_id'] as int?,
      laborers: json['laborers']
          as List<dynamic>?, // Parse new laborers field with unit/budget/extra
      status: json['status']?.toString() ?? '',
    );
  }
}
