import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

class Farm {
  final int id;
  final String farmAddress;
  final double farmSize;
  final String? coordinates;
  final List<FarmWorker> farmWorkers;

  const Farm({
    required this.id,
    required this.farmAddress,
    required this.farmSize,
    this.coordinates,
    required this.farmWorkers,
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

    // Handle farmWorkers as array (new format)
    if (json['farmWorkers'] != null) {
      if (json['farmWorkers'] is List) {
        workers = (json['farmWorkers'] as List<dynamic>)
            .map((worker) => FarmWorker.fromJson(worker))
            .toList();
      }
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
      farmSize: double.tryParse(json['farm_size']?.toString() ?? '0') ?? 0.0,
      coordinates: json['coordinates'],
      farmWorkers: workers,
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

  const FarmWorker({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory FarmWorker.fromJson(Map<String, dynamic> json) {
    return FarmWorker(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
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
