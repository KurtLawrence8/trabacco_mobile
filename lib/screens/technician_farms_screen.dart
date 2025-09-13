import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/farm_service.dart';
import '../models/farm.dart';
import '../services/auth_service.dart';

class TechnicianFarmsScreen extends StatefulWidget {
  final int? focusFarmId; // Optional farm ID to focus on
  const TechnicianFarmsScreen({Key? key, this.focusFarmId}) : super(key: key);

  @override
  _TechnicianFarmsScreenState createState() => _TechnicianFarmsScreenState();
}

class _TechnicianFarmsScreenState extends State<TechnicianFarmsScreen> {
  Future<List<Farm>>? _farmsFuture;
  final FarmService _farmService = FarmService();
  final AuthService _authService = AuthService();
  bool _showMap = true; // Show map by default
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  MapType _currentMapType = MapType.normal; // Default map type

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  /// Focus on a specific farm if focusFarmId is provided
  void _focusOnFarm(List<Farm> farms) {
    if (widget.focusFarmId != null && _mapController != null) {
      try {
        final targetFarm = farms.firstWhere(
          (farm) => farm.id == widget.focusFarmId,
        );

        final coordinates = targetFarm.getCoordinates();
        if (coordinates != null) {
          // Add a small delay to ensure map is fully loaded
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                    coordinates, 18.0), // Increased zoom level
              );
            }
          });
        }
      } catch (e) {
        // Farm not found, do nothing
        print('Farm with ID ${widget.focusFarmId} not found');
      }
    }
  }

  /// Load farms for the current technician
  void _loadFarms() async {
    final token = await _authService.getToken();
    setState(() {
      _farmsFuture = token != null
          ? _farmService.getFarmsByTechnician(token)
          : Future.value([]);
    });
  }

  /// Create markers and polygons for farms with coordinates
  void _createMarkers(List<Farm> farms) {
    _markers.clear();
    _polygons.clear();

    // Filter farms that have actual polygon coordinates
    final farmsWithPolygons =
        farms.where((farm) => farm.getPolygonCoordinates().isNotEmpty).toList();

    for (final farm in farmsWithPolygons) {
      final polygonCoordinates = farm.getPolygonCoordinates();

      // Calculate center point for marker
      double centerLat = 0;
      double centerLng = 0;
      for (final point in polygonCoordinates) {
        centerLat += point.latitude;
        centerLng += point.longitude;
      }
      final centerPoint = LatLng(
        centerLat / polygonCoordinates.length,
        centerLng / polygonCoordinates.length,
      );

      // Create marker at center
      _markers.add(
        Marker(
          markerId: MarkerId('farm_${farm.id}'),
          position: centerPoint,
          infoWindow: InfoWindow.noText,
          onTap: () {
            _showFarmDetails(farm);
          },
        ),
      );

      // Create exact farm polygon using real coordinates
      _polygons.add(
        Polygon(
          polygonId: PolygonId('farm_polygon_${farm.id}'),
          points: polygonCoordinates,
          strokeWidth: 2,
          strokeColor: Colors.green,
          fillColor: Colors.green.withOpacity(0.2),
        ),
      );
    }
  }

  Widget _buildFarmList(List<Farm> farms) {
    return ListView.builder(
      itemCount: farms.length,
      itemBuilder: (context, index) {
        final farm = farms[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.agriculture, color: Colors.green),
            title: Text(
              farm.farmAddress,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Size: ${farm.farmSize} ha'),
                Text(
                  'Workers: ${farm.farmWorkers.map((w) => '${w.firstName} ${w.lastName}').toSet().join(', ')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to farm detail or show on map
              setState(() {
                _showMap = true;
              });
              // Center map on this farm
              if (_mapController != null) {
                final coordinates = farm.getCoordinates();
                if (coordinates != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                        coordinates, 18.0), // Increased zoom level
                  );
                } else {
                  // Don't center on farms without coordinates
                  print('Farm ${farm.id} has no coordinates, skipping center');
                }
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildCustomMapView(List<Farm> farms) {
    // Filter farms with polygon coordinates
    final farmsWithPolygons =
        farms.where((farm) => farm.getPolygonCoordinates().isNotEmpty).toList();

    if (farmsWithPolygons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No farms with coordinates found.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Only farms with GPS coordinates will be displayed on the map.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Map header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Farm Locations (${farmsWithPolygons.length} farms)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          // Map area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Background map-like pattern
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue[50]!,
                            Colors.green[50]!,
                          ],
                        ),
                      ),
                    ),
                    // Farm markers (only farms with polygon coordinates)
                    ...farmsWithPolygons.asMap().entries.map((entry) {
                      final index = entry.key;
                      final farm = entry.value;
                      final left = 50.0 + (index * 80.0);
                      final top = 100.0 + (index * 60.0);

                      return Positioned(
                        left: left,
                        top: top,
                        child: GestureDetector(
                          onTap: () {
                            _showFarmDetails(farm);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.agriculture,
                                    color: Colors.white, size: 20),
                                const SizedBox(height: 4),
                                Text(
                                  'Farm ${farm.id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFarmDetails(Farm farm) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Farm Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Section
                    _buildDetailRow(
                      icon: Icons.location_on_rounded,
                      label: 'Farm Address',
                      value: farm.farmAddress,
                      iconColor: Colors.grey,
                    ),
                    const SizedBox(height: 16),

                    // Size Section
                    _buildDetailRow(
                      icon: Icons.straighten_rounded,
                      label: 'Farm Size',
                      value: '${farm.farmSize} hectares',
                      iconColor: Colors.grey,
                    ),
                    const SizedBox(height: 16),

                    // Map Type Indicator
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            _getMapTypeColor(_currentMapType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getMapTypeColor(_currentMapType)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMapTypeIcon(_currentMapType),
                            color: _getMapTypeColor(_currentMapType),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Viewing in ${_getMapTypeName(_currentMapType)} mode',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getMapTypeColor(_currentMapType),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Workers Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.people_alt_rounded,
                            color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Farm Workers',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...farm.farmWorkers
                                  .map((w) => '${w.firstName} ${w.lastName}')
                                  .toSet()
                                  .map((name) => Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(
                                          '• $name',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Footer with action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Center map on this farm
                          if (_mapController != null) {
                            final coordinates = farm.getCoordinates();
                            if (coordinates != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(coordinates, 15),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.my_location_rounded, size: 16),
                        label: const Text('Locate on Map'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a detail row with icon, label, and value
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get color for map type
  Color _getMapTypeColor(MapType mapType) {
    switch (mapType) {
      case MapType.normal:
        return Colors.blue;
      case MapType.satellite:
        return Colors.green;
      case MapType.terrain:
        return Colors.brown;
      case MapType.hybrid:
        return Colors.orange;
      case MapType.none:
        return Colors.grey;
    }
  }

  /// Get display name for map type
  String _getMapTypeName(MapType mapType) {
    switch (mapType) {
      case MapType.normal:
        return 'Normal';
      case MapType.satellite:
        return 'Satellite';
      case MapType.terrain:
        return 'Terrain';
      case MapType.hybrid:
        return 'Hybrid';
      case MapType.none:
        return 'None';
    }
  }

  /// Get icon for map type
  IconData _getMapTypeIcon(MapType mapType) {
    switch (mapType) {
      case MapType.normal:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite;
      case MapType.terrain:
        return Icons.terrain;
      case MapType.hybrid:
        return Icons.layers;
      case MapType.none:
        return Icons.map;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workers\' Farms'),
        actions: [
          // Map type selector (only show when map is visible)
          if (_showMap)
            PopupMenuButton<MapType>(
              icon: Icon(_getMapTypeIcon(_currentMapType)),
              onSelected: (MapType mapType) {
                setState(() {
                  _currentMapType = mapType;
                });
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<MapType>(
                  value: MapType.normal,
                  child: Row(
                    children: [
                      Icon(Icons.map, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Normal'),
                    ],
                  ),
                ),
                const PopupMenuItem<MapType>(
                  value: MapType.satellite,
                  child: Row(
                    children: [
                      Icon(Icons.satellite, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Satellite'),
                    ],
                  ),
                ),
                const PopupMenuItem<MapType>(
                  value: MapType.terrain,
                  child: Row(
                    children: [
                      Icon(Icons.terrain, color: Colors.brown),
                      SizedBox(width: 8),
                      Text('Terrain'),
                    ],
                  ),
                ),
                const PopupMenuItem<MapType>(
                  value: MapType.hybrid,
                  child: Row(
                    children: [
                      Icon(Icons.layers, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Hybrid'),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: _farmsFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Farm>>(
              future: _farmsFuture!,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No farms found.'));
                }
                final farms = snapshot.data!;

                // Check if any farms have polygon coordinates
                final farmsWithPolygons = farms
                    .where((farm) => farm.getPolygonCoordinates().isNotEmpty)
                    .toList();
                if (farmsWithPolygons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No farms with coordinates found.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Only farms with GPS coordinates will be displayed on the map.',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (_showMap) {
                  // Show map view
                  _createMarkers(farms);
                  return FutureBuilder(
                    future: Future.delayed(const Duration(milliseconds: 500)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading map...'),
                            ],
                          ),
                        );
                      }

                      try {
                        // Use the first farm's coordinates as center, or show no farms message
                        if (farmsWithPolygons.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_off,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No farms with coordinates found.',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Only farms with GPS coordinates will be displayed on the map.',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        // Calculate center from first farm's polygon
                        final firstFarmPolygon =
                            farmsWithPolygons.first.getPolygonCoordinates();
                        double centerLat = 0;
                        double centerLng = 0;
                        for (final point in firstFarmPolygon) {
                          centerLat += point.latitude;
                          centerLng += point.longitude;
                        }
                        final centerFarm = LatLng(
                            centerLat / firstFarmPolygon.length,
                            centerLng / firstFarmPolygon.length);

                        return GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: centerFarm,
                            zoom: 12, // Increased initial zoom
                          ),
                          markers: _markers,
                          polygons: _polygons,
                          mapType: _currentMapType, // Use selected map type
                          zoomControlsEnabled: true, // Enable zoom controls
                          zoomGesturesEnabled: true, // Enable zoom gestures
                          scrollGesturesEnabled: true, // Enable pan gestures
                          tiltGesturesEnabled: true, // Enable tilt gestures
                          rotateGesturesEnabled: true, // Enable rotate gestures
                          myLocationButtonEnabled:
                              true, // Enable location button
                          myLocationEnabled: true, // Enable current location
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            // Focus on specific farm if provided
                            if (widget.focusFarmId != null) {
                              _focusOnFarm(farms);
                            }
                          },
                        );
                      } catch (e) {
                        print('Google Maps error: $e');
                        // Show error message and fallback
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.orange,
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Google Maps failed to load: $e',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _buildCustomMapView(farms),
                            ),
                          ],
                        );
                      }
                    },
                  );
                } else {
                  // Show list view
                  return _buildFarmList(farms);
                }
              },
            ),
    );
  }
}
