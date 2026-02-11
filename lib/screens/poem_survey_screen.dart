import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // 🚀 補上這行

class PoemSurveyScreen extends StatefulWidget {
  final ScaleType initialType;
  final DateTime? targetDate; // 🚀 新增：允許傳入指定補填日期
  final PoemRecord? oldRecord; // 🚀 新增：接收舊紀錄

  const PoemSurveyScreen({
    super.key,
    required this.initialType,
    this.targetDate, // 🚀 補填逻辑關鍵
    this.oldRecord, // 🚀
  });

  @override
  State<PoemSurveyScreen> createState() => _PoemSurveyScreenState();
}

class _PoemSurveyScreenState extends State<PoemSurveyScreen> {
  late ScaleType _selectedScale;
  late List<int> _answers;
  late List<DateTime?> _answerTimestamps;
  late DateTime _recordDate; // 🚀 儲存這筆紀錄真正的日期

  bool _isSaving = false;
  bool _imageConsent = true;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedScale = widget.initialType;
    if (widget.oldRecord != null) {
      // 🚀 編輯模式：抓取舊資料
      _recordDate = widget.oldRecord!.date!;
      // 修正點：使用 ?? [] 確保即使 answers 為空也不會報錯
      _answers = List<int>.from(widget.oldRecord!.answers ?? []);
      _answerTimestamps = List.filled(_answers.length, _recordDate);
      if (widget.oldRecord!.imagePath != null) {
        _image = File(widget.oldRecord!.imagePath!);
      }
      _imageConsent = widget.oldRecord!.imageConsent ?? true;
    } else {
      // 新增模式
      _recordDate = widget.targetDate ?? DateTime.now();
      _initAnswers(_selectedScale);
    }
  }

  // --- 題目配置保持不變 ---
  List<Map<String, dynamic>> _getQuestions(ScaleType type) {
    switch (type) {
      case ScaleType.adct:
        return [
          {"q": "1. 在過去一週，您會如何評價您的濕疹相關症狀？", "options": ["沒有症狀 (0分)", "輕微 (1分)", "中度 (2分)", "嚴重 (3分)", "非常嚴重 (4分)"]},
          {"q": "2. 在過去一週，您有多少天因為濕疹而出現強烈的癢感發作？", "options": ["完全沒有 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "3. 在過去一週，您受濕疹的困擾有多大？", "options": ["完全沒有 (0分)", "有一點 (1分)", "中度 (2分)", "非常 (3分)", "極度 (4分)"]},
          {"q": "4. 在過去一週，您有幾晚因為濕疹而難以入睡或睡不好？", "options": ["都沒有 (0分)", "1-2晚 (1分)", "3-4晚 (2分)", "5-6晚 (3分)", "每晚 (4分)"]},
          {"q": "5. 在過去一週，您的濕疹對您日常活動影響多大？", "options": ["完全沒有 (0分)", "有一點 (1分)", "中度 (2分)", "很大 (3分)", "極度 (4分)"]},
          {"q": "6. 在過去一週，您的濕疹對您心情或情緒影響多大？", "options": ["完全沒有 (0分)", "有一點 (1分)", "中度 (2分)", "很大 (3分)", "極度 (4分)"]},
        ];
      case ScaleType.poem:
        return [
          {"q": "1. 過去一週內，皮膚感到瘙癢的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "2. 過去一週內，因癢而睡眠受干擾的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "3. 過去一週內，皮膚流血的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "4. 過去一週內，皮膚流膿/滲液的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "5. 過去一週內，皮膚裂開的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "6. 過去一週內，皮膚脫屑的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (24分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "7. 過去一週內，皮膚感到乾燥的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
        ];
      case ScaleType.uas7:
        return [
          {"q": "膨疹數量 (過去 24 小時內)", "options": ["無 (0分)", "輕微 (<20個) (1分)", "中度 (20-50個) (2分)", "嚴重 (>50個) (3分)"]},
          {"q": "搔癢程度 (過去 24 小時內)", "options": ["無 (0分)", "輕微 (1分)", "中度 (2分)", "強烈 (3分)"]},
        ];
      case ScaleType.scorad:
        return [
          {"q": "1. 皮膚發紅程度", "options": ["無 (0分)", "輕度 (1分)", "中度 (2分)", "嚴重 (3分)"]},
          {"q": "2. 水腫或丘疹程度", "options": ["無 (0分)", "輕度 (1分)", "中度 (2分)", "嚴重 (3分)"]},
          {"q": "3. 皮膚滲出或結痂程度", "options": ["無 (0分)", "輕度 (1分)", "中度 (2分)", "嚴重 (3分)"]},
          {"q": "4. 表皮抓痕程度", "options": ["無 (0分)", "輕度 (1分)", "中度 (2分)", "嚴重 (3分)"]},
          {"q": "5. 皮膚苔蘚化程度", "options": ["無 (0分)", "輕度 (1分)", "中度 (2分)", "嚴重 (3分)"]},
          {"q": "6. 皮膚乾燥程度", "options": ["無 (0分)", "輕度 (1分)", "中度 (2分)", "嚴重 (3分)"]},
          {"q": "7. 過去 24 小時瘙癢程度 (VAS 0-10)", "type": "slider"},
          {"q": "8. 過去一晚失眠程度 (VAS 0-10)", "type": "slider"},
        ];
      default: return [];
    }
  }

  void _initAnswers(ScaleType type) {
    final count = _getQuestions(type).length;
    setState(() { _answers = List.filled(count, -1); _answerTimestamps = List.filled(count, null); });
  }

  void _onOptionSelected(int qIndex, int score) {
    HapticFeedback.mediumImpact();
    setState(() { _answers[qIndex] = score; _answerTimestamps[qIndex] = DateTime.now(); });
    Future.delayed(const Duration(milliseconds: 300), () => _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut));
  }

  void _saveAndFinish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final total = _answers.where((e) => e != -1).fold(0, (a, b) => a + b);
      // 🚀 如果是編輯模式，沿用舊的 ID
      final record = widget.oldRecord ?? PoemRecord();

      record
        ..date = _recordDate // 🚀 關鍵：儲存補填日期而非「現在」
        ..scaleType = _selectedScale
        ..score = total
        ..answers = _answers
        ..imagePath = _image?.path
        ..imageConsent = _imageConsent;

      await isarService.saveRecord(record); // Isar 會根據 ID 自動判斷是新增或更新

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, _selectedScale);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("儲存失敗：$e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 🚀 新增：直接跳轉至最後一頁（照片頁）的方法
  void _jumpToPhotoPage(int totalPages) {
    HapticFeedback.mediumImpact();
    _pageController.animateToPage(
      totalPages - 1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutExpo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _getQuestions(_selectedScale);
    final totalPages = questions.length + 1;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.oldRecord != null
              ? "修改 ${DateFormat('MM/dd').format(_recordDate)} 紀錄" // 🚀 編輯模式標題
              : (widget.targetDate != null
              ? "補填 ${DateFormat('MM/dd').format(_recordDate)} 紀錄"
              : _getScaleTitle(_selectedScale))),
        centerTitle: true,
        backgroundColor: isDarkMode ? null : Colors.blue.shade50,
        // 🚀 關鍵修改：在 AppBar 加入跳轉按鈕
        actions: [
          if (widget.oldRecord != null && _currentPage < totalPages - 1)
            TextButton(
              onPressed: () => _jumpToPhotoPage(totalPages),
              child: const Text("跳至照片", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentPage + 1) / totalPages, minHeight: 6),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemCount: totalPages,
              itemBuilder: (ctx, idx) {
                if (idx < questions.length) {
                  return _buildQuestionCard(questions, idx, isDarkMode);
                } else {
                  return _buildStandalonePhotoPage(isDarkMode);
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(totalPages),
    );
  }

  // --- UI 元件 ---
  Widget _buildStandalonePhotoPage(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.camera_enhance_rounded, size: 100, color: Colors.blueAccent),
          const SizedBox(height: 24),
          const Text("📷 錄入患部照片", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("上傳照片可幫助醫師\n更精確評估病情 (選填)",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, color: Colors.blueGrey, height: 1.4)
          ),
          const SizedBox(height: 40),

          if (_image != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_image!, height: 280, width: double.infinity, fit: BoxFit.cover)
                )
            ),

          SizedBox(
              width: double.infinity,
              height: 80,
              child: OutlinedButton.icon(
                  onPressed: _showPickImageOptions,
                  icon: const Icon(Icons.camera_alt_rounded, size: 32),
                  label: Text(
                      _image == null ? "開啟相機拍照" : "更換照片",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Colors.blue, width: 3)
                  )
              )
          ),

          const SizedBox(height: 30),
          Theme(
            data: ThemeData(unselectedWidgetColor: Colors.blueGrey),
            child: CheckboxListTile(
              value: _imageConsent,
              activeColor: Colors.blue,
              onChanged: (v) => setState(() => _imageConsent = v!),
              title: const Text("同意照片用於醫師臨床評估", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(List<Map<String, dynamic>> questions, int idx, bool isDarkMode) {
    final q = questions[idx];
    final bool isSlider = q['type'] == 'slider';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("題目 ${idx + 1} / ${questions.length}", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Text(q['q'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4)),
          const SizedBox(height: 32),
          if (isSlider) _buildSliderSection(idx)
          else ...List.generate(q['options'].length, (oIdx) => _buildElderlyOptionCard(q['options'][oIdx], idx, oIdx, _answers[idx] == oIdx, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildElderlyOptionCard(String label, int qIdx, int val, bool isSelected, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => _onOptionSelected(qIdx, val),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(color: isSelected ? Colors.blue.withOpacity(0.1) : (isDarkMode ? Colors.grey.shade900 : Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: isSelected ? 3 : 1.5)),
          child: Row(children: [Expanded(child: Text(label, style: TextStyle(fontSize: 20, fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold))), Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? Colors.blue : Colors.grey.shade400, size: 28)]),
        ),
      ),
    );
  }

  Widget _buildSliderSection(int index) {
    final int currentVal = _answers[index] == -1 ? 0 : _answers[index];
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sliderAreaHeight = screenHeight * 0.4;

    return Center(
      child: Container(
        height: sliderAreaHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("極度嚴重\n(10)", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                Text("$currentVal 分", style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.blue)),
                const Text("無感\n(0)", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
              ],
            ),
            const SizedBox(width: 30),
            SizedBox(
              width: 60, height: sliderAreaHeight,
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 10, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16), overlayShape: const RoundSliderOverlayShape(overlayRadius: 24)),
                  child: Slider(
                    value: currentVal.toDouble(), min: 0, max: 10, divisions: 10, activeColor: Colors.blue, inactiveColor: Colors.blue.withOpacity(0.1),
                    onChanged: (v) => setState(() => _answers[index] = v.toInt()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickImageOptions() {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.camera), title: const Text('現場拍照'), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.photo), title: const Text('相簿選擇'), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
    ])));
  }

  Future<void> _pickImage(ImageSource src) async {
    final XFile? p = await _picker.pickImage(source: src, imageQuality: 40);
    if (p != null) setState(() => _image = File(p.path));
  }

  Widget _buildBottomBar(int total) {
    final isLastPage = _currentPage == total - 1;
    final questionsCount = _getQuestions(_selectedScale).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: (_currentPage == 0 || _isSaving)
                  ? null
                  : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              label: const Text("上一題", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            SizedBox(
              width: 160, height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () {
                  if (isLastPage) {
                    _saveAndFinish();
                  } else {
                    if (_currentPage < questionsCount && _answers[_currentPage] == -1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("請選擇一個選項"), duration: Duration(seconds: 1))
                      );
                      return;
                    }
                    _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastPage ? Colors.green.shade700 : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(isLastPage ? "完成紀錄" : "下一題 ➜",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScaleTitle(ScaleType type) {
    switch (type) {
      case ScaleType.adct: return "ADCT 控制評估";
      case ScaleType.poem: return "POEM 檢測";
      case ScaleType.uas7: return "UAS7 紀錄";
      case ScaleType.scorad: return "SCORAD 自評";
      default: return "量表檢測";
    }
  }
}