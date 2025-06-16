class Report {
  final int id;
  final int technicianId;
  final int farmId;
  final String accomplishments;
  final String issuesObserved;
  final String diseaseDetected;
  final String? diseaseType;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? technician;
  final Map<String, dynamic>? farm;

  Report({
    required this.id,
    required this.technicianId,
    required this.farmId,
    required this.accomplishments,
    required this.issuesObserved,
    required this.diseaseDetected,
    this.diseaseType,
    required this.description,
    required this.timestamp,
    this.technician,
    this.farm,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      technicianId: json['technician_id'],
      farmId: json['farm_id'],
      accomplishments: json['accomplishments'],
      issuesObserved: json['issues_observed'],
      diseaseDetected: json['disease_detected'],
      diseaseType: json['disease_type'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      technician: json['technician'],
      farm: json['farm'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technician_id': technicianId,
      'farm_id': farmId,
      'accomplishments': accomplishments,
      'issues_observed': issuesObserved,
      'disease_detected': diseaseDetected,
      'disease_type': diseaseType,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }
} 