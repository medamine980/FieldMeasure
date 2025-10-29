// lib/height_measurement_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class HeightMeasurementScreen extends StatefulWidget {
  const HeightMeasurementScreen({super.key});

  @override
  State<HeightMeasurementScreen> createState() => _HeightMeasurementScreenState();
}

class _HeightMeasurementScreenState extends State<HeightMeasurementScreen> with WidgetsBindingObserver {
  double _roll = 0.0;
  double _tangentOfRoll = 0.0;
  double _objectHeight = 0.0;
  double _distanceFromObject = 2.0;

  StreamSubscription<AccelerometerEvent>? _streamSubscription;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _permissionDenied = false;
  bool _isLoading = true;
  bool _isFirstVisit = true;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, recheck permission
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndInitialize();
    }
  }

  Future<void> _initialize() async {
    await _checkPermissionAndInitialize();
  }

  Future<void> _checkPermissionAndInitialize() async {
    setState(() {
      _isLoading = true;
      _isCameraInitialized = false; // Reset camera state
    });

    final status = await Permission.camera.status;

    // If it's the first visit and permission is denied (not permanently), request it automatically
    if (_isFirstVisit && status.isDenied) {
      _isFirstVisit = false;
      final requestResult = await Permission.camera.request();

      if (requestResult.isGranted) {
        await _setupCamera();
      } else {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
    } else {
      // Not first visit or already granted/permanently denied
      _isFirstVisit = false;

      if (status.isGranted) {
        await _setupCamera();
      } else {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setupCamera() async {
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }

      // Dispose old controller if exists
      await _cameraController?.dispose();
      _cameraController = null;

      await _initializeCamera();
      _startSensorStream();

      if (mounted) {
        setState(() {
          _permissionDenied = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
    }
  }

  void _startSensorStream() {
    if (_streamSubscription != null) return; // Prevent duplicate subscriptions

    _streamSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
          if (!mounted) return;
          setState(() {
            double y = event.y;
            double z = event.z;
            double rollRadians = atan2(y, z);

            rollRadians = (rollRadians - (90 * pi / 180));
            if (rollRadians < 0) rollRadians = 0;
            _roll = rollRadians * 180 / pi;
            _tangentOfRoll = tan(rollRadians);

            _objectHeight = _tangentOfRoll * _distanceFromObject;
          });
        });
  }

  Future<void> _initializeCamera() async {
    final backCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _retryPermission() async {
    setState(() {
      _isLoading = true;
    });

    final status = await Permission.camera.request();

    if (status.isGranted) {
      await _setupCamera();
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          title: Text(
            'Camera Permission Required',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          content: Text(
            'Camera permission is permanently denied. Please enable it in your device settings.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // After closing dialog, recheck permission in case user granted it
                _checkPermissionAndInitialize();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
                // Permission will be rechecked when app resumes via didChangeAppLifecycleState
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streamSubscription?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(
            color: Colors.teal,
          ))
          : _permissionDenied
          ? _buildPermissionDeniedWidget()
          : _isCameraInitialized
          ? _buildCameraView()
          : const Center(
          child: CircularProgressIndicator(
            color: Colors.teal,
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: isDark ? Colors.black.withAlpha(128) : Colors.white.withAlpha(230),
        foregroundColor: isDark ? Colors.white : Colors.grey[900],
        child: const Icon(Icons.arrow_back),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
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
              Icons.camera_alt_outlined,
              size: 80,
              color: isDark ? Colors.white54 : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This app needs camera access to measure object heights. Please grant camera permission to continue.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _retryPermission,
              icon: const Icon(Icons.camera_alt),
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

  Widget _buildCameraView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        Center(
          child: Container(
            height: 6,
            color: Colors.teal,
          ),
        ),
        Align(
          alignment: const Alignment(0.0, -0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withAlpha(128)
                  : Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDisplayColumn(
                  'Tilt Angle',
                  '${_roll.toStringAsFixed(1)}°',
                ),
                SizedBox(
                  height: 50,
                  child: VerticalDivider(
                    color: isDark ? Colors.white30 : Colors.grey[400],
                    thickness: 1,
                    width: 40,
                  ),
                ),
                _buildDisplayColumn(
                  'Height',
                  '${_objectHeight.toStringAsFixed(2)} m',
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            color: isDark
                ? Colors.black.withAlpha(128)
                : Colors.white.withAlpha(230),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Your distance from object: '
                        '${_distanceFromObject.toStringAsFixed(1)} m',
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                        fontSize: 18
                    ),
                  ),
                ),
                Slider(
                  value: _distanceFromObject,
                  min: 1,
                  max: 20,
                  divisions: 38,
                  label: _distanceFromObject.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _distanceFromObject = value;
                    });
                  },
                  activeColor: Colors.teal,
                  thumbColor: Colors.teal,
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDisplayColumn(String label, String value,
      {bool isPrimary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
      ],
    );
  }
}