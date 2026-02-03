import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../services/export_service.dart';
import '../main.dart';

// 📊 週統計模型
class WeeklyStat {
  final int week;
  final DateTime start;
  final DateTime end;
  final double avg;
  final int min;
  final int max;

  WeeklyStat({required this.week, required this.start, required this.end, required this.avg, required this.min, required this.max});
}

class TrendChartScreen extends StatefulWidget {
  const TrendChartScreen({super.key});

  @override
  State<TrendChartScreen> createState() => _TrendChartScreenState();
}

class _TrendChartScreenState extends State<TrendChartScreen> {
  final GlobalKey _chartKey = GlobalKey();

  // --- 1. 篩選狀態 ---
  int _selectedDays = 7;
  DateTimeRange? _customRange;

  // --- 2. 臨床判斷參數 (可調整) ---
  int _rapidThreshold = 8;  // 急速惡化 (預設 8)
  int _streakCount = 3;     // 連續惡化次數 (預設 3)
  int _streakTotal = 6;     // 連續惡化總分 (預設 6)

  // --- 3. 日期選擇器 ---
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Colors.blue.shade700)), child: child!),
    );
    if (picked != null) setState(() { _selectedDays = -1; _customRange = picked; });
  }

  // --- 4. 🔥 參數設定對話框 (新增：恢復預設按鈕) ---
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // 使用區域變數暫存，避免直接影響主畫面，直到按下應用
        int tempRapid = _rapidThreshold;
        int tempStreak = _streakCount;
        int tempTotal = _streakTotal;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("調整臨床判斷標準"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("這些設定將影響圖表紅點標示與 PDF 報告的判定標準。", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                _buildSlider(setDialogState, "急速惡化門檻 (Rapid Flare)", "分", tempRapid, 3, 15, (v) => tempRapid = v),
                _buildSlider(setDialogState, "連續惡化次數 (Streak)", "次", tempStreak, 2, 10, (v) => tempStreak = v),
                _buildSlider(setDialogState, "連續惡化總分 (Total Increase)", "分", tempTotal, 3, 15, (v) => tempTotal = v),
              ],
            ),
            actions: [
              // 🔥 新增：恢復預設按鈕
              TextButton(
                onPressed: () {
                  // 即時重置滑桿位置
                  setDialogState(() {
                    tempRapid = 8;
                    tempStreak = 3;
                    tempTotal = 6;
                  });
                },
                child: const Text("恢復預設", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _rapidThreshold = tempRapid;
                    _streakCount = tempStreak;
                    _streakTotal = tempTotal;
                  });
                  Navigator.pop(context);
                },
                child: const Text("應用設定"),
              ),
            ],
            // 調整按鈕排列，讓「恢復預設」在左邊，「取消/應用」在右邊 (Optional)
            actionsAlignment: MainAxisAlignment.spaceBetween,
          ),
        );
      },
    );
  }

  Widget _buildSlider(StateSetter setDialogState, String label, String unit, int value, double min, double max, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text("$value $unit", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: Colors.blue.shade700,
          onChanged: (v) => setDialogState(() => onChanged(v.toInt())),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // --- 5. 截圖功能 ---
  Future<Uint8List?> _capturePng() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      await WidgetsBinding.instance.endOfFrame;
      final RenderRepaintBoundary? boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) { return null; }
  }

  // --- 6. 預覽與匯出 ---
  void _showPreview(Uint8List bytes, List<PoemRecord> records) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("匯出預覽"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)), child: Image.memory(bytes, height: 200)),
          const SizedBox(height: 10),
          Text("目前的判斷標準：\nFlare ≥ $_rapidThreshold 分 | 連續 $_streakCount 次 (+ $_streakTotal 分)", style: TextStyle(fontSize: 11, color: Colors.grey.shade700), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          const Text("若預覽圖正常，即可點擊確定匯出", style: TextStyle(fontSize: 12, color: Colors.blue)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ExportService.generatePoemReport(
                  records,
                  bytes,
                  config: PoemReportConfig(
                    rapidIncreaseThreshold: _rapidThreshold,
                    streakThreshold: _streakCount,
                    streakTotalIncrease: _streakTotal,
                  ),
                );
              },
              child: const Text("確定匯出 PDF")
          ),
        ],
      ),
    );
  }

  // --- 7. 資料處理邏輯 ---

  List<WeeklyStat> _buildWeeklyStats(List<PoemRecord> records) {
    final List<WeeklyStat> stats = [];
    if (records.isEmpty) return stats;

    final start = records.first.date;
    final end = records.last.date;
    final int weeksCount = (end.difference(start).inDays / 7).ceil() + 1;

    for (int w = 0; w < weeksCount; w++) {
      final weekStart = start.add(Duration(days: w * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final weekRecords = records.where((r) => r.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) && r.date.isBefore(weekEnd));

      if (weekRecords.isNotEmpty) {
        final scores = weekRecords.map((e) => e.totalScore).toList();
        stats.add(WeeklyStat(
          week: w + 1,
          start: weekStart,
          end: weekEnd.subtract(const Duration(days: 1)),
          avg: scores.reduce((a, b) => a + b) / scores.length,
          min: scores.reduce((a, b) => a < b ? a : b),
          max: scores.reduce((a, b) => a > b ? a : b),
        ));
      }
    }
    return stats;
  }

  List<int> _detectFlares(List<PoemRecord> records) {
    final List<int> flareIndexes = [];
    for (int i = 1; i < records.length; i++) {
      final delta = records[i].totalScore - records[i - 1].totalScore;
      if (delta >= _rapidThreshold) flareIndexes.add(i);
    }
    return flareIndexes;
  }

  bool _isHighRiskWeek(WeeklyStat w) {
    return w.avg >= 17 || w.max >= 24;
  }

  List<PoemRecord> _getThinnedRecords(List<PoemRecord> all) {
    List<PoemRecord> filtered = all.where((r) {
      if (_selectedDays == -1 && _customRange != null) {
        return r.date.isAfter(_customRange!.start.subtract(const Duration(days: 1))) && r.date.isBefore(_customRange!.end.add(const Duration(days: 1)));
      }
      return DateTime.now().difference(r.date).inDays <= (_selectedDays - 1);
    }).toList();
    filtered.sort((a, b) => a.date.compareTo(b.date));
    List<PoemRecord> res = [];
    if (filtered.isNotEmpty) {
      res.add(filtered.first);
      for (int i = 1; i < filtered.length; i++) {
        if (filtered[i].date.difference(res.last.date).inHours >= 12) res.add(filtered[i]);
      }
    }
    return res;
  }

  // --- 8. UI 建構 ---

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PoemRecord>>(
      future: isarService.getAllRecords(),
      builder: (context, snapshot) {
        final allRecords = snapshot.data ?? [];
        final filtered = _getThinnedRecords(allRecords);
        final bool isLongTerm = filtered.isNotEmpty && filtered.last.date.difference(filtered.first.date).inDays >= 20;

        return Scaffold(
          appBar: AppBar(
            title: const Text("病情趨勢分析"),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: "調整判斷標準",
                onPressed: _showSettingsDialog,
              ),
              if (filtered.isNotEmpty) IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () async {
                    setState(() {});
                    final bytes = await _capturePng();
                    if (bytes != null && mounted) _showPreview(bytes, filtered);
                  }
              ),
            ],
          ),
          body: allRecords.isEmpty ? const Center(child: Text("尚無資料")) : SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 20),
              _buildModernFilterBar(),
              if (_selectedDays == -1 && _customRange != null)
                Padding(padding: const EdgeInsets.only(top: 12), child: Text("自訂範圍: ${DateFormat('MM/dd').format(_customRange!.start)} - ${DateFormat('MM/dd').format(_customRange!.end)}", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
              const SizedBox(height: 24),
              _buildHeader(Theme.of(context).brightness == Brightness.dark, filtered),

              RepaintBoundary(
                key: _chartKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1.4,
                    child: LineChart(_mainData(filtered, context), duration: const Duration(milliseconds: 250)),
                  ),
                ),
              ),

              if (isLongTerm) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _legendDot(Colors.blueAccent, "每日紀錄"),
                    _legendLine(Colors.grey.shade400, "每週平均"),
                    _legendDot(Colors.redAccent, "急性發作 (+$_rapidThreshold)", isHollow: false),
                    _legendBox(Colors.red.withOpacity(0.15), "高風險週 (Avg≥17)"),
                  ],
                ),
              ],

              const SizedBox(height: 40),
              _buildSeverityLegend(context),
              const SizedBox(height: 30),
            ]),
          ),
        );
      },
    );
  }

  LineChartData _mainData(List<PoemRecord> records, BuildContext context) {
    if (records.isEmpty) return LineChartData();

    final startDate = records.first.date;
    final endDate = records.last.date;
    final int daysSpan = endDate.difference(startDate).inDays;
    final bool isWeeklyMode = daysSpan >= 20;

    final weeklyStats = isWeeklyMode ? _buildWeeklyStats(records) : <WeeklyStat>[];
    final flareIndexes = isWeeklyMode ? _detectFlares(records) : <int>[];

    final spots = records.map((r) => FlSpot(r.date.difference(startDate).inMinutes / 1440, r.totalScore.toDouble())).toList();

    final weeklyLine = weeklyStats.isNotEmpty
        ? LineChartBarData(
      spots: weeklyStats.map((w) {
        final center = w.start.difference(startDate).inMinutes / 1440 + 3.5;
        return FlSpot(center, w.avg);
      }).toList(),
      isCurved: true,
      color: Colors.grey.shade400,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      dashArray: [5, 5],
    ) : null;

    final xLabels = _buildTimeBasedLabels(records, startDate, daysSpan);

    return LineChartData(
      minY: 0, maxY: 28,
      minX: 0, maxX: (daysSpan < 1) ? 1.0 : daysSpan.toDouble(),

      rangeAnnotations: RangeAnnotations(
        verticalRangeAnnotations: weeklyStats.asMap().entries.map((e) {
          final week = e.value;
          final startX = week.start.difference(startDate).inMinutes / 1440;
          final isHighRisk = _isHighRiskWeek(week);

          if (isHighRisk) {
            return VerticalRangeAnnotation(x1: startX, x2: startX + 7.0, color: Colors.red.withOpacity(0.08));
          }
          else if (e.key % 2 == 0) {
            return VerticalRangeAnnotation(x1: startX, x2: startX + 7.0, color: Colors.blue.withOpacity(0.04));
          }
          return null;
        }).whereType<VerticalRangeAnnotation>().toList(),
      ),

      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: isWeeklyMode,
        verticalInterval: 7,
        getDrawingVerticalLine: (value) => FlLine(color: Colors.blueGrey.withOpacity(0.2), strokeWidth: 1, dashArray: [4, 4]),
        getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFEEEEEE), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 7, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(color: Colors.black87, fontSize: 10)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, m) {
          final match = xLabels.entries.firstWhere((e) => (e.key - v).abs() < 0.1, orElse: () => const MapEntry(-1.0, ""));
          if (match.value.isNotEmpty) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(match.value, style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)));
          return const SizedBox();
        })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blueAccent,
          barWidth: 4,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              if (flareIndexes.contains(index)) {
                return FlDotCirclePainter(radius: 5, color: Colors.redAccent, strokeWidth: 1.5, strokeColor: Colors.white);
              }
              return FlDotCirclePainter(radius: 3.5, color: Colors.blueAccent, strokeWidth: 1.5, strokeColor: Colors.white);
            },
          ),
        ),
        if (weeklyLine != null) weeklyLine,
      ],
    );
  }

  Map<double, String> _buildTimeBasedLabels(List<PoemRecord> records, DateTime start, int span) {
    final Map<double, String> labels = {};
    late DateFormat formatter;

    final bool sameDay = records.first.date.year == records.last.date.year &&
        records.first.date.month == records.last.date.month &&
        records.first.date.day == records.last.date.day;

    final bool isWeeklyMode = span >= 20;

    if (isWeeklyMode) {
      int weeks = (span / 7).ceil();
      for (int i = 0; i <= weeks; i++) {
        double offset = i * 7.0;
        if (offset <= span) {
          labels[offset] = "Week ${i + 1}";
        }
      }
      return labels;
    }

    formatter = sameDay ? DateFormat('HH:mm') : DateFormat('MM/dd');

    const int maxLabels = 5;
    final double step = (span < 1 ? 1.0 : span.toDouble()) / (maxLabels - 1);

    for (int i = 0; i < maxLabels; i++) {
      double targetOffset = i * step;
      PoemRecord closest = records.reduce((a, b) {
        double diffA = (a.date.difference(start).inMinutes / 1440 - targetOffset).abs();
        double diffB = (b.date.difference(start).inMinutes / 1440 - targetOffset).abs();
        return diffA < diffB ? a : b;
      });
      double actualOffset = closest.date.difference(start).inMinutes / 1440;
      labels[actualOffset] = formatter.format(closest.date);
    }

    labels[0.0] = formatter.format(records.first.date);
    double lastOffset = records.last.date.difference(start).inMinutes / 1440;
    labels[lastOffset] = formatter.format(records.last.date);

    return labels;
  }

  String _buildWeekSummary(List<PoemRecord> records) {
    if (records.isEmpty) return "";
    final start = records.first.date;
    final end = records.last.date;
    final int days = end.difference(start).inDays + 1;
    final int weeks = (days / 7).ceil();
    final String dateRange = "${DateFormat('MM/dd').format(start)} – ${DateFormat('MM/dd').format(end)}";
    if (days >= 20) return "Week 1 → Week $weeks · 共 $days 天";
    if (weeks >= 2) return "$dateRange · 約 $weeks 週";
    return dateRange;
  }

  Widget _buildHeader(bool isDarkMode, List<PoemRecord> filtered) {
    final summary = _buildWeekSummary(filtered);
    return Column(children: [
      Text("POEM 總分趨勢圖", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
      const SizedBox(height: 6),
      if (summary.isNotEmpty) Text(summary, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade600)),
    ]);
  }

  Widget _legendDot(Color color, String text, {bool isHollow = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isHollow ? Border.all(color: color, width: 2) : null)),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))
    ]);
  }

  Widget _legendLine(Color color, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 20, height: 2, color: color),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))
    ]);
  }

  Widget _legendBox(Color color, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))
    ]);
  }

  Widget _buildModernFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _filterChip(7, "7天"), _filterChip(14, "14天"), _filterChip(21, "21天"), _filterChip(28, "28天"), _filterChip(-1, "自訂", isSpecial: true),
      ]),
    );
  }

  Widget _filterChip(int days, String label, {bool isSpecial = false}) {
    final bool isSelected = _selectedDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => isSpecial ? _pickDateRange() : setState(() { _selectedDays = days; _customRange = null; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: [if (isSelected) BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]),
          child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600))),
        ),
      ),
    );
  }

  Widget _buildSeverityLegend(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [if (!isDarkMode) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("POEM 嚴重程度分級", style: TextStyle(fontWeight: FontWeight.bold)),
        const Divider(height: 20),
        _buildLegendRow("極重度 (25-28)", Colors.red, isDarkMode),
        _buildLegendRow("重度 (17-24)", Colors.orange, isDarkMode),
        _buildLegendRow("中度 (8-16)", Colors.amber, isDarkMode),
        _buildLegendRow("輕微 (3-7)", Colors.green, isDarkMode),
        _buildLegendRow("無濕疹或極輕微 (0-2)", Colors.blue, isDarkMode),
      ]),
    );
  }

  Widget _buildLegendRow(String text, Color color, bool isDarkMode) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Icon(Icons.circle, size: 12, color: color), const SizedBox(width: 8), Text(text, style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.black54, fontSize: 14))]));
  }
}