/// Yerel (on-device) zamanlanmış bildirimler. Gerçek push (FCM) altyapısı
/// gerektirmez — sabit saatte tekrar eden, sabit içerikli bir günlük hatırlatma
/// sağlar. Dinamik/kişiselleştirilmiş bildirimler (backend gerektirir) kapsam dışı.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const int _dailyReminderId = 1001;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService: başlatılamadı: $e');
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      final androidGranted = await androidPlugin?.requestNotificationsPermission();
      final iosGranted = await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

      return (androidGranted ?? true) && (iosGranted ?? true);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService: izin istenemedi: $e');
      return false;
    }
  }

  /// Her gün belirtilen saatte tekrar eden sabit içerikli hatırlatma kurar.
  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    if (!_initialized) await init();
    try {
      await _plugin.zonedSchedule(
        _dailyReminderId,
        '📚 DersNet Hatırlatma',
        'Bugünkü ders planını kontrol etmeyi unutma!',
        _sonrakiZaman(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Günlük Hatırlatma',
            channelDescription: 'Günlük çalışma planı hatırlatması',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService: hatırlatma zamanlanamadı: $e');
    }
  }

  static Future<void> cancel() async {
    try {
      await _plugin.cancel(_dailyReminderId);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService: iptal edilemedi: $e');
    }
  }

  static tz.TZDateTime _sonrakiZaman(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var zaman = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (zaman.isBefore(now)) {
      zaman = zaman.add(const Duration(days: 1));
    }
    return zaman;
  }
}
