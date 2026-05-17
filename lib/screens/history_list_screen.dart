import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../models/scale_config.dart';
import '../main.dart';
import '../services/export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'poem_survey_screen.dart';

class HistoryListScreen extends StatefulWidget {
  final AppCategory currentCategory;

  const HistoryListScreen({
    super.key,
    required this.currentCategory,
  });

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  ScaleType? _selectedScaleType;
  Map<ScaleType, bool> _enabledScales = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    Map<ScaleType, bool> tempSettings = {};
    for (var type in ScaleType.values) {
      tempSettings[type] = prefs.getBool('enable_${type.name}') ?? true;
    }
    setState(() => _enabledScales = tempSettings);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // 🚀 診斷 1：確認目前頁面的類別
    debugPrint("--- 歷史頁面診斷開始 ---");
    debugPrint("當前頁面類別 (Category): ${widget.currentCategory}");

    if (_enabledScales.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("${_getCategoryName(widget.currentCategory)} 歷史紀錄",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDarkMode ? null : Colors.blue.shade50,
        elevation: 0,
      ),
      backgroundColor: isDarkMode ? null : Colors.grey.shade50,
      body: Column(
        children: [
          _buildDynamicFilterChips(),
          Expanded(
            child: StreamBuilder<List<PoemRecord>>(
              stream: isarService.isar.poemRecords.where().watch(fireImmediately: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allRecords = snapshot.data ?? [];
                // 🚀 診斷 2：看看資料庫到底有沒有東西
                debugPrint("Isar 原生抓到總筆數: ${allRecords.length}");

                final filteredRecords = allRecords.where((r) {
                  // 🚀 診斷 3：針對每一筆紀錄進行「過濾原因」分析
                  bool inCat = _isScaleInCategory(r.scaleType, widget.currentCategory);
                  bool enabled = _enabledScales[r.scaleType] ?? true;
                  bool typeMatch = _selectedScaleType == null || r.scaleType == _selectedScaleType;

                  if (!inCat || !enabled || !typeMatch) {
                    debugPrint("❌ 紀錄 ID:${r.id} 被過濾 | 類別符不符:$inCat (紀錄是:${r.scaleType}) | 開關是否開啟:$enabled | 篩選鈕是否對準:$typeMatch");
                  } else {
                    debugPrint("✅ 紀錄 ID:${r.id} 通過過濾，準備顯示");
                  }

                  return inCat && enabled && typeMatch;
                }).toList();

                // 排序邏輯
                filteredRecords.sort((a, b) => (b.targetDate ?? b.date ?? DateTime.now())
                    .compareTo(a.targetDate ?? a.date ?? DateTime.now()));

                debugPrint("最後顯示筆數: ${filteredRecords.length}");
                debugPrint("--- 歷史頁面診斷結束 ---");

                if (filteredRecords.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) => _buildRecordCard(context, filteredRecords[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFilterChips() {
    final availableScales = ScaleType.values.where((t) =>
    _isScaleInCategory(t, widget.currentCategory) && (_enabledScales[t] ?? true)).toList();

    return Container(
      color: Theme.of(context).brightness == Brightness.dark ? null : Colors.blue.shade50,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildSingleChip("全部", null),
            ...availableScales.map((type) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildSingleChip(_getShortScaleName(type), type), // 🚀 使用縮寫中文
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleChip(String label, ScaleType? type) {
    bool isSelected = _selectedScaleType == type;
    return FilterChip(
      label: Text(label, style: TextStyle(
        fontSize: 15,
        color: isSelected ? Colors.blue.shade900 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: isSelected,
      onSelected: (val) {
        setState(() => _selectedScaleType = type);
        HapticFeedback.lightImpact();
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, PoemRecord record) {
    // 🚀 使用你定義的方法，不要再手動 upperCase
    String scaleTitle = _getShortScaleName(record.scaleType);
    String valueDisplay = "";

    switch (record.scaleType) {
      case ScaleType.growth:
        if (record.height != null) valueDisplay = "${record.height} cm";
        else if (record.weight != null) valueDisplay = "${record.weight} kg";
        else if (record.headCircumference != null) valueDisplay = "${record.headCircumference} cm";
        break;
      case ScaleType.cycle:
      // 🚀 假設你以後會在 score 存經期第幾天
        valueDisplay = record.score != null ? "第 ${record.score} 天" : "紀錄完成";
        break;
      case ScaleType.bristol:
        valueDisplay = "第 ${record.score?.toInt() ?? 0} 型";
        break;
      case ScaleType.ibs_sss:
      case ScaleType.haq:
      default:
        valueDisplay = "${record.score ?? 0} 分";
    }

    String statusLabel = record.severityLabel;
    // 🚀 優化標籤：兒科顯示數據類型，女性健康顯示生理紀錄
    if (record.scaleType == ScaleType.growth) {
      statusLabel = record.height != null ? "身高" : (record.weight != null ? "體重" : "頭圍");
    } else if (record.scaleType == ScaleType.cycle) {
      statusLabel = "生理期紀錄";
    }

    final Color statusColor = record.severityColor;
    final IconData iconData = _getScaleIcon(record.scaleType);
    final DateTime displayDate = record.targetDate ?? record.date ?? DateTime.now();
    final String targetDateStr = _getHumanizedDate(displayDate);

    return Dismissible(
      key: Key(record.recordId ?? record.id.toString()),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      confirmDismiss: (dir) => _confirmDelete(context, record),
      onDismissed: (dir) async {
        await isarService.deleteRecord(record.id);
        _refresh();
      },
      child: Card(
        margin: const EdgeInsets.only(top: 12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 6)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(iconData, color: statusColor, size: 20),
            ),
            title: Text(
              targetDateStr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "$scaleTitle：$statusLabel ($valueDisplay)", // 🚀 自動切換 cm/kg/型/分
              style: TextStyle(
                  fontSize: 13,
                  color: statusColor.withOpacity(0.8),
                  fontWeight: FontWeight.w600
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildScoreDetails(record), // 🚀 記得裡面也要過濾兒科建議
                    if (record.imagePath != null && File(record.imagePath!).existsSync())
                      _buildPhotoWithConsent(record),
                    const SizedBox(height: 16),
                    _buildActionButtons(record),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 🔧 核心邏輯輔助 ---

  bool _isScaleInCategory(ScaleType type, AppCategory category) {
    switch (category) {
      case AppCategory.dermatology:
        return [ScaleType.adct, ScaleType.poem, ScaleType.uas7, ScaleType.scorad].contains(type);

    // 🚀 關鍵修正 1：補上睡眠健康，歷史清單才看得到 ISI/PSQI/ESS
      case AppCategory.sleep:
        return [
          ScaleType.psqi,
          ScaleType.isi,
          ScaleType.ess,
        ].contains(type);

      case AppCategory.neurology:
        return [
          ScaleType.qolie10,
          ScaleType.lsss,
        ].contains(type);

      case AppCategory.chronic:
        return [ScaleType.bp_log, ScaleType.cat, ScaleType.dds, ScaleType.bpi].contains(type);

      case AppCategory.psychiatry:
        return [ScaleType.phq9, ScaleType.gad7].contains(type);
      case AppCategory.pain:
        return type == ScaleType.vas;
      case AppCategory.rheumatology:
        return [ScaleType.haq, ScaleType.vas].contains(type);
      case AppCategory.gastro:
        return [ScaleType.bristol, ScaleType.ibs_sss].contains(type);
      case AppCategory.womens:
        return type == ScaleType.cycle;
      case AppCategory.peds:
        return type == ScaleType.growth;
      default:
        return false;
    }
  }

  String _getCategoryName(AppCategory cat) {
    switch (cat) {
      case AppCategory.dermatology: return "肌膚照護";
      case AppCategory.psychiatry: return "情緒照護";
      case AppCategory.pain: return "疼痛管理";
      case AppCategory.rheumatology: return "風濕免疫";
      case AppCategory.gastro: return "腸胃紀錄";
      case AppCategory.womens: return "女性健康";
      case AppCategory.peds: return "兒科發展";
      case AppCategory.neurology: return "神經健康";
      default: return "健康追蹤";
    }
  }

  // 增加一個輔助方法
  String _getShortScaleName(ScaleType type) {
    switch (type) {
      case ScaleType.growth: return "生長紀錄";
      case ScaleType.bristol: return "便便分類";
      case ScaleType.cycle: return "生理週期";
      case ScaleType.haq: return "功能評估";
      case ScaleType.ibs_sss: return "腸胃嚴重度";
      case ScaleType.qolie10:
        return "QOLIE-10";

      case ScaleType.lsss:
        return "LSSS";

      case ScaleType.ess:
        return "Epworth";
      default: return type.name.toUpperCase();
    }
  }

  IconData _getScaleIcon(ScaleType type) {
    switch (type) {
      case ScaleType.uas7: return Icons.show_chart_rounded;
      case ScaleType.adct: return Icons.fact_check_rounded;
      case ScaleType.scorad: return Icons.biotech_rounded;
      case ScaleType.phq9:
      case ScaleType.gad7: return Icons.psychology_rounded;
      case ScaleType.vas: return Icons.bolt_rounded;
      case ScaleType.haq: return Icons.accessibility_new_rounded; // 🚀 風濕
      case ScaleType.bristol: return Icons.water_drop_rounded;    // 🚀 腸胃
      case ScaleType.cycle: return Icons.calendar_month_rounded; // 🚀 女性
      case ScaleType.growth: return Icons.child_care_rounded;    // 🚀 兒科
      case ScaleType.qolie10:
        return Icons.psychology_rounded;

      case ScaleType.lsss:
        return Icons.bolt_rounded;

      case ScaleType.ess:
        return Icons.bedtime_rounded;
      default: return Icons.assignment_rounded;
    }
  }

  String _getHumanizedDate(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) return "今天 (${DateFormat('E', 'zh_TW').format(date)})";
    if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) return "昨天";
    return DateFormat('yyyy/MM/dd (E)', 'zh_TW').format(date);
  }

  Widget _buildScoreDetails(PoemRecord record) {
    String advice;
    if (record.scaleType == ScaleType.growth) {
      advice = "生長數據已存檔。建議定期測量並對照 WHO 生長曲線標準。";
    } else if (record.scaleType == ScaleType.bristol) {
      advice = "便便型態紀錄完成。若長期出現異常型態，建議調整飲食並諮詢醫師。";
    } else {
      advice = "目前評估為「${record.severityLabel}」。建議持續紀錄，回診時提供給醫師參考。";
    }

    return Text(
        advice,
        style: const TextStyle(fontSize: 15, color: Colors.blueGrey, fontWeight: FontWeight.w500)
    );
  }

  Widget _buildPhotoWithConsent(PoemRecord record) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      const Text("患部照片紀錄：", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
            File(record.imagePath!),
            height: 180, // 🚀 稍微縮小高度，讓小手機也能一次看完
            width: double.infinity,
            fit: BoxFit.cover
        ),
      ),
      StatefulBuilder(builder: (context, setCardState) {
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("同意在臨床報告中顯示照片", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          value: record.imageConsent ?? true,
          onChanged: (val) async {
            await isarService.updateImageConsent(record.id, val);
            setCardState(() => record.imageConsent = val);
          },
        );
      }),
    ]);
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
    );
  }

  // 🚀 修正：現在會回傳對話框結果給 Dismissible
  Future<bool?> _confirmDelete(BuildContext context, PoemRecord record) async {
    HapticFeedback.heavyImpact(); // 🚀 觸發強力震動，警示這是危險操作
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("確認刪除紀錄？"),
        content: const Text("此動作無法復原，該紀錄將從歷史與趨勢圖中移除。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("確定刪除")
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PoemRecord record) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 1. 修改按鈕：保持原樣，確保能回傳刷新
        TextButton.icon(
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(
              builder: (context) => PoemSurveyScreen(initialType: record.scaleType, oldRecord: record),
            ));
            if (result == true) _refresh();
          },
          icon: const Icon(Icons.edit_outlined, size: 20),
          label: const Text("修改", style: TextStyle(fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
        ),

        const SizedBox(width: 4),

        // 2. PDF 按鈕：關鍵修正！加入自動維度判定
        TextButton.icon(
          onPressed: () {
            // 🚀 自動判定兒科模式：根據紀錄中有值的欄位來決定
            String? detectedMode;
            if (record.scaleType == ScaleType.growth) {
              if (record.height != null) detectedMode = 'height';
              else if (record.weight != null) detectedMode = 'weight';
              else if (record.headCircumference != null) detectedMode = 'head';
            }

            // 呼叫 Service，傳入判定後的模式
            ExportService.generateClinicalReport(
              [record],
              null,
              record.scaleType,
              growthMode: detectedMode, // 🚀 讓 PDF 知道該印 cm 還是 kg
            );
          },
          icon: const Icon(Icons.picture_as_pdf, size: 20),
          label: const Text("PDF", style: TextStyle(fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(foregroundColor: Colors.teal.shade700),
        ),

        const SizedBox(width: 4),

        // 3. 刪除按鈕：保持確認邏輯，外觀微調
        TextButton.icon(
          onPressed: () async {
            final confirm = await _confirmDelete(context, record);
            if (confirm == true) {
              await isarService.deleteRecord(record.id);
              _refresh();
            }
          },
          icon: const Icon(Icons.delete_outline, size: 20),
          label: const Text("刪除", style: TextStyle(fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("目前尚無此項紀錄", style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}