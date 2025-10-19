import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

class Farm {
  final int id;
  final String farmAddress;
  final String? name;
  final double area;
  final String? coordinates;
  final List<FarmWorker> farmWorkers;
  final String? siteNumber;
  final String? farmerNumber;
  final String? dataSource;

  const Farm({
    required this.id,
    required this.farmAddress,
    this.name,
    required this.area,
    this.coordinates,
    required this.farmWorkers,
    this.siteNumber,
    this.farmerNumber,
    this.dataSource,
  });

  /// Parse coordinates for center point
  LatLng? getCoordinates() {
    if (coordinates == null || coordinates!.isEmpty) return null;

    try {
      // Try to parse as JSON array (for polygon coordinates)
      if (coordinates!.startsWith('[')) {
        final List<dynamic> coordsList = jsonDecode(coordinates!);
        if (coordsList.isNotEmpty) {
          // Return the first point as center
          final firstPoint = coordsList[0];
          if (firstPoint is Map<String, dynamic>) {
            final lat = firstPoint['lat']?.toDouble();
            final lng = firstPoint['lng']?.toDouble();
            if (lat != null && lng != null) {
              return LatLng(lat, lng);
            }
          }
        }
      }

      // Try simple comma-separated format
      final coords = coordinates!.split(',');
      if (coords.length == 2) {
        final lat = double.tryParse(coords[0].trim());
        final lng = double.tryParse(coords[1].trim());
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      // Silently handle parsing errors
    }
    return null;
  }

  /// Get center coordinates for distance calculation
  double get centerLatitude {
    final coords = getCoordinates();
    return coords?.latitude ?? 0.0;
  }

  double get centerLongitude {
    final coords = getCoordinates();
    return coords?.longitude ?? 0.0;
  }

  /// Parse polygon coordinates
  List<LatLng> getPolygonCoordinates() {
    if (coordinates == null || coordinates!.isEmpty) return [];

    try {
      // Try to parse as JSON array (for polygon coordinates)
      if (coordinates!.startsWith('[')) {
        final List<dynamic> coordsList = jsonDecode(coordinates!);
        final List<LatLng> polygonCoords = [];

        for (final point in coordsList) {
          if (point is Map<String, dynamic>) {
            final lat = point['lat']?.toDouble();
            final lng = point['lng']?.toDouble();
            if (lat != null && lng != null) {
              polygonCoords.add(LatLng(lat, lng));
            }
          }
        }

        return polygonCoords;
      }
    } catch (e) {
      // Silently handle parsing errors
    }

    return [];
  }

  factory Farm.fromJson(Map<String, dynamic> json) {
    List<FarmWorker> workers = [];

    // Debug: Print the JSON data
    print('Farm.fromJson - Raw JSON: $json');
    print('Farm.fromJson - farmWorkers field: ${json['farmWorkers']}');
    print('Farm.fromJson - farm_workers field: ${json['farm_workers']}');

    // Handle farmWorkers as array (camelCase) or farm_workers (snake_case)
    if (json['farmWorkers'] != null) {
      if (json['farmWorkers'] is List) {
        print(
            'Farm.fromJson - farmWorkers is a List with ${(json['farmWorkers'] as List).length} items');
        workers = (json['farmWorkers'] as List<dynamic>)
            .map((worker) => FarmWorker.fromJson(worker))
            .toList();
        print('Farm.fromJson - Parsed workers: $workers');
      } else {
        print(
            'Farm.fromJson - farmWorkers is not a List: ${json['farmWorkers'].runtimeType}');
      }
    } else if (json['farm_workers'] != null) {
      if (json['farm_workers'] is List) {
        print(
            'Farm.fromJson - farm_workers is a List with ${(json['farm_workers'] as List).length} items');
        workers = (json['farm_workers'] as List<dynamic>)
            .map((worker) => FarmWorker.fromJson(worker))
            .toList();
        print('Farm.fromJson - Parsed workers: $workers');
      } else {
        print(
            'Farm.fromJson - farm_workers is not a List: ${json['farm_workers'].runtimeType}');
      }
    } else {
      print('Farm.fromJson - Both farmWorkers and farm_workers are null');
    }

    // Remove duplicate workers based on ID
    final uniqueWorkers = <int, FarmWorker>{};
    for (final worker in workers) {
      uniqueWorkers[worker.id] = worker;
    }
    workers = uniqueWorkers.values.toList();

    return Farm(
      id: json['id'] ?? 0,
      farmAddress: json['farm_address'] ?? '',
      name: json['name'],
      area: double.tryParse(
              (json['area'] ?? json['farm_area'])?.toString() ?? '0') ??
          0.0,
      coordinates: json['coordinates'],
      farmWorkers: workers,
      siteNumber: json['site_number']?.toString(),
      farmerNumber: json['farmer_number']?.toString(),
      dataSource: json['data_source']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Farm && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Farm(id: $id, address: $farmAddress)';
}

class FarmWorker {
  final int id;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? address;
  final Technician? technician;

  const FarmWorker({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.address,
    this.technician,
  });

  factory FarmWorker.fromJson(Map<String, dynamic> json) {
    return FarmWorker(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'],
      address: json['address'],
      technician: json['technician'] != null
          ? Technician.fromJson(json['technician'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmWorker && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FarmWorker(id: $id, name: $firstName $lastName)';
}

class Technician {
  final int id;
  final String firstName;
  final String lastName;

  const Technician({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }

  @override
  String toString() => 'Technician(id: $id, name: $firstName $lastName)';
}
