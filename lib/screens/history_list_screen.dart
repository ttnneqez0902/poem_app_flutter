import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../models/scale_config.dart';
import '../main.dart';
import '../services/export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
            child: FutureBuilder<List<PoemRecord>>(
              future: isarService.getAllRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allRecords = snapshot.data ?? [];

                final filteredRecords = allRecords.where((r) {
                  if (!_isScaleInCategory(r.scaleType, widget.currentCategory)) return false;
                  if (!(_enabledScales[r.scaleType] ?? true)) return false;
                  if (_selectedScaleType != null && r.scaleType != _selectedScaleType) return false;
                  return true;
                }).toList();

                filteredRecords.sort((a, b) => (b.targetDate ?? b.date ?? DateTime.now())
                    .compareTo(a.targetDate ?? a.date ?? DateTime.now()));

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
              child: _buildSingleChip(ScaleConfig.allScales[type]?.title ?? type.name, type),
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
    // 🚀 核心優化：直接從 Model 抓取顏色與判讀標籤
    final Color statusColor = record.severityColor;
    final String statusLabel = record.severityLabel;
    final String scaleTitle = ScaleConfig.allScales[record.scaleType]?.title ?? "量表";

    final IconData iconData = _getScaleIcon(record.scaleType);
    final DateTime displayDate = record.targetDate ?? record.date ?? DateTime.now();
    final String targetDateStr = _getHumanizedDate(displayDate);

    return Dismissible(
      key: Key(record.recordId ?? record.id.toString()),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      confirmDismiss: (dir) => _confirmDelete(context, record), // 🚀 修正：現在會正確等待對話框結果
      onDismissed: (dir) async {
        await isarService.deleteRecord(record.id);
        _refresh();
      },
      child: Card(
        margin: const EdgeInsets.only(top: 12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: statusColor),
              Expanded(
                child: ExpansionTile(
                  shape: const Border(),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(iconData, color: statusColor),
                  ),
                  title: Text(targetDateStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "$scaleTitle：$statusLabel (${record.score ?? 0}分)",
                    style: TextStyle(fontSize: 14, color: statusColor.withOpacity(0.9), fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScoreDetails(record),
                          if (record.imagePath != null && File(record.imagePath!).existsSync())
                            _buildPhotoWithConsent(record), // 🚀 修正：名稱對齊
                          const SizedBox(height: 16),
                          _buildActionButtons(record),
                        ],
                      ),
                    ),
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
      case AppCategory.psychiatry:
        return [ScaleType.phq9, ScaleType.gad7].contains(type);
      case AppCategory.pain:
        return type == ScaleType.vas;
    }
  }

  String _getCategoryName(AppCategory cat) {
    switch (cat) {
      case AppCategory.dermatology: return "皮膚科";
      case AppCategory.psychiatry: return "身心科";
      case AppCategory.pain: return "疼痛管理";
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
    return Text(
        "臨床建議：${record.severityLabel}。請持續觀察紀錄，並於回診時主動提供醫師參考。",
        style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w500)
    );
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
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton.icon(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(
            builder: (context) => PoemSurveyScreen(initialType: record.scaleType, oldRecord: record),
          ));
          if (result == true) _refresh();
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
      TextButton.icon(
        onPressed: () async {
          final confirm = await _confirmDelete(context, record);
          if (confirm == true) {
            await isarService.deleteRecord(record.id);
            _refresh();
          }
        },
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text("刪除", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    ]);
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