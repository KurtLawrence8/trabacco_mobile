import 'dart:convert';

class Schedule {
  final int? id;
  final int? farmWorkerId;
  final DateTime? transplantingDate;
  final int? datr;
  final DateTime? date;
  final String activity;
  final String? remarks;
  final int? numLaborers;
  final String? unit;
  final double? budget;
  final Map<String, dynamic>? extra;
  final String status;

  Schedule({
    this.id,
    this.farmWorkerId,
    this.transplantingDate,
    this.datr,
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
      numLaborers: json['num_laborers'] as int?,
      unit: json['unit']?.toString(),
      budget:
          json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      extra: json['extra'] != null
          ? (json['extra'] is String
              ? Map<String, dynamic>.from(jsonDecode(json['extra']))
              : Map<String, dynamic>.from(json['extra']))
          : null,
      status: json['status']?.toString() ?? '',
    );
  }
}

// OLD ETO PAG NAG ERROR YUNG CHANGES NA LINAGAY KO AT LEAST MERON ETONG BACK UP

// import 'dart:convert';

// class Schedule {
//   final int? id; // Make id nullable since templates don't have real IDs
//   final int farmWorkerId;
//   final DateTime? transplantingDate;
//   final int datr;
//   final DateTime? date;
//   final String activity;
//   final String? remarks;
//   final int? numLaborers;
//   final String? unit;
//   final double? budget;
//   final Map<String, dynamic>? extra;
//   final String status;

//   Schedule({
//     this.id, // Make id optional
//     required this.farmWorkerId,
//     this.transplantingDate,
//     required this.datr,
//     this.date,
//     required this.activity,
//     this.remarks,
//     this.numLaborers,
//     this.unit,
//     this.budget,
//     this.extra,
//     required this.status,
//   });

//   // Getter to check if this is a template schedule
//   bool get isTemplate => id == null;

//   // Getter to get a display ID (either real ID or 'Template')
//   String get displayId => id?.toString() ?? 'Template';

//   factory Schedule.fromJson(Map<String, dynamic> json) {
//     print('[Schedule] [fromJson] Starting to parse schedule JSON: $json');

//     try {
//       // Log each field being parsed
//       print(
//           '[Schedule] [fromJson] Parsing id: ${json['id']} (type: ${json['id'].runtimeType})');
//       print(
//           '[Schedule] [fromJson] Parsing farm_worker_id: ${json['farm_worker_id']} (type: ${json['farm_worker_id'].runtimeType})');
//       print(
//           '[Schedule] [fromJson] Parsing transplanting_date: ${json['transplanting_date']}');
//       print(
//           '[Schedule] [fromJson] Parsing datr: ${json['datr']} (type: ${json['datr'].runtimeType})');
//       print('[Schedule] [fromJson] Parsing date: ${json['date']}');
//       print('[Schedule] [fromJson] Parsing activity: ${json['activity']}');
//       print('[Schedule] [fromJson] Parsing remarks: ${json['remarks']}');
//       print(
//           '[Schedule] [fromJson] Parsing num_laborers: ${json['num_laborers']} (type: ${json['num_laborers']?.runtimeType})');
//       print('[Schedule] [fromJson] Parsing unit: ${json['unit']}');
//       print(
//           '[Schedule] [fromJson] Parsing budget: ${json['budget']} (type: ${json['budget']?.runtimeType})');
//       print('[Schedule] [fromJson] Parsing extra: ${json['extra']}');
//       print('[Schedule] [fromJson] Parsing status: ${json['status']}');

//       // Safe type conversion for integer fields
//       final id =
//           json['id'] != null ? _safeIntConversion(json['id'], 'id') : null;
//       final farmWorkerId =
//           _safeIntConversion(json['farm_worker_id'], 'farm_worker_id');
//       final datr = _safeIntConversion(json['datr'], 'datr');
//       final numLaborers = json['num_laborers'] != null
//           ? _safeIntConversion(json['num_laborers'], 'num_laborers')
//           : null;

//       final schedule = Schedule(
//         id: id,
//         farmWorkerId: farmWorkerId,
//         transplantingDate: json['transplanting_date'] != null
//             ? DateTime.tryParse(json['transplanting_date'])
//             : null,
//         datr: datr,
//         date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
//         activity: json['activity'] ?? '',
//         remarks: json['remarks'],
//         numLaborers: numLaborers,
//         unit: json['unit'],
//         budget: json['budget'] != null
//             ? _safeDoubleConversion(json['budget'])
//             : null,
//         extra: json['extra'] != null
//             ? (json['extra'] is String
//                 ? Map<String, dynamic>.from(jsonDecode(json['extra']))
//                 : Map<String, dynamic>.from(json['extra']))
//             : null,
//         status: json['status'] ?? '',
//       );

//       print(
//           '[Schedule] [fromJson] Successfully created schedule with ID: ${schedule.displayId}');
//       return schedule;
//     } catch (e) {
//       print('[Schedule] [fromJson] ERROR parsing schedule: $e');
//       print('[Schedule] [fromJson] Problematic JSON: $json');
//       rethrow;
//     }
//   }

//   // Helper method to safely convert values to int
//   static int _safeIntConversion(dynamic value, String fieldName) {
//     if (value == null) {
//       print(
//           '[Schedule] [_safeIntConversion] WARNING: $fieldName is null, using 0 as default');
//       return 0;
//     }

//     if (value is int) {
//       return value;
//     }

//     if (value is String) {
//       print(
//           '[Schedule] [_safeIntConversion] WARNING: $fieldName is string "$value", attempting to parse');
//       final parsed = int.tryParse(value);
//       if (parsed != null) {
//         return parsed;
//       } else {
//         print(
//             '[Schedule] [_safeIntConversion] ERROR: Cannot parse "$value" as int for $fieldName');
//         throw FormatException(
//             'Cannot parse "$value" as int for field $fieldName');
//       }
//     }

//     if (value is double) {
//       print(
//           '[Schedule] [_safeIntConversion] WARNING: $fieldName is double $value, converting to int');
//       return value.toInt();
//     }

//     print(
//         '[Schedule] [_safeIntConversion] ERROR: Unexpected type ${value.runtimeType} for $fieldName: $value');
//     throw FormatException(
//         'Unexpected type ${value.runtimeType} for field $fieldName: $value');
//   }

//   // Helper method to safely convert values to double
//   static double _safeDoubleConversion(dynamic value) {
//     if (value == null) return 0.0;

//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is String) {
//       final parsed = double.tryParse(value);
//       if (parsed != null) return parsed;
//       throw FormatException('Cannot parse "$value" as double');
//     }

//     throw FormatException('Unexpected type ${value.runtimeType}: $value');
//   }
// }
