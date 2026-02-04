import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../services/export_service.dart';
import '../main.dart';

enum ChartViewMode { daily, weekly, combined }

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
  ChartViewMode _viewMode = ChartViewMode.weekly;

  int _selectedDays = 7;
  DateTimeRange? _customRange;
  int _rapidThreshold = 8;
  int _streakCount = 3;
  int _streakTotal = 6;

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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
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
              TextButton(
                onPressed: () {
                  setDialogState(() { tempRapid = 8; tempStreak = 3; tempTotal = 6; });
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

  Future<Uint8List?> _capturePng() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return null;
      await WidgetsBinding.instance.endOfFrame;
      final RenderRepaintBoundary? boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) { return null; }
  }

  void _showPreview(Uint8List bytes, List<PoemRecord> records) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("匯出預覽"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)), child: Image.memory(bytes, height: 200)),
          const SizedBox(height: 10),
          Text("判定標準：Flare ≥ $_rapidThreshold 分 | Streak $_streakCount 次", style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
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

  List<WeeklyStat> _buildWeeklyStats(List<PoemRecord> records) {
    final List<WeeklyStat> stats = [];
    final weeklyRecords = records.where((r) => r.type == RecordType.weekly).toList();
    if (weeklyRecords.isEmpty) return stats;

    final start = weeklyRecords.first.date!;
    final end = weeklyRecords.last.date!;
    final int weeksCount = (end.difference(start).inDays / 7).ceil() + 1;

    for (int w = 0; w < weeksCount; w++) {
      final weekStart = start.add(Duration(days: w * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final currentWeekRecords = weeklyRecords.where((r) => r.date!.isAfter(weekStart.subtract(const Duration(seconds: 1))) && r.date!.isBefore(weekEnd));

      if (currentWeekRecords.isNotEmpty) {
        final scores = currentWeekRecords.map((e) => e.totalScore).toList();
        stats.add(WeeklyStat(
          week: w + 1, start: weekStart, end: weekEnd.subtract(const Duration(days: 1)),
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
    final weekly = records.where((r) => r.type == RecordType.weekly).toList();
    for (int i = 1; i < weekly.length; i++) {
      final delta = weekly[i].totalScore - weekly[i - 1].totalScore;
      if (delta >= _rapidThreshold) flareIndexes.add(i);
    }
    return flareIndexes;
  }

  bool _isHighRiskWeek(WeeklyStat w) {
    return w.avg >= 17 || w.max >= 24;
  }

  List<PoemRecord> _getThinnedRecords(List<PoemRecord> all) {
    List<PoemRecord> filtered = all.where((r) {
      if (r.date == null) return false;
      if (_selectedDays == -1 && _customRange != null) {
        return r.date!.isAfter(_customRange!.start.subtract(const Duration(days: 1))) && r.date!.isBefore(_customRange!.end.add(const Duration(days: 1)));
      }
      return DateTime.now().difference(r.date!).inDays <= (_selectedDays - 1);
    }).toList();

    filtered.sort((a, b) => a.date!.compareTo(b.date!));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PoemRecord>>(
      future: isarService.getAllRecords(),
      builder: (context, snapshot) {
        final allRecords = snapshot.data ?? [];
        final filtered = _getThinnedRecords(allRecords);
        // ✅ 修正：增加 filtered.isNotEmpty 檢查，避免紅屏崩潰
        final bool isLongTerm = filtered.isNotEmpty &&
            filtered.last.date!.difference(filtered.first.date!).inDays >= 20;

        return Scaffold(
          appBar: AppBar(
            title: const Text("病情趨勢分析"),
            actions: [
              // ✅ 1. 找回參數設定按鈕
              IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: "調整判斷標準",
                  onPressed: _showSettingsDialog
              ),
              // ✅ 2. 找回 PDF 輸出按鈕，僅在有資料時顯示
              if (filtered.isNotEmpty)
                IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: "導出報告",
                    onPressed: () async {
                      setState(() {}); // 確保 UI 最新
                      final bytes = await _capturePng();
                      if (bytes != null && mounted) _showPreview(bytes, filtered);
                    }
                ),
            ],
          ),
          body: allRecords.isEmpty ? const Center(child: Text("尚無資料")) : SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 20),
              // 📍 頂部：檢測模式切換 (每日檢測 / 每週檢測 / 合併)
              _buildViewModeSelector(),

              const SizedBox(height: 24),
              _buildHeader(Theme.of(context).brightness == Brightness.dark, filtered),

              // 📈 圖表區域
              RepaintBoundary(
                key: _chartKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1.4,
                    child: filtered.isEmpty
                        ? const SizedBox()
                        : LineChart(_mainData(filtered, context), duration: const Duration(milliseconds: 250)),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // 🔥 重點優化：將「時間篩選器」移到圖表下方，按鈕變大且好按
              _buildModernFilterBar(),

              const SizedBox(height: 20),
              _buildLegend(isLongTerm),
              const SizedBox(height: 40),
              _buildSeverityLegend(context),
              const SizedBox(height: 30),
            ]),
          ),
        );
      },
    );
  }



// ✅ 2. 統一的第一行：時間篩選器
  // ✅ 3. 優化後的時間篩選器 (移至下方，加大點擊範圍)
  Widget _buildModernFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      width: double.infinity,
      child: SegmentedButton<int>(
        style: capsuleButtonStyle, // 套用加大版樣式
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 7, label: Text("7天")),
          ButtonSegment(value: 14, label: Text("14天")),
          ButtonSegment(value: 21, label: Text("21天")),
          ButtonSegment(value: 28, label: Text("28天")),
          ButtonSegment(value: -1, label: Text("自訂")),
        ],
        selected: {_selectedDays},
        onSelectionChanged: (newSelection) {
          if (newSelection.first == -1) {
            _pickDateRange();
          } else {
            setState(() { _selectedDays = newSelection.first; _customRange = null; });
          }
        },
      ),
    );
  }


// ✅ 2. 優化後的模式切換 (每日/每週/合併)
  Widget _buildViewModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: SegmentedButton<ChartViewMode>(
        style: capsuleButtonStyle, // 套用加大版樣式
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: ChartViewMode.daily, label: Text("每日檢測")),
          ButtonSegment(value: ChartViewMode.weekly, label: Text("每週檢測")),
          ButtonSegment(value: ChartViewMode.combined, label: Text("合併")),
        ],
        selected: {_viewMode},
        onSelectionChanged: (newSelection) => setState(() => _viewMode = newSelection.first),
      ),
    );
  }


  List<LineChartBarData> _getLines(List<PoemRecord> records, DateTime startDate, List<int> flareIndexes) {
    List<LineChartBarData> lines = [];

    if (_viewMode == ChartViewMode.weekly || _viewMode == ChartViewMode.combined) {
      final weekly = records.where((r) => r.type == RecordType.weekly).toList();
      lines.add(LineChartBarData(
        spots: weekly.map((r) => FlSpot(r.date!.difference(startDate).inMinutes / 1440, r.totalScore.toDouble())).toList(),
        color: Colors.blueAccent,
        barWidth: 4,
        isCurved: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) {
            if (flareIndexes.contains(index)) {
              return FlDotCirclePainter(radius: 5, color: Colors.redAccent, strokeWidth: 1.5, strokeColor: Colors.white);
            }
            return FlDotCirclePainter(radius: 3.5, color: Colors.blueAccent, strokeWidth: 1.5, strokeColor: Colors.white);
          },
        ),
      ));
    }

    if (_viewMode == ChartViewMode.daily || _viewMode == ChartViewMode.combined) {
      final daily = records.where((r) => r.type == RecordType.daily).toList();
      lines.add(LineChartBarData(
        spots: daily.map((r) => FlSpot(r.date!.difference(startDate).inMinutes / 1440, (r.dailyItch ?? 0).toDouble())).toList(),
        color: Colors.orangeAccent,
        barWidth: 2,
        isCurved: true,
        dotData: FlDotData(show: _viewMode == ChartViewMode.daily),
      ));
    }
    return lines;
  }

  LineChartData _mainData(List<PoemRecord> filtered, BuildContext context) {
    if (filtered.isEmpty) return LineChartData();
    final startDate = filtered.first.date!;
    final endDate = filtered.last.date!;
    final int daysSpan = endDate.difference(startDate).inDays;

    final weeklyStats = _buildWeeklyStats(filtered);
    final flareIndexes = _detectFlares(filtered);
    final xLabels = _buildTimeBasedLabels(filtered, startDate, daysSpan);

    return LineChartData(
      minY: 0,
      maxY: _viewMode == ChartViewMode.daily ? 10 : 28,
      minX: 0,
      maxX: (daysSpan < 1) ? 1.0 : daysSpan.toDouble(),
      lineBarsData: _getLines(filtered, startDate, flareIndexes),
      rangeAnnotations: RangeAnnotations(
        verticalRangeAnnotations: _viewMode == ChartViewMode.daily ? [] : weeklyStats.asMap().entries.map((e) {
          final week = e.value;
          final startX = week.start.difference(startDate).inMinutes / 1440;
          if (_isHighRiskWeek(week)) return VerticalRangeAnnotation(x1: startX, x2: startX + 7.0, color: Colors.red.withOpacity(0.08));
          return VerticalRangeAnnotation(x1: startX, x2: startX + 7.0, color: Colors.blue.withOpacity(0.04));
        }).toList(),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: true, verticalInterval: 7),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _viewMode == ChartViewMode.daily ? 2 : 7,
            getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10))
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, m) {
              final match = xLabels.entries.firstWhere((e) => (e.key - v).abs() < 0.1, orElse: () => const MapEntry(-1.0, ""));
              return match.value.isNotEmpty ? Text(match.value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)) : const SizedBox();
            }
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode, List<PoemRecord> filtered) {
    final title = _viewMode == ChartViewMode.daily ? "每日癢度趨勢" : "POEM 總分趨勢圖";
    return Column(children: [
      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
      const SizedBox(height: 6),
      Text(_buildWeekSummary(filtered), style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600)),
    ]);
  }

  Widget _buildLegend(bool isLongTerm) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        if (_viewMode != ChartViewMode.daily) _legendDot(Colors.blueAccent, "每週 POEM"),
        if (_viewMode != ChartViewMode.weekly) _legendDot(Colors.orangeAccent, "每日癢度"),
        if (_viewMode == ChartViewMode.weekly) _legendLine(Colors.grey.shade400, "每週平均"),
        _legendDot(Colors.redAccent, "急性發作", isHollow: false),
        if (isLongTerm) _legendBox(Colors.red.withOpacity(0.15), "高風險週 (Avg≥17)"),
      ],
    );
  }

  // --- 輔助 UI 元件與字串處理 ---

  String _buildWeekSummary(List<PoemRecord> records) {
    if (records.isEmpty) return "";
    final start = records.first.date!;
    final end = records.last.date!;
    final int days = end.difference(start).inDays + 1;
    final int weeks = (days / 7).ceil();
    final String dateRange = "${DateFormat('MM/dd').format(start)} – ${DateFormat('MM/dd').format(end)}";
    if (days >= 20) return "Week 1 → Week $weeks · 共 $days 天";
    if (weeks >= 2) return "$dateRange · 約 $weeks 週";
    return dateRange;
  }

  Map<double, String> _buildTimeBasedLabels(List<PoemRecord> records, DateTime start, int span) {
    final Map<double, String> labels = {};
    late DateFormat formatter;
    final bool sameDay = records.first.date!.year == records.last.date!.year &&
        records.first.date!.month == records.last.date!.month &&
        records.first.date!.day == records.last.date!.day;
    final bool isWeeklyMode = span >= 20;
    if (isWeeklyMode) {
      int weeks = (span / 7).ceil();
      for (int i = 0; i <= weeks; i++) {
        double offset = i * 7.0;
        if (offset <= span) labels[offset] = "Week ${i + 1}";
      }
      return labels;
    }
    formatter = sameDay ? DateFormat('HH:mm') : DateFormat('MM/dd');
    const int maxLabels = 5;
    final double step = (span < 1 ? 1.0 : span.toDouble()) / (maxLabels - 1);
    for (int i = 0; i < maxLabels; i++) {
      double targetOffset = i * step;
      PoemRecord closest = records.reduce((a, b) {
        double diffA = (a.date!.difference(start).inMinutes / 1440 - targetOffset).abs();
        double diffB = (b.date!.difference(start).inMinutes / 1440 - targetOffset).abs();
        return diffA < diffB ? a : b;
      });
      double actualOffset = closest.date!.difference(start).inMinutes / 1440;
      labels[actualOffset] = formatter.format(closest.date!);
    }
    return labels;
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

// ✅ 1. 修正後的圖例小方塊 (與按鈕分開)
  Widget _legendBox(Color color, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))
      ),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))
    ]);
  }

  // ✅ 2. 定義在類別層級的「寬大版質感樣式」
// 解決 image_1a25bd 按鈕擁擠與 image_1a3120 不好按的問題
  final capsuleButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) return Colors.blue.shade700;
      return Colors.grey.shade100;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      return Colors.grey.shade700;
    }),
    side: WidgetStateProperty.all(BorderSide.none),
    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
    elevation: WidgetStateProperty.all(0),
    // 🚀 大幅增加垂直內距 (18)，讓按鈕變高、變好按
    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 4)),
    textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
  );

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