import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

// ✅ 1. 補齊所有錯誤類型，解決 Member not found 報錯
enum BootStage { database, notification, finalizing, ready }
enum BootstrapError { none, databaseTimeout, permissionDenied, diskFull, unknown }

class BootstrapController {
  final ValueNotifier<BootStage> stage = ValueNotifier(BootStage.database);
  final ValueNotifier<BootstrapError> error = ValueNotifier(BootstrapError.none);
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<String> errorMessage = ValueNotifier("");
  final ValueNotifier<bool> needsConsent = ValueNotifier(false);

  // ✅ 2. 宣告 _startTime，解決 Undefined name 報錯
  DateTime? _startTime;

  Future<void> start() async {
    _startTime = DateTime.now();
    error.value = BootstrapError.none;
    errorMessage.value = "";
    needsConsent.value = false;

    try {
      // 階段 1: 臨床資料庫 (含 8 秒 Watchdog)
      _update(BootStage.database, 0.2);
      await isarService.db.timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw BootstrapError.databaseTimeout,
      );

      // 階段 2: 通知服務 (確保 UAS7 每日提醒功能正常)
      _update(BootStage.notification, 0.5);
      await notificationService.init();

      // 階段 3: 法規同意權檢查
      _update(BootStage.finalizing, 0.8);
      final prefs = await SharedPreferences.getInstance();
      final hasAccepted = prefs.getBool('has_accepted_consent') ?? false;

      if (!hasAccepted) {
        needsConsent.value = true;
        _update(BootStage.finalizing, 0.9);
      } else {
        _update(BootStage.ready, 1.0);
        _logKPI();
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> completeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_accepted_consent', true);
    needsConsent.value = false;
    _update(BootStage.ready, 1.0);
    _logKPI();
  }

  void _update(BootStage s, double p) {
    stage.value = s;
    progress.value = p;
  }

  void _handleError(Object e) {
    debugPrint("🚨 Bootstrap Error: $e");
    if (e is BootstrapError) {
      error.value = e;
      errorMessage.value = _getErrorText(e);
    } else {
      error.value = BootstrapError.unknown;
      errorMessage.value = e.toString();
    }
  }

  // ✅ 3. 確保所有方法都在 class 大括號內
  String _getErrorText(BootstrapError e) {
    switch (e) {
      case BootstrapError.databaseTimeout:
        return "臨床資料庫連線逾時，請檢查剩餘儲存空間。";
      case BootstrapError.permissionDenied:
        return "未取得必要權限，將影響 UAS7 每日提醒功能。";
      case BootstrapError.diskFull:
        return "裝置空間不足，無法載入醫療紀錄。";
      default:
        return "系統初始化異常，請聯繫技術支援。";
    }
  }

  void _logKPI() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      debugPrint("⏱️ [SaMD KPI] Boot Sequence Completed in ${duration.inMilliseconds}ms");
    }
  }
} // ✅ 確保這是最後一個括號，對應 class BootstrapController