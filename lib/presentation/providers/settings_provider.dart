/// Cihaz-yerel uygulama ayarları (tema, yazı boyutu, hatırlatma tercihi).
/// Buluta senkronlanmaz — her cihazın kendi tercihi olması beklenir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import 'profil_provider.dart';

const String _settingsStorageKey = 'app_settings';

class SettingsState {
  final ThemeMode themeMode;
  final double textScale;
  final bool dailyReminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.dailyReminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? dailyReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'textScale': textScale,
        'dailyReminderEnabled': dailyReminderEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? false,
      reminderHour: json['reminderHour'] as int? ?? 20,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final storage = _ref.read(localStorageServiceProvider);
    final map = await storage.getMap(_settingsStorageKey);
    if (map != null) {
      state = SettingsState.fromJson(map);
    }
  }

  Future<void> _persist() async {
    final storage = _ref.read(localStorageServiceProvider);
    await storage.setMap(_settingsStorageKey, state.toJson());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _persist();
  }

  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale);
    await _persist();
  }

  Future<void> setDailyReminder({required bool enabled, int? hour, int? minute}) async {
    state = state.copyWith(
      dailyReminderEnabled: enabled,
      reminderHour: hour,
      reminderMinute: minute,
    );
    await _persist();

    if (enabled) {
      final granted = await NotificationService.requestPermissions();
      if (granted) {
        await NotificationService.scheduleDailyReminder(state.reminderHour, state.reminderMinute);
      } else {
        state = state.copyWith(dailyReminderEnabled: false);
        await _persist();
      }
    } else {
      await NotificationService.cancel();
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
