import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../screens/poem_survey_screen.dart';

class WeeklyTrackerCard extends StatefulWidget {
  final ScaleType type;
  final List<PoemRecord> history;
  final VoidCallback? onRefresh;

  // 🚀 1. 新增接收外部傳入的時間字串與點擊事件
  final String? reminderText;
  final VoidCallback? onReminderTap;

  const WeeklyTrackerCard({
    super.key,
    required this.type,
    required this.history,
    this.onRefresh,
    this.reminderText,   // 🚀 加入建構子
    this.onReminderTap,  // 🚀 加入建構子
  });

  @override
  State<WeeklyTrackerCard> createState() => _WeeklyTrackerCardState();
}

class _WeeklyTrackerCardState extends State<WeeklyTrackerCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentWeek());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentWeek() {
    if (!_scrollController.hasClients) return;
    final now = DateTime.now();
    final DateTime baseDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 28));
    int weekIndex = (now.difference(baseDate).inDays / 7).floor();

    if (weekIndex >= 0) {
      double itemWidth = 64.0;
      double screenWidth = MediaQuery.of(context).size.width;
      double offset = (weekIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2) + 20;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      );
    }
  }

  PoemRecord? _getRecordInWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    try {
      return widget.history.firstWhere((r) =>
      (r.targetDate ?? r.date!) != null &&
          ((r.targetDate ?? r.date!).isAtSameMomentAs(weekStart) || (r.targetDate ?? r.date!).isAfter(weekStart)) &&
          (r.targetDate ?? r.date!).isBefore(weekEnd)
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
    final DateTime baseDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 28));
    final List<DateTime> schedule = List.generate(8, (i) => baseDate.add(Duration(days: i * 7)));

    bool isCompletedThisWeek = widget.history.any((r) =>
    r.date != null && now.difference(r.date!).inDays < 7
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(title, color, isCompletedThisWeek),
            const SizedBox(height: 12),
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(schedule.length, (index) {
                  final weekStartDate = schedule[index];
                  final record = _getRecordInWeek(weekStartDate);
                  final bool isDone = record != null;
                  final bool isTodayWeek = _isTodayInWeek(weekStartDate);
                  final bool canFill = !isDone && !weekStartDate.isAfter(now);

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          child: Text(
                            "${DateFormat('M').format(weekStartDate)}月",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (isDone || isTodayWeek) ? color : Colors.blueGrey.shade200
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDateSquare(weekStartDate, isDone, isTodayWeek, canFill, color, record),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: Text(
                            isDone
                                ? _getTimeString(record!, weekStartDate)
                                : (isTodayWeek ? "本週" : (canFill ? "待補" : "預計")),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                color: isDone && (record.date!.difference(weekStartDate).inDays >= 7)
                                    ? Colors.orange.shade800
                                    : (isTodayWeek ? color : (isDone ? color : Colors.grey.shade600)),
                                fontWeight: (isDone || isTodayWeek || canFill) ? FontWeight.bold : FontWeight.normal
                            ),
                          ),
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

  Widget _buildHeader(String title, Color color, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🚀 關鍵修正：用 Expanded 包住標題，設定單行與溢出省略號 (...)
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blueGrey),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8), // 增加一點安全間距，避免文字跟按鈕黏死

            // 🚀 2. 將原本的 icon 替換成可點擊的精緻時間按鈕
            if (widget.reminderText != null && widget.onReminderTap != null)
              InkWell(
                onTap: widget.onReminderTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1), // 截圖中的藍色底色
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm_rounded, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        widget.reminderText!,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              )
            else
              Icon(isCompleted ? Icons.check_circle : Icons.pending_actions, size: 20, color: isCompleted ? Colors.green : Colors.orange),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isCompleted ? "🎉 周任務已完成" : "🔔 周任務未完成",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : Colors.orange.shade800),
        ),
      ],
    );
  }

  String _getTimeString(PoemRecord record, DateTime weekStartDate) {
    final DateTime fillDate = record.date!;
    final bool isLateFill = fillDate.difference(weekStartDate).inDays >= 7;

    if (isLateFill) {
      return "補 ${DateFormat('M/d').format(fillDate)}\n${DateFormat('HH:mm').format(fillDate)}";
    } else {
      return DateFormat('HH:mm').format(fillDate);
    }
  }


  Widget _buildDateSquare(DateTime date, bool isDone, bool isToday, bool canFill, Color color, PoemRecord? record) {
    return InkWell(
      onTap: () async {
        bool? needsRefresh;
        if (isDone) {
          HapticFeedback.lightImpact();
          needsRefresh = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: widget.type, oldRecord: record))
          );
        } else if (canFill || isToday) {
          HapticFeedback.mediumImpact();
          HapticFeedback.lightImpact();
          needsRefresh = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: widget.type, targetDate: date))
          );
        }

        if (needsRefresh == true && mounted) {
          widget.onRefresh?.call();
          setState(() {});
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: isToday ? Colors.white : (isDone ? color.withOpacity(0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (isDone || isToday) ? color : (canFill ? Colors.orange.shade300 : Colors.grey.shade300), width: 2.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(DateFormat('dd').format(date), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: (isDone || isToday) ? color : (canFill ? Colors.orange.shade800 : Colors.grey.shade700))),
            if (isDone) Positioned(right: 2, top: 2, child: Icon(Icons.check_circle, color: color, size: 16)),
            if (canFill && !isToday) Positioned(right: 2, top: 2, child: Icon(Icons.add_circle_outline, color: Colors.orange.shade300, size: 14)),
          ],
        ),
      ),
    );
  }

  String _getScaleTitle(ScaleType t) => {ScaleType.adct: "ADCT每周檢測", ScaleType.poem: "POEM每周檢測", ScaleType.scorad: "SCORAD每周檢測"}[t] ?? "量表追蹤";
  Color _getScaleColor(ScaleType t) => {ScaleType.adct: Colors.teal, ScaleType.poem: Colors.blue, ScaleType.scorad: Colors.indigo}[t] ?? Colors.grey;
}