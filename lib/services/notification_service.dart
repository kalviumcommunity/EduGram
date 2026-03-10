import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPush = 'notif_push';
const _kNewReg = 'notif_new_reg';
const _kUpdates = 'notif_updates';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  int _nextId = 0;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<bool> _isEnabled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // Master push switch must be ON AND the specific toggle must be ON
    final masterOn = prefs.getBool(_kPush) ?? true;
    final toggleOn = prefs.getBool(key) ?? true;
    return masterOn && toggleOn;
  }

  Future<void> _show({
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(_nextId++, title, body, details);
  }

  /// Called when a NEW student is registered
  Future<void> notifyNewStudent(String name) async {
    if (!await _isEnabled(_kNewReg)) return;
    await _show(
      title: '🎓 New Student Registered',
      body: '$name has been added to the system.',
      channelId: 'new_registrations',
      channelName: 'New Registrations',
    );
  }

  /// Called when a NEW teacher is added
  Future<void> notifyNewTeacher(String name) async {
    if (!await _isEnabled(_kNewReg)) return;
    await _show(
      title: '👨‍🏫 New Teacher Added',
      body: '$name has joined as a teacher.',
      channelId: 'new_registrations',
      channelName: 'New Registrations',
    );
  }

  /// Called when a NEW batch is created
  Future<void> notifyNewBatch(String name) async {
    if (!await _isEnabled(_kUpdates)) return;
    await _show(
      title: '📚 New Batch Created',
      body: 'Batch "$name" has been added to the system.',
      channelId: 'system_updates',
      channelName: 'System Updates',
    );
  }
}
