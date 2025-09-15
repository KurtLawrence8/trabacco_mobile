class TobaccoVariety {
  final int id;
  final String varietyName;
  final double defaultSeedsPerHectare;
  final double expectedYieldPerPlant;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TobaccoVariety({
    required this.id,
    required this.varietyName,
    required this.defaultSeedsPerHectare,
    required this.expectedYieldPerPlant,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory TobaccoVariety.fromJson(Map<String, dynamic> json) {
    return TobaccoVariety(
      id: json['id'] ?? 0,
      varietyName: json['variety_name'] ?? '',
      defaultSeedsPerHectare: _parseDouble(json['default_seeds_per_hectare']),
      expectedYieldPerPlant: _parseDouble(json['default_yield_per_plant']),
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variety_name': varietyName,
      'default_seeds_per_hectare': defaultSeedsPerHectare,
      'default_yield_per_plant': expectedYieldPerPlant,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TobaccoVariety(id: $id, varietyName: $varietyName, defaultSeedsPerHectare: $defaultSeedsPerHectare, expectedYieldPerPlant: $expectedYieldPerPlant)';
  }
}
