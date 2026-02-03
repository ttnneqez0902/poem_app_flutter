import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    // 🤖 Android 初始化設定
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 🍎 iOS 初始化設定 (Demo 關鍵：iPhone 才能收到通知)
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  // ============================
  // 測試通知 (立即發送)
  // ============================

  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'poem_test_channel',
      '測試通知',
      channelDescription: 'POEM 系統測試通知', // ✅ 補上 Description，符合 Google 規範
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await _notifications.show(
      999, // 測試用的 ID
      "POEM 測試成功！",
      "如果你看到這個，代表通知引擎運作正常。",
      platformDetails,
    );
  }

  // ============================
  // 權限管理 (雙平台)
  // ============================

  Future<bool> checkExactAlarmPermission() async {
    final platform = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (platform != null) {
      return await platform.canScheduleExactNotifications() ?? false;
    }
    return true; // iOS 預設不需要此特定權限
  }

  Future<void> requestPermissions() async {
    // 🤖 Android 13+ 權限請求
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    // 🍎 iOS 權限請求 (關鍵：跳出「允許通知」視窗)
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ============================
  // 每日提醒排程
  // ============================

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // ✅ 關鍵保險：先取消舊的 ID=0，避免重複堆疊
    await _notifications.cancel(0);

    await _notifications.zonedSchedule(
      0, // 固定 ID，確保每天只有一個提醒
      "POEM 檢測提醒",
      "該記錄今天的皮膚狀況囉！保持紀錄能幫助醫生更好評估療效。",
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'poem_reminder_channel',
          '每日提醒',
          channelDescription: '定時提醒填寫 POEM 問卷',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(), // ✅ 確保 iOS 也能收到排程通知
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 每天同一時間觸發
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // ============================
  // 取消所有通知
  // ============================

  Future<void> cancelAll() async => _notifications.cancelAll();
}