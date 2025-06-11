class User {
  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String email;
  final String phoneNumber;
  final String userType; // 'technician' or 'farm_worker'

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.email,
    required this.phoneNumber,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      middleName: json['middle_name'],
      email: json['email_address'] ?? '',
      phoneNumber: json['phone_number'],
      userType: json['user_type'] ?? 'technician',
    );
  }
} 