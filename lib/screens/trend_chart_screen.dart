import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../services/export_service.dart';
import '../main.dart';
import '../models/scale_config.dart';
import '../models/growth_curve_data.dart';

class TrendChartScreen extends StatefulWidget {
  final AppCategory currentCategory;
  const TrendChartScreen({
    super.key,
    required this.currentCategory,
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

  // 👶 兒科專用狀態
  String _growthViewMode = 'height';
  bool _isBoy = true;
  DateTime? _childBirthday;

  @override
  void initState() {
    super.initState();
    _loadChildInfo();
    _loadEnabledScales();
  }

  DateTime? _childDueDate;
  // --- ⚙️ 初始化邏輯 ---

  // 🚀 修改 _loadChildInfo 方法 (第 44 行附近)：
  Future<void> _loadChildInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBoy = prefs.getBool('child_is_boy') ?? true;
      final bStr = prefs.getString('child_birthday');
      if (bStr != null) _childBirthday = DateTime.parse(bStr);

      // 🚀 補上這行，確保預產期被讀入
      final dStr = prefs.getString('child_due_date');
      if (dStr != null) _childDueDate = DateTime.parse(dStr);
    });
  }

  Future<void> _loadEnabledScales() async {
    final prefs = await SharedPreferences.getInstance();
    Map<ScaleType, bool> tempSettings = {};
    for (var type in ScaleType.values) {
      tempSettings[type] = prefs.getBool('enable_${type.name}') ?? true;
    }

    setState(() {
      _enabledScales = tempSettings;
      // 根據科別初始化預設量表
      switch (widget.currentCategory) {
        case AppCategory.psychiatry: _selectedScale = ScaleType.phq9; break;
        case AppCategory.rheumatology:
        case AppCategory.pain: _selectedScale = ScaleType.vas; break; // 🚀 修正：痛症與風濕預設 VAS
        case AppCategory.gastro: _selectedScale = ScaleType.bristol; break;
        case AppCategory.womens: _selectedScale = ScaleType.cycle; break; // 🚀 修正：女性健康預設生理期
        case AppCategory.peds: _selectedScale = ScaleType.growth; break;
        default: _selectedScale = ScaleType.adct;
      }
    });
  }

  // --- 📉 數據與臨床邏輯 ---

  bool _isScaleInCategory(ScaleType type, AppCategory category) {
    switch (category) {
      case AppCategory.dermatology: return [ScaleType.adct, ScaleType.poem, ScaleType.uas7, ScaleType.scorad].contains(type);
      case AppCategory.psychiatry: return [ScaleType.phq9, ScaleType.gad7].contains(type);
      case AppCategory.rheumatology:
      case AppCategory.pain: return [ScaleType.vas, ScaleType.haq].contains(type);
      case AppCategory.gastro: return [ScaleType.bristol, ScaleType.ibs_sss].contains(type);
      case AppCategory.womens: return [ScaleType.cycle].contains(type);
      case AppCategory.peds: return [ScaleType.growth].contains(type);
      default: return false;
    }
  }

  List<PoemRecord> _getThinnedRecords(List<PoemRecord> all) {
    List<PoemRecord> filtered = all.where((r) {
      final date = r.targetDate ?? r.date;
      if (date == null || r.scaleType != _selectedScale) return false;
      if (_selectedDays == -1 && _customRange != null) {
        return date.isAfter(_customRange!.start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(_customRange!.end.add(const Duration(days: 1)));
      }
      return DateTime.now().difference(date).inDays <= (_selectedDays - 1);
    }).toList();
    return filtered..sort((a, b) => (a.targetDate ?? a.date!).compareTo((b.targetDate ?? b.date!)));
  }

  double _getThresholdForScale(ScaleType t) {
    if (t == ScaleType.uas7) return 5;
    if (t == ScaleType.adct) return 7;
    if (t == ScaleType.poem) return 17;
    if (t == ScaleType.phq9 || t == ScaleType.gad7) return 10;
    if (t == ScaleType.vas) return 4;
    if (t == ScaleType.ibs_sss) return 35;
    if (t == ScaleType.haq) return 1.0;
    if (t == ScaleType.scorad) return 50.0;
    return 0.0;
  }

  // --- 📊 圖表核心引擎 ---

  LineChartData _mainData(List<PoemRecord> filtered, BuildContext context) {
    if (filtered.isEmpty) return LineChartData();

    final startDate = filtered.first.targetDate ?? filtered.first.date!;
    final endDate = filtered.last.targetDate ?? filtered.last.date!;
    final threshold = _getThresholdForScale(_selectedScale);
    final double rawDays = endDate.difference(startDate).inMinutes / 1440;

    double bottomInterval = rawDays > 60 ? 14.0 : (rawDays > 20 ? 7.0 : (rawDays >= 10 ? 3.0 : 1.0));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final textColor = isDark ? Colors.grey.shade400 : Colors.blueGrey;
    final color = _getLineColor(_selectedScale);

    List<LineChartBarData> allLines = [];
    if (_selectedScale == ScaleType.growth) {
      allLines.addAll(_getGrowthBackgroundLines(startDate));
    }
    allLines.add(_getLineData(filtered, startDate));

    return LineChartData(
      lineTouchData: LineTouchData(
        touchCallback: (event, res) { if (event is FlPanStartEvent || event is FlTapDownEvent) HapticFeedback.selectionClick(); },
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => isDark ? const Color(0xFF2C2C2C) : Colors.indigo.shade50,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              if (spot.barIndex < allLines.length - 1 && _selectedScale == ScaleType.growth) return null;
              final date = startDate.add(Duration(minutes: (spot.x * 1440).toInt()));
              bool dec = (_selectedScale == ScaleType.growth && _growthViewMode == 'weight') || (_selectedScale == ScaleType.haq);
              String valStr = dec ? spot.y.toStringAsFixed(1) : spot.y.toInt().toString();
              String unit = _selectedScale == ScaleType.growth ? (_growthViewMode == 'weight' ? " kg" : " cm") : " 分";
              if (_selectedScale == ScaleType.bristol) unit = " 型";

              return LineTooltipItem(
                "${DateFormat('MM/dd').format(date)}\n",
                TextStyle(color: isDark ? Colors.white70 : Colors.indigo.shade900, fontWeight: FontWeight.bold),
                children: [TextSpan(text: "$valStr$unit", style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900))],
              );
            }).toList();
          },
        ),
      ),
      minX: -0.2, maxX: rawDays < 0.5 ? 1.0 : rawDays + 0.8,
      minY: _selectedScale == ScaleType.growth ? _getMinYForGrowth(filtered) : 0,
      maxY: _getMaxYForScale(_selectedScale, filtered),
      lineBarsData: allLines,
      extraLinesData: ExtraLinesData(
        horizontalLines: [ScaleType.growth, ScaleType.bristol, ScaleType.cycle].contains(_selectedScale) ? [] : [
          HorizontalLine(y: threshold, color: Colors.redAccent.withOpacity(0.8), strokeWidth: 2, dashArray: [6, 4],
            label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, style: TextStyle(fontSize: 10, color: Colors.redAccent.withOpacity(0.8), fontWeight: FontWeight.bold), labelResolver: (_) => "警戒 ≥${threshold.toInt()}"),
          ),
        ],
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48, interval: _getIntervalForScale(_selectedScale),
          getTitlesWidget: (value, meta) {
            if (_selectedScale == ScaleType.bristol) {
              String t = ""; if (value == 1) t = '便秘'; else if (value == 4) t = '理想'; else if (value == 7) t = '腹瀉';
              return SideTitleWidget(meta: meta, child: Text(t, style: const TextStyle(fontSize: 10, color: Colors.brown)));
            }
            bool dec = (_selectedScale == ScaleType.growth && _growthViewMode == 'weight') || (_selectedScale == ScaleType.haq);
            return SideTitleWidget(meta: meta, child: Text(dec ? value.toStringAsFixed(1) : value.toInt().toString(), style: TextStyle(color: textColor, fontSize: 10)));
          },
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, interval: bottomInterval,
          getTitlesWidget: (v, m) {
            if (v < 0 || v > rawDays + 0.1) return const SizedBox.shrink();
            return SideTitleWidget(meta: m, child: Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('MM/dd').format(startDate.add(Duration(minutes: (v * 1440).toInt()))), style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold))));
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, verticalInterval: bottomInterval, horizontalInterval: _getIntervalForScale(_selectedScale)),
      borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: gridColor, width: 2), left: BorderSide(color: gridColor, width: 2))),
    );
  }

  // --- 🛠️ 內部組件與計算 ---

  LineChartBarData _getLineData(List<PoemRecord> records, DateTime startDate) {
    Color color = _getLineColor(_selectedScale);
    if (_selectedScale == ScaleType.growth) {
      if (_growthViewMode == 'weight') color = Colors.green;
      else if (_growthViewMode == 'head') color = Colors.orange;
    }
    final spots = records.map((r) {
      double y = (r.scaleType == ScaleType.growth)
          ? (_growthViewMode == 'weight' ? (r.weight ?? 0.0) : (_growthViewMode == 'head' ? (r.headCircumference ?? 0.0) : (r.height ?? 0.0)))
          : (r.score ?? 0).toDouble();
      return FlSpot((r.targetDate ?? r.date!).difference(startDate).inMinutes / 1440.0, y);
    }).where((s) => _selectedScale == ScaleType.growth ? s.y > 0 : true).toList();

    return LineChartBarData(
      spots: spots, color: color, barWidth: 4, isCurved: _selectedScale != ScaleType.uas7 && spots.length >= 3,
      dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 6, color: color, strokeWidth: 2, strokeColor: Colors.white)),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
    );
  }

  List<LineChartBarData> _getGrowthBackgroundLines(DateTime startDate) {
    if (_childBirthday == null) return [];
    final double offset = startDate.difference(_childBirthday!).inDays.toDouble();
    List<List<FlSpot>> raw;
    if (_growthViewMode == 'weight') raw = _isBoy ? BoyWeightData.allPercentiles : GirlWeightData.allPercentiles;
    else if (_growthViewMode == 'head') raw = _isBoy ? BoyHeadCircumferenceData.allPercentiles : GirlHeadCircumferenceData.allPercentiles;
    else raw = _isBoy ? BoyHeightData.allPercentiles : GirlHeightData.allPercentiles;

    return raw.map((spots) => LineChartBarData(
      spots: spots.map((s) => FlSpot(s.x * 30.4375 - offset, s.y)).where((s) => s.x >= -30 && s.x <= _selectedDays + 30).toList(),
      isCurved: true, color: Colors.grey.withOpacity(0.15), barWidth: 1.2, dashArray: [5, 5], dotData: const FlDotData(show: false),
    )).toList();
  }

  double _getMinYForGrowth(List<PoemRecord> filtered) {
    if (filtered.isEmpty) return 0;
    double minV = 999;
    for (var r in filtered) {
      double v = _growthViewMode == 'weight' ? (r.weight ?? 0) : (_growthViewMode == 'head' ? (r.headCircumference ?? 0) : (r.height ?? 0));
      if (v > 0 && v < minV) minV = v;
    }
    return (minV - 5).clamp(0, 200);
  }

  double _getMaxYForScale(ScaleType t, List<PoemRecord> filtered) {
    if (t == ScaleType.growth) {
      double maxV = 0;
      for (var r in filtered) {
        double v = _growthViewMode == 'weight' ? (r.weight ?? 0) : (_growthViewMode == 'head' ? (r.headCircumference ?? 0) : (r.height ?? 0));
        if (v > maxV) maxV = v;
      }
      return maxV > 0 ? maxV * 1.15 : 100;
    }

// 🚀 補上這幾行
    if (t == ScaleType.scorad) return 110.0;  // SCORAD 滿分約 103
    if (t == ScaleType.ibs_sss) return 520.0; // IBS-SSS 滿分 500
    if (t == ScaleType.gad7) return 22.0;    // GAD-7 滿分 21

    if (t == ScaleType.vas || t == ScaleType.cycle) return 10.5;
    if (t == ScaleType.bristol) return 7.5;
    if (t == ScaleType.haq) return 3.2;
    if (t == ScaleType.phq9) return 27.5;
    return 30.0;
  }

// 🚀 修改：座標軸間距優化
  double _getIntervalForScale(ScaleType t) {
    if (t == ScaleType.growth) return _growthViewMode == 'weight' ? 2.0 : 5.0;
    if (t == ScaleType.bristol || t == ScaleType.haq) return 1.0;
    if (t == ScaleType.scorad || t == ScaleType.ibs_sss) return 20.0; // 🚀 大量表間隔加大
    return 5.0;
  }

  Color _getLineColor(ScaleType t) {
    switch (t) {
      case ScaleType.uas7: return Colors.orangeAccent;
      case ScaleType.adct: return Colors.teal;
      case ScaleType.phq9: return Colors.indigo;
      case ScaleType.gad7: return Colors.green.shade700; // 🚀 新增
      case ScaleType.scorad: return Colors.purpleAccent; // 🚀 新增
      case ScaleType.growth: return Colors.lightBlue;
      case ScaleType.vas: return Colors.redAccent;
      case ScaleType.bristol: return Colors.brown;
      case ScaleType.ibs_sss: return Colors.orange; // 🚀 新增
      default: return Colors.blueAccent;
    }
  }


  // 🚀 修改：補齊顯示名稱
  String _getScaleDisplayName(ScaleType t) {
    switch (t) {
      case ScaleType.vas: return "VAS 疼痛強度";
      case ScaleType.haq: return "HAQ 功能評估";
      case ScaleType.bristol: return "布里斯托便便分類";
      case ScaleType.growth: return "生長曲線數據";
      case ScaleType.cycle: return "生理週期紀錄";
      case ScaleType.phq9: return "PHQ-9 憂鬱篩檢";
      case ScaleType.gad7: return "GAD-7 焦慮評估"; // 🚀 新增
      case ScaleType.adct: return "ADCT 控制評估";
      case ScaleType.poem: return "POEM 濕疹檢測";
      case ScaleType.uas7: return "UAS7 活性紀錄";
      case ScaleType.scorad: return "SCORAD 綜合評分"; // 🚀 新增
      case ScaleType.ibs_sss: return "IBS 腸胃嚴重度"; // 🚀 新增
      default: return t.name.toUpperCase();
    }
  }

  // --- 🎨 UI 建構 ---

  @override
  Widget build(BuildContext context) {
    if (_enabledScales.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return FutureBuilder<List<PoemRecord>>(
      future: isarService.getAllRecords(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final categoryRecords = all.where((r) => _isScaleInCategory(r.scaleType, widget.currentCategory)).toList();
        final filtered = _getThinnedRecords(categoryRecords);

        return Scaffold(
          appBar: AppBar(
            title: Text(
                "${_getCategoryName(widget.currentCategory)} 趨勢分析",
                style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            centerTitle: true,

            // 🚀 就是這裡！在 AppBar 裡面加入 actions
            actions: [
              // 只有在兒科類別下才顯示這個小頭像按鈕
              if (widget.currentCategory == AppCategory.peds)
                IconButton(
                  icon: const Icon(Icons.face_retouching_natural_rounded), // 換一個更顯眼的圖示
                  onPressed: _showChildProfileEditor,
                  tooltip: "修改寶寶資料",
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(children: [
              _buildScaleSelector(),
              if (_selectedScale == ScaleType.growth) _buildGrowthModeChips(),
              const SizedBox(height: 24),
              _buildChartHeader(filtered),
              const SizedBox(height: 10),
              _buildChartContainer(filtered),
              _buildFilterBar(),
              const SizedBox(height: 20),
              _buildSeverityLegend(),
              const SizedBox(height: 40),
              _buildLargeExportButton(filtered),
              const SizedBox(height: 60),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildChartContainer(List<PoemRecord> filtered) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RepaintBoundary(
        key: _chartKey,
        child: Container(
          height: 350,
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
          ),
          padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
          child: () {
            // 🚀 優先級 1：如果是兒科且沒設生日，不管有沒有紀錄，都先叫他去設定
            if (_selectedScale == ScaleType.growth && _childBirthday == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.child_care_rounded, size: 64, color: Colors.lightBlue),
                    const SizedBox(height: 12),
                    const Text("尚未設定寶寶基本資料", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      child: Text("設定生日與性別後，系統才能為您對照 WHO 生長百分位參考線。",
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                    TextButton.icon(
                      onPressed: _showChildProfileEditor,
                      icon: const Icon(Icons.edit_calendar_rounded),
                      label: const Text("立即設定資料"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.lightBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  ],
                ),
              );
            }

            // 🚀 優先級 2：沒資料
            if (filtered.isEmpty) {
              return const Center(child: Text("目前此指標無紀錄", style: TextStyle(color: Colors.grey)));
            }

            // 🚀 優先級 3：正常繪圖
            return LineChart(_mainData(filtered, context));
          }(), // 這裡用一個立即執行的匿名函數來處理複雜判斷
        ),
      ),
    );
  }

  Widget _buildScaleSelector() {
    final list = ScaleType.values.where((t) => _isScaleInCategory(t, widget.currentCategory) && (_enabledScales[t] ?? true)).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<ScaleType>(
        value: _selectedScale,
        decoration: InputDecoration(labelText: "分析目標", filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        items: list.map((t) => DropdownMenuItem(value: t, child: Text(_getScaleDisplayName(t)))).toList(),
        onChanged: (v) => setState(() => _selectedScale = v!),
      ),
    );
  }

  Widget _buildGrowthModeChips() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _buildModeChip("身高", 'height', Colors.blue),
      const SizedBox(width: 8),
      _buildModeChip("體重", 'weight', Colors.green),
      const SizedBox(width: 8),
      _buildModeChip("頭圍", 'head', Colors.orange),
    ]);
  }

  void _showChildProfileEditor() {
    bool tempIsBoy = _isBoy;
    DateTime tempBirthday = _childBirthday ?? DateTime.now();
    DateTime tempDueDate = _childDueDate ?? tempBirthday; // 🚀 預設跟隨生日

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("寶寶基本資料設定", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // 1. 性別切換
                _buildSettingTile(
                  icon: tempIsBoy ? Icons.boy_rounded : Icons.girl_rounded,
                  iconColor: tempIsBoy ? Colors.blue : Colors.pink,
                  title: "寶寶性別",
                  trailing: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text("男"), icon: Icon(Icons.male)),
                      ButtonSegment(value: false, label: Text("女"), icon: Icon(Icons.female)),
                    ],
                    selected: {tempIsBoy},
                    onSelectionChanged: (v) => setModalState(() => tempIsBoy = v.first),
                  ),
                ),

                const Divider(height: 32),

                // 2. 出生日期
                _buildSettingTile(
                  icon: Icons.cake_rounded,
                  iconColor: Colors.orange,
                  title: "出生日期",
                  subtitle: DateFormat('yyyy / MM / dd').format(tempBirthday),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: tempBirthday, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (picked != null) setModalState(() => tempBirthday = picked);
                  },
                ),

                // 3. 預產期 (早產兒矯正年齡評估用)
                _buildSettingTile(
                  icon: Icons.child_friendly_rounded,
                  iconColor: Colors.teal,
                  title: "預產期 (選填)",
                  subtitle: DateFormat('yyyy / MM / dd').format(tempDueDate),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      // 🚀 關鍵改動：將初始日期設為 tempBirthday
                      // 這樣當使用者點開日曆時，會直接停在他們剛剛選好的出生日期那一天
                      initialDate: tempBirthday,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2027),
                    );
                    if (picked != null) {
                      setModalState(() {
                        tempBirthday = picked;
                        // 🚀 UX 進階連動：選完生日，自動把預產期也先設成那一天，方便後續微調
                        tempDueDate = picked;
                      });
                    }
                  },
                ),

// 3. 預產期 (修正後的邏輯)
                _buildSettingTile(
                  icon: Icons.child_friendly_rounded,
                  iconColor: Colors.teal,
                  title: "預產期 (選填)",
                  subtitle: DateFormat('yyyy / MM / dd').format(tempDueDate),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempBirthday, // 🚀 關鍵改動：日曆自動打開在「出生日期」那一天
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2027),
                    );
                    if (picked != null) {
                      setModalState(() {
                        // ✅ 修正：這裡「只」更新預產期，不應該動到 tempBirthday
                        tempDueDate = picked;
                      });
                    }
                  },
                ),

                const SizedBox(height: 32),

                // 儲存按鈕
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('child_is_boy', tempIsBoy);
                      await prefs.setString('child_birthday', tempBirthday.toIso8601String());
                      await prefs.setString('child_due_date', tempDueDate.toIso8601String()); // 這裡一定要存

                      setState(() {
                        _isBoy = tempIsBoy;
                        _childBirthday = tempBirthday;
                        _childDueDate = tempDueDate; // 🚀 更新當前狀態
                      });

                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                    child: const Text("確認儲存資料", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

// 輔助 UI 元件
  Widget _buildSettingTile({required IconData icon, required Color iconColor, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildModeChip(String label, String mode, Color color) {
    bool sel = _growthViewMode == mode;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: sel ? color : Colors.grey, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      selected: sel, selectedColor: color.withOpacity(0.15),
      onSelected: (v) { if(v) { HapticFeedback.lightImpact(); setState(() => _growthViewMode = mode); } },
    );
  }

  Widget _buildChartHeader(List<PoemRecord> filtered) {
    final String fullTitle = _getScaleDisplayName(_selectedScale);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        SizedBox(height: 44, child: Marquee(key: ValueKey(_selectedScale), text: "$fullTitle 數據趨勢圖", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), blankSpace: 100, velocity: 30, pauseAfterRound: const Duration(seconds: 5))),
        if (filtered.isNotEmpty) Text("${DateFormat('MM/dd').format(filtered.first.targetDate ?? filtered.first.date!)} - ${DateFormat('MM/dd').format(filtered.last.targetDate ?? filtered.last.date!)}", style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [7, 14, 28, 90, -1].map((d) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(d == -1 ? "自訂" : "${d}天"), selected: _selectedDays == d,
          onSelected: (v) async {
            if (d == -1) {
              final r = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
              if (r != null) setState(() { _selectedDays = -1; _customRange = r; });
            } else { setState(() { _selectedDays = d; _customRange = null; }); }
          },
        ),
      )).toList()),
    );
  }

  Widget _buildSeverityLegend() {
    final t = _getThresholdForScale(_selectedScale);
    final color = _getLineColor(_selectedScale);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap( // 🚀 用 Wrap 避免文字太長在小手機切掉
        spacing: 20,
        runSpacing: 10,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 20, height: 4, color: color),
            const SizedBox(width: 8), const Text("數據趨勢", style: TextStyle(fontSize: 13)),
          ]),
          if (_selectedScale == ScaleType.growth) // 🚀 新增兒科背景線說明
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Text("- -", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8), const Text("WHO 參考線", style: TextStyle(fontSize: 13, color: Colors.grey)),
            ]),
          if (t > 0)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Text("- -", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8), Text("警戒線 ≥ ${t.toInt()}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
            ]),
        ],
      ),
    );
  }

  Widget _buildLargeExportButton(List<PoemRecord> filtered) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        width: double.infinity, height: 80,
        child: ElevatedButton.icon(
          onPressed: filtered.isEmpty ? null : () async {
            final bytes = await _capturePng();
            if (bytes != null) ExportService.generateClinicalReport(filtered, bytes, _selectedScale, growthMode: _growthViewMode);
          },
          style: ElevatedButton.styleFrom(backgroundColor: _getLineColor(_selectedScale), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 8),
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 30), label: const Text("導出專業臨床報告", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  String _getCategoryName(AppCategory cat) {
    switch (cat) {
      case AppCategory.dermatology: return "肌膚照護";
      case AppCategory.psychiatry: return "情緒照護";
      case AppCategory.peds: return "兒科發展";
      case AppCategory.rheumatology: return "風濕免疫";
      case AppCategory.gastro: return "腸胃紀錄";
      case AppCategory.pain: return "疼痛管理";
      default: return "健康追蹤";
    }
  }

  Future<Uint8List?> _capturePng() async {
    final b = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return null;
    ui.Image img = await b.toImage(pixelRatio: 3.0);
    ByteData? d = await img.toByteData(format: ui.ImageByteFormat.png);
    return d?.buffer.asUint8List();
  }
}