import 'package:flutter/material.dart';

class BackupDialogs {
  /// 顯示執行中的進度彈窗（備份或恢復共用）
  static Future<void> showProcessingDialog({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // 傳輸中不准亂點
      builder: (BuildContext context) {
        // 使用一個內部的 Future 來執行邏輯，並在完成後自動關閉彈窗
        action().then((_) {
          if (Navigator.canPop(context)) Navigator.pop(context);
        }).catchError((err) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          _showErrorSnackBar(context, err.toString());
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  /// 錯誤提示 SnackBar
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("發生錯誤: $message"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 恢復前的確認警告
  static Future<bool> confirmRestore(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ 警告"),
        content: const Text("恢復雲端資料將覆蓋手機目前的所有紀錄。建議恢復前先進行備份。確定要繼續嗎？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("取消")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("確認覆蓋", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }
}