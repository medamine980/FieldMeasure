// lib/distance_measurement_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:fieldmeasure/gps_distance_screen.dart';
import 'angle_painter.dart';

// --- WIDGET 1: THE PARENT WIDGET THAT CONTROLS THE TUTORIAL ---
class DistanceMeasurementScreenWithTutorial extends StatefulWidget {
  const DistanceMeasurementScreenWithTutorial({super.key});

  @override
  State<DistanceMeasurementScreenWithTutorial> createState() =>
      _DistanceMeasurementScreenWithTutorialState();
}

class _DistanceMeasurementScreenWithTutorialState
    extends State<DistanceMeasurementScreenWithTutorial> {
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();
    _setupShowcase();
  }

  Future<void> _setupShowcase() async {
    ShowcaseView.register(
      blurValue: 0.7,
      autoPlayDelay: const Duration(seconds: 3),
    );

    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenDistanceTutorial') ?? false;

    if (!hasSeenTutorial) {
      setState(() => _showAnimation = true);
      await prefs.setBool('hasSeenDistanceTutorial', true);
    }
  }

  void _onTutorialAnimationDone() {
    setState(() => _showAnimation = false);

    Future.delayed(const Duration(milliseconds: 500), () {
      ShowcaseView.get().startShowCase([
        DistanceMeasurementScreen.keyKnownDistance,
        DistanceMeasurementScreen.keySetReference,
        DistanceMeasurementScreen.keyResult,
      ]);
    });
  }

  void _showTutorialWithAnimation() {
    setState(() => _showAnimation = true);
  }

  // NEW: Check if showcase is active
  bool _isShowcaseActive() {
    return ShowcaseView.get().isShowCaseCompleted == false;
  }

  // NEW: Handle back button press
  Future<bool> _onWillPop() async {
    // If Lottie animation is showing, dismiss it
    if (_showAnimation) {
      setState(() => _showAnimation = false);
      return false; // Prevent default back behavior
    }

    // If showcase is active, dismiss it
    if (_isShowcaseActive()) {
      ShowcaseView.get().dismiss();
      return false; // Prevent default back behavior
    }

    // Allow normal back navigation
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Stack(
        children: [
          DistanceMeasurementScreen(
            onShowTutorial: _showTutorialWithAnimation,
          ),

          // LOTTIE OVERLAY
          if (_showAnimation)
            GestureDetector(
              onTap: _onTutorialAnimationDone,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 300,
                        height: 250,
                        child: Lottie.asset(
                          'assets/Measurement_Toolkit_tutorial_v2.json',
                          repeat: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to skip and continue',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
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


// --- WIDGET 2: THE UI SCREEN ---
class DistanceMeasurementScreen extends StatefulWidget {
  final VoidCallback? onShowTutorial;

  const DistanceMeasurementScreen({super.key, this.onShowTutorial});

  static final GlobalKey keyKnownDistance = GlobalKey();
  static final GlobalKey keySetReference = GlobalKey();
  static final GlobalKey keyResult = GlobalKey();

  @override
  State<DistanceMeasurementScreen> createState() =>
      _DistanceMeasurementScreenState();
}

class _DistanceMeasurementScreenState extends State<DistanceMeasurementScreen> {
  double _heading = 0.0;
  double? _referenceHeading;
  double _angle = 0.0;
  double _knownDistance = 10.0;
  double _resultDistance = 0.0;

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  @override
  void initState() {
    super.initState();
    _magnetometerSubscription =
        magnetometerEventStream().listen((MagnetometerEvent event) {
          if (!mounted) return;
          setState(() {
            _heading = (atan2(event.y, event.x) * 180 / pi);
            if (_referenceHeading != null) {
              double difference = _heading - _referenceHeading!;
              if (difference.abs() > 180) {
                difference = difference > 0 ? difference - 360 : difference + 360;
              }
              _angle = difference;
              if (_angle.abs() >= 1) {
                _resultDistance = _knownDistance * tan(_angle.abs() * pi / 180);
              } else {
                _resultDistance = 0.0;
              }
            }
          });
        });
  }

  void _setReferencePoint() {
    setState(() {
      _referenceHeading = _heading;
      _angle = 0;
    });
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Measure Distance"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Show Tutorial',
            onPressed: () {
              if (widget.onShowTutorial != null) {
                widget.onShowTutorial!();
              } else {
                ShowcaseView.get().startShowCase([
                  DistanceMeasurementScreen.keyKnownDistance,
                  DistanceMeasurementScreen.keySetReference,
                  DistanceMeasurementScreen.keyResult,
                ]);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.gps_fixed),
            tooltip: 'Switch to GPS Mode',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GpsDistanceScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: AnglePainter(
                  angleInDegrees: _angle,
                  hasReference: _referenceHeading != null,
                  isAngleTooLarge: _angle.abs() >= 90,
                  isDarkMode: isDark,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Showcase(
                key: DistanceMeasurementScreen.keyKnownDistance,
                title: 'Step 1: Look at Your Object & Move',
                description:
                'First, spot your object. Now, walk straight to your side for a known distance (e.g., 5 meters). Use this slider to enter that distance.',
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  color: isDark
                      ? Colors.black.withAlpha(100)
                      : Colors.white.withAlpha(230),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Known Distance: ${_knownDistance.toStringAsFixed(1)} m',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                          fontSize: 16,
                        ),
                      ),
                      Slider(
                        value: _knownDistance,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        label: _knownDistance.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _knownDistance = value;
                          });
                        },
                        activeColor: Colors.teal,
                        thumbColor: Colors.teal,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24.0),
                color: isDark
                    ? Colors.black.withAlpha(100)
                    : Colors.white.withAlpha(230),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildResultDisplay(
                            "Angle", '${_angle.abs().toStringAsFixed(1)}°'),
                        Showcase(
                          key: DistanceMeasurementScreen.keyResult,
                          title: 'Step 3: Measure!',
                          description:
                          'Finally, slowly turn your phone to aim back at the object. The calculated distance will appear here instantly!',
                          child: _buildResultDisplay(
                              "Distance",
                              _resultDistance <= 0
                                  ? '---'
                                  : '${_resultDistance.toStringAsFixed(2)} m'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Showcase(
                      key: DistanceMeasurementScreen.keySetReference,
                      title: 'Step 2: Set Your Reference',
                      description:
                      "Great! Now that you've moved, aim your phone back at the exact spot where you were first standing and tap this button.",
                      child: ElevatedButton(
                        onPressed: _setReferencePoint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          textStyle: const TextStyle(
                              fontFamily: 'RobotoCondensed',
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text(_referenceHeading == null
                            ? 'Set Reference'
                            : 'Reset Reference'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultDisplay(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey[900],
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}