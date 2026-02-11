import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../screens/poem_survey_screen.dart';

class Uas7TrackerCard extends StatefulWidget {
  final DateTime startDate;
  final List<bool> completionStatus;
  final List<PoemRecord> history;

  const Uas7TrackerCard({
    super.key,
    required this.startDate,
    required this.completionStatus,
    required this.history,
  });

  @override
  State<Uas7TrackerCard> createState() => _Uas7TrackerCardState();
}

class _Uas7TrackerCardState extends State<Uas7TrackerCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final int index = today.difference(widget.startDate).inDays;

    if (index >= 0 && index < widget.completionStatus.length) {
      double itemWidth = 64.0;
      double offset = (index * itemWidth);
      double screenWidth = MediaQuery.of(context).size.width;
      double centerOffset = offset - (screenWidth / 2) + (itemWidth / 2) + 20;

      _scrollController.animateTo(
        centerOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTodayDone = _checkIfTodayDone();
    final Color themeColor = Colors.teal;

    // 🚀 計算下次預計日期 (明天)
    final DateTime nextDate = DateTime.now().add(const Duration(days: 1));
    final String nextExpectedDate = DateFormat('MM/dd').format(nextDate);

    return Card(
      // 🚀 關鍵修改：將 horizontal: 20 改為 4 (或 0)
      // 這樣就不會與 PageView 的 viewportFraction 產生的間距疊加，導致空白過大
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 標題列
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("UAS7 七日蕁麻疹追蹤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blueGrey)),
                Icon(isTodayDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: isTodayDone ? Colors.green : Colors.orange, size: 24),
              ],
            ),
            const SizedBox(height: 4),

            // 🚀 2. 修正點：補回消失的狀態文字邏輯
            Text(
              isTodayDone
                  ? "🎉 日任務已完成 (下次預計: $nextExpectedDate)"
                  : "🔔 日任務未完成",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isTodayDone ? Colors.green : Colors.orange.shade800
              ),
            ),

            const SizedBox(height: 12),

            // 3. 橫向日期捲動區
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(widget.completionStatus.length, (index) {
                  final date = widget.startDate.add(Duration(days: index));
                  final bool isDone = widget.completionStatus[index];
                  final bool isToday = _isSameDay(date, DateTime.now());
                  final bool isPastUnfinished = !isDone && !isToday && date.isBefore(DateTime.now());

                  String timeLabel = isDone
                      ? _getTimeString(date)
                      : (isToday ? "今日" : (isPastUnfinished ? "補填" : "預計"));

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Text("${DateFormat('M').format(date)}月",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (isDone || isToday) ? themeColor : Colors.blueGrey.shade200)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _handleOnTap(date, isDone, isToday, isPastUnfinished),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: isToday ? Colors.white : (isDone ? themeColor.withOpacity(0.05) : (isPastUnfinished ? Colors.orange.withOpacity(0.05) : Colors.grey.shade50)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isToday ? themeColor : (isDone ? themeColor : (isPastUnfinished ? Colors.orange.shade300 : Colors.grey.shade300)),
                                width: 2.5,
                              ),
                              boxShadow: isToday ? [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 4)] : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(DateFormat('dd').format(date), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: (isDone || isToday) ? themeColor : (isPastUnfinished ? Colors.orange.shade800 : Colors.grey.shade700))),
                                if (isDone) Positioned(right: 2, top: 2, child: Icon(Icons.check_circle, color: themeColor, size: 16)),
                                if (isPastUnfinished) Positioned(right: 2, top: 2, child: Icon(Icons.add_circle_outline, color: Colors.orange.shade300, size: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(timeLabel, style: TextStyle(fontSize: 11, color: isToday ? themeColor : (isDone ? themeColor : (isPastUnfinished ? Colors.orange.shade800 : Colors.grey.shade600)), fontWeight: (isDone || isToday || isPastUnfinished) ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 內部邏輯維持不變 ---
  void _handleOnTap(DateTime date, bool isDone, bool isToday, bool isPastUnfinished) async {
    if (isDone) {
      try {
        final oldRecord = widget.history.firstWhere((r) => _isSameDay(r.date!, date));
        await Navigator.push(context, MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: ScaleType.uas7, oldRecord: oldRecord)));
      } catch (_) {}
    } else if (isToday || isPastUnfinished) {
      HapticFeedback.lightImpact();
      await Navigator.push(context, MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: ScaleType.uas7, targetDate: date)));
    }
  }

  String _getTimeString(DateTime date) {
    try {
      final record = widget.history.firstWhere((r) => _isSameDay(r.date!, date));
      return DateFormat('HH:mm').format(record.date!);
    } catch (_) { return "已完成"; }
  }

  bool _checkIfTodayDone() {
    final now = DateTime.now();
    for (int i = 0; i < widget.completionStatus.length; i++) {
      if (_isSameDay(widget.startDate.add(Duration(days: i)), now)) return widget.completionStatus[i];
    }
    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}