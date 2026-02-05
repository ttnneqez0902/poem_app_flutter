import 'package:flutter/material.dart';
import '../main.dart'; // 引用全域 bootstrapController

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});
  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _isRead = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("隱私權與臨床研究同意書")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("親愛的參與者您好：", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                const Text("本 App 旨在協助追蹤您的皮膚狀況（如 POEM、UAS7 等數據），您的數據將以去識別化方式存儲於本裝置中。"),
                const SizedBox(height: 12),
                const Text("點擊同意代表您了解並授權本程式紀錄您的醫療症狀資訊。"),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              CheckboxListTile(
                value: _isRead,
                onChanged: (v) => setState(() => _isRead = v!),
                title: const Text("我已閱讀並同意參與臨床數據紀錄"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isRead ? () => bootstrapController.completeConsent() : null,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("確認並進入系統"),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}