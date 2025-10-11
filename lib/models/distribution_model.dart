class SupplyDistribution {
  final int id;
  final int farmWorkerFarmId;
  final int inventoryId;
  final String dateDistributed;
  final String status;
  final int quantity;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final FarmWorkerFarm? farmWorkerFarm;
  final Inventory? inventory;

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $value, error: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  SupplyDistribution({
    required this.id,
    required this.farmWorkerFarmId,
    required this.inventoryId,
    required this.dateDistributed,
    required this.status,
    required this.quantity,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.farmWorkerFarm,
    this.inventory,
  });

  factory SupplyDistribution.fromJson(Map<String, dynamic> json) {
    return SupplyDistribution(
      id: json['id'] ?? 0,
      farmWorkerFarmId: json['farm_worker_farm_id'] ?? 0,
      inventoryId: json['inventory_id'] ?? 0,
      dateDistributed: json['date_distributed'] ?? '',
      status: json['status'] ?? '',
      quantity: json['quantity'] ?? 0,
      deletedAt: json['deleted_at'] != null
          ? _parseDateTime(json['deleted_at'])
          : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      farmWorkerFarm: json['farm_worker_farm'] != null
          ? FarmWorkerFarm.fromJson(json['farm_worker_farm'])
          : null,
      inventory: json['inventory'] != null
          ? Inventory.fromJson(json['inventory'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_worker_farm_id': farmWorkerFarmId,
      'inventory_id': inventoryId,
      'date_distributed': dateDistributed,
      'status': status,
      'quantity': quantity,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'farm_worker_farm': farmWorkerFarm?.toJson(),
      'inventory': inventory?.toJson(),
    };
  }
}

class CashDistribution {
  final int id;
  final int farmWorkerFarmId;
  final String dateDistributed;
  final String status;
  final double amount;
  final int? requestId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final FarmWorkerFarm? farmWorkerFarm;

  CashDistribution({
    required this.id,
    required this.farmWorkerFarmId,
    required this.dateDistributed,
    required this.status,
    required this.amount,
    this.requestId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.farmWorkerFarm,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $value, error: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory CashDistribution.fromJson(Map<String, dynamic> json) {
    return CashDistribution(
      id: json['id'] ?? 0,
      farmWorkerFarmId: json['farm_worker_farm_id'] ?? 0,
      dateDistributed: json['date_distributed'] ?? '',
      status: json['status'] ?? '',
      amount: _parseDouble(json['amount']),
      requestId: json['request_id'],
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      deletedAt: json['deleted_at'] != null
          ? _parseDateTime(json['deleted_at'])
          : null,
      farmWorkerFarm: json['farm_worker_farm'] != null
          ? FarmWorkerFarm.fromJson(json['farm_worker_farm'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_worker_farm_id': farmWorkerFarmId,
      'date_distributed': dateDistributed,
      'status': status,
      'amount': amount,
      'request_id': requestId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'farm_worker_farm': farmWorkerFarm?.toJson(),
    };
  }
}

// New models for supply distribution
class FarmWorkerFarm {
  final int id;
  final int farmWorkerId;
  final int farmId;
  final String dateAssigned;
  final String status;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Farm? farm;
  final FarmWorker? farmWorker;

  FarmWorkerFarm({
    required this.id,
    required this.farmWorkerId,
    required this.farmId,
    required this.dateAssigned,
    required this.status,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.farm,
    this.farmWorker,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $value, error: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory FarmWorkerFarm.fromJson(Map<String, dynamic> json) {
    return FarmWorkerFarm(
      id: json['id'] ?? 0,
      farmWorkerId: json['farm_worker_id'] ?? 0,
      farmId: json['farm_id'] ?? 0,
      dateAssigned: json['date_assigned'] ?? '',
      status: json['status'] ?? '',
      deletedAt: json['deleted_at'] != null
          ? _parseDateTime(json['deleted_at'])
          : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      farm: json['farm'] != null ? Farm.fromJson(json['farm']) : null,
      farmWorker: json['farm_worker'] != null
          ? FarmWorker.fromJson(json['farm_worker'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_worker_id': farmWorkerId,
      'farm_id': farmId,
      'date_assigned': dateAssigned,
      'status': status,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'farm': farm?.toJson(),
      'farm_worker': farmWorker?.toJson(),
    };
  }
}

class Farm {
  final int id;
  final String area;
  final String farmAddress;
  final String coordinates;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Farm({
    required this.id,
    required this.area,
    required this.farmAddress,
    required this.coordinates,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $value, error: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] ?? 0,
      area: (json['area'] ?? json['farm_area'] ?? '').toString(),
      farmAddress: json['farm_address'] ?? '',
      coordinates: json['coordinates'] ?? '',
      deletedAt: json['deleted_at'] != null
          ? _parseDateTime(json['deleted_at'])
          : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area': area,
      'farm_address': farmAddress,
      'coordinates': coordinates,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Inventory {
  final int id;
  final String productName;
  final String category;
  final String price;
  final int quantity;
  final String expiryDate;
  final String dateOrdered;
  final String dateDelivered;
  final String availability;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Inventory({
    required this.id,
    required this.productName,
    required this.category,
    required this.price,
    required this.quantity,
    required this.expiryDate,
    required this.dateOrdered,
    required this.dateDelivered,
    required this.availability,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $value, error: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? '',
      quantity: json['quantity'] ?? 0,
      expiryDate: json['expiry_date'] ?? '',
      dateOrdered: json['date_ordered'] ?? '',
      dateDelivered: json['date_delivered'] ?? '',
      availability: json['availability'] ?? '',
      deletedAt: json['deleted_at'] != null
          ? _parseDateTime(json['deleted_at'])
          : null,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
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
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Technician model for cash distribution
class Technician {
  final int id;
  final String? name;

  Technician({
    required this.id,
    this.name,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

// Reuse existing models from request_model.dart
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

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $value, error: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory FarmWorker.fromJson(Map<String, dynamic> json) {
    return FarmWorker(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'],
      birthDate: json['birth_date'] ?? '',
      sex: json['sex'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      profilePicture: json['profile_picture'],
      idPicture: json['id_picture'],
      technicianId: json['technician_id'] ?? 0,
      status: json['status'] ?? '',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
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

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $value, error: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory Supply.fromJson(Map<String, dynamic> json) {
    return Supply(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? '',
      quantity: json['quantity'] ?? 0,
      expiryDate: json['expiry_date'] ?? '',
      dateOrdered: json['date_ordered'] ?? '',
      dateDelivered: json['date_delivered'] ?? '',
      availability: json['availability'] ?? '',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
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
