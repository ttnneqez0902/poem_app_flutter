import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../screens/poem_survey_screen.dart';

class Uas7TrackerCard extends StatefulWidget {
  final DateTime startDate;
  final List<bool> completionStatus;
  final List<PoemRecord> history;
  final VoidCallback? onRefresh;

  // 🚀 1. 新增接收外部傳入的時間字串與點擊事件
  final String? reminderText;
  final VoidCallback? onReminderTap;

  const Uas7TrackerCard({
    super.key,
    required this.startDate,
    required this.completionStatus,
    required this.history,
    this.onRefresh,
    this.reminderText,   // 🚀 加入建構子
    this.onReminderTap,  // 🚀 加入建構子
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
    final Color themeColor = Colors.teal;
    final DateTime nextDate = DateTime.now().add(const Duration(days: 1));
    final String nextExpectedDate = DateFormat('MM/dd').format(nextDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isTodayDone, nextExpectedDate),
            const SizedBox(height: 12),

            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(widget.completionStatus.length, (index) {
                  final date = widget.startDate.add(Duration(days: index));
                  final bool isDone = widget.completionStatus[index];
                  final record = _getRecordAtDate(date);
                  final bool isToday = _isSameDay(date, DateTime.now());
                  final bool isPastUnfinished = !isDone && !isToday && date.isBefore(DateTime.now());

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          child: Text(
                            "${DateFormat('M').format(date)}月",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (isDone || isToday) ? themeColor : Colors.blueGrey.shade200
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDateSquare(date, isDone, isToday, isPastUnfinished, themeColor, record),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: Text(
                            isDone ? _getTimeString(date) : (isToday ? "今日" : (isPastUnfinished ? "補填" : "預計")),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                color: isDone && !_isSameDay(_getRecordAtDate(date)?.date ?? date, date)
                                    ? Colors.orange.shade700
                                    : (isToday ? themeColor : Colors.grey.shade600),
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

  Widget _buildHeader(bool isTodayDone, String nextExpectedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("UAS7 七日追蹤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blueGrey)),

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
              Icon(isTodayDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: isTodayDone ? Colors.green : Colors.orange, size: 24),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isTodayDone ? "🎉 日任務已完成 (下次預計: $nextExpectedDate)" : "🔔 日任務未完成",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isTodayDone ? Colors.green : Colors.orange.shade800),
        ),
      ],
    );
  }

  Widget _buildDateSquare(DateTime date, bool isDone, bool isToday, bool isPastUnfinished, Color themeColor, PoemRecord? record) {
    return InkWell(
      onTap: () async {
        if (isToday || isPastUnfinished || isDone) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => PoemSurveyScreen(
              initialType: ScaleType.uas7,
              oldRecord: isDone ? record : null,
              targetDate: isDone ? null : date,
            )),
          );

          if (result == true && mounted) {
            if (widget.onRefresh != null) {
              widget.onRefresh!();
            }
            setState(() {});
          }
        }
      },
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
    );
  }

  String _getTimeString(DateTime targetDate) {
    try {
      final record = widget.history.firstWhere(
              (r) => _isSameDay(r.targetDate ?? r.date!, targetDate)
      );

      final DateTime fillDate = record.date!;
      final bool isLateFill = !_isSameDay(fillDate, targetDate);

      if (isLateFill) {
        return "補 ${DateFormat('M/d').format(fillDate)}\n${DateFormat('HH:mm').format(fillDate)}";
      } else {
        return DateFormat('HH:mm').format(fillDate);
      }
    } catch (_) {
      return "已完成";
    }
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