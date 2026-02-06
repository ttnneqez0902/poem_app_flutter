import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../main.dart';
import '../services/export_service.dart';

// 🚀 1. 定義修正後的篩選模式：移除 daily，加入 adct
enum HistoryViewFilter { all, adct, poem, uas7, scorad }

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  // 預設選擇「全部紀錄」
  HistoryViewFilter _selectedFilter = HistoryViewFilter.all;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
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
          // 🚀 2. 橫向篩選標籤列 (整合 ADCT)
          _buildUnifiedFilterChips(),

          Expanded(
            child: FutureBuilder<List<PoemRecord>>(
              future: isarService.getAllRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 🚀 核心修正：安全處理 null，防止 image_574622 報錯
                final allRecords = snapshot.data ?? [];

                final filteredRecords = allRecords.where((r) {
                  // 排除掉 RecordType.daily (醫師不看的數據)
                  if (r.type == RecordType.daily) return false;

                  switch (_selectedFilter) {
                    case HistoryViewFilter.all:
                      return true;
                    case HistoryViewFilter.adct:
                      return r.scaleType == ScaleType.adct;
                    case HistoryViewFilter.poem:
                      return r.scaleType == ScaleType.poem;
                    case HistoryViewFilter.uas7:
                      return r.scaleType == ScaleType.uas7;
                    case HistoryViewFilter.scorad:
                      return r.scaleType == ScaleType.scorad;
                  }
                }).toList();

                // 依日期由新到舊排序
                filteredRecords.sort((a, b) =>
                    (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));

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

  // 🚀 橫向篩選標籤：字體稍微放大
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
            const SizedBox(width: 8),
            _buildSingleChip("ADCT 控制", HistoryViewFilter.adct),
            const SizedBox(width: 8),
            _buildSingleChip("POEM 檢測", HistoryViewFilter.poem),
            const SizedBox(width: 8),
            _buildSingleChip("UAS7 活性", HistoryViewFilter.uas7),
            const SizedBox(width: 8),
            _buildSingleChip("SCORAD 自評", HistoryViewFilter.scorad),
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

  // --- 🎨 紀錄卡片：長輩友善與 Null 安全 ---

  Widget _buildRecordCard(BuildContext context, PoemRecord record) {
    // 🚀 安全讀取：使用 ?? 防止紅畫面
    final Color iconColor = _getSeverityColor(record);
    final IconData iconData = _getScaleIcon(record.scaleType);
    final String dateStr = record.date != null
        ? DateFormat('yyyy/MM/dd HH:mm').format(record.date!)
        : "日期未知";
    final int score = record.score ?? 0;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(dateStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(
          "${_getScaleName(record.scaleType)}：${_getSeverityText(record)} ($score分)",
          style: const TextStyle(fontSize: 14),
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
    );
  }

  Widget _buildScoreDetails(PoemRecord record) {
    final int score = record.score ?? 0;
    String description = "";

    // 🚀 依據不同量表顯示正確的臨床判讀
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

  // --- 🔧 臨床輔助工具 (包含 ADCT 判斷) ---

  Color _getSeverityColor(PoemRecord record) {
    final int score = record.score ?? 0;
    if (record.scaleType == ScaleType.adct) {
      return score >= 7 ? Colors.red : Colors.green; //
    }
    if (record.scaleType == ScaleType.uas7) {
      if (score >= 28) return Colors.red;
      if (score >= 16) return Colors.orange;
      return Colors.green; //
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
    return Icons.assignment_rounded;
  }

  Widget _buildActionButtons(PoemRecord record) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton.icon(
        onPressed: () => ExportService.generatePoemReport([record], null),
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("導出 PDF 報告", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      TextButton.icon(
        onPressed: () => _confirmDelete(context, record),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text("刪除", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  Widget _buildEmptyState() => const Center(child: Text("目前尚無此項紀錄", style: TextStyle(color: Colors.grey, fontSize: 16)));

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