class Request {
  final int id;
  final int technicianId;
  final int farmWorkerId;
  final String requestType;
  final String description;
  final double? amount;
  final int? supplyId;
  final int? quantity;
  final String status;
  final String? adminNote;
  final String timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Technician? technician;
  final FarmWorker? farmWorker;
  final Supply? supply;

  Request({
    required this.id,
    required this.technicianId,
    required this.farmWorkerId,
    required this.requestType,
    required this.description,
    this.amount,
    this.supplyId,
    this.quantity,
    required this.status,
    this.adminNote,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
    this.technician,
    this.farmWorker,
    this.supply,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'],
      technicianId: json['technician_id'],
      farmWorkerId: json['farm_worker_id'],
      requestType: json['request_type'],
      description: json['description'],
      amount: json['amount']?.toDouble(),
      supplyId: json['supply_id'],
      quantity: json['quantity'],
      status: json['status'],
      adminNote: json['admin_note'],
      timestamp: json['timestamp'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      technician: json['technician'] != null ? Technician.fromJson(json['technician']) : null,
      farmWorker: json['farm_worker'] != null ? FarmWorker.fromJson(json['farm_worker']) : null,
      supply: json['supply'] != null ? Supply.fromJson(json['supply']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technician_id': technicianId,
      'farm_worker_id': farmWorkerId,
      'request_type': requestType,
      'description': description,
      'amount': amount,
      'supply_id': supplyId,
      'quantity': quantity,
      'status': status,
      'admin_note': adminNote,
      'timestamp': timestamp,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'technician': technician?.toJson(),
      'farm_worker': farmWorker?.toJson(),
      'supply': supply?.toJson(),
    };
  }
}

class Technician {
  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String birthDate;
  final String sex;
  final String emailAddress;
  final String phoneNumber;
  final String address;
  final String status;
  final String? profilePicture;
  final String? idPicture;
  final DateTime createdAt;
  final DateTime updatedAt;

  Technician({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.birthDate,
    required this.sex,
    required this.emailAddress,
    required this.phoneNumber,
    required this.address,
    required this.status,
    this.profilePicture,
    this.idPicture,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      middleName: json['middle_name'],
      birthDate: json['birth_date'],
      sex: json['sex'],
      emailAddress: json['email_address'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      status: json['status'],
      profilePicture: json['profile_picture'],
      idPicture: json['id_picture'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'birth_date': birthDate,
      'sex': sex,
      'email_address': emailAddress,
      'phone_number': phoneNumber,
      'address': address,
      'status': status,
      'profile_picture': profilePicture,
      'id_picture': idPicture,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class FarmWorker {
  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String birthDate;
  final String sex;
  final String phoneNumber;
  final String address;
  final String? profilePicture;
  final String? idPicture;
  final int technicianId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmWorker({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.birthDate,
    required this.sex,
    required this.phoneNumber,
    required this.address,
    this.profilePicture,
    this.idPicture,
    required this.technicianId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmWorker.fromJson(Map<String, dynamic> json) {
    return FarmWorker(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      middleName: json['middle_name'],
      birthDate: json['birth_date'],
      sex: json['sex'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      profilePicture: json['profile_picture'],
      idPicture: json['id_picture'],
      technicianId: json['technician_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'birth_date': birthDate,
      'sex': sex,
      'phone_number': phoneNumber,
      'address': address,
      'profile_picture': profilePicture,
      'id_picture': idPicture,
      'technician_id': technicianId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Supply {
  final int id;
  final String productName;
  final String category;
  final String price;
  final int quantity;
  final String expiryDate;
  final String dateOrdered;
  final String dateDelivered;
  final String availability;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supply({
    required this.id,
    required this.productName,
    required this.category,
    required this.price,
    required this.quantity,
    required this.expiryDate,
    required this.dateOrdered,
    required this.dateDelivered,
    required this.availability,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supply.fromJson(Map<String, dynamic> json) {
    return Supply(
      id: json['id'],
      productName: json['product_name'],
      category: json['category'],
      price: json['price'],
      quantity: json['quantity'],
      expiryDate: json['expiry_date'],
      dateOrdered: json['date_ordered'],
      dateDelivered: json['date_delivered'],
      availability: json['availability'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'category': category,
      'price': price,
      'quantity': quantity,
      'expiry_date': expiryDate,
      'date_ordered': dateOrdered,
      'date_delivered': dateDelivered,
      'availability': availability,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
