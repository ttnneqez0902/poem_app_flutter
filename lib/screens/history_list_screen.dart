import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../main.dart';
import '../services/export_service.dart';

// 🚀 定義統一的 5 個篩選模式
enum HistoryViewFilter { all, daily, poem, uas7, scorad }

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  // 預設選擇「全部」
  HistoryViewFilter _selectedFilter = HistoryViewFilter.all;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("臨床檢測紀錄"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // 🚀 核心改動：僅保留一排 5 個 FilterChips
          _buildUnifiedFilterChips(),

          Expanded(
            child: FutureBuilder<List<PoemRecord>>(
              future: isarService.getAllRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allRecords = snapshot.data ?? [];

                // 🚀 統一過濾邏輯
                final filteredRecords = allRecords.where((r) {
                  switch (_selectedFilter) {
                    case HistoryViewFilter.all:
                      return true;
                    case HistoryViewFilter.daily:
                      return r.type == RecordType.daily;
                    case HistoryViewFilter.poem:
                      return r.type == RecordType.weekly && r.scaleType == ScaleType.poem;
                    case HistoryViewFilter.uas7:
                      return r.type == RecordType.weekly && r.scaleType == ScaleType.uas7;
                    case HistoryViewFilter.scorad:
                      return r.type == RecordType.weekly && r.scaleType == ScaleType.scorad;
                  }
                }).toList().reversed.toList();

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

  // 🚀 統一後的橫向篩選標籤列 (共 5 個)
  Widget _buildUnifiedFilterChips() {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildSingleChip("全部紀錄", HistoryViewFilter.all),
            const SizedBox(width: 8),
            _buildSingleChip("每日打卡", HistoryViewFilter.daily),
            const SizedBox(width: 8),
            _buildSingleChip("POEM", HistoryViewFilter.poem),
            const SizedBox(width: 8),
            _buildSingleChip("UAS7", HistoryViewFilter.uas7),
            const SizedBox(width: 8),
            _buildSingleChip("SCORAD", HistoryViewFilter.scorad),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleChip(String label, HistoryViewFilter filter) {
    bool isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label, style: TextStyle(
        color: isSelected ? Colors.blue.shade900 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = filter);
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

  // --- 🎨 UI 組件：紀錄卡片與顏色判定 (保持先前優化的專業邏輯) ---

  Widget _buildRecordCard(BuildContext context, PoemRecord record) {
    final bool isDaily = record.type == RecordType.daily;
    final iconColor = isDaily ? Colors.orange : _getSeverityColor(record);
    final iconData = isDaily ? Icons.today : _getScaleIcon(record.scaleType);

    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          DateFormat('yyyy/MM/dd HH:mm').format(record.date ?? DateTime.now()),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isDaily
              ? "快速紀錄 (癢:${record.dailyItch} / 睡:${record.dailySleep})"
              : "${_getScaleName(record.scaleType)}：${record.severityLabel} (${record.score}分)",
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
    if (record.type == RecordType.daily) {
      return Column(children: [
        _buildDetailRow(Icons.touch_app, "搔癢程度 (NRS)", "${record.dailyItch} 分"),
        const SizedBox(height: 8),
        _buildDetailRow(Icons.bedtime, "睡眠影響 (NRS)", "${record.dailySleep} 分"),
      ]);
    }
    // POEM/UAS7/SCORAD 詳情
    return Text("總分：${record.score} 分 (${record.severityLabel})");
  }

  Widget _buildPhotoWithConsent(PoemRecord record) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 32),
      const Text("患部照片紀錄：", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(record.imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
      ),
      StatefulBuilder(builder: (context, setCardState) {
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("在臨床報告中顯示", style: TextStyle(fontSize: 14)),
          value: record.imageConsent ?? true,
          onChanged: (val) async {
            await isarService.updateImageConsent(record.id, val);
            setCardState(() => record.imageConsent = val);
          },
        );
      }),
    ]);
  }

  // --- 🔧 輔助工具方法 ---

  Color _getSeverityColor(PoemRecord record) {
    int score = record.score ?? 0;
    if (record.scaleType == ScaleType.uas7) {
      if (score >= 28) return Colors.red;
      if (score >= 16) return Colors.orange;
      return Colors.green;
    }
    if (score >= 17) return Colors.red;
    if (score >= 8) return Colors.orange;
    return Colors.green;
  }

  String _getScaleName(ScaleType type) {
    switch (type) {
      case ScaleType.poem: return "POEM";
      case ScaleType.uas7: return "UAS7";
      case ScaleType.scorad: return "SCORAD";
      default: return "測試";
    }
  }

  IconData _getScaleIcon(ScaleType type) {
    if (type == ScaleType.scorad) return Icons.fact_check_rounded;
    if (type == ScaleType.uas7) return Icons.show_chart_rounded;
    return Icons.assignment_rounded;
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 20, color: Colors.grey),
      const SizedBox(width: 8),
      Text(label),
      const Spacer(),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildActionButtons(PoemRecord record) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      if (record.type == RecordType.weekly)
        TextButton.icon(
          onPressed: () => ExportService.generatePoemReport([record], null),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("導出報告"),
        ),
      TextButton.icon(
        onPressed: () => _confirmDelete(context, record),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text("刪除", style: TextStyle(color: Colors.red)),
      ),
    ]);
  }

  Widget _buildEmptyState() => Center(child: Text("目前尚無此項紀錄", style: TextStyle(color: Colors.grey)));

  void _confirmDelete(BuildContext context, PoemRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("確認刪除"),
        content: const Text("此動作無法復原，確定刪除嗎？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
              onPressed: () async {
                await isarService.deleteRecord(record.id);
                if (!mounted) return;
                Navigator.pop(ctx);
                _refresh();
              },
              child: const Text("確定")
          ),
        ],
      ),
    );
  }
}