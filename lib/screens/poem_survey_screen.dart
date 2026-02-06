import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PoemSurveyScreen extends StatefulWidget {
  final ScaleType initialType;
  const PoemSurveyScreen({super.key, required this.initialType});

  @override
  State<PoemSurveyScreen> createState() => _PoemSurveyScreenState();
}

class _PoemSurveyScreenState extends State<PoemSurveyScreen> {
  late ScaleType _selectedScale;
  late List<int> _answers;
  late List<DateTime?> _answerTimestamps;
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
    _initAnswers(_selectedScale);
  }

  List<Map<String, dynamic>> _getQuestions(ScaleType type) {
    switch (type) {
      case ScaleType.adct:
      // 6題, 每題 0-4 分
        return [
          {"q": "1. 在過去一週，您會如何評價您的濕疹相關症狀？", "options": ["沒有症狀 (0分)", "輕微 (1分)", "中度 (2分)", "嚴重 (3分)", "非常嚴重 (4分)"]},
          {"q": "2. 在過去一週，您有多少天因為濕疹而出現強烈的癢感發作？", "options": ["完全沒有 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "3. 在過去一週，您受濕疹的困擾有多大？", "options": ["完全沒有 (0分)", "有一點 (1分)", "中度 (2分)", "非常 (3分)", "極度 (4分)"]},
          {"q": "4. 在過去一週，您有幾晚因為濕疹而難以入睡或睡不好？", "options": ["都沒有 (0分)", "1-2晚 (1分)", "3-4晚 (2分)", "5-6晚 (3分)", "每晚 (4分)"]},
          {"q": "5. 在過去一週，您的濕疹對您日常活動影響多大？", "options": ["完全沒有 (0分)", "有一點 (1分)", "中度 (2分)", "很大 (3分)", "極度 (4分)"]},
          {"q": "6. 在過去一週，您的濕疹對您心情或情緒影響多大？", "options": ["完全沒有 (0分)", "有一點 (1分)", "中度 (2分)", "很大 (3分)", "極度 (4分)"]},
        ];
      case ScaleType.poem:
      // 7題, 0-4 分
        return [
          {"q": "1. 過去一週內，皮膚感到瘙癢的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "2. 過去一週內，因癢而睡眠受干擾的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "3. 過去一週內，皮膚流血的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "4. 過去一週內，皮膚流膿/滲液的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "5. 過去一週內，皮膚裂開的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "6. 過去一週內，皮膚脫屑的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
          {"q": "7. 過去一週內，皮膚感到乾燥的天數？", "options": ["0天 (0分)", "1-2天 (1分)", "3-4天 (2分)", "5-6天 (3分)", "每天 (4分)"]},
        ];
      case ScaleType.uas7:
      // 2題, 0-3 分
        return [
          {"q": "膨疹數量 (過去 24 小時內)", "options": ["無 (0分)", "輕微 (<20個) (1分)", "中度 (20-50個) (2分)", "嚴重 (>50個) (3分)"]},
          {"q": "搔癢程度 (過去 24 小時內)", "options": ["無 (0分)", "輕微 (1分)", "中度 (2分)", "強烈 (3分)"]},
        ];
      case ScaleType.scorad:
      //
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
    setState(() {
      _answers = List.filled(count, -1);
      _answerTimestamps = List.filled(count, null);
    });
  }

  void _onOptionSelected(int qIndex, int score) {
    HapticFeedback.mediumImpact();
    setState(() { _answers[qIndex] = score; _answerTimestamps[qIndex] = DateTime.now(); });
    if (qIndex < _getQuestions(_selectedScale).length - 1) {
      Future.delayed(const Duration(milliseconds: 300), () => _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut));
    }
  }

  void _saveAndFinish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final total = _answers.map((e) => e == -1 ? 0 : e).reduce((a, b) => a + b);
      final record = PoemRecord()
        ..date = DateTime.now()..scaleType = _selectedScale..type = RecordType.weekly
        ..score = total..answers = _answers..imagePath = _image?.path..imageConsent = _imageConsent;
      await isarService.saveRecord(record);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("儲存失敗：$e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _getQuestions(_selectedScale);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(_getScaleTitle(_selectedScale)), centerTitle: true, backgroundColor: isDarkMode ? null : Colors.blue.shade50),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentPage + 1) / questions.length, minHeight: 6),
          Expanded(
            child: PageView.builder(
              controller: _pageController, physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemCount: questions.length,
              itemBuilder: (ctx, idx) => _buildQuestionCard(questions, idx, isDarkMode),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(questions.length),
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
          if (idx == questions.length - 1) _buildPhotoSection(isDarkMode),
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
    return Column(children: [
      Text("${_answers[index] == -1 ? 0 : _answers[index]} 分", style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.blue)),
      Slider(value: (_answers[index] == -1 ? 0 : _answers[index]).toDouble(), min: 0, max: 10, divisions: 10, onChanged: (v) => setState(() { _answers[index] = v.toInt(); })),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("無感 (0)", style: TextStyle(fontWeight: FontWeight.bold)), Text("極度嚴重 (10)", style: TextStyle(fontWeight: FontWeight.bold))]),
    ]);
  }

  Widget _buildPhotoSection(bool isDarkMode) {
    return Column(children: [
      const Divider(height: 60, thickness: 1.5),
      const Text("📷 錄入患部照片 (選填)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      CheckboxListTile(value: _imageConsent, activeColor: Colors.blue, onChanged: (v) => setState(() => _imageConsent = v!), title: const Text("同意照片用於醫師臨床評估", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)), contentPadding: EdgeInsets.zero),
      if (_image != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover))),
      SizedBox(width: double.infinity, height: 60, child: OutlinedButton.icon(onPressed: _showPickImageOptions, icon: const Icon(Icons.camera_alt_rounded), label: Text(_image == null ? "開啟相機拍照" : "更換照片", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Colors.blue, width: 2)))),
    ]);
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
    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextButton(onPressed: _currentPage == 0 ? null : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut), child: const Text("上一題", style: TextStyle(fontSize: 18))),
        if (_currentPage == total - 1) ElevatedButton(onPressed: _isSaving ? null : _saveAndFinish, child: _isSaving ? const CircularProgressIndicator() : const Text("確認提交", style: TextStyle(fontSize: 18))),
      ]),
    ));
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