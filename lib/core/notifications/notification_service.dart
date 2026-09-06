import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  void Function(String mapId, String nodeId)? onTaskNotificationTap;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> checkLaunchNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (details?.didNotificationLaunchApp == true && response != null) {
      _handleTap(response);
    }
  }

  void _handleTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final parts = payload.split('|');
    if (parts.length != 2) return;
    onTaskNotificationTap?.call(parts[0], parts[1]);
  }

  Future<void> scheduleTaskReminder({
    required String mapId,
    required String nodeId,
    required String title,
    required DateTime dueDate,
  }) async {
    if (dueDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: _notificationId(nodeId),
      title: 'Task due: $title',
      body: 'This idea was marked as a task in MindScape.',
      scheduledDate: tz.TZDateTime.from(dueDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'mindscape_tasks',
          'Task reminders',
          channelDescription: 'Reminders for nodes converted to tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // "|" is safe as a separator — generateId()/Firestore doc ids
      // never contain it.
      payload: '$mapId|$nodeId',
    );
  }

  Future<void> cancelTaskReminder(String nodeId) async {
    await _plugin.cancel(id: _notificationId(nodeId));
  }

  int _notificationId(String nodeId) => nodeId.hashCode & 0x7fffffff;
}
