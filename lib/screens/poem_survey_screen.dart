import 'package:flutter/material.dart';
import '../models/poem_record.dart';
import '../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PoemSurveyScreen extends StatefulWidget {
  const PoemSurveyScreen({super.key});

  @override
  State<PoemSurveyScreen> createState() => _PoemSurveyScreenState();
}

class _PoemSurveyScreenState extends State<PoemSurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final List<int> _answers = List.filled(7, -1);

  final List<String> _questions = [
    "在過去的一星期中，您的皮膚感到搔癢的天數有多少？",
    "在過去的一星期中，您的睡眠因為濕疹而於晚間遭到干擾的天數有多少？",
    "在過去的一星期中，您的皮膚出血的天數有多少？",
    "在過去的一星期中，您的皮膚滲出或分泌透明液體的天數有多少？",
    "在過去的一星期中，您的皮膚出現龜裂的天數有多少？",
    "在過去的一星期中，您的皮膚出現剝落（脫皮）的天數有多少？",
    "在過去的一星期中，您的皮膚感到乾燥或粗糙的天數有多少？",
  ];

  final List<String> _options = ["0 天", "1 - 2 天", "3 - 4 天", "5 - 6 天", "每天"];

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
    }
  }

  void _onOptionSelected(int score) {
    setState(() {
      _answers[_currentPage] = score;
    });

    if (_currentPage < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _saveAndFinish() async {
    if (_answers.contains(-1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請完成所有題目後再提交")),
      );
      return;
    }

    // 修正級聯運算子語法
    final newRecord = PoemRecord()
      ..date = DateTime.now()
      ..scores = List.from(_answers) // 建議使用 List.from 確保資料獨立
      ..imagePath = _image?.path;

    await isarService.saveRecord(newRecord);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("檢測紀錄已儲存！")),
    );
    Navigator.pop(context);
  }

  // 修改後的圖片選取邏輯
  Future<void> _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(
      source: source,
      imageQuality: 50, // 壓縮圖片以節省空間，這對 Isar 儲存路徑較友善
    );

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
    }
  }

// 建立一個選擇視窗，讓使用者選取來源
  void _showPickImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('開啟相機拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('從相簿選擇照片'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text("POEM 檢測"),
        backgroundColor: isDarkMode ? null : Colors.blue.shade50,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / _questions.length,
            // 進度條底色在深色模式下調深
            backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: _questions.length,
        itemBuilder: (context, index) => _buildQuestionCard(index),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildQuestionCard(int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 修正：在深色模式下使用亮灰色，增加辨識度
          Text(
              "問題 ${index + 1} / 7",
              style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)
          ),
          const SizedBox(height: 16),
          Text(
            _questions[index],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
              // 確保題目文字在深色模式下是純白的
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // --- 關鍵修正：呼叫您寫好的高對比組件 ---
          ...List.generate(_options.length, (optIndex) {
            bool isSelected = _answers[index] == optIndex;
            return _buildOptionCard(context, _options[optIndex], optIndex, isSelected);
          }),

          if (index == 6) ...[
            const Divider(height: 40),
            Text(
                "紀錄患部照片 (供醫生看診參考)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                )
            ),
            const SizedBox(height: 12),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showPickImageOptions,
              icon: const Icon(Icons.add_a_photo),
              label: Text(_image == null ? "新增照片" : "更換照片"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                // 深色模式下調整按鈕顏色
                side: BorderSide(color: isDarkMode ? Colors.blue.shade300 : Colors.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String label, int value, bool isSelected) {
    // 取得主題狀態與顏色
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => _onOptionSelected(value),
      child: AnimatedContainer( // 使用動畫容器，讓切換更平滑
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(18), // 稍微增加內距提升手感
        decoration: BoxDecoration(
          // 1. 背景高亮：選中時使用主題主色並降低透明度，未選中時使用深灰色區塊
          color: isSelected
              ? primaryColor.withOpacity(isDarkMode ? 0.25 : 0.15)
              : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade50),

          borderRadius: BorderRadius.circular(15),

          // 2. 邊框強化：選中時加粗邊框，未選中時保持低調
          border: Border.all(
            color: isSelected ? primaryColor : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
            width: isSelected ? 3.0 : 1.5,
          ),

          // 3. 增加陰影發光效果：解決深色模式看不清楚的問題
          boxShadow: isSelected && isDarkMode
              ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  // 4. 文字強化：選中時加粗文字，並確保在深色模式下為白色
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isDarkMode ? Colors.white : (isSelected ? primaryColor : Colors.black87),
                ),
              ),
            ),
            // 5. 視覺回饋：加入勾選圖示
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 28)
            else
              Icon(Icons.radio_button_unchecked, color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _currentPage == 0
                  ? null
                  : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              child: const Text("上一題"),
            ),
            if (_currentPage == _questions.length - 1)
              ElevatedButton(
                onPressed: _saveAndFinish,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text("提交結果並儲存"),
              ),
          ],
        ),
      ),
    );
  }
}