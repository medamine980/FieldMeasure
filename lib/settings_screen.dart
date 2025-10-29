// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedUnit;
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedUnit = 'meters';
    _selectedLanguage = 'English';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Appearance Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Colors.grey[800] : Colors.grey[100],
            ),
            child: ListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Toggle between light and dark theme'),
              trailing: CustomThemeToggle(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
          ),

          // Measurements Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
            child: Text(
              'Measurements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Colors.grey[800] : Colors.grey[100],
            ),
            child: ListTile(
              title: const Text('Unit System'),
              subtitle: const Text('Choose your preferred measurement unit'),
              trailing: DropdownButton<String>(
                value: _selectedUnit,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'meters', child: Text('Meters (m)')),
                  DropdownMenuItem(value: 'feet', child: Text('Feet (ft)')),
                  DropdownMenuItem(value: 'kilometers', child: Text('Kilometers (km)')),
                  DropdownMenuItem(value: 'miles', child: Text('Miles (mi)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value!;
                  });
                },
              ),
            ),
          ),

          // Language Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
            child: Text(
              'Language',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Colors.grey[800] : Colors.grey[100],
            ),
            child: ListTile(
              title: const Text('App Language'),
              subtitle: const Text('Select your preferred language'),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Français', child: Text('Français')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Custom Theme Toggle Widget
class CustomThemeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomThemeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? Colors.teal[700] : Colors.teal[300],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}