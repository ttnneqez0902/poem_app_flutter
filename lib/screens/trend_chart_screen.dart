import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../services/export_service.dart';
import '../main.dart';
import '../models/scale_config.dart'; // 🚀 確保有引入這個，才能認得 AppCategory
import 'package:shared_preferences/shared_preferences.dart';


class TrendChartScreen extends StatefulWidget {
  // 🚀 1. 新增這個必填參數
  final AppCategory currentCategory;
  const TrendChartScreen({
    super.key,
    required this.currentCategory, // 🚀 2. 在這裡接收參數
  });

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

  _loadEnabledScales() async {
    final prefs = await SharedPreferences.getInstance();
    Map<ScaleType, bool> tempSettings = {};
    for (var type in ScaleType.values) {
      tempSettings[type] = prefs.getBool('enable_${type.name}') ?? true;
    }

    setState(() {
      _enabledScales = tempSettings;

      // 🚀 根據科別設定初始量表，避免身心科進去卻抓皮膚科量表
      if (widget.currentCategory == AppCategory.psychiatry) {
        _selectedScale = ScaleType.phq9;
      } else if (widget.currentCategory == AppCategory.pain) {
        _selectedScale = ScaleType.vas;
      } else {
        _selectedScale = ScaleType.adct;
      }

      // 防呆：如果預設量表被關閉了，改選該科別下第一個啟用的
      if (!(_enabledScales[_selectedScale] ?? true)) {
        _selectedScale = ScaleType.values.firstWhere(
              (t) => _isScaleInCategory(t, widget.currentCategory) && (_enabledScales[t] ?? true),
          orElse: () => _selectedScale,
        );
      }
    });
  }

// 輔助方法：判斷量表是否屬於該科別 (建議加在類別末尾)
  bool _isScaleInCategory(ScaleType type, AppCategory category) {
    if (category == AppCategory.dermatology) return [ScaleType.adct, ScaleType.poem, ScaleType.uas7, ScaleType.scorad].contains(type);
    if (category == AppCategory.psychiatry) return [ScaleType.phq9, ScaleType.gad7].contains(type);
    return type == ScaleType.vas;
  }

  // --- 📉 數據篩選邏輯 ---
  List<PoemRecord> _getThinnedRecords(List<PoemRecord> all) {
    List<PoemRecord> filtered = all.where((r) {
      final displayDate = r.targetDate ?? r.date;
      if (displayDate == null || r.scaleType != _selectedScale) return false;

      if (_selectedDays == -1 && _customRange != null) {
        return displayDate.isAfter(_customRange!.start.subtract(const Duration(seconds: 1))) &&
            displayDate.isBefore(_customRange!.end.add(const Duration(days: 1)));
      }

      return DateTime.now().difference(displayDate).inDays <= (_selectedDays - 1);
    }).toList();

    filtered.sort((a, b) => (a.targetDate ?? a.date!).compareTo((b.targetDate ?? b.date!)));
    return filtered;
  }

  double _getThresholdForScale(ScaleType t) {
    if (t == ScaleType.uas7) return 5;
    if (t == ScaleType.adct) return 7;
    if (t == ScaleType.poem) return 17;
    if (t == ScaleType.phq9) return 10; // 🚀 PHQ-9 臨床警戒線 10
    if (t == ScaleType.gad7) return 10; // 🚀 GAD-7 臨床警戒線 10
    return 25;
  }

  // --- 📊 圖表配置邏輯 ---
  LineChartData _mainData(List<PoemRecord> filtered, BuildContext context) {
    if (filtered.isEmpty) return LineChartData();

    final startDate = filtered.first.targetDate ?? filtered.first.date!;
    final endDate = filtered.last.targetDate ?? filtered.last.date!;
    final threshold = _getThresholdForScale(_selectedScale);
    final double rawDays = endDate.difference(startDate).inMinutes / 1440;

    double bottomInterval = 1.0;
    if (rawDays > 60) {
      bottomInterval = 14.0;
    } else if (rawDays > 20) {
      bottomInterval = 7.0;
    } else if (rawDays >= 10) {
      bottomInterval = 3.0;
    }

    // 🚀 動態判定目前是否為深色模式，以決定網格與文字顏色
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final textColor = isDark ? Colors.grey.shade400 : Colors.blueGrey;

    return LineChartData(
      minX: -0.2,
      maxX: rawDays < 0.5 ? 1.0 : rawDays + 0.8,
      minY: 0,
      maxY: _getMaxYForScale(_selectedScale),

      lineBarsData: [
        _getLineData(filtered, startDate)
      ],

      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: threshold,
            color: Colors.redAccent.withOpacity(0.8),
            strokeWidth: 2,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              style: TextStyle(
                fontSize: 10,
                color: Colors.redAccent.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
              labelResolver: (_) => "≥${threshold.toInt()}",
            ),
          ),
        ],
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        verticalInterval: bottomInterval,
        horizontalInterval: _getIntervalForScale(_selectedScale),
        // 🚀 網格線顏色適配深色模式
        getDrawingHorizontalLine: (value) => FlLine(color: gridColor, strokeWidth: 1),
        getDrawingVerticalLine: (value) => FlLine(color: gridColor, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: _getIntervalForScale(_selectedScale),
              // 🚀 Y軸數字顏色適配
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: textColor, fontSize: 12)),
            )
        ),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: bottomInterval,
                getTitlesWidget: (v, m) {
                  if (v < 0 || v > rawDays + 0.1) return const SizedBox.shrink();

                  final date = startDate.add(Duration(minutes: (v * 1440).toInt()));

                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      // 🚀 X軸日期顏色適配
                      style: TextStyle(
                          fontSize: 10,
                          color: textColor,
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
      // 🚀 邊框顏色適配深色模式
      borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: gridColor, width: 2), left: BorderSide(color: gridColor, width: 2))),
    );
  }

  LineChartBarData _getLineData(List<PoemRecord> records, DateTime startDate) {
    Color color = _getLineColor(_selectedScale);

    final List<FlSpot> spots = records.map((r) {
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
      isCurved: _selectedScale != ScaleType.uas7 && spots.length >= 3,
      preventCurveOverShooting: true,
      curveSmoothness: 0.15,
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
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.08),
      ),
    );
  }

  // --- 🎨 UI 建構 ---
  @override
  Widget build(BuildContext context) {
    if (_enabledScales.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<List<PoemRecord>>(
      future: isarService.getAllRecords(),
      builder: (context, snapshot) {
        // 1. 先拿到原始數據
        final allRawData = snapshot.data ?? [];

        // 🚀 2. 在這裡加入你提供的「科別篩選」邏輯 (這就是你要加的地方！)
        final categoryRecords = allRawData.where((r) {
          switch (widget.currentCategory) {
            case AppCategory.dermatology:
              return [ScaleType.adct, ScaleType.poem, ScaleType.uas7, ScaleType.scorad].contains(r.scaleType);
            case AppCategory.psychiatry:
              return [ScaleType.phq9, ScaleType.gad7].contains(r.scaleType);
            case AppCategory.pain:
              return r.scaleType == ScaleType.vas;
            default:
              return false;
          }
        }).toList();

        // 3. 最後再丟入原本的「時間/量表細分過濾」
        final filtered = _getThinnedRecords(categoryRecords);

        return Scaffold(
          appBar: AppBar(
            title: const Text("病情趨勢分析", style: TextStyle(fontWeight: FontWeight.bold)),
            // 🚀 1. 移除 backgroundColor: Colors.blue.shade50，讓 AppBar 隨系統深淺色變換
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: RepaintBoundary(
                    key: _chartKey,
                    child: Container(
                      height: 300,
                      // 🚀 2. 將 Colors.white 改為 Theme 的 cardColor，並加入圓角讓圖表變精緻
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 16, 24, 0), // 內縮避免圖表貼邊
                      child: filtered.isEmpty
                          ? const Center(child: Text("目前無檢測紀錄", style: TextStyle(color: Colors.grey)))
                      // 🚀 3. 將 context 傳入 _mainData
                          : LineChart(_mainData(filtered, context)),
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
    // 🚀 修改點：過濾選單，只顯示「目前科別」且「已啟用」的量表
    final List<ScaleType> availableScales = ScaleType.values
        .where((type) =>
    _isScaleInCategory(type, widget.currentCategory) && // 門神 1：科別正確
        (_enabledScales[type] ?? true)                      // 門神 2：設定開啟
    ).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<ScaleType>(
        value: _selectedScale,
        style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold
        ),
        decoration: InputDecoration(
            labelText: "分析量表目標",
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
        ),
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

  String _getScaleDisplayName(ScaleType type) {
    switch (type) {
      case ScaleType.adct: return "ADCT 控制評估 (每週)";
      case ScaleType.poem: return "POEM 濕疹檢測 (每週)";
      case ScaleType.uas7: return "UAS7 活性紀錄 (每日)";
      case ScaleType.scorad: return "SCORAD 綜合評分 (每週)";
    // 🚀 新增身心科與疼痛
      case ScaleType.phq9: return "PHQ-9 憂鬱情緒篩檢 (兩週)";
      case ScaleType.gad7: return "GAD-7 焦慮狀況評估 (兩週)";
      case ScaleType.vas: return "VAS 疼痛視覺類比 (即時)";
      default: return type.toString().split('.').last.toUpperCase();
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
              ExportService.generateClinicalReport(
                  filtered,
                  bytes,
                  _selectedScale
              );
            }
          },
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 34),
          label: const Text("導出專業臨床報告", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade700,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade800, // 🚀 適配深色模式的停用顏色
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }

  Widget _buildChartHeader(List<PoemRecord> filtered) {
    String unit = _selectedScale == ScaleType.uas7 ? '每日' : '每週';

    final firstDisplayDate = filtered.isNotEmpty ? (filtered.first.targetDate ?? filtered.first.date!) : null;
    final lastDisplayDate = filtered.isNotEmpty ? (filtered.last.targetDate ?? filtered.last.date!) : null;

    return Column(children: [
      Text(
          "${_getScaleName(_selectedScale)} $unit趨勢圖",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
      ),
      if (filtered.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
              "${DateFormat('MM/dd').format(firstDisplayDate!)} – ${DateFormat('MM/dd').format(lastDisplayDate!)}  (≥${_getThresholdForScale(_selectedScale).toInt()})",
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

    final threshold = _getThresholdForScale(_selectedScale);
    final lineColor = _getLineColor(_selectedScale);

    String label;

    switch (_selectedScale) {
      case ScaleType.uas7: label = "UAS7 臨床警戒"; break;
      case ScaleType.adct: label = "ADCT 控制不佳"; break;
      case ScaleType.poem: label = "POEM 重度"; break;
      case ScaleType.phq9: label = "PHQ-9 中度憂鬱"; break; // 🚀 新增
      case ScaleType.gad7: label = "GAD-7 中度焦慮"; break; // 🚀 新增
      case ScaleType.vas: label = "VAS 中度疼痛"; break;   // 🚀 新增
      default: label = "臨床重度";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [

          /// 趨勢線
          Container(
            width: 20,
            height: 4,
            color: lineColor,
          ),

          const SizedBox(width: 8),

          const Text(
            "趨勢",
            style: TextStyle(fontSize: 13),
          ),

          const SizedBox(width: 20),

          /// 警戒線
          Row(
            children: List.generate(
              6,
                  (i) => Container(
                width: 3,
                height: 4,
                margin: const EdgeInsets.only(right: 2),
                color: Colors.redAccent.withOpacity(0.8),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              "$label ≥ ${threshold.toInt()}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxYForScale(ScaleType t) {
    if (t == ScaleType.adct) return 24.0;
    if (t == ScaleType.poem) return 28.0;
    if (t == ScaleType.uas7) return 6.0;
    if (t == ScaleType.phq9) return 27.0; // 🚀 PHQ-9 最高 27 分
    if (t == ScaleType.gad7) return 21.0; // 🚀 GAD-7 最高 21 分
    if (t == ScaleType.vas) return 10.0;  // 🚀 VAS 最高 10 分
    return 38.0;
  }

  // 優化間距：讓座標軸數字更整齊
  double _getIntervalForScale(ScaleType t) {
    if (t == ScaleType.uas7) return 1.0;
    if (t == ScaleType.vas) return 2.0;    // 🚀 VAS 每 2 分一格
    if (t == ScaleType.phq9) return 3.0;   // 🚀 PHQ-9 每 3 分一格 (因總分27)
    return 5.0; // 其他（如 POEM）每 5 分一格
  }

  // 匹配首頁配色
  Color _getLineColor(ScaleType t) {
    if (t == ScaleType.uas7) return Colors.orangeAccent;
    if (t == ScaleType.adct) return Colors.teal;
    if (t == ScaleType.scorad) return Colors.purpleAccent;
    if (t == ScaleType.phq9) return Colors.indigo;      // 🚀 身心科靛色
    if (t == ScaleType.gad7) return Colors.green.shade700; // 🚀 焦慮綠色
    if (t == ScaleType.vas) return Colors.redAccent;     // 🚀 疼痛紅色
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