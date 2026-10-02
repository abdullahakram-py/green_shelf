import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/food_item.dart';
import 'settings_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init({void Function(String?)? onSelectNotification}) async {
    if (_isInitialized) return;

    // Initialize Timezone
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Timezone initialization fallback: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && onSelectNotification != null) {
          onSelectNotification(response.payload);
        }
      },
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Derives notification ID from item ID and slot
  int generateNotificationId(int itemId, {int slot = 0}) {
    return (itemId * 10 + slot).abs() % 2147483647;
  }

  /// Schedule local notification for a food item
  Future<void> scheduleExpiryNotification(
    FoodItem item, {
    int? leadDays,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    if (item.id == null) return;

    final effectiveLeadDays = leadDays ?? SettingsService.instance.reminderLeadDays;
    final hour = reminderHour ?? SettingsService.instance.reminderHour;
    final minute = reminderMinute ?? SettingsService.instance.reminderMinute;

    final expiryDate = item.expiryDateTime;
    final targetDate = expiryDate.subtract(Duration(days: effectiveLeadDays));

    final targetDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );

    // If scheduled time is in past, don't schedule
    if (targetDateTime.isBefore(DateTime.now())) {
      return;
    }

    final scheduledTzDate = tz.TZDateTime.from(targetDateTime, tz.local);
    final notificationId = generateNotificationId(item.id!);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'green_shelf_expiry_channel',
      'Food Expiry Reminders',
      channelDescription: 'Alerts before food items in your pantry expire',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    String title;
    if (effectiveLeadDays == 0) {
      title = '${item.name} expires today!';
    } else if (effectiveLeadDays == 1) {
      title = '${item.name} expires tomorrow!';
    } else {
      title = '${item.name} expires in $effectiveLeadDays days';
    }

    final body =
        'You have ${item.quantity} ${item.unit} in your ${item.location}. Cook or consume it soon!';

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTzDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: item.id.toString(),
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notificationsPlugin.cancel(notificationId);
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  /// Safety net: Reschedule notifications for all active pantry items
  Future<void> rescheduleAll(List<FoodItem> items) async {
    await _notificationsPlugin.cancelAll();
    for (final item in items) {
      if (!item.isExpired()) {
        await scheduleExpiryNotification(item);
      }
    }
  }
}
