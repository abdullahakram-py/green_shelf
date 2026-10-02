import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  static const String _keyLeadDays = 'reminder_lead_days';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyExpiringSoonThreshold = 'expiring_soon_threshold';
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  int get reminderLeadDays => _prefs.getInt(_keyLeadDays) ?? 1;
  Future<bool> setReminderLeadDays(int days) async => await _prefs.setInt(_keyLeadDays, days);

  int get reminderHour => _prefs.getInt(_keyReminderHour) ?? 9;
  int get reminderMinute => _prefs.getInt(_keyReminderMinute) ?? 0;
  Future<bool> setReminderTime(int hour, int minute) async {
    await _prefs.setInt(_keyReminderHour, hour);
    return await _prefs.setInt(_keyReminderMinute, minute);
  }

  int get expiringSoonThreshold => _prefs.getInt(_keyExpiringSoonThreshold) ?? 3;
  Future<bool> setExpiringSoonThreshold(int days) async =>
      await _prefs.setInt(_keyExpiringSoonThreshold, days);

  bool get hasSeenOnboarding => _prefs.getBool(_keyHasSeenOnboarding) ?? false;
  Future<bool> setHasSeenOnboarding(bool seen) async =>
      await _prefs.setBool(_keyHasSeenOnboarding, seen);
}
