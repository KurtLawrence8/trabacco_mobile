class Laborer {
  final int id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Laborer({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $middleName $lastName';

  factory Laborer.fromJson(Map<String, dynamic> json) {
    return Laborer(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Laborer(id: $id, name: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Laborer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
