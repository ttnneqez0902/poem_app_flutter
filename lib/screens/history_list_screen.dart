import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import '../main.dart'; // 引用全域 isarService
import 'package:poem_app/services/export_service.dart'; // 假設您想在這裡也能導出單筆 PDF

class HistoryListScreen extends StatelessWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("歷史檢測紀錄"),
        backgroundColor: Colors.blue.shade50,
      ),
      body: FutureBuilder<List<PoemRecord>>(
        future: isarService.getAllRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return _buildEmptyState();
          }

          // 將紀錄按日期由新到舊排序
          final sortedRecords = records.reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sortedRecords.length,
            itemBuilder: (context, index) {
              final record = sortedRecords[index];
              return _buildRecordCard(context, record);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, PoemRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(record.totalScore),
          child: Text(
            record.totalScore.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          DateFormat('yyyy年MM月dd日').format(record.date!),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("嚴重程度：${record.severityLabel}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text("作答細項：", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // 顯示 7 題的分數
                Wrap(
                  spacing: 8,
                  children: List.generate(record.answers!.length, (i) {
                    return Chip(
                      label: Text("Q${i + 1}: ${record.answers![i]}分"),
                      backgroundColor: Colors.grey.shade100,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (record.imagePath != null && File(record.imagePath!).existsSync()) ...[
                  const Text("患部照片：", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(record.imagePath!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      // 修正點：傳入 [record] 作為列表，並加上 null 作為第二個參數
                      onPressed: () => ExportService.generatePoemReport([record], null),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("導出此筆報告"),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context, record),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("刪除", style: TextStyle(color: Colors.red)),
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

  // 顏色邏輯與 PDF 保持一致
  Color _getSeverityColor(int score) {
    if (score >= 17) return Colors.red;
    if (score >= 8) return Colors.orange;
    return Colors.green;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("目前尚無歷史紀錄", style: TextStyle(color: Colors.grey)),
    );
  }

  void _confirmDelete(BuildContext context, PoemRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("確認刪除"),
        content: const Text("確定要刪除這筆檢測紀錄嗎？此動作無法復原。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () async {
              await isarService.deleteRecord(record.id);
              Navigator.pop(context); // 關閉對話框
              // 建議這裡可以使用重新整理頁面的邏輯
            },
            child: const Text("刪除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}