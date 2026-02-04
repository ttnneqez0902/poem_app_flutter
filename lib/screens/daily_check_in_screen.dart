import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/poem_record.dart';
import '../main.dart'; // 引用全域的 isarService

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  double _itchLevel = 0;
  double _sleepLossLevel = 0;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (photo != null) setState(() => _image = File(photo.path));
  }

  void _saveDailyLog() async {
    // 建立每日紀錄物件
    final newRecord = PoemRecord()
      ..date = DateTime.now()
      ..type = RecordType.daily // ✅ 標記為每日紀錄
      ..dailyItch = _itchLevel.toInt()
      ..dailySleep = _sleepLossLevel.toInt()
      ..imagePath = _image?.path;

    try {
      await isarService.saveRecord(newRecord);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("今日狀態已紀錄！")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("儲存失敗: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("每日快速打卡")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("過去 24 小時最癢的程度", _itchLevel),
            _buildNRSSlider(
              value: _itchLevel,
              onChanged: (v) => setState(() => _itchLevel = v),
              activeColor: Colors.orange,
            ),
            const SizedBox(height: 40),
            _buildSectionTitle("皮膚問題對昨晚睡眠的影響", _sleepLossLevel),
            _buildNRSSlider(
              value: _sleepLossLevel,
              onChanged: (v) => setState(() => _sleepLossLevel = v),
              activeColor: Colors.indigo,
            ),
            const SizedBox(height: 40),
            _buildPhotoSection(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveDailyLog,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("完成今日紀錄", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ✅ 1. 使用 Expanded 讓標題佔滿剩餘空間
        Expanded(
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown, // ✅ 2. 如果寬度真的不夠，自動縮小字體而不換行
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16, // ✅ 3. 字體稍微縮小（原為 18）
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12), // 標題與分數間的間距
        Text(
          "${value.toInt()} 分",
          style: TextStyle(
            fontSize: 20, // 分數也稍微縮小一點點（原為 22）
            fontWeight: FontWeight.w900, // 使用 w900 替代 .black 解決報錯
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildNRSSlider({required double value, required ValueChanged<double> onChanged, required Color activeColor}) {
    return Column(
      children: [
        Slider(
          value: value,
          min: 0,
          max: 10,
          divisions: 10,
          label: value.toInt().toString(),
          activeColor: activeColor,
          onChanged: onChanged,
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("完全不影響", style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text("極度嚴重", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("今日患部照片 (選擇性)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _image == null
                ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_image!, fit: BoxFit.cover)),
          ),
        ),
      ],
    );
  }
}