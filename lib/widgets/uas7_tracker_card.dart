import 'package:flutter/material.dart';

class Uas7TrackerCard extends StatelessWidget {
  final int completedCount; // 過去 7 天內完成的天數 (0~7)
  final bool isTodayDone;   // 今天是否已完成紀錄

  const Uas7TrackerCard({
    super.key,
    required this.completedCount,
    required this.isTodayDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題與狀態圖示
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                    "UAS7 七日活性追蹤",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)
                ),
                Icon(
                    isTodayDone ? Icons.check_circle : Icons.pending_actions,
                    color: isTodayDone ? Colors.green : Colors.orange
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 狀態提示文字
            Text(
              isTodayDone
                  ? "🎉 今日任務已完成 ($completedCount/7)"
                  : "🔔 今日尚未紀錄（目前進度 $completedCount/7）",
              style: TextStyle(
                  fontSize: 12,
                  color: isTodayDone ? Colors.green : Colors.grey.shade600
              ),
            ),
            const SizedBox(height: 20),

            // 🚀 核心：七日進度球列 (由左至右點亮)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                // 邏輯判定：
                // 1. 已完成 (isActive)：索引小於完成天數
                // 2. 當前目標 (isCurrent)：索引等於完成天數，且今天還沒做
                bool isActive = index < completedCount;
                bool isCurrent = index == completedCount && !isTodayDone;

                return _buildStepCircle(
                  label: "D${index + 1}",
                  isActive: isActive,
                  isCurrent: isCurrent,
                  isDarkMode: isDarkMode,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle({
    required String label,
    required bool isActive,
    required bool isCurrent,
    required bool isDarkMode,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 32, height: 32,
          decoration: BoxDecoration(
            // 已完成用藍色，當前目標用白底藍框，未完成用灰色
            color: isActive ? Colors.blue : (isCurrent ? Colors.white : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100)),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isActive || isCurrent) ? Colors.blue : Colors.grey.shade300,
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: isCurrent ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4)] : null,
          ),
          child: Icon(
            isActive ? Icons.check : Icons.circle,
            size: isActive ? 16 : 8,
            color: isActive ? Colors.white : (isCurrent ? Colors.blue : Colors.grey.shade400),
          ),
        ),
        const SizedBox(height: 6),
        Text(
            label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? Colors.blue : Colors.grey
            )
        ),
      ],
    );
  }
}