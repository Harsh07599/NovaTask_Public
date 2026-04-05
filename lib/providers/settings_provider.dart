import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class SettingsProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String? _alarmSoundPath;
  String? _alarmSoundName;
  String? _reminderSoundPath;
  String? _reminderSoundName;
  ThemeMode _themeMode = ThemeMode.dark;

  String? get alarmSoundPath => _alarmSoundPath;
  String? get alarmSoundName => _alarmSoundName;
  String? get reminderSoundPath => _reminderSoundPath;
  String? get reminderSoundName => _reminderSoundName;
  ThemeMode get themeMode => _themeMode;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> loadSettings() async {
    _alarmSoundPath = await _dbHelper.getSetting('alarm_sound_path');
    _alarmSoundName = await _dbHelper.getSetting('alarm_sound_name');
    _reminderSoundPath = await _dbHelper.getSetting('reminder_sound_path');
    _reminderSoundName = await _dbHelper.getSetting('reminder_sound_name');
    
    final themeStr = await _dbHelper.getSetting('theme_mode');
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setAlarmSound(String? path, String? name) async {
    _alarmSoundPath = path;
    _alarmSoundName = name;
    await _dbHelper.updateSetting('alarm_sound_path', path ?? '');
    await _dbHelper.updateSetting('alarm_sound_name', name ?? '');
    notifyListeners();
  }

  Future<void> setReminderSound(String? path, String? name) async {
    _reminderSoundPath = path;
    _reminderSoundName = name;
    await _dbHelper.updateSetting('reminder_sound_path', path ?? '');
    await _dbHelper.updateSetting('reminder_sound_name', name ?? '');
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _dbHelper.updateSetting('theme_mode', mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }
}
