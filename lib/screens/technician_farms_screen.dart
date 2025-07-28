import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/farm_service.dart';
import '../models/farm.dart';
import '../services/auth_service.dart';

class TechnicianFarmsScreen extends StatefulWidget {
  const TechnicianFarmsScreen({Key? key}) : super(key: key);

  @override
  _TechnicianFarmsScreenState createState() => _TechnicianFarmsScreenState();
}

class _TechnicianFarmsScreenState extends State<TechnicianFarmsScreen> {
  Future<List<Farm>>? _farmsFuture;
  final FarmService _farmService = FarmService();
  final AuthService _authService = AuthService();
  bool _showMap = true; // Show map by default
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    _loadFarms();
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
          infoWindow: InfoWindow(
            title: farm.farmAddress,
            snippet:
                'Size: ${farm.farmSize} ha\nWorkers: ${farm.farmWorkers.map((w) => '${w.firstName} ${w.lastName}').toSet().join(', ')}',
          ),
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
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(Icons.agriculture, color: Colors.green),
            title: Text(
              farm.farmAddress,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Size: ${farm.farmSize} ha'),
                Text(
                  'Workers: ${farm.farmWorkers.map((w) => '${w.firstName} ${w.lastName}').toSet().join(', ')}',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios),
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
                    CameraUpdate.newLatLng(coordinates),
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
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No farms with coordinates found.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
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
            padding: EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              children: [
                Icon(Icons.map, color: Colors.green),
                SizedBox(width: 8),
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
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
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
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.agriculture,
                                    color: Colors.white, size: 20),
                                SizedBox(height: 4),
                                Text(
                                  'Farm ${farm.id}',
                                  style: TextStyle(
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
      builder: (context) => AlertDialog(
        title: Text('Farm Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${farm.farmAddress}'),
            Text('Size: ${farm.farmSize} ha'),
            SizedBox(height: 8),
            Text('Workers:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...farm.farmWorkers
                .map((w) => '${w.firstName} ${w.lastName}')
                .toSet()
                .map((name) => Text('• $name')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Workers\' Farms'),
        actions: [
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
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Farm>>(
              future: _farmsFuture!,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No farms found.'));
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
                        Icon(Icons.location_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No farms with coordinates found.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
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
                    future: Future.delayed(Duration(milliseconds: 500)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
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
                                Icon(Icons.location_off,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No farms with coordinates found.',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
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
                            zoom: 10,
                          ),
                          markers: _markers,
                          polygons: _polygons,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                        );
                      } catch (e) {
                        print('Google Maps error: $e');
                        // Show error message and fallback
                        return Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              color: Colors.orange,
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Google Maps failed to load: $e',
                                      style: TextStyle(color: Colors.white),
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
