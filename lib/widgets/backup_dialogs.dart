import 'package:flutter/material.dart';

class BackupDialogs {
  /// 顯示執行中的進度彈窗（備份或恢復共用）
  static Future<void> showProcessingDialog({
    required BuildContext context,
    required String title,
    ValueNotifier<String>? progressNotifier, // ✅ 確保參數名稱正確
    ValueNotifier<double>? percentNotifier,  // 🚀 新增：進度百分比監聽 (0.0 ~ 1.0)
    required Future<void> Function() action,
  }) async {
    // 1. 先顯示彈窗，但不直接在 builder 裡跑邏輯
    final dialog = showDialog(
      context: context,
      barrierDismissible: false, // 傳輸中禁止點擊外部關閉
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // 🚀 核心優化：同時監聽「進度條長度」與「下方文字」
              ListenableBuilder(
                listenable: Listenable.merge([progressNotifier, percentNotifier]),
                builder: (context, _) {
                  final progress = percentNotifier?.value ?? -1.0; // -1 表示顯示不確定進度
                  final message = progressNotifier?.value ?? "處理中...";

                  return Column(
                    children: [
                      LinearProgressIndicator(
                        // 🚀 如果有傳入百分比，就顯示固定進度，否則跑動畫
                        value: progress < 0 ? null : progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      // 🚀 顯示百分比文字
                      if (progress >= 0)
                        Text("${(progress * 100).toInt()}%",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 24),
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    try {
      await action();
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  /// 恢復前的確認警告
  static Future<bool> confirmRestore(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("危險操作"),
          ],
        ),
        content: const Text("恢復雲端資料將「完全覆蓋」手機目前的所有紀錄與照片。此動作無法還原，確定要繼續嗎？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消"),
          ),
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