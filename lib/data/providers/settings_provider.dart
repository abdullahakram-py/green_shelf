import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

class SettingsState {
  final int reminderLeadDays;
  final int reminderHour;
  final int reminderMinute;
  final int expiringSoonThreshold;

  const SettingsState({
    required this.reminderLeadDays,
    required this.reminderHour,
    required this.reminderMinute,
    required this.expiringSoonThreshold,
  });

  SettingsState copyWith({
    int? reminderLeadDays,
    int? reminderHour,
    int? reminderMinute,
    int? expiringSoonThreshold,
  }) {
    return SettingsState(
      reminderLeadDays: reminderLeadDays ?? this.reminderLeadDays,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      expiringSoonThreshold: expiringSoonThreshold ?? this.expiringSoonThreshold,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service = SettingsService.instance;

  SettingsNotifier()
      : super(SettingsState(
          reminderLeadDays: SettingsService.instance.reminderLeadDays,
          reminderHour: SettingsService.instance.reminderHour,
          reminderMinute: SettingsService.instance.reminderMinute,
          expiringSoonThreshold: SettingsService.instance.expiringSoonThreshold,
        ));

  Future<void> updateLeadDays(int days) async {
    await _service.setReminderLeadDays(days);
    state = state.copyWith(reminderLeadDays: days);
  }

  Future<void> updateReminderTime(int hour, int minute) async {
    await _service.setReminderTime(hour, minute);
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
  }

  Future<void> updateExpiringSoonThreshold(int days) async {
    await _service.setExpiringSoonThreshold(days);
    state = state.copyWith(expiringSoonThreshold: days);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
