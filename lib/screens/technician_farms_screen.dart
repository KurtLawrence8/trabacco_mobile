import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/farm_service.dart';
import '../models/farm.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class TechnicianFarmsScreen extends StatefulWidget {
  final int? focusFarmId; // Optional farm ID to focus on
  const TechnicianFarmsScreen({Key? key, this.focusFarmId}) : super(key: key);

  @override
  _TechnicianFarmsScreenState createState() => _TechnicianFarmsScreenState();
}

class _TechnicianFarmsScreenState extends State<TechnicianFarmsScreen> {
  // Using centralized Google Maps API key from ApiConfig

  Future<List<Farm>>? _farmsFuture;
  final FarmService _farmService = FarmService();
  final AuthService _authService = AuthService();
  bool _showMap = true; // Show map by default
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  final Set<Polyline> _polylines = {}; // For route lines
  MapType _currentMapType = MapType.hybrid; // Default map type
  Farm? _selectedFarm; // Track selected farm for bottom drawer
  double _drawerHeight = 0.5; // Drawer height as percentage of screen height
  final Location _location = Location();
  LatLng? _currentLocation;

  // Route information
  String? _routeDistance;
  String? _routeDuration;
  bool _isLoadingRoute = false;

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
      padding: const EdgeInsets.all(12),
      itemCount: farms.length,
      itemBuilder: (context, index) {
        final farm = farms[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Farm Address (full width)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm Address',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      farm.farmAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Two column layout starting from Farm Name (same as drawer)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Farm Name
                          if (farm.name != null && farm.name!.isNotEmpty) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Farm Name',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  farm.name!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Farm Area
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Farm Area',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${farm.area} sqm',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (farm.siteNumber != null &&
                              farm.siteNumber!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Site Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  farm.siteNumber!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Farmer Number
                          if (farm.farmerNumber != null &&
                              farm.farmerNumber!.isNotEmpty) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Farmer Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  farm.farmerNumber!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Data Source
                          if (farm.dataSource != null &&
                              farm.dataSource!.isNotEmpty) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data Source',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  farm.dataSource == 'kmz_upload'
                                      ? 'KMZ Upload'
                                      : 'Manual Entry',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Farm Workers (full width, below the 2-column layout)
                if (farm.farmWorkers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Assigned Workers',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...farm.farmWorkers.map((worker) {
                    try {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• ${worker.firstName} ${worker.lastName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    } catch (e) {
                      return const SizedBox.shrink();
                    }
                  }).toList(),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    'Assigned Workers',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No workers assigned',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
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
    setState(() {
      _selectedFarm = farm;
    });

    // Auto-zoom to the farm location and adjust for drawer
    final coordinates = farm.getCoordinates();
    if (coordinates != null && _mapController != null) {
      // Use a slight delay to ensure state is updated
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_mapController != null) {
          // Focus on the farm plot, but adjust the target slightly south and left
          // so the farm plot appears in the upper portion above the drawer and more centered
          final drawerOffset =
              0.003 * _drawerHeight; // Small offset based on drawer height
          final targetLat = coordinates.latitude -
              drawerOffset; // Move target slightly south so farm appears higher
          final targetLng = coordinates.longitude +
              0.001; // Move target slightly west so farm appears more to the left

          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(targetLat, targetLng),
                zoom: 16.0,
              ),
            ),
          );
        }
      });
    }
  }

  void _hideFarmDetails() {
    setState(() {
      _selectedFarm = null;
    });
  }

  void _adjustDrawerHeight(double delta) {
    setState(() {
      final newHeight =
          (_drawerHeight - delta / MediaQuery.of(context).size.height)
              .clamp(0.3, 0.8); // Min 30%, Max 80% of screen height
      _drawerHeight = newHeight;

      // Adjust camera position when drawer height changes to keep farm visible
      if (_selectedFarm != null) {
        final coordinates = _selectedFarm!.getCoordinates();
        if (coordinates != null && _mapController != null) {
          // Focus on the farm plot, but adjust target slightly south and left
          // so the farm plot appears in the upper portion above the drawer and more centered
          final drawerOffset =
              0.003 * newHeight; // Small offset based on drawer height
          final targetLat = coordinates.latitude -
              drawerOffset; // Move target slightly south so farm appears higher
          final targetLng = coordinates.longitude +
              0.001; // Move target slightly west so farm appears more to the left

          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(targetLat, targetLng),
                zoom: 16.0,
              ),
            ),
          );
        }
      }
    });
  }

  /// Get current location
  Future<LatLng?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return null;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return null;
      }

      final locationData = await _location.getLocation();
      return LatLng(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      return null;
    }
  }

  /// Show route from current location to farm
  Future<void> _showRouteToFarm(Farm farm) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current location
      final currentLoc = await _getCurrentLocation();
      if (currentLoc == null) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog(
            'Unable to get your current location. Please enable location services.');
        return;
      }

      final farmCoords = farm.getCoordinates();
      if (farmCoords == null) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Farm location not available.');
        return;
      }

      Navigator.pop(context); // Close loading dialog

      // Update state and get road route
      setState(() {
        _currentLocation = currentLoc;
        _clearRoute();
        _addCurrentLocationMarker(currentLoc);
        _isLoadingRoute = true;
        _routeDistance = null;
        _routeDuration = null;
      });

      // Get actual road route from Google Directions API
      await _getRoadRoute(currentLoc, farmCoords);
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog if still open
      }
      _showErrorDialog('Error showing route: $e');
    }
  }

  /// Clear existing route
  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _routeDistance = null;
      _routeDuration = null;
      _isLoadingRoute = false;
      // Also remove current location marker
      _markers
          .removeWhere((marker) => marker.markerId.value == 'current_location');
    });
  }

  /// Get road route from Google Directions API
  Future<void> _getRoadRoute(LatLng start, LatLng end) async {
    try {
      if (ApiConfig.googleMapsApiKey.isEmpty) {
        // Fallback to straight line if no API key is configured
        
        // Show user-friendly message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Route API key not configured. Showing direct path. Please configure Google Directions API key for real road routes.'),
              duration: Duration(seconds: 4),
            ),
          );
        }

        _drawRoute(start, end);
        return;
      }

      // Request shortest path with traffic consideration
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${start.latitude},${start.longitude}&'
          'destination=${end.latitude},${end.longitude}&'
          'mode=driving&'
          'avoid=tolls&'
          'traffic_model=best_guess&'
          'departure_time=now&'
          'key=${ApiConfig.googleMapsApiKey}';

      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);


        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          // Extract route information (distance and duration)
          String? distance, duration;
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            final leg = route['legs'][0];
            if (leg['distance'] != null) {
              distance = leg['distance']['text'];
            }
            if (leg['duration_in_traffic'] != null) {
              // Use duration_in_traffic if available (includes traffic)
              duration = leg['duration_in_traffic']['text'];
            } else if (leg['duration'] != null) {
              // Fallback to regular duration
              duration = leg['duration']['text'];
            }
          }

          // Use the overview_polyline which contains the complete route path
          if (route['overview_polyline'] != null &&
              route['overview_polyline']['points'] != null) {
            final overviewPolyline =
                route['overview_polyline']['points'] as String;

            final routePoints = _decodePolyline(overviewPolyline);

            if (routePoints.isNotEmpty) {
              setState(() {
                _polylines.clear(); // Clear existing routes
                _polylines.add(
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: routePoints,
                    color: const Color(0xFF4285F4), // Changed to blue
                    width: 6, // Slightly thicker for better visibility
                    patterns: [PatternItem.dash(25), PatternItem.gap(15)],
                  ),
                );

                // Update route information
                _routeDistance = distance;
                _routeDuration = duration;
                _isLoadingRoute = false;
              });

              // Update camera bounds to show the full route
              if (_mapController != null && routePoints.isNotEmpty) {
                final bounds = _calculateBoundsFromPoints(routePoints);
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 120.0),
                );
              }
            } else {
              _drawRoute(start, end);
            }
          } else {
            _drawRoute(start, end);
          }
        } else {
                    // Fallback to straight line if API fails
          _drawRoute(start, end);
        }
      } else {
        // Fallback to straight line if request fails
        _drawRoute(start, end);
      }
    } catch (e) {
      // Fallback to straight line
      _drawRoute(start, end);
    }
  }

  /// Decode Google polyline string to list of LatLng points
  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  /// Calculate bounds from a list of points
  LatLngBounds _calculateBoundsFromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLng = minLng > point.longitude ? point.longitude : minLng;
      maxLng = maxLng < point.longitude ? point.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Draw route from current location to farm (fallback method)
  void _drawRoute(LatLng start, LatLng end) {
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [start, end],
          color: const Color(0xFF4285F4), // Changed to blue
          width: 6,
          patterns: [PatternItem.dash(25), PatternItem.gap(15)],
        ),
      );
      _isLoadingRoute = false;
      _routeDistance = null; // No distance info for straight line
      _routeDuration = null; // No duration info for straight line
    });
  }

  /// Add current location marker
  void _addCurrentLocationMarker(LatLng location) {
    setState(() {
      // Remove existing current location marker if any
      _markers
          .removeWhere((marker) => marker.markerId.value == 'current_location');

      // Add new current location marker
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'My Location',
            snippet: 'You are here',
          ),
        ),
      );
    });
  }

  /// Open Google Maps with route to farm
  Future<void> _openInGoogleMaps(Farm farm) async {
    try {
      // Get current location first
      final currentLoc = await _getCurrentLocation();
      final farmCoords = farm.getCoordinates();

      if (currentLoc == null) {
        _showErrorDialog(
            'Unable to get your current location. Please enable location services.');
        return;
      }

      if (farmCoords == null) {
        _showErrorDialog('Farm location not available.');
        return;
      }

      // Open Google Maps with route
      final url =
          'https://www.google.com/maps/dir/${currentLoc.latitude},${currentLoc.longitude}/${farmCoords.latitude},${farmCoords.longitude}';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog(
            'Could not open Google Maps. Please make sure Google Maps is installed.');
      }
    } catch (e) {
      _showErrorDialog('Error opening Google Maps: $e');
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Build the bottom drawer for farm details
  Widget _buildFarmDetailsDrawer(Farm farm) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _selectedFarm != null ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {}, // Prevent tap from closing drawer when tapping inside
        child: Container(
          height: MediaQuery.of(context).size.height * _drawerHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              GestureDetector(
                onPanUpdate: (details) {
                  _adjustDrawerHeight(details.delta.dy);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Farm Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: IconButton(
                        onPressed: _hideFarmDetails,
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farm Information Section
                      Text(
                        'Farm Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Farm Address (full width)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Farm Address',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            farm.farmAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Two column layout starting from Farm Name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Farm Name
                                if (farm.name != null &&
                                    farm.name!.isNotEmpty) ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Farm Name',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        farm.name!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Farm Area
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Farm Area',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${farm.area} sqm',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (farm.siteNumber != null &&
                                    farm.siteNumber!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Site Number',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        farm.siteNumber!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Right column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Farmer Number
                                if (farm.farmerNumber != null &&
                                    farm.farmerNumber!.isNotEmpty) ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Farmer Number',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        farm.farmerNumber!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Data Source
                                if (farm.dataSource != null &&
                                    farm.dataSource!.isNotEmpty) ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Data Source',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        farm.dataSource == 'kmz_upload'
                                            ? 'KMZ Upload'
                                            : 'Manual Entry',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Farm Workers Section
                      _buildDrawerSection(
                        title: 'Farm Workers',
                        children: [
                          if (farm.farmWorkers.isNotEmpty) ...[
                            ...farm.farmWorkers.map((worker) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF27AE60)
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${worker.firstName[0]}${worker.lastName[0]}',
                                            style: const TextStyle(
                                              color: Color(0xFF27AE60),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${worker.firstName} ${worker.lastName}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            Text(
                                              'Farm Worker',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ] else ...[
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'No workers assigned to this farm',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Route Navigation Buttons
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          // Show route on map
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showRouteToFarm(farm),
                              icon: const Icon(Icons.directions_car,
                                  color: Colors.white, size: 18),
                              label: const Text(
                                'Show Route',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF27AE60),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Open in Google Maps
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openInGoogleMaps(farm),
                              icon: const Icon(Icons.open_in_new,
                                  color: Colors.white, size: 18),
                              label: const Text(
                                'Open Maps',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4285F4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Route Information Display
                      if (_isLoadingRoute) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue[600]!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Calculating route...',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_routeDistance != null ||
                          _routeDuration != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.directions,
                                  color: Colors.blue[600], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    if (_routeDistance != null) ...[
                                      Icon(Icons.straighten,
                                          color: Colors.blue[600], size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _routeDistance!,
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                    if (_routeDistance != null &&
                                        _routeDuration != null)
                                      const SizedBox(width: 16),
                                    if (_routeDuration != null) ...[
                                      Icon(Icons.access_time,
                                          color: Colors.blue[600], size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _routeDuration!,
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section in the drawer
  Widget _buildDrawerSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: _showMap,
      appBar: AppBar(
        title: const Text('Assigned Farms'),
        centerTitle: true,
        backgroundColor:
            _showMap ? Colors.transparent : const Color(0xFF27AE60),
        elevation: _showMap ? 0 : null,
        iconTheme: _showMap
            ? const IconThemeData(color: Colors.white)
            : const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showMap ? Icons.list : Icons.map,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          _farmsFuture == null
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
                        .where(
                            (farm) => farm.getPolygonCoordinates().isNotEmpty)
                        .toList();
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
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
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

                    if (_showMap) {
                      // Show map view
                      _createMarkers(farms);
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
                          polylines: _polylines,
                          mapType: _currentMapType, // Use selected map type
                          zoomControlsEnabled: true, // Enable zoom controls
                          zoomGesturesEnabled: true, // Enable zoom gestures
                          scrollGesturesEnabled: true, // Enable pan gestures
                          tiltGesturesEnabled: true, // Enable tilt gestures
                          rotateGesturesEnabled: true, // Enable rotate gestures
                          compassEnabled: false, // Disable compass icon
                          myLocationButtonEnabled:
                              false, // Disable location button
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
                        // Show error message and fallback
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.orange,
                              child: Row(
                                children: [
                                  const Icon(Icons.warning,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Google Maps failed to load: $e',
                                      style:
                                          const TextStyle(color: Colors.white),
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
                    } else {
                      // Show list view
                      return _buildFarmList(farms);
                    }
                  },
                ),
          // Bottom drawer overlay
          if (_selectedFarm != null) _buildFarmDetailsDrawer(_selectedFarm!),
        ],
      ),
    );
  }
}

