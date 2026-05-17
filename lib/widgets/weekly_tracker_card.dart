import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../screens/poem_survey_screen.dart';
import '../models/scale_config.dart';

class WeeklyTrackerCard extends StatefulWidget {
  final ScaleType type;
  final List<PoemRecord> history;
  final String unit;
  final VoidCallback? onRefresh;
  final String? reminderText;
  final VoidCallback? onReminderTap;

  const WeeklyTrackerCard({
    super.key,
    required this.type,
    required this.history,
    this.unit = "分",
    this.onRefresh,
    this.reminderText,
    this.onReminderTap,
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
      return widget.history.firstWhere((r) {
        final d = r.targetDate ?? r.date;
        return d != null &&
            (d.isAtSameMomentAs(weekStart) || d.isAfter(weekStart)) &&
            d.isBefore(weekEnd);
      });
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(title, color, isCompletedThisWeek),
            const SizedBox(height: 16),
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
                    padding: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        Text(
                          "${DateFormat('M').format(weekStartDate)}月",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: (isDone || isTodayWeek) ? color : Colors.blueGrey.shade200
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDateSquare(weekStartDate, isDone, isTodayWeek, canFill, color, record),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 35,
                          child: Text(
                            isDone
                                ? _getTimeString(record!, weekStartDate)
                                : (isTodayWeek ? "本週" : (canFill ? "待補" : "預計")),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                color: isDone ? color : Colors.grey.shade600,
                                fontWeight: (isDone || isTodayWeek) ? FontWeight.bold : FontWeight.normal
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
    final lastRecord = widget.history.isNotEmpty ? widget.history.first : null;

    // 🚀 1. 定義簡短主標題 (例如 ADCT, POEM, 血壓)
    String mainTitle = "";
    switch (widget.type) {
      case ScaleType.bp_log: mainTitle = "血壓"; break;
      case ScaleType.growth: mainTitle = "生長"; break;
      case ScaleType.cycle:  mainTitle = "週期"; break;
      case ScaleType.bristol: mainTitle = "腸胃"; break;
      default:
      // 這裡會把 enum 名字轉成大寫，如 ScaleType.adct -> ADCT
        mainTitle = widget.type.name.toUpperCase();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🚀 2. 第一行：只顯示簡短主標題 + 完成勾勾 (對齊 UAS7 風格)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                mainTitle,
                style: TextStyle(
                  fontSize: 20,           // 👈 加大字體，增加權重
                  fontWeight: FontWeight.w900,
                  color: isCompleted ? color : Colors.blueGrey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCompleted)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),

        const SizedBox(height: 10), // 縮小間距，讓視覺更緊湊

        // 🚀 3. 第二行：任務狀態文字 + 最新數值膠囊
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 任務狀態文字
            Expanded(
              child: Text(
                isCompleted ? "🎉 周任務已完成" : "🔔 周任務未完成",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : Colors.orange.shade800
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 8),

            // 最新數值顯示 (例如：最新：9 分)
            if (lastRecord != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "最新：${_formatLastValue(lastRecord)}",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: color
                  ),
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

  String _formatLastValue(PoemRecord record) {
    if (widget.type == ScaleType.bp_log) {
      return "${record.systolic ?? '-'}/${record.diastolic ?? '-'} ${widget.unit}";
    }
    if (widget.type == ScaleType.growth) {
      if (widget.unit == "kg") return "${record.weight?.toStringAsFixed(1) ?? '0'} kg";
      final double val = record.height ?? record.headCircumference ?? 0;
      return "${val.toInt()} cm";
    }
    if (widget.type == ScaleType.bristol) return "第 ${record.score?.toInt() ?? '0'} 型";
    if (widget.type == ScaleType.haq) return "${record.score?.toStringAsFixed(1) ?? '0'} ${widget.unit}";
    return "${record.score?.toInt() ?? '0'} ${widget.unit}";
  }

  String _getTimeString(PoemRecord record, DateTime weekStartDate) {
    final DateTime fillDate = record.date!;
    return fillDate.difference(weekStartDate).inDays >= 7
        ? "補 ${DateFormat('M/d').format(fillDate)}"
        : DateFormat('HH:mm').format(fillDate);
  }

  Widget _buildDateSquare(DateTime date, bool isDone, bool isToday, bool canFill, Color color, PoemRecord? record) {
    return InkWell(
      onTap: () async {
        bool? res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => PoemSurveyScreen(
              initialType: widget.type,
              oldRecord: isDone ? record : null,
              targetDate: isDone ? null : date,
            ))
        );
        if (res == true) widget.onRefresh?.call();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: isToday ? Colors.white : (isDone ? color.withOpacity(0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDone || isToday) ? color : (canFill ? Colors.orange.shade300 : Colors.grey.shade300), width: 2.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(DateFormat('dd').format(date), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: (isDone || isToday) ? color : (canFill ? Colors.orange.shade800 : Colors.grey.shade700))),
            if (isDone) Positioned(right: 2, top: 2, child: Icon(Icons.check_circle, color: color, size: 16)),
          ],
        ),
      ),
    );
  }

  String _getScaleTitle(ScaleType t) {
    if (t == ScaleType.bp_log) return "血壓紀錄";
    if (t == ScaleType.growth) return "生長數據";
    if (t == ScaleType.ess) return "ESS";
    return t.name.toUpperCase();
  }

  Color _getScaleColor(ScaleType t) {
    return ScaleConfig.allScales[t]?.color ?? Colors.blueGrey;
  }
}