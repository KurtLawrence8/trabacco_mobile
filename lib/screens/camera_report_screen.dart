import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../services/farm_service.dart';
import '../services/report_service.dart';
import '../models/farm.dart';

class CameraReportScreen extends StatefulWidget {
  final String? token;
  final int? technicianId;
  final bool showCloseButton;
  final String? reportType;

  const CameraReportScreen({
    Key? key,
    this.token,
    this.technicianId,
    this.showCloseButton = true, // Default to true for backward compatibility
    this.reportType,
  }) : super(key: key);

  @override
  State<CameraReportScreen> createState() => _CameraReportScreenState();
}

class _CameraReportScreenState extends State<CameraReportScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isLocationLoading = false;
  Position? _currentPosition;
  Farm? _detectedFarm;
  String? _errorMessage;
  List<Farm>? _cachedFarms;

  final _farmService = FarmService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkLocationStatus();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No cameras available';
          });
        }
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  Future<void> _checkLocationStatus() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return; // Location services disabled, user will need to enable manually
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        return; // Permission not granted, user will need to grant manually
      }

      if (permission == LocationPermission.deniedForever) {
        return; // Permission permanently denied, user will need to enable in settings
      }

      // If we already have location and farm detected, don't reload
      if (_currentPosition != null && _detectedFarm != null) {
        return;
      }

      // If we have permission, automatically get location
      await _getCurrentLocation();
    } catch (e) {
      print('Error checking location status: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isLocationLoading = true;
      });
    }

    try {
      // Get current position with timeout and medium accuracy for faster response
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationLoading = false;
        });
      }

      // Detect farm based on location
      await _detectFarm(position);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
      print('Error getting current location: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    if (mounted) {
      setState(() {
        _isLocationLoading = true;
      });
    }

    try {
      // CHECK IF LOCATION SERVICE IS ENABLED
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Location services are disabled. Please enable them.';
            _isLocationLoading = false;
          });
        }
        return;
      }

      // CHECK LOCATION PERMISSION
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Location permission denied';
              _isLocationLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Location permissions are permanently denied. Please enable them in settings.';
            _isLocationLoading = false;
          });
        }
        return;
      }

      // GET CURRENT LOCATION
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationLoading = false;
        });
      }

      // DETECT CURRENT LOCATION
      await _detectFarm(position);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to get location: $e';
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _detectFarm(Position position) async {
    try {
      // Use cached farms if available, otherwise fetch them
      List<Farm> farms = _cachedFarms ??
          await _farmService.getFarmsByTechnician(widget.token!);
      _cachedFarms ??= farms;

      Farm? detectedFarm;
      double minDistance = double.infinity;

      for (var farm in farms) {
        if (farm.coordinates != null && farm.coordinates!.isNotEmpty) {
          // PARSE POLYGON COORDINATES
          List<Map<String, double>> polygon =
              _parsePolygonCoordinates(farm.coordinates!);

          // CHECK IF POINT IS INSIDE POLYGON
          if (_isPointInPolygon(
              position.latitude, position.longitude, polygon)) {
            detectedFarm = farm;
            break;
          }

          // CALCULATE DISTANCE TO FARM CENTER AS FALLBACK
          double distance = _calculateDistance(
            position.latitude,
            position.longitude,
            farm.centerLatitude,
            farm.centerLongitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            detectedFarm = farm;
          }
        }
      }

      if (mounted) {
        setState(() {
          _detectedFarm = detectedFarm;
        });
      }
    } catch (e) {
      print('Error detecting farm: $e');
    }
  }

  List<Map<String, double>> _parsePolygonCoordinates(String coordinates) {
    // PARSE COORDINATES STRING (assuming format: "lat1,lng1;lat2,lng2;...")
    List<Map<String, double>> polygon = [];
    List<String> points = coordinates.split(';');

    for (String point in points) {
      List<String> coords = point.split(',');
      if (coords.length == 2) {
        polygon.add({
          'lat': double.parse(coords[0]),
          'lng': double.parse(coords[1]),
        });
      }
    }

    return polygon;
  }

  bool _isPointInPolygon(
      double lat, double lng, List<Map<String, double>> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i]['lat']! > lat) != (polygon[j]['lat']! > lat)) &&
          (lng <
              (polygon[j]['lng']! - polygon[i]['lng']!) *
                      (lat - polygon[i]['lat']!) /
                      (polygon[j]['lat']! - polygon[i]['lat']!) +
                  polygon[i]['lng']!)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  void _drawText(
      img.Image image, String text, int x, int y, int r, int g, int b) {
    // Use the image package's built-in text rendering
    try {
      // Try to use arial font if available
      img.drawString(image, text,
          font: img.arial14, x: x, y: y, color: img.ColorRgb8(r, g, b));
    } catch (e) {
      // Fallback - draw simple text using rectangles
      _drawSimpleText(image, text, x, y, r, g, b);
    }
  }

  void _drawSimpleText(
      img.Image image, String text, int x, int y, int r, int g, int b) {
    // Draw text as simple rectangles for each character
    int charWidth = 8;
    int charHeight = 12;

    for (int i = 0; i < text.length; i++) {
      int charX = x + (i * charWidth);
      if (charX + charWidth > image.width) break;

      // Draw a simple rectangle for each character
      for (int py = 0; py < charHeight; py++) {
        for (int px = 0; px < charWidth; px++) {
          if (charX + px < image.width && y + py < image.height) {
            image.setPixelRgba(charX + px, y + py, r, g, b, 255);
          }
        }
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_currentPosition == null) {
      await _requestLocationPermission();
      if (_currentPosition == null) return;
    }

    if (mounted) {
      setState(() {
        _isCapturing = true;
      });
    }

    try {
      final XFile photo = await _cameraController!.takePicture();

      // ADD TEXT OVERLAY TO PHOTO
      final File processedPhoto = await _addTextOverlay(photo);

      // SHOW FULL SCREEN-PREVIEW FIRST
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoPreviewScreen(
              token: widget.token,
              technicianId: widget.technicianId,
              photo: processedPhoto,
              position: _currentPosition!,
              detectedFarm: _detectedFarm,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to capture photo: $e';
          _isCapturing = false;
        });
      }
    }
  }

  Future<File> _addTextOverlay(XFile photo) async {
    // READ IMAGE
    final Uint8List imageBytes = await photo.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // GET FARM ADDRESS AND FORMAT IT
    final String farmAddress = _detectedFarm?.farmAddress ?? 'Unknown Farm';

    // Format timestamp like the example: 27/09/22 09:12 AM GMT +08:00
    final DateTime now = DateTime.now();
    final String day = now.day.toString().padLeft(2, '0');
    final String month = now.month.toString().padLeft(2, '0');
    final String year = now.year.toString().substring(2);
    final String hour = now.hour.toString().padLeft(2, '0');
    final String minute = now.minute.toString().padLeft(2, '0');
    final String ampm = now.hour < 12 ? 'AM' : 'PM';
    final String timestamp = '$day/$month/$year $hour:$minute $ampm GMT +08:00';

    // Format coordinates like the example: (16.722653, 121.684602)
    final String lat = _currentPosition!.latitude.toStringAsFixed(6);
    final String lng = _currentPosition!.longitude.toStringAsFixed(6);
    final String coordinates = '($lat, $lng)';

    // Format location like the example: 16.7225°N, 121.6846°E
    final String latFormatted = _currentPosition!.latitude.toStringAsFixed(4);
    final String lngFormatted = _currentPosition!.longitude.toStringAsFixed(4);
    final String location = '$latFormatted°N, $lngFormatted°E';

    // Create solid black overlay at bottom for text
    const int overlayHeight = 180;
    final img.Image overlay =
        img.Image(width: image.width, height: overlayHeight);
    img.fill(overlay,
        color: img.ColorRgba8(0, 0, 0, 255)); // Solid black background

    // Add text to overlay using simple text rendering
    int yOffset = 20;
    int fontSize = 14;

    // "Detected Farm:" label
    _drawText(overlay, 'Detected Farm:', 15, yOffset, 255, 255, 255);
    yOffset += fontSize + 5;

    // Farm address (main text)
    _drawText(overlay, farmAddress, 15, yOffset, 255, 255, 255);
    yOffset += fontSize + 5;

    // Coordinates in parentheses
    _drawText(overlay, coordinates, 15, yOffset, 255, 255, 255);
    yOffset += fontSize + 5;

    // Location with degrees
    _drawText(overlay, 'Location: $location', 15, yOffset, 200, 200, 200);
    yOffset += fontSize + 5;

    // Timestamp
    _drawText(overlay, 'Timestamp: $timestamp', 15, yOffset, 200, 200, 200);

    // Composite overlay onto image at the bottom
    img.compositeImage(image, overlay,
        dstX: 0, dstY: image.height - overlayHeight);

    // Save processed image
    final Directory tempDir = Directory.systemTemp;
    final String fileName =
        'report_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File processedFile = File('${tempDir.path}/$fileName');

    await processedFile.writeAsBytes(img.encodeJpg(image));

    return processedFile;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Error'),
          backgroundColor: const Color(0xFF27AE60),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // Top overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Show X button only if showCloseButton is true
                    if (widget.showCloseButton)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 30),
                      )
                    else
                      const SizedBox(width: 50), // Spacer when no X button
                    const Text(
                      'Take Report Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 50), // Spacer to center the title
                  ],
                ),
              ),
            ),
          ),

          // Location status
          if (_isLocationLoading)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Getting location...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Location info
          if (_currentPosition != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}°N, ${_currentPosition!.longitude.toStringAsFixed(4)}°E',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (_detectedFarm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Farm: ${_detectedFarm!.farmAddress}',
                        style:
                            const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Farm Size: ${_detectedFarm!.farmSize.toStringAsFixed(1)} hectares',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      if (_detectedFarm!.farmWorkers.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Farm Workers: ${_detectedFarm!.farmWorkers.map((w) => '${w.firstName} ${w.lastName}').join(', ')}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_currentPosition == null)
                      ElevatedButton.icon(
                        onPressed: _requestLocationPermission,
                        icon: const Icon(Icons.location_on),
                        label: const Text('Enable Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _isCapturing ? null : _capturePhoto,
                        icon: _isCapturing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.camera_alt, size: 30),
                        label: Text(
                          _isCapturing ? 'Capturing...' : 'Take Photo',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Photo Preview Screen - Full screen photo with embedded text
class PhotoPreviewScreen extends StatefulWidget {
  final String? token;
  final int? technicianId;
  final File photo;
  final Position position;
  final Farm? detectedFarm;

  const PhotoPreviewScreen({
    Key? key,
    this.token,
    this.technicianId,
    required this.photo,
    required this.position,
    this.detectedFarm,
  }) : super(key: key);

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  bool _showForm = false;

  Future<void> _downloadPhoto() async {
    try {
      if (kIsWeb) {
        // For web, show message that download is not available on mobile
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Download not available on mobile. Use web version for download.')),
          );
        }
      } else {
        // For mobile, save directly to device gallery
        try {
          // Check if we have permission to access gallery
          final hasAccess = await Gal.hasAccess();
          if (!hasAccess) {
            final granted = await Gal.requestAccess();
            if (!granted) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gallery permission denied'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }

          // Save the photo to gallery
          await Gal.putImageBytes(
            await widget.photo.readAsBytes(),
            name: 'report_photo_${DateTime.now().millisecondsSinceEpoch}',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo saved to gallery!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving to gallery: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen photo
          Positioned.fill(
            child: InteractiveViewer(
              child: Image.file(
                widget.photo,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 30),
                    ),
                    const Text(
                      'Photo Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _downloadPhoto(),
                      icon: const Icon(Icons.download,
                          color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Go back to camera screen to retake photo
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraReportScreen(
                              token: widget.token,
                              technicianId: widget.technicianId,
                              showCloseButton: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Retake'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _showForm = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form Modal
          if (_showForm)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ReportFormModal(
                    token: widget.token,
                    technicianId: widget.technicianId,
                    photo: widget.photo,
                    position: widget.position,
                    detectedFarm: widget.detectedFarm,
                    onClose: () {
                      if (mounted) {
                        setState(() {
                          _showForm = false;
                        });
                      }
                    },
                    onSubmit: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Report Form Modal
class ReportFormModal extends StatefulWidget {
  final String? token;
  final int? technicianId;
  final File photo;
  final Position position;
  final Farm? detectedFarm;
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  const ReportFormModal({
    Key? key,
    this.token,
    this.technicianId,
    required this.photo,
    required this.position,
    this.detectedFarm,
    required this.onClose,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<ReportFormModal> createState() => _ReportFormModalState();
}

class _ReportFormModalState extends State<ReportFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _reportService = ReportService();
  bool _isLoading = false;

  final TextEditingController _accomplishmentsController =
      TextEditingController();
  final TextEditingController _issuesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _diseaseTypeController = TextEditingController();

  String _diseaseDetected = 'None';

  @override
  void dispose() {
    _accomplishmentsController.dispose();
    _issuesController.dispose();
    _descriptionController.dispose();
    _diseaseTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF27AE60),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Complete Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Farm info with better styling
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: Colors.black, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Detected Farm Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.detectedFarm?.farmAddress ?? 'Unknown Farm',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF495057),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.my_location,
                                  color: Colors.black, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.position.latitude.toStringAsFixed(4)}°N, ${widget.position.longitude.toStringAsFixed(4)}°E',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C757D),
                                ),
                              ),
                            ],
                          ),
                          if (widget.detectedFarm != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.people,
                                    color: Colors.black, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Farm Workers: ${widget.detectedFarm!.farmWorkers.map((w) => '${w.firstName} ${w.lastName}').join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6C757D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.straighten,
                                    color: Colors.black, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Farm Size: ${widget.detectedFarm!.farmSize.toStringAsFixed(1)} hectares',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6C757D),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Accomplishments field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Accomplishments',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _accomplishmentsController,
                          decoration: InputDecoration(
                            hintText: 'Describe what you accomplished today...',
                            hintStyle: const TextStyle(fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFDEE2E6)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF27AE60), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your accomplishments';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Issues Observed field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_outlined,
                                color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Issues Observed',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _issuesController,
                          decoration: InputDecoration(
                            hintText:
                                'Describe any issues or problems you noticed...',
                            hintStyle: const TextStyle(fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFDEE2E6)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF27AE60), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter issues observed';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Disease Detection section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.health_and_safety_outlined,
                                color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Disease Detection',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _diseaseDetected,
                          decoration: InputDecoration(
                            hintText: 'Select if disease was detected',
                            hintStyle: const TextStyle(fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFDEE2E6)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF27AE60), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'None',
                                child: Text(
                                  'No Disease Detected',
                                  style: TextStyle(fontSize: 14),
                                )),
                            DropdownMenuItem(
                                value: 'Yes',
                                child: Text(
                                  'Disease Detected',
                                  style: TextStyle(fontSize: 14),
                                )),
                          ],
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {
                                _diseaseDetected = value!;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Disease Type field (conditional)
                    if (_diseaseDetected == 'Yes')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Disease Type',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              Text(
                                ' *',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _diseaseTypeController,
                            decoration: InputDecoration(
                              hintText:
                                  'Specify the type of disease detected...',
                              hintStyle: const TextStyle(fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDEE2E6)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Color(0xFF27AE60), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            validator: (value) {
                              if (_diseaseDetected == 'Yes' &&
                                  (value == null || value.isEmpty)) {
                                return 'Please specify the disease type';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    if (_diseaseDetected == 'Yes') const SizedBox(height: 20),

                    // Description field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.description_outlined,
                                color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Additional Description',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText:
                                'Provide additional details about your visit...',
                            hintStyle: const TextStyle(fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFDEE2E6)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF27AE60), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button with better styling
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitReport,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, size: 16),
                        label: Text(
                          _isLoading ? 'Submitting...' : 'Submit Report',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final report = {
        'technician_id': widget.technicianId ?? 1,
        'farm_id': widget.detectedFarm?.id ?? 1,
        'accomplishments': _accomplishmentsController.text,
        'issues_observed': _issuesController.text,
        'disease_detected': _diseaseDetected,
        'disease_type':
            _diseaseDetected == 'Yes' ? _diseaseTypeController.text : null,
        'description': _descriptionController.text,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _reportService.createReport(
        report,
        widget.token!,
        images: [widget.photo],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        widget.onSubmit();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
