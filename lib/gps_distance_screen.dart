import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:permission_handler/permission_handler.dart' as permission_handler;

class GpsDistanceScreen extends StatefulWidget {
  const GpsDistanceScreen({super.key});

  @override
  State<GpsDistanceScreen> createState() => _GpsDistanceScreenState();
}

class _GpsDistanceScreenState extends State<GpsDistanceScreen> with WidgetsBindingObserver {
  Position? _currentPosition;
  Position? _pointA;
  Position? _pointB;
  double _distanceInMeters = 0.0;
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _serviceDisabled = false;
  String _errorMessage = '';
  bool _isFirstVisit = true;

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, recheck permission and service status
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndInitialize();
    }
  }

  Future<void> _initializeLocation() async {
    await _checkPermissionAndInitialize();
  }

  Future<void> _checkPermissionAndInitialize() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
      _serviceDisabled = false;
      _errorMessage = '';
    });

    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _serviceDisabled = true;
          _isLoading = false;
          _errorMessage = 'Location services are disabled';
          _isFirstVisit = false;
        });
        return;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // If it's the first visit and permission is denied (not permanently), request it automatically
      if (_isFirstVisit && permission == LocationPermission.denied) {
        _isFirstVisit = false;
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
          _errorMessage = permission == LocationPermission.deniedForever
              ? 'Location permission is permanently denied'
              : 'Location permission is required';
          _isFirstVisit = false;
        });
        return;
      }

      // Permission granted, start location updates
      _isFirstVisit = false;
      await _startLocationUpdates();

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isFirstVisit = false;
        });
      }
    }
  }

  Future<void> _startLocationUpdates() async {
    // Cancel existing stream if any
    await _positionStream?.cancel();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // Update every 1 meter moved
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(
          (Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _isLoading = false;
            _errorMessage = '';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error getting location: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _checkPermissionAndInitialize();
    } else if (permission == LocationPermission.deniedForever) {
      // Show dialog to open app settings
      if (!mounted) return;

      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          title: Text(
            'Location Permission Required',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          content: Text(
            'Location permission is permanently denied. Please enable it in your device settings to use this feature.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _checkPermissionAndInitialize();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await permission_handler.openAppSettings();
                // Permission will be rechecked when app resumes
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    // Service status will be rechecked when app resumes
  }

  void _setPoint(String point) {
    if (_currentPosition != null) {
      setState(() {
        if (point == 'A') {
          _pointA = _currentPosition;
        } else {
          _pointB = _currentPosition;
        }
        _calculateDistance();
      });
    }
  }

  void _calculateDistance() {
    if (_pointA != null && _pointB != null) {
      final distance = const latlong.Distance();
      _distanceInMeters = distance(
        latlong.LatLng(_pointA!.latitude, _pointA!.longitude),
        latlong.LatLng(_pointB!.latitude, _pointB!.longitude),
      );
    }
  }

  void _resetPoints() {
    setState(() {
      _pointA = null;
      _pointB = null;
      _distanceInMeters = 0.0;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("GPS Distance"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.architecture),
            tooltip: 'Switch to Angle Mode',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.teal,
        ),
      )
          : _serviceDisabled
          ? _buildServiceDisabledWidget()
          : _permissionDenied
          ? _buildPermissionDeniedWidget()
          : _errorMessage.isNotEmpty
          ? _buildErrorWidget()
          : buildMeasurementUI(),
    );
  }

  Widget _buildServiceDisabledWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: isDark ? Colors.white54 : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Location Services Disabled',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Please enable location services in your device settings to measure distances.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openLocationSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open Location Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _checkPermissionAndInitialize,
              child: const Text(
                'Check Again',
                style: TextStyle(color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gps_off,
              size: 80,
              color: isDark ? Colors.white54 : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Location Permission Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This app needs location access to measure distances between two GPS points.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.location_on),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: isDark ? Colors.white54 : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checkPermissionAndInitialize,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMeasurementUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildRealtimeGpsDisplay(),
          _buildDistanceResultDisplay(),
          _buildPointButtons(),
        ],
      ),
    );
  }

  Widget _buildRealtimeGpsDisplay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withAlpha(100)
            : Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.my_location, color: Colors.teal, size: 20),
          const SizedBox(width: 10),
          Text(
            _currentPosition != null
                ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(5)}'
                : 'Searching...',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey[900],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceResultDisplay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          'Distance',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[700],
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'A ' + ('-' * 15) + ' B',
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.grey[600]!.withOpacity(0.6),
              fontSize: 20,
              letterSpacing: 2),
        ),
        const SizedBox(height: 10),
        Text(
          _distanceInMeters < 1000
              ? '${_distanceInMeters.toStringAsFixed(2)} m'
              : '${(_distanceInMeters / 1000).toStringAsFixed(2)} km',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey[900],
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPointButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _pointButton('A', _pointA, () => _setPoint('A')),
            _pointButton('B', _pointB, () => _setPoint('B')),
          ],
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _resetPoints,
          icon: const Icon(Icons.refresh, color: Colors.teal),
          label: const Text('Reset', style: TextStyle(color: Colors.teal)),
        )
      ],
    );
  }

  Widget _pointButton(String label, Position? point, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSet = point != null;

    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSet ? Colors.teal : (isDark ? Colors.grey[700] : Colors.grey[400]),
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(32),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        const SizedBox(height: 8),
        Text(
          isSet
              ? 'Lat: ${point!.latitude.toStringAsFixed(3)}\nLon: ${point.longitude.toStringAsFixed(3)}'
              : 'Not Set',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}