import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- ENUMS ---
enum DisplayDensity { comfortable, compact }

enum StartDay { monday, sunday }

// --- THEME COLOR ENUM ---
enum AppThemeColor {
  blue(Colors.blue, 'Blue'),
  green(Colors.green, 'Green'),
  purple(Colors.purple, 'Purple'),
  orange(Colors.orange, 'Orange'),
  pink(Colors.pink, 'Pink'),
  teal(Colors.teal, 'Teal'),
  indigo(Colors.indigo, 'Indigo'),
  red(Colors.red, 'Red');

  final Color color;
  final String label;
  const AppThemeColor(this.color, this.label);
}

class SettingsManager with ChangeNotifier {
  // =======================
  // STORAGE KEYS
  // =======================
  static const String _keyStartDay = 'settings_start_day';
  static const String _keyAllNotifications =
      'settings_all_notifications_enabled';
  static const String _keyThemeColor = 'settings_theme_color';
  static const String _keyFontSizeStep = 'settings_font_size_step';
  static const String _keyCompletionSounds = 'settings_completion_sounds';
  static const String _keyHaptics = 'settings_haptics_enabled';

  // =======================
  // GENERAL
  // =======================
  StartDay _startDay = StartDay.monday;
  StartDay get startDay => _startDay;

  bool _allNotificationsEnabled = true;
  bool get allNotificationsEnabled => _allNotificationsEnabled;

  // =======================
  // UI
  // =======================
  AppThemeColor _themeColor = AppThemeColor.blue;
  AppThemeColor get themeColor => _themeColor;

  double _fontSizeStep = 1.0; // 0 = Small, 1 = Medium, 2 = Large
  double get fontSizeStep => _fontSizeStep;

  DisplayDensity _displayDensity = DisplayDensity.comfortable;
  DisplayDensity get displayDensity => _displayDensity;

  // =======================
  // SOUND & HAPTIC
  // =======================
  bool _completionSoundsEnabled = true;
  bool _hapticsEnabled = true;

  bool get completionSoundsEnabled => _completionSoundsEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  // =======================
  // LOAD SETTINGS
  // =======================
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _startDay = StartDay.values[prefs.getInt(_keyStartDay) ?? 0];
    _allNotificationsEnabled =
        prefs.getBool(_keyAllNotifications) ?? true;
    _themeColor =
        AppThemeColor.values[prefs.getInt(_keyThemeColor) ?? 0];
    _fontSizeStep = prefs.getDouble(_keyFontSizeStep) ?? 1.0;
    _completionSoundsEnabled =
        prefs.getBool(_keyCompletionSounds) ?? true;
    _hapticsEnabled = prefs.getBool(_keyHaptics) ?? true;

    debugPrint(
        '>>> Settings loaded: sound=$_completionSoundsEnabled, haptic=$_hapticsEnabled');

    notifyListeners();
  }

  // =======================
  // SAVE SETTINGS
  // =======================
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyStartDay, _startDay.index);
    await prefs.setBool(
        _keyAllNotifications, _allNotificationsEnabled);
    await prefs.setInt(_keyThemeColor, _themeColor.index);
    await prefs.setDouble(_keyFontSizeStep, _fontSizeStep);
    await prefs.setBool(
        _keyCompletionSounds, _completionSoundsEnabled);
    await prefs.setBool(
        _keyHaptics, _hapticsEnabled);
  }

  // =======================
  // SETTERS
  // =======================
  void setStartDay(StartDay newDay) {
    if (_startDay == newDay) return;
    _startDay = newDay;
    _save();
    notifyListeners();
  }

  void setAllNotifications(bool isEnabled) {
    if (_allNotificationsEnabled == isEnabled) return;
    _allNotificationsEnabled = isEnabled;
    _save();
    notifyListeners();
  }

  void setThemeColor(AppThemeColor newColor) {
    if (_themeColor == newColor) return;
    _themeColor = newColor;
    _save();
    notifyListeners();
  }

  void setFontSizeStep(double newStep) {
    if (_fontSizeStep == newStep) return;
    _fontSizeStep = newStep;
    _save();
    notifyListeners();
  }

  void setDisplayDensity(DisplayDensity newDensity) {
    if (_displayDensity == newDensity) return;
    _displayDensity = newDensity;
    notifyListeners();
  }

  void setCompletionSounds(bool isEnabled) {
    if (_completionSoundsEnabled == isEnabled) return;
    _completionSoundsEnabled = isEnabled;
    _save();
    notifyListeners();
  }

  void setHaptics(bool isEnabled) {
    if (_hapticsEnabled == isEnabled) return;
    _hapticsEnabled = isEnabled;
    _save();
    notifyListeners();
  }

  // =======================
  // HELPERS
  // =======================
  double get fontSizeMultiplier {
    switch (_fontSizeStep.round()) {
      case 0:
        return 0.9;
      case 1:
        return 1.0;
      case 2:
        return 1.25;
      default:
        return 1.0;
    }
  }

  String get fontSizeLabel {
    switch (_fontSizeStep.round()) {
      case 0:
        return 'Small';
      case 1:
        return 'Medium';
      case 2:
        return 'Large';
      default:
        return 'Medium';
    }
  }
}
