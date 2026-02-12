import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../services/export_service.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🚀 補上這行


class TrendChartScreen extends StatefulWidget {
  const TrendChartScreen({super.key});

  @override
  State<TrendChartScreen> createState() => _TrendChartScreenState();
}

class _TrendChartScreenState extends State<TrendChartScreen> {
  final GlobalKey _chartKey = GlobalKey();
  ScaleType _selectedScale = ScaleType.adct;

  int _selectedDays = 7;
  DateTimeRange? _customRange;
  final int _flareThreshold = 8;
  Map<ScaleType, bool> _enabledScales = {};

  @override
  void initState() {
    super.initState();
    _loadEnabledScales();
  }

  Future<void> _loadEnabledScales() async {
    final prefs = await SharedPreferences.getInstance();
    Map<ScaleType, bool> tempSettings = {};
    for (var type in ScaleType.values) {
      // 預設為 true，與首頁邏輯一致
      tempSettings[type] = prefs.getBool('enable_${type.name}') ?? true;
    }

    setState(() {
      _enabledScales = tempSettings;
      // 🚀 安全檢查：如果預設選擇的 ADCT 被關閉了，自動跳到第一個開啟的量表
      if (!(_enabledScales[_selectedScale] ?? true)) {
        _selectedScale = _enabledScales.entries
            .firstWhere((e) => e.value, orElse: () => _enabledScales.entries.first)
            .key;
      }
    });
  }

  // --- 📉 數據篩選邏輯 ---
  List<PoemRecord> _getThinnedRecords(List<PoemRecord> all) {
    List<PoemRecord> filtered = all.where((r) {
      final displayDate = r.targetDate ?? r.date;
      if (displayDate == null || r.scaleType != _selectedScale) return false;

      if (_selectedDays == -1 && _customRange != null) {
        // 🚀 補上自訂日期範圍的判定
        return displayDate.isAfter(_customRange!.start.subtract(const Duration(seconds: 1))) &&
            displayDate.isBefore(_customRange!.end.add(const Duration(days: 1)));
      }

      return DateTime.now().difference(displayDate).inDays <= (_selectedDays - 1);
    }).toList();

    filtered.sort((a, b) => (a.targetDate ?? a.date!).compareTo((b.targetDate ?? b.date!)));
    return filtered;
  }

  // --- 📊 圖表配置邏輯 ---
  // --- 📊 圖表配置邏輯 ---
  LineChartData _mainData(List<PoemRecord> filtered) {
    if (filtered.isEmpty) return LineChartData();

    final startDate = filtered.first.targetDate ?? filtered.first.date!;
    final endDate = filtered.last.targetDate ?? filtered.last.date!;
    final double rawDays = endDate.difference(startDate).inMinutes / 1440;

    // 🚀 核心修正：更積極的智慧標籤間隔，解決 14/28/90 天擁擠問題
    double bottomInterval = 1.0;
    if (rawDays > 60) {
      bottomInterval = 14.0; // 90天：每兩週顯示一個標籤
    } else if (rawDays > 20) {
      bottomInterval = 7.0;  // 28天：每週顯示一個標籤
    } else if (rawDays >= 10) {
      bottomInterval = 3.0;  // 14天：每三天顯示一個標籤
    }

    return LineChartData(
      minX: -0.2,
      maxX: rawDays < 0.5 ? 1.0 : rawDays + 0.5,
      minY: 0,
      maxY: _getMaxYForScale(_selectedScale),
      lineBarsData: [_getLineData(filtered, startDate)],
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        verticalInterval: bottomInterval, // 網格線隨日期密度調整
        horizontalInterval: _getIntervalForScale(_selectedScale),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: _getIntervalForScale(_selectedScale))),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40, // 增加預留高度防止遮擋
                interval: bottomInterval, // 套用新計算的間隔
                getTitlesWidget: (v, m) {
                  if (v < 0 || v > rawDays + 0.1) return const SizedBox.shrink();

                  final date = startDate.add(Duration(minutes: (v * 1440).toInt()));

                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0), // 增加間距防止被按鈕擋到
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  );
                }
            )
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2))),
    );
  }


  LineChartBarData _getLineData(List<PoemRecord> records, DateTime startDate) {
    Color color = _getLineColor(_selectedScale);

    final List<FlSpot> spots = records.map((r) {
      // 🚀 修正：使用 targetDate 計算與起點的天數差距
      final displayDate = r.targetDate ?? r.date!;
      return FlSpot(
          displayDate.difference(startDate).inMinutes / 1440,
          (r.score ?? 0).toDouble()
      );
    }).toList();

    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: 4,
      isCurved: _selectedScale != ScaleType.uas7 && spots.length >= 3, // 🚀 UAS7 建議用折線
      preventCurveOverShooting: true,
      curveSmoothness: 0.15, // 🚀 降低平滑度
      dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) {
            bool isFlare = false;
            if (index > 0) {
              final delta = (records[index].score ?? 0) - (records[index-1].score ?? 0);
              if (delta >= _flareThreshold) isFlare = true;
            }
            return FlDotCirclePainter(
                radius: isFlare ? 7 : 4,
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
    // 如果設定還沒讀取完，顯示載入中
    if (_enabledScales.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<List<PoemRecord>>(
      future: isarService.getAllRecords(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final filtered = _getThinnedRecords(all);

        return Scaffold(
          appBar: AppBar(
            title: const Text("病情趨勢分析", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blue.shade50,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildScaleSelector(),
                const SizedBox(height: 24),
                _buildChartHeader(filtered),
                const SizedBox(height: 20),

                // 🚀 圖表區塊
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 32, 10),
                  child: RepaintBoundary(
                    key: _chartKey,
                    child: Container(
                      height: 300,
                      color: Colors.white,
                      child: filtered.isEmpty
                          ? const Center(child: Text("目前無檢測紀錄", style: TextStyle(color: Colors.grey)))
                          : LineChart(_mainData(filtered)),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                _buildFilterBar(),
                const SizedBox(height: 20),
                _buildSeverityLegend(),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),

                // 🚀 長輩友善巨型按鈕 (85px 高)
                _buildLargeExportButton(filtered),

                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScaleSelector() {
    // 🚀 只過濾出被開啟的選項
    final List<ScaleType> availableScales = ScaleType.values
        .where((type) => _enabledScales[type] ?? true)
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: DropdownButtonFormField<ScaleType>(
        value: _selectedScale,
        style: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
            labelText: "分析量表目標",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
        ),
        // 🚀 動態生成選單內容
        items: availableScales.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(_getScaleDisplayName(type)),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedScale = val!),
      ),
    );
  }

// 輔助方法：獲取更友善的名稱
  String _getScaleDisplayName(ScaleType type) {
    switch (type) {
      case ScaleType.adct: return "ADCT 控制評估 (每週)";
      case ScaleType.poem: return "POEM 濕疹檢測 (每週)";
      case ScaleType.uas7: return "UAS7 活性紀錄 (每日)";
      case ScaleType.scorad: return "SCORAD 綜合評分 (每週)";
      default: return type.toString();
    }
  }

  Widget _buildLargeExportButton(List<PoemRecord> filtered) {
    final bool hasData = filtered.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        width: double.infinity,
        height: 85,
        child: ElevatedButton.icon(
          onPressed: !hasData ? null : () async {
            final bytes = await _capturePng();
            if (bytes != null) {
              // 🚀 確保傳遞完整的 filtered 清單，ExportService 會根據 targetDate 再次校準
              ExportService.generateClinicalReport(
                  filtered,
                  bytes,
                  _selectedScale
              );
            }
          },
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 34),
          label: const Text("導出專業臨床報告", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade700,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }

  Widget _buildChartHeader(List<PoemRecord> filtered) {
    String unit = _selectedScale == ScaleType.uas7 ? '每日' : '每週';

    // 🚀 關鍵修正 1：確保觀察區間顯示的是病程的真實歸屬日期 (Target Date)
    final firstDisplayDate = filtered.isNotEmpty ? (filtered.first.targetDate ?? filtered.first.date!) : null;
    final lastDisplayDate = filtered.isNotEmpty ? (filtered.last.targetDate ?? filtered.last.date!) : null;

    return Column(children: [
      // 🚀 關鍵修正 2：移除 "pw." 前綴。在 Screen 檔案裡要用 Flutter 原生的 TextStyle
      Text(
          "${_getScaleName(_selectedScale)} $unit趨勢圖",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold) // 移除 pw. 和 const 衝突問題
      ),
      if (filtered.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
              "${DateFormat('MM/dd').format(firstDisplayDate!)} – ${DateFormat('MM/dd').format(lastDisplayDate!)}",
              style: const TextStyle(fontSize: 16, color: Colors.grey)
          ),
        ),
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
                  label: Text(d == -1 ? "自訂範圍" : "${d}天", style: const TextStyle(fontSize: 16)),
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
      // 🚀 修正：每日圖表應標註每日活性判定
      text = "高度活性 (每日 ≥ 5 分)";
      color = Colors.orange;
    } else {
      text = "重度病灶 (≥ 17 分)";
      color = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Text("臨床警戒：$text", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey))
      ]),
    );
  }

  // --- 🔧 臨床輔助方法 ---
  double _getMaxYForScale(ScaleType t) {
    if (t == ScaleType.adct) return 24.0;
    if (t == ScaleType.poem) return 28.0;
    if (t == ScaleType.uas7) return 6.0;
    return 38.0;
  }

  double _getIntervalForScale(ScaleType t) => t == ScaleType.uas7 ? 1.0 : 7.0;
  Color _getLineColor(ScaleType t) {
    if (t == ScaleType.uas7) return Colors.orangeAccent;
    if (t == ScaleType.adct) return Colors.teal;
    if (t == ScaleType.scorad) return Colors.purpleAccent; // 🚀 新增紫色區分
    return Colors.blueAccent;
  }
  String _getScaleName(ScaleType type) => type.toString().split('.').last.toUpperCase();

  Future<Uint8List?> _capturePng() async {
    final RenderRepaintBoundary? b = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return null;
    ui.Image img = await b.toImage(pixelRatio: 3.0);
    ByteData? d = await img.toByteData(format: ui.ImageByteFormat.png);
    return d?.buffer.asUint8List();
  }
}