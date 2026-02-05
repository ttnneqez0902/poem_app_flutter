import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../services/export_service.dart';
import '../main.dart';
import '../models/scale_configs.dart';

// --- 定義分析模式 ---
enum ChartViewMode { daily, weekly, combined }

// --- 每週統計資料模型 ---
class WeeklyStat {
  final int week;
  final DateTime start;
  final DateTime end;
  final double avg;
  final int min;
  final int max;

  WeeklyStat({
    required this.week,
    required this.start,
    required this.end,
    required this.avg,
    required this.min,
    required this.max
  });
}

class TrendChartScreen extends StatefulWidget {
  const TrendChartScreen({super.key});

  @override
  State<TrendChartScreen> createState() => _TrendChartScreenState();
}

class _TrendChartScreenState extends State<TrendChartScreen> {
  // 📍 核心狀態
  final GlobalKey _chartKey = GlobalKey();
  ChartViewMode _viewMode = ChartViewMode.weekly;
  ScaleType _selectedScale = ScaleType.poem;

  int _selectedDays = 7;
  DateTimeRange? _customRange;

  // 臨床判定參數
  int _rapidThreshold = 8;
  int _streakCount = 3;
  int _streakTotal = 6;

  // --- 🔧 業務邏輯方法 ---

  // 🚀 核心功能：圖表截圖轉 PNG 位元組 (用於 PDF 導出)
  Future<Uint8List?> _capturePng() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return null;

      final RenderRepaintBoundary? boundary =
      _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("截圖導出失敗: $e");
      return null;
    }
  }

  // 時間範圍選擇器
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: Colors.blue.shade700)
          ),
          child: child!
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDays = -1;
        _customRange = picked;
      });
    }
  }

  // 臨床設定彈窗
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
                const Text("這些設定將影響趨勢圖紅點標示與 PDF 報告的判定基準。",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                _buildSlider(setDialogState, "急速惡化門檻 (Rapid Flare)", "分", tempRapid, 3, 15, (v) => tempRapid = v),
                _buildSlider(setDialogState, "連續惡化次數 (Streak)", "次", tempStreak, 2, 10, (v) => tempStreak = v),
                _buildSlider(setDialogState, "連續惡化總分 (Total Increase)", "分", tempTotal, 3, 15, (v) => tempTotal = v),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => setDialogState(() { tempRapid = 8; tempStreak = 3; tempTotal = 6; }),
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

  // --- 📉 數據處理與分析邏輯 ---

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
      final currentWeekRecords = weeklyRecords.where((r) =>
      r.date!.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
          r.date!.isBefore(weekEnd)
      );

      if (currentWeekRecords.isNotEmpty) {
        final scores = currentWeekRecords.map((e) => e.score ?? 0).toList();
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
    final weekly = records.where((r) => r.type == RecordType.weekly).toList();
    for (int i = 1; i < weekly.length; i++) {
      final delta = (weekly[i].score ?? 0) - (weekly[i - 1].score ?? 0);
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
        return r.date!.isAfter(_customRange!.start.subtract(const Duration(days: 1))) &&
            r.date!.isBefore(_customRange!.end.add(const Duration(days: 1)));
      }
      return DateTime.now().difference(r.date!).inDays <= (_selectedDays - 1);
    }).toList();

    filtered.sort((a, b) => a.date!.compareTo(b.date!));
    return filtered;
  }

  // --- 📊 核心繪圖配置 ---

  LineChartData _mainData(List<PoemRecord> filtered, BuildContext context) {
    if (filtered.isEmpty) return LineChartData();
    final startDate = filtered.first.date!;
    final endDate = filtered.last.date!;
    final int daysSpan = endDate.difference(startDate).inDays;

    final weeklyStats = _buildWeeklyStats(filtered);
    final flareIndexes = _detectFlares(filtered);

    // 🚀 修正：精簡日期標籤，防止重疊
    final xLabels = _buildTimeBasedLabels(filtered, startDate, daysSpan);

    double dynamicMaxY = _viewMode == ChartViewMode.daily
        ? 10.0
        : _getMaxYForScale(_selectedScale);

    return LineChartData(
      minY: 0,
      maxY: dynamicMaxY,
      minX: 0,
      maxX: (daysSpan < 1) ? 1.0 : daysSpan.toDouble(),
      lineBarsData: _getLines(filtered, startDate, flareIndexes),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem(
              "${spot.y.toInt()} 分\n${DateFormat('MM/dd').format(startDate.add(Duration(days: spot.x.toInt())))}",
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          )).toList(),
        ),
      ),
      rangeAnnotations: RangeAnnotations(
        verticalRangeAnnotations: _viewMode == ChartViewMode.daily ? [] : weeklyStats.asMap().entries.map((e) {
          final week = e.value;
          final startX = week.start.difference(startDate).inMinutes / 1440;
          if (_isHighRiskWeek(week)) {
            return VerticalRangeAnnotation(x1: startX, x2: startX + 7.0, color: Colors.red.withOpacity(0.08));
          }
          return VerticalRangeAnnotation(x1: startX, x2: startX + 7.0, color: Colors.blue.withOpacity(0.04));
        }).toList(),
      ),
      gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: daysSpan > 30 ? 14 : 7, // 根據跨度調整格線間隔
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: _selectedScale == ScaleType.uas7 ? 10 : 7,
            getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10))
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            // 🚀 關鍵修正：透過固定 interval 避免日期亂掉
            interval: (daysSpan < 5) ? 1.0 : (daysSpan / 4),
            getTitlesWidget: (v, m) {
              final date = startDate.add(Duration(days: v.toInt()));
              // 如果這是一個標籤點，則顯示日期
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              );
            }
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
    );
  }

  List<LineChartBarData> _getLines(List<PoemRecord> records, DateTime startDate, List<int> flareIndexes) {
    List<LineChartBarData> lines = [];

    if (_viewMode == ChartViewMode.weekly || _viewMode == ChartViewMode.combined) {
      final weekly = records.where((r) => r.type == RecordType.weekly).toList();
      lines.add(LineChartBarData(
        spots: weekly.map((r) => FlSpot(r.date!.difference(startDate).inMinutes / 1440, (r.score ?? 0).toDouble())).toList(),
        color: Colors.blueAccent,
        barWidth: 4,
        isCurved: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => flareIndexes.contains(index)
              ? FlDotCirclePainter(radius: 5, color: Colors.redAccent, strokeWidth: 1.5, strokeColor: Colors.white)
              : FlDotCirclePainter(radius: 3.5, color: Colors.blueAccent, strokeWidth: 1.5, strokeColor: Colors.white),
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

  // --- 🎨 UI 建構方法 ---

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PoemRecord>>(
      future: isarService.getAllRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final allRecords = snapshot.data ?? [];
        final scaleFiltered = allRecords.where((r) => r.scaleType == _selectedScale).toList();
        final filtered = _getThinnedRecords(scaleFiltered);

        final bool isLongTerm = filtered.isNotEmpty &&
            filtered.last.date!.difference(filtered.first.date!).inDays >= 20;

        return Scaffold(
          appBar: AppBar(
            title: const Text("病情趨勢分析"),
            backgroundColor: Colors.blue.shade50,
            elevation: 0,
            actions: [
              IconButton(icon: const Icon(Icons.tune), tooltip: "調整判定標準", onPressed: _showSettingsDialog),
              if (filtered.isNotEmpty)
                IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: "導出報告",
                    onPressed: () async {
                      final bytes = await _capturePng();
                      if (bytes != null && mounted) _showPreview(bytes, filtered);
                    }
                ),
            ],
          ),
          body: allRecords.isEmpty
              ? const Center(child: Text("尚無臨床檢測紀錄"))
              : SingleChildScrollView(
            child: Column(
              children: [
                _buildScaleSelector(),
                const SizedBox(height: 20),
                _buildViewModeSelector(),
                const SizedBox(height: 24),
                _buildHeader(Theme.of(context).brightness == Brightness.dark, filtered),

                RepaintBoundary(
                  key: _chartKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(10, 20, 30, 20), // 增加右側內距防止日期切到
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: filtered.isEmpty
                          ? const Center(child: Text("此量表目前無數據"))
                          : LineChart(_mainData(filtered, context), duration: const Duration(milliseconds: 250)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                _buildModernFilterBar(),
                const SizedBox(height: 20),
                _buildLegend(isLongTerm),
                const SizedBox(height: 40),
                _buildSeverityLegendForCurrentScale(context),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScaleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: Colors.blue.shade50,
      child: DropdownButtonFormField<ScaleType>(
        value: _selectedScale,
        decoration: InputDecoration(
          labelText: "分析目標量表",
          filled: true,
          fillColor: Colors.white.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: const [
          DropdownMenuItem(value: ScaleType.poem, child: Text("POEM 總分趨勢 (AD)")),
          DropdownMenuItem(value: ScaleType.uas7, child: Text("UAS7 活性趨勢 (蕁麻疹)")),
          DropdownMenuItem(value: ScaleType.scorad, child: Text("SCORAD 自評趨勢 (AD)")),
        ],
        onChanged: (val) => setState(() => _selectedScale = val!),
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: SegmentedButton<ChartViewMode>(
        style: capsuleButtonStyle,
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

  Widget _buildModernFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      width: double.infinity,
      child: SegmentedButton<int>(
        style: capsuleButtonStyle,
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

  Widget _buildSeverityLegendForCurrentScale(BuildContext context) {
    List<Map<String, dynamic>> levels = [];
    if (_selectedScale == ScaleType.poem) {
      levels = [
        {"label": "極重度 (25-28)", "color": Colors.red},
        {"label": "重度 (17-24)", "color": Colors.orange},
        {"label": "中度 (8-16)", "color": Colors.yellow.shade700},
        {"label": "輕微 (3-7)", "color": Colors.lightGreen},
        {"label": "無 (0-2)", "color": Colors.green},
      ];
    } else if (_selectedScale == ScaleType.uas7) {
      levels = [
        {"label": "嚴重活性 (28-42)", "color": Colors.red},
        {"label": "中度活性 (16-27)", "color": Colors.orange},
        {"label": "輕微活性 (7-15)", "color": Colors.yellow.shade700},
        {"label": "無活性 (0-6)", "color": Colors.green},
      ];
    } else {
      levels = [{"label": "SCORAD 自評包含強度與主觀感覺評估", "color": Colors.blue}];
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${_getScaleName(_selectedScale)} 嚴重程度分級", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...levels.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: l['color'] as Color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(l['label'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          )),
        ],
      ),
    );
  }

  // --- 🔧 基礎輔助工具 ---

  void _showPreview(Uint8List bytes, List<PoemRecord> records) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("導出預覽"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(bytes, height: 200),
            const SizedBox(height: 10),
            Text("判定標準：Flare ≥ $_rapidThreshold 分", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ExportService.generatePoemReport(
                    records, bytes,
                    config: PoemReportConfig(
                        rapidIncreaseThreshold: _rapidThreshold,
                        streakThreshold: _streakCount,
                        streakTotalIncrease: _streakTotal
                    )
                );
              },
              child: const Text("導出 PDF")
          )
        ],
      ),
    );
  }

  double _getMaxYForScale(ScaleType type) {
    switch (type) {
      case ScaleType.poem: return 28.0;
      case ScaleType.uas7: return 42.0;
      case ScaleType.scorad: return 38.0;
      default: return 30.0;
    }
  }

  String _getScaleName(ScaleType type) {
    switch (type) {
      case ScaleType.poem: return "POEM";
      case ScaleType.uas7: return "UAS7";
      case ScaleType.scorad: return "SCORAD";
      default: return "量表";
    }
  }

  Widget _buildHeader(bool isDarkMode, List<PoemRecord> filtered) {
    final title = _viewMode == ChartViewMode.daily ? "每日癢度趨勢" : "${_getScaleName(_selectedScale)} 總分趨勢圖";
    return Column(children: [
      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
      const SizedBox(height: 6),
      Text(_buildWeekSummary(filtered), style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600))
    ]);
  }

  String _buildWeekSummary(List<PoemRecord> records) {
    if (records.isEmpty) return "";
    return "時間範圍: ${DateFormat('MM/dd').format(records.first.date!)} – ${DateFormat('MM/dd').format(records.last.date!)}";
  }

  // 🚀 關鍵優化：修正標籤生成邏輯，防止日期標籤重複或重疊
  Map<double, String> _buildTimeBasedLabels(List<PoemRecord> records, DateTime start, int span) {
    final Map<double, String> labels = {};
    if (span <= 0) {
      labels[0.0] = DateFormat('MM/dd').format(start);
      return labels;
    }

    // 無論跨度多大，我們固定只在底部顯示 4-5 個均勻分佈的標籤
    int labelCount = (span < 4) ? span + 1 : 5;
    double step = span / (labelCount - 1);

    for (int i = 0; i < labelCount; i++) {
      double offset = i * step;
      labels[offset] = DateFormat('MM/dd').format(start.add(Duration(days: offset.toInt())));
    }
    return labels;
  }

  Widget _buildLegend(bool isLongTerm) {
    return Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 8, children: [
      if (_viewMode != ChartViewMode.daily) _legendDot(Colors.blueAccent, "每週 ${_getScaleName(_selectedScale)}"),
      if (_viewMode != ChartViewMode.weekly) _legendDot(Colors.orangeAccent, "每日癢度"),
      _legendDot(Colors.redAccent, "急性發作"),
      if (isLongTerm) _legendBox(Colors.red.withOpacity(0.15), "高風險週"),
    ]);
  }

  final capsuleButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((s) => s.contains(WidgetState.selected) ? Colors.blue.shade700 : Colors.grey.shade100),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((s) => s.contains(WidgetState.selected) ? Colors.white : Colors.grey.shade700),
    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
  );

  Widget _legendDot(Color color, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))]);
  Widget _legendBox(Color color, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))]);
}