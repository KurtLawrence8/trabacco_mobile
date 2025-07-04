class User {
  final int id;
  final String name;
  final String? email;
  final String? emailVerifiedAt;
  final List<String>? roles;
  final String? token;

  User({
    required this.id,
    required this.name,
    this.email,
    this.emailVerifiedAt,
    this.roles,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      roles: json['roles'] != null ? List<String>.from(json['roles']) : null,
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'roles': roles,
      'token': token,
    };
  }
}

class FarmWorker {
  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String phoneNumber;
  final String? address;
  final String? sex;
  final String? birthDate;
  final int technicianId;
  final Map<String, dynamic>? technician;
  final List<dynamic>? farms;

  FarmWorker({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.phoneNumber,
    this.address,
    this.sex,
    this.birthDate,
    required this.technicianId,
    this.technician,
    this.farms,
  });

  factory FarmWorker.fromJson(Map<String, dynamic> json) {
    return FarmWorker(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      middleName: json['middle_name'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      sex: json['sex'],
      birthDate: json['birth_date'],
      technicianId: json['technician_id'],
      technician: json['technician'],
      farms: json['farms'],
    );
  }
}

class RequestModel {
  final int id;
  final int farmWorkerId;
  final int technicianId;
  final String? type; // 'CASH ADVANCE' or 'SUPPLY'
  final double? amount;
  final String? reason;
  final String? status;
  final int? supplyId;
  final String? supplyName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminNote;

  RequestModel({
    required this.id,
    required this.farmWorkerId,
    required this.technicianId,
    this.type,
    this.amount,
    this.reason,
    this.status,
    this.supplyId,
    this.supplyName,
    required this.createdAt,
    this.updatedAt,
    this.adminNote,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'],
      farmWorkerId: json['farm_worker_id'],
      technicianId: json['technician_id'],
      type: json['request_type']?.toLowerCase() == 'cash advance'
          ? 'cash_advance'
          : (json['request_type']?.toLowerCase() == 'supply' ? 'supply' : null),
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString())
          : null,
      reason: json['description'] ?? '-',
      status: json['status'] ?? '-',
      supplyId: json['supply_id'],
      supplyName: json['supply_name'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      adminNote: json['admin_note'],
    );
  }
}

class InventoryItem {
  final int id;
  final String name;
  final int quantity;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      name: json['name'] ?? json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final String? data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? '-',
      body: json['body'] ?? '-',
      type: json['type'] ?? '-',
      data: json['data'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
