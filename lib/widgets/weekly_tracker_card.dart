import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';

class WeeklyTrackerCard extends StatelessWidget {
  final ScaleType type;
  final List<PoemRecord> history;

  const WeeklyTrackerCard({super.key, required this.type, required this.history});

  @override
  Widget build(BuildContext context) {
    // 抓取最新紀錄為基準點
    final lastRecord = history.isNotEmpty ? history.first : null;
    final DateTime baseDate = lastRecord?.date ?? DateTime.now();
    final schedule = List.generate(4, (i) => baseDate.add(Duration(days: i * 7)));

    final String title = _getScaleTitle(type);
    final Color color = _getScaleColor(type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
              Icon(Icons.calendar_today_rounded, color: color.withOpacity(0.5)),
            ]),
            const SizedBox(height: 8),
            Text(
                lastRecord != null ? "上次檢測：${DateFormat('MM/dd').format(baseDate)}" : "尚未開始每週週期檢測",
                style: const TextStyle(fontSize: 14, color: Colors.grey)
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                final date = schedule[index];
                bool isDone = (index == 0 && lastRecord != null);
                bool isToday = (DateFormat('MM/dd').format(DateTime.now()) == DateFormat('MM/dd').format(date));

                return Column(children: [
                  Container(
                    width: 48, height: 48, // 🚀 稍微加大圓圈，確保不擁擠
                    decoration: BoxDecoration(
                        color: isDone ? color : (isToday ? Colors.white : Colors.grey.shade50),
                        shape: BoxShape.circle,
                        border: Border.all(color: (isDone || isToday) ? color : Colors.grey.shade300, width: 2),
                        boxShadow: isToday ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6)] : null
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                          : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        // 🚀 關鍵：FittedBox 確保文字自動縮放，絕對不換行
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                              DateFormat('MM/dd').format(date),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isToday ? color : Colors.grey)
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      isDone ? "已完成" : (isToday ? "今日待測" : "預計"),
                      style: TextStyle(fontSize: 11, color: isToday ? color : Colors.grey, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)
                  ),
                ]);
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _getScaleTitle(ScaleType t) {
    if (t == ScaleType.adct) return "ADCT 控制評估";
    if (t == ScaleType.poem) return "POEM 每週檢測";
    return "SCORAD 強度評估";
  }

  Color _getScaleColor(ScaleType t) {
    if (t == ScaleType.adct) return Colors.teal;
    if (t == ScaleType.poem) return Colors.blue;
    return Colors.indigo;
  }
}