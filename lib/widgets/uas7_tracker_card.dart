import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Uas7TrackerCard extends StatelessWidget {
  final DateTime startDate; // 本次七日週期的起始日
  final List<bool> completionStatus; // 長度為 7 的布林列表，代表每一天是否有紀錄

  const Uas7TrackerCard({
    super.key,
    required this.startDate,
    required this.completionStatus
  });

  @override
  Widget build(BuildContext context) {
    final bool isTodayDone = _checkIfTodayDone();
    final int doneCount = completionStatus.where((done) => done).length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("UAS7 七日活性追蹤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
              Icon(isTodayDone ? Icons.check_circle : Icons.pending_actions, color: isTodayDone ? Colors.green : Colors.orange),
            ]),
            const SizedBox(height: 8),
            Text(
                isTodayDone ? "🎉 今日任務已完成 ($doneCount/7)" : "🔔 今日尚未紀錄 (目前進度 $doneCount/7)",
                style: TextStyle(fontSize: 12, color: isTodayDone ? Colors.green : Colors.grey.shade600)
            ),
            const Spacer(),
            // 🚀 七日圓圈列：顯示日期與狀態，防止病患忘記日期
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date = startDate.add(Duration(days: index));
                final bool isDone = completionStatus[index];
                final bool isToday = _isSameDay(date, DateTime.now());

                return _buildDateDot(
                  label: "D${index + 1}",
                  dateStr: DateFormat('MM/dd').format(date),
                  isDone: isDone,
                  isToday: isToday,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  bool _checkIfTodayDone() {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      if (_isSameDay(startDate.add(Duration(days: i)), now)) {
        return completionStatus[i];
      }
    }
    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateDot({required String label, required String dateStr, required bool isDone, required bool isToday}) {
    return Column(children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: isDone ? Colors.blue : (isToday ? Colors.white : Colors.grey.shade100),
          shape: BoxShape.circle,
          border: Border.all(color: (isDone || isToday) ? Colors.blue : Colors.grey.shade300, width: isToday ? 2 : 1),
          boxShadow: isToday ? [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 4)] : null,
        ),
        child: Icon(isDone ? Icons.check : Icons.circle, size: isDone ? 16 : 6, color: isDone ? Colors.white : (isToday ? Colors.blue : Colors.grey.shade300)),
      ),
      const SizedBox(height: 6),
      Text(dateStr, style: TextStyle(fontSize: 9, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? Colors.blue : Colors.grey)),
      Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
    ]);
  }
}