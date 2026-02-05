import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🚀 建議 5️⃣：Haptic 反饋
import '../models/poem_record.dart';
import '../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/scale_configs.dart';

class PoemSurveyScreen extends StatefulWidget {
  const PoemSurveyScreen({super.key});

  @override
  State<PoemSurveyScreen> createState() => _PoemSurveyScreenState();
}

class _PoemSurveyScreenState extends State<PoemSurveyScreen> {
  // 📍 核心狀態
  ScaleType _selectedScale = ScaleType.poem;
  late List<int> _answers;
  late List<DateTime?> _answerTimestamps; // 🚀 建議 4️⃣：回答時間戳
  bool _isSaving = false;
  bool _imageConsent = true; // 🚀 建議 3️⃣：圖片上傳知情同意

  final PageController _pageController = PageController();
  int _currentPage = 0;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initAnswers(ScaleType.poem);
  }

  void _initAnswers(ScaleType type) {
    final count = ScaleConfig.allScales[type]!.questions.length;
    _answers = List.filled(count, -1);
    _answerTimestamps = List.filled(count, null); // 記錄每題作答時間
  }

  // 🚀 建議 1️⃣：中途離開確認 (防止資料遺失)
  Future<bool> _onWillPop() async {
    final hasAnswers = _answers.any((a) => a != -1);
    if (!hasAnswers) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("中途離開？"),
        content: const Text("目前填寫的進度尚未儲存，確定要離開嗎？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("繼續填寫")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("離開", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  void _onOptionSelected(int index, int score) {
    HapticFeedback.lightImpact(); // 🚀 建議 5️⃣：觸感反饋
    setState(() {
      _answers[index] = score;
      _answerTimestamps[index] = DateTime.now(); // 🚀 建議 4️⃣：紀錄作答時間
    });

    final config = ScaleConfig.allScales[_selectedScale]!;
    if (index < config.questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 350), () {
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      });
    }
    // 🚀 建議 2️⃣：此處可呼叫 isarService.saveDraft(_answers) 實作自動儲存
  }

  void _saveAndFinish() async {
    if (_isSaving) return;
    final currentConfig = ScaleConfig.allScales[_selectedScale]!;

    // 漏填檢查
    final missing = <int>[];
    for (int i = 0; i < _answers.length; i++) {
      if (_answers[i] == -1) missing.add(i + 1);
    }

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("漏填項目：${missing.join(', ')}")));
      _pageController.animateToPage(missing.first - 1, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final totalScore = _answers.reduce((a, b) => a + b);
      final newRecord = PoemRecord()
        ..date = DateTime.now()
        ..scaleType = _selectedScale
        ..type = RecordType.weekly
        ..score = totalScore
        ..answers = _answers
      // 🚀 關鍵調整：
        ..imagePath = _image?.path  // 無論有無授權，照片路徑都存進資料庫供個人查看
        ..imageConsent = _imageConsent; // 紀錄使用者是否同意將此照片放進「報告」

      await isarService.saveRecord(newRecord);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("數據已安全存入臨床紀錄")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("儲存失敗：$e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = ScaleConfig.allScales[_selectedScale]!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope( // 🚀 建議 1️⃣：取代 WillPopScope 控制返回邏輯
      canPop: !_answers.any((a) => a != -1),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(currentConfig.title),
          backgroundColor: isDarkMode ? null : Colors.blue.shade50,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / currentConfig.questions.length,
              backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              minHeight: 6,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildScaleSelector(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: currentConfig.questions.length,
                itemBuilder: (context, index) => _buildDynamicQuestionCard(currentConfig, index),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(currentConfig.questions.length),
      ),
    );
  }

  Widget _buildDynamicQuestionCard(ScaleConfig config, int index) {
    final question = config.questions[index];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isButtonType = question.options != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚀 建議 6️⃣：進度百分比文字
          Text(
            "${config.title} 進度 ${index + 1} / ${config.questions.length} (${((index + 1) / config.questions.length * 100).toInt()}%)",
            style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(question.label,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4, color: isDarkMode ? Colors.white : Colors.black87)),
          const SizedBox(height: 32),

          if (isButtonType)
            ...List.generate(question.options!.length, (optIndex) {
              return Semantics( // 🚀 建議 7️⃣：語意化標籤
                label: "量表選項 ${optIndex + 1}：${question.options![optIndex]}",
                child: _buildOptionCard(context, question.options![optIndex], index, optIndex, _answers[index] == optIndex),
              );
            })
          else
            _buildSliderSection(config, index),

          // 🚀 建議 3️⃣：知情同意下的照片上傳 (僅限最後一題)
          if (index == config.questions.length - 1) _buildPhotoSection(isDarkMode),
        ],
      ),
    );
  }

  // 🚀 修正：滑桿區塊加入時間戳紀錄與觸感反饋
  Widget _buildSliderSection(ScaleConfig config, int index) {
    return Column(children: [
      Text(
          "${_answers[index] == -1 ? 0 : _answers[index]} 分",
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)
      ),
      Slider(
        value: (_answers[index] == -1 ? 0 : _answers[index]).toDouble(),
        min: 0,
        max: 10,
        divisions: 10,
        // 1. onChanged 僅負責更新數值與觸感，不跳頁
        onChanged: (v) {
          HapticFeedback.selectionClick();
          setState(() {
            _answers[index] = v.toInt();
            _answerTimestamps[index] = DateTime.now();
          });
        },
        // 2. 🚀 新增：當手指放開時，延遲一下下就自動跳下一頁
        onChangeEnd: (v) {
          final currentConfig = ScaleConfig.allScales[_selectedScale]!;
          if (index < currentConfig.questions.length - 1) {
            Future.delayed(const Duration(milliseconds: 400), () {
              _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut
              );
            });
          }
        },
      ),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("無 (0)", style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text("極其嚴重 (10)", style: TextStyle(fontSize: 12, color: Colors.grey))
        ],
      ),
    ]);
  }



  // 2. 更新後的照片區域 UI
  Widget _buildPhotoSection(bool isDarkMode) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 60),
      const Text("📷 可選：錄入患部照片", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),

      // 🚀 授權勾選框：預設打勾，僅控制「報告顯示」權限
      CheckboxListTile(
        value: _imageConsent,
        onChanged: (v) => setState(() => _imageConsent = v!),
        title: const Text(
            "同意將此照片用於醫師臨床評估（未勾選則照片僅供個人紀錄，不顯示於報告中）。",
            style: TextStyle(fontSize: 12, color: Colors.grey)
        ),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),

      const SizedBox(height: 16),

      // 🚀 預覽圖：只要有拍照就顯示
      if (_image != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_image!, height: 180, width: double.infinity, fit: BoxFit.cover)
          ),
        ),

      // 🚀 相機按鈕：始終開啟，不受 Checkbox 限制
      OutlinedButton.icon(
        onPressed: _showPickImageOptions,
        icon: const Icon(Icons.camera_alt),
        label: Text(_image == null ? "開啟相機拍照" : "更換照片"),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(color: isDarkMode ? Colors.blue.shade300 : Colors.blue),
        ),
      ),
    ]);
  }

  // 🚀 補回：量表切換邏輯 (含防誤觸與重置)
  Future<void> _onScaleChanged(ScaleType? newScale) async {
    if (newScale == null || newScale == _selectedScale) return;
    final hasAnswers = _answers.any((a) => a != -1);

    if (hasAnswers) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("切換量表？"),
          content: const Text("目前填寫的進度將被清空，確定要切換嗎？"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("確定重置", style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _selectedScale = newScale;
      _currentPage = 0;
      _initAnswers(newScale);
      _pageController.jumpToPage(0);
    });
  }

  // --- UI 元件 (下拉選單, OptionCard, BottomBar 等保持優化) ---
  Widget _buildScaleSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButtonFormField<ScaleType>(
        value: _selectedScale,
        decoration: InputDecoration(
          labelText: "目前執行的量表任務",
          filled: true,
          fillColor: Colors.blue.shade50.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        items: const [
          DropdownMenuItem(value: ScaleType.poem, child: Text("POEM 每週評估 (AD)")),
          DropdownMenuItem(value: ScaleType.uas7, child: Text("UAS7 每日紀錄 (蕁麻疹)")),
          DropdownMenuItem(value: ScaleType.scorad, child: Text("SCORAD 症狀自評 (AD)")),
        ],
        onChanged: _onScaleChanged,
      ),
    );
  }

  Widget _buildBottomBar(int totalQuestions) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _currentPage == 0 ? null : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              child: const Text("上一題"),
            ),
            if (_currentPage == totalQuestions - 1)
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAndFinish, // 🚀 Guard 鎖定按鈕
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("提交結果並存入歷史"),
              )
          ],
        ),
      ),
    );
  }

  // ... (原本的 _buildOptionCard, _showPickImageOptions, _pickImage) ...
  Widget _buildOptionCard(BuildContext context, String label, int questionIndex, int value, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () {
        setState(() => _answers[questionIndex] = value);
        if (questionIndex < ScaleConfig.allScales[_selectedScale]!.questions.length - 1) {
          Future.delayed(const Duration(milliseconds: 300), () => _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(isDarkMode ? 0.25 : 0.15) : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? primaryColor : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300), width: isSelected ? 3.0 : 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 18, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isDarkMode ? Colors.white : (isSelected ? primaryColor : Colors.black87)))),
            Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? primaryColor : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source, imageQuality: 50);
    if (photo != null) setState(() => _image = File(photo.path));
  }

  void _showPickImageOptions() {
    showModalBottomSheet(context: context, builder: (context) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('開啟相機拍照'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.photo_library), title: const Text('從相簿選擇照片'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
    ])));
  }
}