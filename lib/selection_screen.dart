// lib/selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fieldmeasure/distance_measurement_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'height_measurement_screen.dart';
import 'theme_provider.dart';
import 'settings_screen.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          title: Text(
            'About FieldMeasure',
            style: TextStyle(color: isDark ? Colors.teal : Colors.teal[700]),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'This app helps you measure distances and heights using your phone\'s sensors.\nIt may be used by people working in the field (such as lumberjacks or construction workers), or even for fun.\n\nThe app\'s accuracy depends on the phone sensor\'s accuracy',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Created by Mohamed-Amine Benali',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => launchUrl(
                      Uri.parse('https://linkedin.com/in/mohamed-amine-benali')),
                  child: Text(
                    'LinkedIn',
                    style: TextStyle(
                      color: Colors.teal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () =>
                      launchUrl(Uri.parse('https://github.com/medamine980')),
                  child: Text(
                    'GitHub',
                    style: TextStyle(
                      color: Colors.teal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close', style: TextStyle(color: Colors.teal)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    const appcastURL = 'https://raw.githubusercontent.com/medamine980/FieldMeasure/main/appcast.xml';

    return UpgradeAlert(
      upgrader: Upgrader(
        storeController: UpgraderStoreController(
          onAndroid: () => UpgraderAppcastStore(
            appcastURL: appcastURL,
            osVersion: Version(0, 0, 0),
          ),
          oniOS: () => UpgraderAppcastStore(
            appcastURL: appcastURL,
            osVersion: Version(0, 0, 0),
          ),
        ),
        durationUntilAlertAgain: const Duration(hours: 3),
        debugDisplayAlways: false,
        debugLogging: true,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () => _showAboutDialog(context),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/app_logo_helmet_black.png'),
            ),
          ),
          title: const Text('FieldMeasure'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.height),
                  label: const Text('Get Height'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontFamily: 'RobotoCondensed',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HeightMeasurementScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.straighten),
                  label: const Text('Get Distance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontFamily: 'RobotoCondensed',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const DistanceMeasurementScreenWithTutorial()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}