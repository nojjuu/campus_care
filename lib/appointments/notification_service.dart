import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Call once in main() before runApp().
  static Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);

    // Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static int _nid(String appointmentId) => appointmentId.hashCode & 0x7fffffff;

  /// Reminder 30 minutes before the appointment.
  static Future<void> scheduleReminder(
      String appointmentId, DateTime appointmentTime, String reason) async {
    final when = appointmentTime.subtract(const Duration(minutes: 30));
    if (when.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _nid(appointmentId),
      'Clinic appointment reminder',
      'You have an appointment at 30 minutes: $reason',
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointments',
          'Appointment reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelReminder(String appointmentId) =>
      _plugin.cancel(_nid(appointmentId));
}
