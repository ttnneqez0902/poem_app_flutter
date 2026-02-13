import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../screens/poem_survey_screen.dart';

class WeeklyTrackerCard extends StatefulWidget {
  final ScaleType type;
  final List<PoemRecord> history;
  final VoidCallback? onRefresh; // 🚀 1. 新增刷新回調參數定義

  const WeeklyTrackerCard({
    super.key,
    required this.type,
    required this.history,
    this.onRefresh, // 🚀 2. 將其加入建構子
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
                                ? _getTimeString(record!, weekStartDate) // 🚀 這裡要改成調用你寫好的 _getTimeString
                                : (isTodayWeek ? "本週" : (canFill ? "待補" : "預計")), // 建議將補填改成「待補」語氣較順
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blueGrey)),
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

  // 建議在 _WeeklyTrackerCardState 內新增此方法或修改 Text 的邏輯
  String _getTimeString(PoemRecord record, DateTime weekStartDate) {
    final DateTime fillDate = record.date!; // 實際填寫時間
    // 判斷填寫日是否不在那一週內 (或是與該週起始日不同天)
    // 周量表通常是以該週起始日為準，若 fillDate 距離起始日超過 7 天，顯然是補填
    final bool isLateFill = fillDate.difference(weekStartDate).inDays >= 7;

    if (isLateFill) {
      // 🚀 誠實提醒：這是補填的
      return "補 ${DateFormat('M/d').format(fillDate)}\n${DateFormat('HH:mm').format(fillDate)}";
    } else {
      // 當週準時填寫
      return DateFormat('HH:mm').format(fillDate);
    }
  }


  Widget _buildDateSquare(DateTime date, bool isDone, bool isToday, bool canFill, Color color, PoemRecord? record) {
    return InkWell(
      // WeeklyTrackerCard.dart 內的 _buildDateSquare
      onTap: () async {
        bool? needsRefresh;
        if (isDone) {
          HapticFeedback.lightImpact(); // 編輯舊紀錄也給點反饋
          // 編輯模式
          needsRefresh = await Navigator.push<bool>( // 🚀 3. 指定返回型別為 bool
              context,
              MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: widget.type, oldRecord: record))
          );
        } else if (canFill || isToday) {
          HapticFeedback.mediumImpact(); // 補填給稍微重一點的反饋
          // 補填模式
          HapticFeedback.lightImpact();
          needsRefresh = await Navigator.push<bool>( // 🚀 3. 指定返回型別為 bool
              context,
              MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: widget.type, targetDate: date))
          );
        }

        // 🚀 4. 關鍵刷新邏輯修正
        if (needsRefresh == true && mounted) {
          widget.onRefresh?.call(); // 通知首頁更新數據
          setState(() {}); // 更新本地顯示
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

  String _getScaleTitle(ScaleType t) => {ScaleType.adct: "ADCT 每周異膚控制", ScaleType.poem: "POEM 每周異膚檢測", ScaleType.scorad: "SCORAD 每周異膚綜合"}[t] ?? "量表追蹤";
  Color _getScaleColor(ScaleType t) => {ScaleType.adct: Colors.teal, ScaleType.poem: Colors.blue, ScaleType.scorad: Colors.indigo}[t] ?? Colors.grey;
}