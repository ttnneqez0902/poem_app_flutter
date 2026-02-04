import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../main.dart';
import '../services/export_service.dart';

// 定義分類模式
enum HistoryFilterMode { all, daily, weekly }

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  HistoryFilterMode _selectedFilter = HistoryFilterMode.all;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // 定義更有質感的按鈕樣式
    final segmentedButtonStyle = ButtonStyle(
      // 背景顏色：選中時為深藍色，未選中時為淺灰色
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.blue.shade700; // 選中顏色
          }
          return Colors.grey.shade200; // 未選中顏色
        },
      ),
      // 文字與圖示顏色：選中時為白色，未選中時為深灰色
      foregroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.grey.shade700;
        },
      ),
      // 移除預設邊框
      side: MaterialStateProperty.all(BorderSide.none),
      // 圓角造型
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      // 移除陰影
      elevation: MaterialStateProperty.all(0),
      // 增加內部填充讓按鈕胖一點
      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("歷史檢測紀錄"),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50, // 背景稍微調灰一點，讓卡片更跳
      body: Column(
        children: [
          // 質感切換按鈕區塊
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: Colors.blue.shade50, // 與 AppBar 同色延伸
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<HistoryFilterMode>(
                // 套用自定義樣式
                style: segmentedButtonStyle,
                // 隱藏預設的勾選圖示，看起來更簡潔
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: HistoryFilterMode.all,
                    label: Text("全部"),
                    // 可以選擇性加入 icon: Icon(Icons.list),
                  ),
                  ButtonSegment(
                    value: HistoryFilterMode.daily,
                    label: Text("每日打卡"),
                  ),
                  ButtonSegment(
                    value: HistoryFilterMode.weekly,
                    label: Text("每週檢測"),
                  ),
                ],
                selected: {_selectedFilter},
                onSelectionChanged: (newSelection) {
                  setState(() => _selectedFilter = newSelection.first);
                },
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<PoemRecord>>(
              future: isarService.getAllRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allRecords = snapshot.data ?? [];

                // 根據選擇的模式過濾紀錄
                final filteredRecords = allRecords.where((r) {
                  if (_selectedFilter == HistoryFilterMode.daily) return r.type == RecordType.daily;
                  if (_selectedFilter == HistoryFilterMode.weekly) return r.type == RecordType.weekly;
                  return true; // All
                }).toList().reversed.toList();

                if (filteredRecords.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    return _buildRecordCard(context, filteredRecords[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, PoemRecord record) {
    final displayDate = record.date ?? DateTime.now();
    final bool isDaily = record.type == RecordType.daily;

    // 🎨 顏色分流邏輯：
    // 每日打卡固定使用亮橘色
    // 每週檢測使用嚴重度顏色 (綠/黃/紅)
    final Color iconBgColor = isDaily ? Colors.orangeAccent.shade700 : _getSeverityColor(record.totalScore);
    // 圖示分流邏輯
    final IconData iconData = isDaily ? Icons.access_time_filled_rounded : Icons.assignment_turned_in_rounded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: ExpansionTile(
        shape: Border.all(color: Colors.transparent), // 移除展開時的上下邊框線
        leading: CircleAvatar(
          backgroundColor: iconBgColor,
          radius: 22,
          child: Icon(iconData, color: Colors.white, size: 22),
        ),
        title: Text(
          DateFormat('yyyy年MM月dd日 HH:mm').format(displayDate),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            isDaily
                ? "每日打卡 (癢:${record.dailyItch ?? 0} / 睡:${record.dailySleep ?? 0})"
                : "每週檢測：${record.severityLabel} (${record.totalScore}分)",
            style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: isDaily ? FontWeight.normal : FontWeight.w500
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                if (isDaily) ...[
                  _buildDetailRow(Icons.touch_app, "搔癢程度 (NRS)", "${record.dailyItch ?? 0} 分"),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.bedtime, "睡眠影響 (NRS)", "${record.dailySleep ?? 0} 分"),
                ] else ...[
                  const Text("每週 POEM 作答細項：", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (record.answers != null && record.answers!.isNotEmpty)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(record.answers!.length, (i) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade100)
                          ),
                          child: Text("Q${i + 1}: ${record.answers![i]}分", style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w500)),
                        );
                      }),
                    )
                  else
                    const Text("無詳細作答資料", style: TextStyle(color: Colors.grey)),
                ],

                // 患部照片
                if (record.imagePath != null && record.imagePath!.isNotEmpty && File(record.imagePath!).existsSync()) ...[
                  const SizedBox(height: 24),
                  const Text("患部照片紀錄：", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(record.imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isDaily)
                      TextButton.icon(
                        onPressed: () => ExportService.generatePoemReport([record], null),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text("導出報告"),
                        style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context, record),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      label: const Text("刪除紀錄", style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 輔助小元件：建立每日細項的行
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ],
    );
  }

  Color _getSeverityColor(int score) {
    if (score >= 17) return Colors.red.shade600;
    if (score >= 8) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  Widget _buildEmptyState() {
    String message = "目前尚無紀錄";
    if (_selectedFilter == HistoryFilterMode.daily) message = "尚無每日打卡紀錄";
    if (_selectedFilter == HistoryFilterMode.weekly) message = "尚無每週檢測紀錄";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PoemRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("確認刪除"),
        content: const Text("確定要刪除這筆紀錄嗎？此動作無法復原。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await isarService.deleteRecord(record.id);
              if (!mounted) return;
              Navigator.pop(context);
              _refresh();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text("確認刪除"),
          ),
        ],
      ),
    );
  }
}