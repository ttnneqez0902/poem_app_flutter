import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 為了加入震動回饋
import 'cloud_backup_service.dart';     // 確保路徑正確以引用 BackupException

/// 🚀 專門處理備份與還原異常的彈出對話框
class BackupErrorDialog extends StatelessWidget {
  final BackupException exception;

  const BackupErrorDialog({super.key, required this.exception});

  /// 快速顯示對話框的靜態方法
  static Future<void> show(BuildContext context, BackupException e) {
    // 增加一點觸覺回饋，讓使用者感覺到「操作被攔截」
    HapticFeedback.mediumImpact();

    return showDialog(
      context: context,
      barrierDismissible: false, // 強制使用者必須閱讀
      builder: (context) => BackupErrorDialog(exception: e),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 定義不同錯誤類型的視覺配置
    final Map<BackupExceptionType, _ErrorContent> contentMap = {
      BackupExceptionType.storage: _ErrorContent(
        title: "雲端空間不足",
        message: "您的儲存空間已滿，導致備份中斷。請清理部分雲端檔案後再重試。",
        icon: Icons.cloud_off_rounded,
        color: Colors.orange,
        actionLabel: "我知道了",
      ),
      BackupExceptionType.network: _ErrorContent(
        title: "網路連線中斷",
        message: "目前偵測不到穩定的網路連線，建議您切換至 Wi-Fi 環境以確保傳輸穩定。",
        icon: Icons.wifi_off_rounded,
        color: Colors.blue,
        actionLabel: "重試",
      ),
      BackupExceptionType.permission: _ErrorContent(
        title: "帳號登入失效",
        message: "您的雲端帳號登入資訊已過期，請重新登入以獲得存取權限。",
        icon: Icons.lock_person_rounded,
        color: Colors.red,
        actionLabel: "重新登入",
      ),
      BackupExceptionType.incomplete: _ErrorContent(
        title: "備份狀態異常",
        message: "偵測到雲端數據不完整或有正在進行中的備份，請稍候再試。",
        icon: Icons.warning_amber_rounded,
        color: Colors.amber,
        actionLabel: "重試",
      ),
      BackupExceptionType.unknown: _ErrorContent(
        title: "發生未知的錯誤",
        message: "處理備份時遇到非預期錯誤。請檢查網路並再試一次。\n代碼: ${exception.originalError.runtimeType}",
        icon: Icons.error_outline_rounded,
        color: Colors.grey,
        actionLabel: "確定",
      ),
    };

    final content = contentMap[exception.type] ?? contentMap[BackupExceptionType.unknown]!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(content.icon, size: 64, color: content.color),
      title: Text(content.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(
        content.message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: content.color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(content.actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _ErrorContent {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String actionLabel;

  _ErrorContent({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.actionLabel,
  });
}