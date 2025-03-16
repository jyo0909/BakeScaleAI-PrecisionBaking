import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('theme_mode', themeMode.toString());
  }
  
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString('theme_mode') ?? 'ThemeMode.system';
      
      if (themeModeString == 'ThemeMode.light') {
        _themeMode = ThemeMode.light;
      } else if (themeModeString == 'ThemeMode.dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading theme preferences: $e');
      // Default to system theme if there's an error
      _themeMode = ThemeMode.system;
    }
  }
}