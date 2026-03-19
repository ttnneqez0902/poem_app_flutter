import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/poem_record.dart';
import '../models/scale_config.dart';
import '../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PoemSurveyScreen extends StatefulWidget {
  final ScaleType initialType;
  final DateTime? targetDate;
  final PoemRecord? oldRecord;

  const PoemSurveyScreen({
    super.key,
    required this.initialType,
    this.targetDate,
    this.oldRecord,
  });

  @override
  State<PoemSurveyScreen> createState() => _PoemSurveyScreenState();
}

class _PoemSurveyScreenState extends State<PoemSurveyScreen> {
  // --- 核心狀態變數 ---
  late ScaleType _selectedScale;
  late List<int> _answers;
  late List<DateTime?> _answerTimestamps; // 🚀 關鍵：紀錄每一題的作答時間
  late DateTime _recordDate;

  bool _isSaving = false;
  bool _imageConsent = true;

  // --- 控制器 ---
  final PageController _pageController = PageController();
  int _currentPage = 0;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedScale = widget.initialType;
    final config = ScaleConfig.allScales[_selectedScale]!;

    if (widget.oldRecord != null) {
      // 🚀 編輯模式：載入舊數據
      _recordDate = widget.oldRecord!.targetDate ?? widget.oldRecord!.date ?? DateTime.now();
      _answers = List<int>.from(widget.oldRecord!.answers ?? List.filled(config.questions.length, -1));
      _answerTimestamps = List.filled(config.questions.length, _recordDate);
      if (widget.oldRecord!.imagePath != null) {
        _image = File(widget.oldRecord!.imagePath!);
      }
      _imageConsent = widget.oldRecord!.imageConsent ?? true;
    } else {
      // 🚀 新增模式（含補填）
      _recordDate = widget.targetDate ?? DateTime.now();
      _answers = List.filled(config.questions.length, -1);
      _answerTimestamps = List.filled(config.questions.length, null);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  // 獲取當前量表的配置
  ScaleConfig get _currentConfig {
    final config = ScaleConfig.allScales[_selectedScale];
    if (config == null) {
      throw Exception("ScaleConfig 未定義: $_selectedScale");
    }
    return config;
  }

  // --- 業務邏輯方法 ---

  void _onOptionSelected(int qIndex, int score) {
    HapticFeedback.mediumImpact();
    setState(() {
      _answers[qIndex] = score;
      _answerTimestamps[qIndex] = DateTime.now();
    });

    // 選完自動跳下一頁 (延遲 300ms 讓使用者看清選了什麼)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_currentPage < _currentConfig.questions.length) {
        _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut
        );
      }
    });
  }

  void _saveAndFinish() async {
    if (_isSaving) return;

    // 🚀 防呆驗證：確保沒有漏寫的題目
    if (_answers.contains(-1)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("請完成所有量表題目後再提交"), behavior: SnackBarBehavior.floating)
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final total = _answers.fold(0, (a, b) => a + b);

      // 1. 建立或更新紀錄物件
      final record = widget.oldRecord ?? PoemRecord();
      record
        ..userId = FirebaseAuth.instance.currentUser?.uid
        ..date = DateTime.now()
        ..targetDate = _recordDate
        ..scaleType = _selectedScale
        ..score = total
        ..answers = _answers
        ..imagePath = _image?.path
        ..imageConsent = _imageConsent
        ..isSynced = false;

      record.ensureId(); // 🚀 建議在這裡呼叫，確保本地 UUID 與雲端完全一致

      // 2. 本地儲存 (Isar)
      await isarService.saveRecord(record);
      debugPrint("✅ 本地 Isar 儲存成功");

      // 3. 觸發背景同步邏輯
      syncRecordsOptimized();

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true); // 回傳 true 告知首頁刷新數據
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("儲存失敗：$e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 🚀 修正後的優化同步：使用批量更新避免巢狀交易
  Future<void> syncRecordsOptimized() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final unsynced = await isarService.getUnsyncedRecords(user.uid);
      if (unsynced.length < 2) return;

      Map<String, List<PoemRecord>> monthlyBundles = {};
      for (var r in unsynced) {
        final key = "${r.targetDate?.year}_${r.targetDate?.month.toString().padLeft(2, '0')}";
        monthlyBundles.putIfAbsent(key, () => []).add(r);
      }

      for (var monthKey in monthlyBundles.keys) {
        final docRef = FirebaseFirestore.instance
            .collection('users').doc(user.uid)
            .collection('monthly_data').doc(monthKey);

        final List<Map<String, dynamic>> jsonList =
        monthlyBundles[monthKey]!.map((r) => r.toFirestore()).toList();

        await docRef.set({
          'records': FieldValue.arrayUnion(jsonList),
          'lastUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ✅ 修正點：直接在這一層進行批量更新，不呼叫 saveRecord
        await isarService.isar.writeTxn(() async {
          for (var r in monthlyBundles[monthKey]!) {
            r.isSynced = true;
            r.ensureId(); // 確保 UUID 存在
          }
          // 批量放入，效能極高
          await isarService.isar.poemRecords.putAll(monthlyBundles[monthKey]!);
        });
        debugPrint("☁️ $monthKey 同步完成");
      }
    } catch (e) {
      debugPrint("❌ 同步發生錯誤: $e");
    }
  }

  void _jumpToPhotoPage(int totalPages) {
    HapticFeedback.mediumImpact();
    _pageController.animateToPage(
        totalPages - 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutExpo
    );
  }

  // --- UI 構建 ---

  @override
  Widget build(BuildContext context) {
    final config = _currentConfig;
    final totalPages = config.questions.length + 1; // 題目 + 最後的照片頁
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.oldRecord != null
            ? "修改 ${DateFormat('MM/dd').format(_recordDate)} 紀錄"
            : (config.title ?? "量表檢測")),
        centerTitle: true,
        backgroundColor: isDarkMode ? null : Colors.blue.shade50,
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
          // 進度條
          LinearProgressIndicator(
            value: (_currentPage + 1) / totalPages,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemCount: totalPages,
              itemBuilder: (ctx, idx) {
                if (idx < config.questions.length) {
                  return _buildQuestionCard(config.questions[idx], idx, isDarkMode);
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

  Widget _buildQuestionCard(ScaleQuestion q, int idx, bool isDarkMode) {
    final bool isSlider = q.options == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("題目 ${idx + 1} / ${_currentConfig.questions.length}",
              style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Text(q.label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4)),
          const SizedBox(height: 32),
          if (isSlider)
            _buildSliderSection(idx)
          else
            ...List.generate(q.options!.length, (oIdx) =>
                _buildElderlyOptionCard(q.options![oIdx], idx, oIdx, _answers[idx] == oIdx, isDarkMode)),
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.1) : (isDarkMode ? Colors.grey.shade900 : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: isSelected ? 3 : 1.5)
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 20, fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold))),
              Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? Colors.blue : Colors.grey.shade400, size: 28)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSection(int index) {
    final int currentVal = _answers[index] == -1 ? 0 : _answers[index];
    final double sliderHeight = MediaQuery.of(context).size.height * 0.45;

    return Center(
      child: SizedBox(
        height: sliderHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("極度嚴重", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                Text("$currentVal 分", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue)),
                const Text("完全無感", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green)),
              ],
            ),
            const SizedBox(width: 40),
            SizedBox(
              width: 60, height: sliderHeight,
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 20),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 32),
                  ),
                  child: Slider(
                    value: currentVal.toDouble(), min: 0, max: 10, divisions: 10,
                    onChanged: (v) => setState(() => _answers[index] = v.toInt()),
                    onChangeEnd: (v) {
                      _answerTimestamps[index] = DateTime.now();
                      Future.delayed(const Duration(milliseconds: 400), () {
                        if (_currentPage < _currentConfig.questions.length) {
                          _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandalonePhotoPage(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.camera_enhance_rounded, size: 100, color: Colors.blueAccent),
          const SizedBox(height: 24),
          const Text("📷 錄入患部照片", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("上傳照片可幫助醫師更精確評估病情 (選填)", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
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
              width: double.infinity, height: 75,
              child: OutlinedButton.icon(
                  onPressed: _showPickImageOptions,
                  icon: const Icon(Icons.camera_alt_rounded, size: 28),
                  label: Text(_image == null ? "開啟相機拍照" : "更換照片", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: const BorderSide(color: Colors.blue, width: 2.5))
              )
          ),
          const SizedBox(height: 30),
          CheckboxListTile(
            value: _imageConsent,
            activeColor: Colors.blue,
            onChanged: (v) => setState(() => _imageConsent = v!),
            title: const Text("同意照片用於醫師臨床評估", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
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
    final questionsCount = _currentConfig.questions.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: (_currentPage == 0 || _isSaving) ? null : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              label: const Text("上一題", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              width: 170, height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () {
                  if (isLastPage) {
                    _saveAndFinish();
                  } else {
                    // 🚀 關鍵驗證：若未選答案則不准跳下一頁
                    if (_currentPage < questionsCount && _answers[_currentPage] == -1) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("請先選擇一個選項"), behavior: SnackBarBehavior.floating));
                      return;
                    }
                    _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastPage ? Colors.green.shade700 : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(isLastPage ? "完成紀錄" : "下一題 ➜", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}