import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // ============================
  // 初始化
  // ============================

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // 初始化時先不要求權限，等使用者點擊按鈕再要求
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: settings);
  }

  // ============================
  // 權限請求
  // ============================

  Future<void> requestPermissions() async {
    // Android
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    // iOS / macOS（不指定型別，避免 Android 編譯期爆炸）
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }




  // ============================
  // 立即通知
  // ============================

  Future<void> showInstantNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'poem_test_channel',
      '測試通知',
      channelDescription: 'POEM 系統測試通知',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: 999,
      title: 'POEM 測試成功！',
      body: '如果你看到這個，代表通知引擎運作正常。',
      notificationDetails: details,
    );

  }

  // ============================
  // 每日提醒
  // ============================

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.cancel(id: 0);


    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _notifications.zonedSchedule(
      id: 0,
      title: 'POEM 檢測提醒',
      body: '該記錄今天的皮膚狀況囉！',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'poem_reminder_channel',
          '每日提醒',
          channelDescription: '定時提醒填寫 POEM 問卷',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // ============================
  // 取消
  // ============================

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}