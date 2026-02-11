import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../screens/poem_survey_screen.dart';

class WeeklyTrackerCard extends StatefulWidget {
  final ScaleType type;
  final List<PoemRecord> history;

  const WeeklyTrackerCard({super.key, required this.type, required this.history});

  @override
  State<WeeklyTrackerCard> createState() => _WeeklyTrackerCardState();
}

class _WeeklyTrackerCardState extends State<WeeklyTrackerCard> {
  // 🚀 1. 定義滾動控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 🚀 2. 渲染完成後自動滾動到「本週」
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentWeek());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 自動滾動邏輯
  void _scrollToCurrentWeek() {
    if (!_scrollController.hasClients) return;

    final now = DateTime.now();
    // 這裡的起始日要跟下面 build 裡的 baseDate 一致
    final DateTime baseDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 28));

    // 計算今天屬於第幾週 (0-indexed)
    int weekIndex = (now.difference(baseDate).inDays / 7).floor();

    if (weekIndex >= 0) {
      double itemWidth = 64.0; // 方塊 52 + 間距 12
      double screenWidth = MediaQuery.of(context).size.width;
      // 算出位移，並嘗試將當週置中
      double offset = (weekIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2) + 20;

      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // 🚀 輔助方法：判斷紀錄是否落在特定的那一週區間內
  PoemRecord? _getRecordInWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    try {
      return widget.history.firstWhere((r) =>
      r.date != null &&
          (r.date!.isAtSameMomentAs(weekStart) || r.date!.isAfter(weekStart)) &&
          r.date!.isBefore(weekEnd)
      );
    } catch (_) {
      return null;
    }
  }

  bool _isTodayInWeek(DateTime weekStart) {
    final now = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 7));
    return (now.isAtSameMomentAs(weekStart) || now.isAfter(weekStart)) && now.isBefore(weekEnd);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final String title = _getScaleTitle(widget.type);
    final Color color = _getScaleColor(widget.type);

    // 🚀 3. 動態產生 8 週 (過去 4 週 + 未來 4 週)，確保至少有 6 週的廣度
    final DateTime baseDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 28));
    final List<DateTime> schedule = List.generate(8, (i) => baseDate.add(Duration(days: i * 7)));

    // 判斷整體週任務狀態 (最近 7 天內是否有紀錄)
    bool isCompletedThisWeek = widget.history.any((r) =>
    r.date != null && now.difference(r.date!).inDays < 7
    );

    return Card(
      // 🚀 關鍵修改：將 horizontal: 20 改為 0 或較小數值 (例如 4)
      // 因為 PageView 的 viewportFraction 已經幫你留好左右間距了
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blueGrey)),
                  Icon(
                      isCompletedThisWeek ? Icons.check_circle : Icons.pending_actions,
                      size: 20,
                      color: isCompletedThisWeek ? Colors.green : Colors.orange
                  ),
                ]
            ),
            const SizedBox(height: 4),
            Text(
              isCompletedThisWeek ? "🎉 周任務已完成" : "🔔 周任務未完成",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isCompletedThisWeek ? Colors.green : Colors.orange.shade800),
            ),
            const SizedBox(height: 12),

            // 🚀 4. 使用滾動控制器
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(schedule.length, (index) {
                  final weekStartDate = schedule[index];
                  final record = _getRecordInWeek(weekStartDate);
                  final bool isDone = record != null;
                  final bool isTodayWeek = _isTodayInWeek(weekStartDate);
                  final bool canFill = !isDone && !weekStartDate.isAfter(now);

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Text("${DateFormat('M').format(weekStartDate)}月",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (isDone || isTodayWeek) ? color : Colors.blueGrey.shade200)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            if (isDone) {
                              // 修改模式
                              await Navigator.push(context, MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: widget.type, oldRecord: record)));
                            } else if (canFill || isTodayWeek) {
                              // 補填/今日模式
                              HapticFeedback.lightImpact();
                              await Navigator.push(context, MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: widget.type, targetDate: weekStartDate)));
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: isTodayWeek ? Colors.white : (isDone ? color.withOpacity(0.05) : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: (isDone || isTodayWeek) ? color : (canFill ? Colors.orange.shade300 : Colors.grey.shade300), width: 2.5),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(DateFormat('dd').format(weekStartDate), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: (isDone || isTodayWeek) ? color : (canFill ? Colors.orange.shade800 : Colors.grey.shade700))),
                                if (isDone) Positioned(right: 2, top: 2, child: Icon(Icons.check_circle, color: color, size: 16)),
                                if (canFill && !isTodayWeek) Positioned(right: 2, top: 2, child: Icon(Icons.add_circle_outline, color: Colors.orange.shade300, size: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isDone ? DateFormat('MM/dd').format(record.date!) : (isTodayWeek ? "本週" : (canFill ? "補填" : "預計")),
                          style: TextStyle(fontSize: 11, color: isTodayWeek ? color : (isDone ? color : (canFill ? Colors.orange.shade800 : Colors.grey.shade600)), fontWeight: (isDone || isTodayWeek || canFill) ? FontWeight.bold : FontWeight.normal),
                        ),
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

  String _getScaleTitle(ScaleType t) => {ScaleType.adct: "ADCT 每周異膚控制", ScaleType.poem: "POEM 每周異膚檢測", ScaleType.scorad: "SCORAD 每周異膚綄合"}[t] ?? "量表追蹤";
  Color _getScaleColor(ScaleType t) => {ScaleType.adct: Colors.teal, ScaleType.poem: Colors.blue, ScaleType.scorad: Colors.indigo}[t] ?? Colors.grey;
}