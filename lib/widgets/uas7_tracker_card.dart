import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../screens/poem_survey_screen.dart';

class Uas7TrackerCard extends StatefulWidget {
  final DateTime startDate;
  final List<bool> completionStatus;
  final List<PoemRecord> history;
  final VoidCallback? onRefresh; // 🚀 1. 新增這一行

  const Uas7TrackerCard({
    super.key,
    required this.startDate,
    required this.completionStatus,
    required this.history,
    this.onRefresh, // 🚀 2. 在這裡加入參數
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

  // 🚀 輔助方法：找出對應日期的紀錄
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
                  final record = _getRecordAtDate(date); // 獲取紀錄以顯示時間
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
                          height: 32,
                          child: Text(
                            isDone ? _getTimeString(date) : (isToday ? "今日" : (isPastUnfinished ? "補填" : "預計")),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.2,
                                color: isToday ? themeColor : (isDone ? themeColor : (isPastUnfinished ? Colors.orange.shade800 : Colors.grey.shade600)),
                                fontWeight: (isDone || isToday || isPastUnfinished) ? FontWeight.bold : FontWeight.normal
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
            const Text("UAS7 七日蕁麻疹追蹤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blueGrey)),
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
            // 🚀 1. 等待導航返回結果
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (context) => PoemSurveyScreen(
                initialType: ScaleType.uas7,
                oldRecord: isDone ? record : null,
                targetDate: isDone ? null : date,
              )),
            );

            // 2. 核心修正：如果儲存成功返回 true
            if (result == true && mounted) {
              // 🚀 執行傳入的刷新函式，這會通知 HomeScreen 重新抓取資料庫
              if (widget.onRefresh != null) {
                widget.onRefresh!();
              }

              // 同時也刷新卡片內部狀態
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
      // 🚀 關鍵修正：必須透過 targetDate 尋找，才能正確顯示補填當下的時間
      final record = widget.history.firstWhere((r) => _isSameDay(r.targetDate ?? r.date!, targetDate));
      return "${DateFormat('MM/dd').format(record.date!)}\n${DateFormat('HH:mm').format(record.date!)}";
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