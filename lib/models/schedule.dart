import 'dart:convert';

class Schedule {
  final int id;
  final int farmWorkerId;
  final DateTime? transplantingDate;
  final int datr;
  final DateTime? date;
  final String activity;
  final String? remarks;
  final int? numLaborers;
  final String? unit;
  final double? budget;
  final Map<String, dynamic>? extra;
  final String status;

  Schedule({
    required this.id,
    required this.farmWorkerId,
    this.transplantingDate,
    required this.datr,
    this.date,
    required this.activity,
    this.remarks,
    this.numLaborers,
    this.unit,
    this.budget,
    this.extra,
    required this.status,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      farmWorkerId: json['farm_worker_id'],
      transplantingDate: json['transplanting_date'] != null
          ? DateTime.tryParse(json['transplanting_date'])
          : null,
      datr: json['datr'],
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      activity: json['activity'] ?? '',
      remarks: json['remarks'],
      numLaborers: json['num_laborers'],
      unit: json['unit'],
      budget:
          json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      extra: json['extra'] != null
          ? (json['extra'] is String
              ? Map<String, dynamic>.from(jsonDecode(json['extra']))
              : Map<String, dynamic>.from(json['extra']))
          : null,
      status: json['status'] ?? '',
    );
  }
}
