import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../screens/poem_survey_screen.dart';
import '../models/scale_config.dart';

class Uas7TrackerCard extends StatefulWidget {
  final DateTime startDate;
  final List<bool> completionStatus;
  final List<PoemRecord> history;
  final VoidCallback? onRefresh;
  final String? reminderText;
  final VoidCallback? onReminderTap;

  const Uas7TrackerCard({
    super.key,
    required this.startDate,
    required this.completionStatus,
    required this.history,
    this.onRefresh,
    this.reminderText,
    this.onReminderTap,
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final int index = today.difference(widget.startDate).inDays;

    if (index >= 0 && index < widget.completionStatus.length) {
      double itemWidth = 64.0;
      double screenWidth = MediaQuery.of(context).size.width;
      double centerOffset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2) + 20;

      _scrollController.animateTo(
        centerOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      );
    }
  }

  PoemRecord? _getRecordAtDate(DateTime targetDate) {
    try {
      return widget.history.firstWhere((r) =>
          _isSameDay(r.targetDate ?? r.date!, targetDate));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTodayDone = _checkIfTodayDone();
    final Color themeColor = ScaleConfig.allScales[ScaleType.uas7]?.color ?? Colors.teal;
    final String displayTitle = "UAS7"; // 🚀 直接用大寫縮寫

    final DateTime nextDate = DateTime.now().add(const Duration(days: 1));
    final String nextExpectedDate = DateFormat('MM/dd').format(nextDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isTodayDone, nextExpectedDate, displayTitle, themeColor),
            const SizedBox(height: 16),

            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(widget.completionStatus.length, (index) {
                  final date = widget.startDate.add(Duration(days: index));
                  final bool isDone = widget.completionStatus[index];
                  final record = _getRecordAtDate(date);
                  final bool isToday = _isSameDay(date, DateTime.now());
                  final bool isPastUnfinished = !isDone && !isToday && date.isBefore(DateTime.now());

                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        Text(
                          "${DateFormat('M').format(date)}月",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: (isDone || isToday) ? themeColor : Colors.blueGrey.shade200
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDateSquare(date, isDone, isToday, isPastUnfinished, themeColor, record),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 35,
                          child: Text(
                            isDone ? _getTimeString(date) : (isToday ? "今日" : (isPastUnfinished ? "待補" : "預計")),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                color: isDone ? themeColor : Colors.grey.shade600,
                                fontWeight: (isDone || isToday) ? FontWeight.bold : FontWeight.normal
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

  Widget _buildHeader(bool isTodayDone, String nextExpectedDate, String title, Color color) {
    // 🚀 抓取最新紀錄顯示數值
    final lastRecord = widget.history.isNotEmpty ? widget.history.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🚀 1. 標題：靜態大寫標題
            Expanded(
              child: Text(
                "$title 紀錄進度",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  color: color.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 🚀 2. 提醒或狀態圖示
            if (widget.reminderText != null && widget.onReminderTap != null)
              _buildReminderChip(color)
            else
              Icon(
                  isTodayDone ? Icons.check_circle : Icons.pending_actions,
                  size: 22,
                  color: isTodayDone ? Colors.green : Colors.orange
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isTodayDone ? "🎉 今日任務已完成" : "🔔 今日任務未完成",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isTodayDone ? Colors.green : Colors.orange.shade800
              ),
            ),
            // 🚀 3. 最新分數膠囊 (UAS7 專用)
            if (lastRecord != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "最新：${lastRecord.score ?? 0} 分",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReminderChip(Color color) {
    return InkWell(
      onTap: widget.onReminderTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.alarm_rounded, size: 14, color: color),
            const SizedBox(width: 4),
            Text(widget.reminderText!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSquare(DateTime date, bool isDone, bool isToday, bool isPastUnfinished, Color themeColor, PoemRecord? record) {
    return InkWell(
      onTap: () async {
        if (isToday || isPastUnfinished || isDone) {
          bool? result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => PoemSurveyScreen(
              initialType: ScaleType.uas7,
              oldRecord: isDone ? record : null,
              targetDate: isDone ? null : date,
            )),
          );
          if (result == true) widget.onRefresh?.call();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: isToday ? Colors.white : (isDone ? themeColor.withOpacity(0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? themeColor : (isDone ? themeColor : (isPastUnfinished ? Colors.orange.shade300 : Colors.grey.shade300)),
            width: 2.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(DateFormat('dd').format(date), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: (isDone || isToday) ? themeColor : (isPastUnfinished ? Colors.orange.shade800 : Colors.grey.shade700))),
            if (isDone) Positioned(right: 2, top: 2, child: Icon(Icons.check_circle, color: themeColor, size: 16)),
          ],
        ),
      ),
    );
  }

  String _getTimeString(DateTime targetDate) {
    try {
      final record = widget.history.firstWhere((r) => _isSameDay(r.targetDate ?? r.date!, targetDate));
      final DateTime fillDate = record.date!;
      return _isSameDay(fillDate, targetDate) ? DateFormat('HH:mm').format(fillDate) : "補 ${DateFormat('M/d').format(fillDate)}";
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