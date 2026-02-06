import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../services/export_service.dart';
import '../main.dart';

class TrendChartScreen extends StatefulWidget {
  const TrendChartScreen({super.key});

  @override
  State<TrendChartScreen> createState() => _TrendChartScreenState();
}

class _TrendChartScreenState extends State<TrendChartScreen> {
  final GlobalKey _chartKey = GlobalKey();
  ScaleType _selectedScale = ScaleType.adct; // 🚀 預設改為 ADCT

  int _selectedDays = 7;
  DateTimeRange? _customRange;

  // 臨床判定參數
  final int _flareThreshold = 8;

  // --- 📉 數據篩選 ---
  List<PoemRecord> _getThinnedRecords(List<PoemRecord> all) {
    List<PoemRecord> filtered = all.where((r) {
      if (r.date == null || r.scaleType != _selectedScale) return false;
      if (_selectedDays == -1 && _customRange != null) {
        return r.date!.isAfter(_customRange!.start.subtract(const Duration(days: 1))) &&
            r.date!.isBefore(_customRange!.end.add(const Duration(days: 1)));
      }
      return DateTime.now().difference(r.date!).inDays <= (_selectedDays - 1);
    }).toList();

    filtered.sort((a, b) => a.date!.compareTo(b.date!));
    return filtered;
  }

  // --- 📊 圖表配置 ---
  LineChartData _mainData(List<PoemRecord> filtered) {
    if (filtered.isEmpty) return LineChartData();

    final startDate = filtered.first.date!;
    final endDate = filtered.last.date!;
    final int daysSpan = endDate.difference(startDate).inDays;

    double dynamicMaxY = _getMaxYForScale(_selectedScale);
    double interval = _getIntervalForScale(_selectedScale);

    return LineChartData(
      minY: 0,
      maxY: dynamicMaxY,
      minX: 0,
      maxX: (daysSpan < 1) ? 1.0 : daysSpan.toDouble(),
      lineBarsData: [_getLineData(filtered, startDate)],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem(
              "${spot.y.toInt()} 分\n${DateFormat('MM/dd').format(startDate.add(Duration(days: spot.x.toInt())))}",
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          )).toList(),
        ),
      ),
      gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          // 🚀 UAS7 顯示每日格線，每週量表則顯示每週格線
          verticalInterval: _selectedScale == ScaleType.uas7 ? 1 : 7,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: interval,
            getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey))
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            interval: (daysSpan < 5) ? 1.0 : (daysSpan / 4).clamp(1.0, 30.0),
            getTitlesWidget: (v, m) {
              final date = startDate.add(Duration(days: v.toInt()));
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
              );
            }
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
    );
  }

  LineChartBarData _getLineData(List<PoemRecord> records, DateTime startDate) {
    Color color = _getLineColor(_selectedScale);
    return LineChartBarData(
      spots: records.map((r) => FlSpot(
          r.date!.difference(startDate).inMinutes / 1440,
          (r.score ?? 0).toDouble())
      ).toList(),
      color: color,
      barWidth: 4,
      // 🚀 核心修正：點太少（< 3）就不使用曲線，防止變形
      isCurved: records.length >= 3,
      curveSmoothness: 0.3,
      dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) {
            bool isFlare = false;
            if (index > 0) {
              final delta = (records[index].score ?? 0) - (records[index-1].score ?? 0);
              if (delta >= _flareThreshold) isFlare = true;
            }
            return FlDotCirclePainter(
                radius: isFlare ? 6 : 4,
                color: isFlare ? Colors.redAccent : color,
                strokeWidth: 2,
                strokeColor: Colors.white
            );
          }
      ),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.05)),
    );
  }

  // --- 🎨 UI 建構 ---
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PoemRecord>>(
      future: isarService.getAllRecords(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final filtered = _getThinnedRecords(all);

        return Scaffold(
          appBar: AppBar(
            title: const Text("病情趨勢分析", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blue.shade50,
            actions: [
              if (filtered.isNotEmpty)
                IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: "導出報告",
                    onPressed: () async {
                      final bytes = await _capturePng();
                      if (bytes != null) ExportService.generatePoemReport(filtered, bytes);
                    }
                ),
            ],
          ),
          body: Column(
            children: [
              _buildScaleSelector(), // 🚀 包含 ADCT 選項
              const SizedBox(height: 24),
              _buildChartHeader(filtered),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 32, 10),
                  child: RepaintBoundary(
                    key: _chartKey,
                    child: Container(
                      color: Colors.white,
                      child: filtered.isEmpty
                          ? const Center(child: Text("目前無檢測紀錄", style: TextStyle(color: Colors.grey)))
                          : LineChart(_mainData(filtered)),
                    ),
                  ),
                ),
              ),
              _buildFilterBar(),
              const SizedBox(height: 20),
              _buildSeverityLegend(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScaleSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: DropdownButtonFormField<ScaleType>(
        value: _selectedScale,
        style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
            labelText: "分析量表目標",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
        ),
        items: const [
          DropdownMenuItem(value: ScaleType.adct, child: Text("ADCT 控制評估 (每週)")),
          DropdownMenuItem(value: ScaleType.poem, child: Text("POEM 濕疹檢測 (每週)")),
          DropdownMenuItem(value: ScaleType.uas7, child: Text("UAS7 活性紀錄 (每日)")),
          DropdownMenuItem(value: ScaleType.scorad, child: Text("SCORAD 綜合評分 (每週)")),
        ],
        onChanged: (val) => setState(() => _selectedScale = val!),
      ),
    );
  }

  Widget _buildChartHeader(List<PoemRecord> filtered) {
    String unit = _selectedScale == ScaleType.uas7 ? '每日' : '每週';
    String title = "${_getScaleName(_selectedScale)} $unit趨勢圖";
    return Column(children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
      if (filtered.isNotEmpty)
        Text("${DateFormat('MM/dd').format(filtered.first.date!)} – ${DateFormat('MM/dd').format(filtered.last.date!)}",
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
    ]);
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
          children: [7, 14, 28, 90, -1].map((d) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                  label: Text(d == -1 ? "自訂範圍" : "${d}天"),
                  selected: _selectedDays == d,
                  onSelected: (v) async {
                    if (d == -1) {
                      final r = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
                      if (r != null) setState(() { _selectedDays = -1; _customRange = r; });
                    } else {
                      setState(() { _selectedDays = d; _customRange = null; });
                    }
                  }
              )
          )).toList()
      ),
    );
  }

  Widget _buildSeverityLegend() {
    String text = "";
    Color color = Colors.orange;

    if (_selectedScale == ScaleType.adct) {
      text = "控制不佳 (≥ 7 分)";
      color = Colors.red;
    } else if (_selectedScale == ScaleType.uas7) {
      text = "高度活性 (≥ 4 分)";
      color = Colors.orange;
    } else {
      text = "重度病灶 (≥ 17 分)";
      color = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text("臨床判定警戒：$text", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey))
      ]),
    );
  }

  // --- 🔧 數據輔助方法 ---

  double _getMaxYForScale(ScaleType t) {
    if (t == ScaleType.adct) return 24.0; //
    if (t == ScaleType.poem) return 28.0; //
    if (t == ScaleType.uas7) return 6.0;  // 每日最高分
    return 38.0;
  }

  double _getIntervalForScale(ScaleType t) => (t == ScaleType.uas7) ? 1.0 : 6.0;

  Color _getLineColor(ScaleType t) {
    if (t == ScaleType.uas7) return Colors.orangeAccent;
    if (t == ScaleType.adct) return Colors.teal;
    return Colors.blueAccent;
  }

  String _getScaleName(ScaleType type) {
    return type.toString().split('.').last.toUpperCase();
  }

  Future<Uint8List?> _capturePng() async {
    final RenderRepaintBoundary? b = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return null;
    ui.Image img = await b.toImage(pixelRatio: 3.0);
    ByteData? d = await img.toByteData(format: ui.ImageByteFormat.png);
    return d?.buffer.asUint8List();
  }
}