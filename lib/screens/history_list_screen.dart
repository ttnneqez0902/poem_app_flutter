import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../main.dart';
import '../services/export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'poem_survey_screen.dart';

enum HistoryViewFilter { all, adct, poem, uas7, scorad }

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  HistoryViewFilter _selectedFilter = HistoryViewFilter.all;
  Map<ScaleType, bool> _enabledScales = {};

  void _refresh() => setState(() {});

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

    setState(() {
      _enabledScales = tempSettings;
      if (_selectedFilter != HistoryViewFilter.all) {
        ScaleType? currentType = _getScaleTypeFromFilter(_selectedFilter);
        if (currentType != null && !(_enabledScales[currentType] ?? true)) {
          _selectedFilter = HistoryViewFilter.all;
        }
      }
    });
  }

  ScaleType? _getScaleTypeFromFilter(HistoryViewFilter filter) {
    switch (filter) {
      case HistoryViewFilter.adct: return ScaleType.adct;
      case HistoryViewFilter.poem: return ScaleType.poem;
      case HistoryViewFilter.uas7: return ScaleType.uas7;
      case HistoryViewFilter.scorad: return ScaleType.scorad;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enabledScales.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("臨床檢測紀錄", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDarkMode ? null : Colors.blue.shade50,
        elevation: 0,
      ),
      backgroundColor: isDarkMode ? null : Colors.grey.shade50,
      body: Column(
        children: [
          _buildUnifiedFilterChips(),

          Expanded(
            child: FutureBuilder<List<PoemRecord>>(
              future: isarService.getAllRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allRecords = snapshot.data ?? [];

                final filteredRecords = allRecords.where((r) {
                  if (r.type == RecordType.daily) return false;
                  bool isScaleEnabled = _enabledScales[r.scaleType] ?? true;
                  if (!isScaleEnabled) return false;

                  switch (_selectedFilter) {
                    case HistoryViewFilter.all: return true;
                    case HistoryViewFilter.adct: return r.scaleType == ScaleType.adct;
                    case HistoryViewFilter.poem: return r.scaleType == ScaleType.poem;
                    case HistoryViewFilter.uas7: return r.scaleType == ScaleType.uas7;
                    case HistoryViewFilter.scorad: return r.scaleType == ScaleType.scorad;
                  }
                }).toList();

                filteredRecords.sort((a, b) {
                  final dateA = a.targetDate ?? a.date ?? DateTime.now();
                  final dateB = b.targetDate ?? b.date ?? DateTime.now();
                  return dateB.compareTo(dateA);
                });

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

  Widget _buildUnifiedFilterChips() {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark ? null : Colors.blue.shade50,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildSingleChip("全部", HistoryViewFilter.all),
            if (_enabledScales[ScaleType.adct] ?? true) ...[
              const SizedBox(width: 8),
              _buildSingleChip("ADCT 異膚", HistoryViewFilter.adct),
            ],
            if (_enabledScales[ScaleType.poem] ?? true) ...[
              const SizedBox(width: 8),
              _buildSingleChip("POEM 濕疹", HistoryViewFilter.poem),
            ],
            if (_enabledScales[ScaleType.uas7] ?? true) ...[
              const SizedBox(width: 8),
              _buildSingleChip("UAS7 蕁麻疹", HistoryViewFilter.uas7),
            ],
            if (_enabledScales[ScaleType.scorad] ?? true) ...[
              const SizedBox(width: 8),
              _buildSingleChip("SCORAD 異膚", HistoryViewFilter.scorad),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleChip(String label, HistoryViewFilter filter) {
    bool isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label, style: TextStyle(
        fontSize: 15,
        color: isSelected ? Colors.blue.shade900 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: isSelected,
      onSelected: (val) { if (val) setState(() => _selectedFilter = filter); },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300),
      ),
    );
  }

  // --- 🎨 紀錄卡片：進化加入 Dismissible 與 人性化日期 ---
  Widget _buildRecordCard(BuildContext context, PoemRecord record) {
    final Color iconColor = _getSeverityColor(record);
    final IconData iconData = _getScaleIcon(record.scaleType);

    final DateTime displayDate = record.targetDate ?? record.date ?? DateTime.now();
    final String targetDateStr = _getHumanizedDate(displayDate);

    final String createdTimeStr = record.date != null
        ? DateFormat('MM/dd HH:mm').format(record.date!)
        : "";

    // 🚀 進化：加入 Dismissible 實現側滑刪除
    return Dismissible(
      key: Key(record.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(top: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("確認刪除？"),
            content: Text("即將刪除 $targetDateStr 的 ${_getScaleName(record.scaleType)} 紀錄，此動作無法復原。"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("確定刪除", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await isarService.deleteRecord(record.id);
        _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("已刪除 $targetDateStr 的紀錄"), behavior: SnackBarBehavior.floating),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(top: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(iconData, color: iconColor),
          ),
          title: Text(targetDateStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_getScaleName(record.scaleType)}：${_getSeverityText(record)} (${record.score ?? 0}分)",
                style: const TextStyle(fontSize: 14),
              ),
              if (createdTimeStr.isNotEmpty)
                Text(
                    "實際錄入：$createdTimeStr",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScoreDetails(record),
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
    );
  }

  // 🚀 進化：人性化日期輔助方法
  String _getHumanizedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return "今天 (${DateFormat('E', 'zh_TW').format(date)})";
    if (target == yesterday) return "昨天 (${DateFormat('E', 'zh_TW').format(date)})";
    return DateFormat('yyyy/MM/dd (E)', 'zh_TW').format(date);
  }

  Widget _buildScoreDetails(PoemRecord record) {
    final int score = record.score ?? 0;
    String description = "";

    switch (record.scaleType) {
      case ScaleType.adct:
        description = score >= 7 ? "⚠️ 目前濕疹控制不佳，建議諮詢醫師。" : "✅ 目前濕疹控制良好。";
        break;
      case ScaleType.poem:
        description = "POEM 總分分級：${_getSeverityText(record)}";
        break;
      case ScaleType.uas7:
        description = "UAS7 七日活性判定：${_getSeverityText(record)}";
        break;
      case ScaleType.scorad: // 🚀 進化：補上 SCORAD 描述
        description = "SCORAD 綜合評估：${_getSeverityText(record)}";
        break;
      default:
        description = "已完成臨床評估紀錄。";
    }

    return Text(description, style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w500));
  }

  Widget _buildPhotoWithConsent(PoemRecord record) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 32),
      const Text("患部照片紀錄：", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(record.imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
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

  // --- 🔧 臨床輔助工具 (進化：補齊 SCORAD 判讀邏輯) ---
  Color _getSeverityColor(PoemRecord record) {
    final int score = record.score ?? 0;
    if (record.scaleType == ScaleType.adct) {
      return score >= 7 ? Colors.red : Colors.green;
    }
    if (record.scaleType == ScaleType.uas7) {
      if (score >= 28) return Colors.red;
      if (score >= 16) return Colors.orange;
      return Colors.green;
    }
    if (record.scaleType == ScaleType.scorad) {
      if (score >= 50) return Colors.red;
      if (score >= 25) return Colors.orange;
      return Colors.green;
    }
    // POEM
    if (score >= 17) return Colors.red;
    if (score >= 8) return Colors.orange;
    return Colors.green;
  }

  String _getSeverityText(PoemRecord record) {
    final int s = record.score ?? 0;
    switch (record.scaleType) {
      case ScaleType.adct: return s >= 7 ? "控制不佳" : "控制良好";
      case ScaleType.poem:
        if (s >= 17) return "重度";
        if (s >= 8) return "中度";
        return "中輕度";
      case ScaleType.uas7:
        if (s >= 28) return "高度活性";
        if (s >= 16) return "中度活性";
        return "低度活性";
      case ScaleType.scorad:
        if (s >= 50) return "重度";
        if (s >= 25) return "中度";
        return "輕度";
      default: return "已完成";
    }
  }

  String _getScaleName(ScaleType type) {
    switch (type) {
      case ScaleType.adct: return "ADCT";
      case ScaleType.poem: return "POEM";
      case ScaleType.uas7: return "UAS7";
      case ScaleType.scorad: return "SCORAD";
      default: return "量表";
    }
  }

  IconData _getScaleIcon(ScaleType type) {
    if (type == ScaleType.uas7) return Icons.show_chart_rounded;
    if (type == ScaleType.adct) return Icons.fact_check_rounded;
    if (type == ScaleType.scorad) return Icons.biotech_rounded;
    return Icons.assignment_rounded;
  }

  Widget _buildActionButtons(PoemRecord record) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PoemSurveyScreen(
                initialType: record.scaleType,
                oldRecord: record,
              ),
            ),
          );
          if (result != null) {
            _refresh();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("紀錄已成功更新"), backgroundColor: Colors.green)
            );
          }
        },
        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
        label: const Text("修改", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: () => ExportService.generateClinicalReport([record], null, record.scaleType),
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("PDF", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      // 🚀 刪除按鈕依然保留，滿足不想滑動的使用者
      TextButton.icon(
        onPressed: () => _confirmDelete(context, record),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text("刪除", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  // 🚀 進化：美化空白狀態
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("目前尚無此項紀錄", style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("您填寫的臨床檢測都會顯示在這裡", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PoemRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("確認刪除紀錄？"),
        content: const Text("此動作無法復原，該紀錄將從歷史與趨勢圖中移除。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
              onPressed: () async {
                await isarService.deleteRecord(record.id);
                if (!mounted) return;
                Navigator.pop(ctx);
                _refresh();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("確定刪除")
          ),
        ],
      ),
    );
  }
}