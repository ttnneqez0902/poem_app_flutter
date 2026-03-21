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

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _headController = TextEditingController();

  // 🚀 1. 補上 HAQ 的題目清單
  final List<String> haqQuestions = [
    "穿衣服、繫鞋帶或扣扣子",
    "洗澡、擦乾身體或洗頭髮",
    "從椅子起身（不使用扶手）",
    "在戶外平地行走",
    "拿取裝滿水的杯子並喝水"
  ];


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

      // ✅ 修正：編輯模式下，把舊的數值填入控制器
      if (_selectedScale == ScaleType.growth) {
        _heightController.text = widget.oldRecord!.height?.toString() ?? "";
        _weightController.text = widget.oldRecord!.weight?.toString() ?? "";
        _headController.text = widget.oldRecord!.headCircumference?.toString() ?? "";
      }
    } else {
      // 🚀 新增模式
      _recordDate = widget.targetDate ?? DateTime.now();
      _answers = List.filled(config.questions.length, -1);
      _answerTimestamps = List.filled(config.questions.length, null);
    }
  }


  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _headController.dispose();
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

    // 🚀 1. 判定是否為兒科生長數據
    final bool isGrowth = _selectedScale == ScaleType.growth;

    // 🚀 2. 防呆驗證區分
    if (isGrowth) {
      // 檢查輸入框是否為空
      if (_heightController.text.isEmpty || _weightController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("請至少輸入身高與體重數據"), behavior: SnackBarBehavior.floating)
        );
        return;
      }
    } else {
      // 一般量表：檢查是否有漏寫題目
      if (_answers.contains(-1)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("請完成所有量表題目後再提交"), behavior: SnackBarBehavior.floating)
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      // 1. 建立或更新紀錄物件
      final record = widget.oldRecord ?? PoemRecord();
      record
        ..userId = FirebaseAuth.instance.currentUser?.uid
        ..date = DateTime.now()
        ..targetDate = _recordDate
        ..scaleType = _selectedScale
        ..imagePath = _image?.path
        ..imageConsent = _imageConsent
        ..isSynced = false;

      // 🚀 3. 資料賦值邏輯分流
      if (isGrowth) {
        // 兒科：儲存物理數值，總分設為 0
        record.height = double.tryParse(_heightController.text);
        record.weight = double.tryParse(_weightController.text);
        record.headCircumference = double.tryParse(_headController.text);
        record.score = 0;
        record.answers = []; // 生長紀錄不需要題目答案
      } else {
        // 一般量表：儲存總分與每一題答案
        final total = _answers.fold(0, (a, b) => a + b);
        record.score = total;
        record.answers = _answers;
        // 確保清除生長欄位，避免髒數據
        record.height = null;
        record.weight = null;
        record.headCircumference = null;
      }

      record.ensureId();

      // 2. 本地儲存 (Isar)
      await isarService.saveRecord(record);
      debugPrint("✅ 本地 Isar 儲存成功 (${isGrowth ? '生長數據' : '評分量表'})");

      // 3. 觸發背景同步邏輯
      syncRecordsOptimized();

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true);
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

  Widget _buildGrowthInput(int idx) {
    String label = "";
    String unit = "";
    IconData icon = Icons.straighten_rounded;
    TextEditingController controller;

    // 🚀 修正：使用傳入的 idx 而不是未定義的 _currentStep
    switch (idx) {
      case 0:
        label = "目前身高";
        unit = "cm";
        icon = Icons.height_rounded;
        controller = _heightController;
        break;
      case 1:
        label = "目前體重";
        unit = "kg";
        icon = Icons.monitor_weight_rounded;
        controller = _weightController;
        break;
      case 2:
        label = "目前頭圍";
        unit = "cm";
        icon = Icons.face_rounded;
        controller = _headController;
        break;
      default:
        return const SizedBox();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          // 視覺引導圖示
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: Colors.lightBlue),
          ),
          const SizedBox(height: 24),
          Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),

          // 🚀 核心：超大數字輸入框
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            autofocus: true, // 進入頁面自動彈起鍵盤
            style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.lightBlue,
                letterSpacing: 2
            ),
            decoration: InputDecoration(
              hintText: "0.0",
              suffixText: unit,
              suffixStyle: const TextStyle(fontSize: 24, color: Colors.grey, fontWeight: FontWeight.normal),
              border: InputBorder.none, // 移除預設邊框改用下方的自定義底線
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) {
              // 🚀 觸發 setState 讓底部的「下一題」按鈕能即時偵測到有填寫文字
              setState(() {});
            },
          ),

          // 自定義裝飾底線
          Container(
            height: 4,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 40),
          Text(
            "請輸入寶寶今日的${label.substring(2)}",
            style: const TextStyle(color: Colors.blueGrey, fontSize: 16),
          ),
          const Text(
            "(精確至小數點後一位)",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 🚀 修正後的優化同步：使用批量更新避免巢狀交易
  Future<void> syncRecordsOptimized() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final unsynced = await isarService.getUnsyncedRecords();
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

  // 在 _PoemSurveyScreenState 內的 build 方法
  Widget _buildRheumatologyUI(int idx) {
    // 🚀 修正 1：判斷 ScaleType，並使用 _answers[idx] 來存取數據
    if (_selectedScale == ScaleType.vas) {
      return VasSlider(
        // VAS 通常只有一題，所以 index 固定是 0
        value: _answers[idx] == -1 ? 0 : _answers[idx],
        onChanged: (val) => setState(() {
          _answers[idx] = val;
          _answerTimestamps[idx] = DateTime.now();
        }),
      );
    } else if (_selectedScale == ScaleType.haq) {
      // HAQ 則會顯示對應 index 的問題
      return HaqOptionSelector(
        question: haqQuestions[idx],
        selectedValue: _answers[idx],
        onSelected: (val) {
          _onOptionSelected(idx, val); // 使用原本的跳頁邏輯
        },
      );
    }
    return const SizedBox.shrink();
  }

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
                // 1. 處理「題目頁」 (Index 小於題目總數)
                if (idx < config.questions.length) {

                  // 🚀 關鍵新增：如果是「兒科生長數據」，顯示專屬輸入框
                  if (_selectedScale == ScaleType.growth) {
                    return _buildGrowthInput(idx);
                  }

                  // 🏥 如果是「風濕科量表 (VAS/HAQ)」，顯示特殊介面
                  if (_selectedScale == ScaleType.vas || _selectedScale == ScaleType.haq) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text("題目 ${idx + 1} / ${config.questions.length}",
                              style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          _buildRheumatologyUI(idx),
                        ],
                      ),
                    );
                  }

                  // 📋 其他標準量表 (ADCT, PHQ-9, POEM...) 使用標準卡片
                  return _buildQuestionCard(config.questions[idx], idx, isDarkMode);

                } else {
                  // 2. 處理最後一頁：照片錄入
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
                    // 🚀 兒科與一般量表的驗證邏輯區分
                    bool canGoNext = false;
                    if (_selectedScale == ScaleType.growth) {
                      // 檢查當前輸入框是否有填
                      if (_currentPage == 0) canGoNext = _heightController.text.isNotEmpty;
                      else if (_currentPage == 1) canGoNext = _weightController.text.isNotEmpty;
                      else if (_currentPage == 2) canGoNext = _headController.text.isNotEmpty;
                    } else {
                      canGoNext = _answers[_currentPage] != -1;
                    }

                    if (!canGoNext) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("請填寫數值後再繼續")));
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
// 🦴 疼痛管理：VAS 滑桿元件
class VasSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const VasSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "目前疼痛感：$value 分",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
        ),
        Slider(
          value: value.toDouble(),
          min: 0, max: 10, divisions: 10,
          label: value.toString(),
          activeColor: Color.lerp(Colors.green, Colors.red, value / 10),
          onChanged: (v) => onChanged(v.toInt()),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text("完全不痛", style: TextStyle(color: Colors.green)), Text("極度疼痛", style: TextStyle(color: Colors.red))],
        ),
      ],
    );
  }
}

// 🦴 風濕免疫：HAQ 選項選擇器
class HaqOptionSelector extends StatelessWidget {
  final String question; final int selectedValue; final ValueChanged<int> onSelected;
  const HaqOptionSelector({super.key, required this.question, required this.selectedValue, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    final List<String> options = ["無困難", "稍有困難", "頗為困難", "無法執行"];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: List.generate(4, (i) => ChoiceChip(label: Text(options[i]), selected: selectedValue == i, onSelected: (_) => onSelected(i)))),
    ])));
  }
}