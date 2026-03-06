import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance =
  NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ============================
  // 初始化通知系統
  // ============================
// 🚀 將原本的 init() 改成需要傳入 onPayloadReceived
  Future<void> init({required void Function(String?) onPayloadReceived}) async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ✅ 確認簽名：initialize({ required settings, onDidReceive...? })
    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("💡 使用者點擊通知，Payload: ${response.payload}");
        // 🚀 觸發回調，把 payload 傳給 main.dart
        onPayloadReceived(response.payload);
      },
    );

    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          'health_reminder_channel',
          '健康追蹤提醒',
          description: '提醒使用者填寫健康追蹤資料',
          importance: Importance.max,
        ),
      );
    }
    await requestPermissions();
    _initialized = true;
  }

  // ============================
  // 權限請求
  // ============================
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await android?.requestNotificationsPermission();
      // 🚀 3. 新增這行：請求「精確鬧鐘」權限 (Pixel 9 Pro 必備！)
      await android?.requestExactAlarmsPermission();
    }

    if (Platform.isIOS) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // ============================
  // 每日提醒
  // ============================
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload, // 🚀 新增這行
  }) async {
    // ✅ 確認簽名：cancel({ required id, tag? })
    await _notifications.cancel(id: id);
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    // ✅ 確認簽名：zonedSchedule({ required id, required scheduledDate,
    //    required notificationDetails, required androidScheduleMode,
    //    title?, body?, ... })
    await _notifications.zonedSchedule(
      id: id,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'health_reminder_channel',
          '健康追蹤提醒',
          channelDescription: '提醒使用者填寫健康追蹤資料',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload, // 🚀 將 payload 塞進去
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ============================
  // 計算下一次提醒時間
  // ============================
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
  // 每週提醒排程 (POEM / ADCT / SCORAD)
  // ============================
  Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek, // 1 = 週一, 7 = 週日 (符合 DateTime 規範)
    required int hour,
    required int minute,
    required String payload, // 🚀 新增這行
  }) async {
    await _notifications.cancel(id: id);

    final scheduledDate = _nextInstanceOfDayAndTime(dayOfWeek, hour, minute);

    await _notifications.zonedSchedule(
      id: id,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'health_reminder_channel',
          '健康追蹤提醒',
          channelDescription: '提醒使用者填寫健康追蹤資料',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload, // 🚀 將 payload 塞進去
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ============================
  // 計算下一次的「星期幾 + 時間」
  // ============================
  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    // 如果今天不是指定的星期幾，就往後加一天，直到對上為止
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // ============================
  // 測試通知
  // ============================
  Future<void> showInstantNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        '系統測試',
        channelDescription: '測試通知',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    // ✅ 確認簽名：show({ required id, title?, body?, notificationDetails?, payload? })
    await _notifications.show(
      id: 999,
      title: '測試成功',
      body: '通知系統正常運作',
      notificationDetails: details,
    );
  }

  // ============================
  // 獲取冷啟動時的 Payload
  // ============================
  Future<String?> getColdStartPayload() async {
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      return details.notificationResponse?.payload;
    }
    return null;
  }

  // ============================
  // 取消單個通知
  // ============================
  Future<void> cancel(int id) async {
    await _notifications.cancel(id: id);
  }

  // ============================
  // 取消全部通知
  // ============================
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}