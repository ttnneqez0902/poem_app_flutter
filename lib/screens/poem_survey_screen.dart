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

  // --- 補上血壓控制器 ---
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedScale = widget.initialType;
    debugPrint("📝 問卷頁面已鎖定類型：$_selectedScale");
    final config = ScaleConfig.allScales[_selectedScale]!;

    if (widget.oldRecord != null) {
      // 🚀 編輯模式：載入舊數據
      _recordDate = widget.oldRecord!.targetDate ?? widget.oldRecord!.date ?? DateTime.now();
      _answers = List<int>.from(widget.oldRecord!.answers ?? List.filled(config.questions.length, -1));
      _answerTimestamps = List.filled(config.questions.length, _recordDate);

      if (widget.oldRecord != null) {
        // 🚀 編輯模式：補上血壓數據載入
        if (_selectedScale == ScaleType.bp_log) {
          _systolicController.text = widget.oldRecord!.systolic?.toString() ?? "";
          _diastolicController.text = widget.oldRecord!.diastolic?.toString() ?? "";
          _pulseController.text = widget.oldRecord!.pulse?.toString() ?? "";
        }
      }

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
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
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
  int get totalPages => _currentConfig.questions.length + 1;
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

    // 🚀 A. 強行收起鍵盤並確保 Controller 數據被寫入
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    final bool isGrowth = _selectedScale == ScaleType.growth;
    final bool isBloodPressure = _selectedScale == ScaleType.bp_log;

    // --- 1. 數據驗證分流 ---
    if (isGrowth) {
      if (_heightController.text.isEmpty && _weightController.text.isEmpty && _headController.text.isEmpty) {
        _showWarning("請至少輸入一項生長數據");
        return;
      }
    }
    else if (isBloodPressure) {
      if (_systolicController.text.isEmpty || _diastolicController.text.isEmpty) {
        _showWarning("請輸入完整的收縮壓與舒張壓");
        return;
      }
    }
    else {
      // 📋 一般問卷：確保題目沒有漏答
      if (_answers.contains(-1)) {
        _showWarning("請完成所有量表題目後再提交");
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final record = widget.oldRecord ?? PoemRecord();
      record
        ..userId = FirebaseAuth.instance.currentUser?.uid
        ..date = DateTime.now()
        ..targetDate = _recordDate
        ..scaleType = _selectedScale
        ..imagePath = _image?.path
        ..imageConsent = _imageConsent
        ..isSynced = false;

      // --- 2. 數據賦值分流 (關鍵隔離區) ---

      // 🚀 初始化：先清空所有數值欄位，防止數據交叉感染
      record.height = null; record.weight = null; record.headCircumference = null;
      record.systolic = null; record.diastolic = null; record.pulse = null;
      record.answers = [];

      if (isGrowth) {
        // 👶 兒科路徑：身高/體重/頭圍
        record.height = double.tryParse(_heightController.text);
        record.weight = double.tryParse(_weightController.text);
        record.headCircumference = double.tryParse(_headController.text);
        record.score = 0; // 兒科通常不計算總分
      }
      else if (isBloodPressure) {
        // 🩺 血壓路徑：收縮/舒張/心率
        record.systolic = int.tryParse(_systolicController.text);
        record.diastolic = int.tryParse(_diastolicController.text);
        record.pulse = int.tryParse(_pulseController.text);
        // 💡 臨床策略：讓 score 等於收縮壓，方便趨勢圖預設繪製
        record.score = record.systolic;
      }
      else {
        // 📋 一般問卷路徑：POEM, ADCT, PHQ-9, PSQI...
        record.answers = _answers;
        // 🚀 使用 fold 安全計算總分
        record.score = _answers.fold<int>(0, (sum, item) => sum + (item == -1 ? 0 : item));
      }

      record.ensureId();

      // --- 3. 儲存與觸發背景同步 ---
      await isarService.saveRecord(record);

      // 🔥 1. 標記有新資料
      hasPendingSync = true;

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      debugPrint("‼️ [存檔崩潰]: $e\n$stack");
      if (mounted) _showWarning("儲 can't save: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

// 輔助方法：統一提示 UI
  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildNumericInput(String label, String unit, int? initialValue, Function(int) onChanged) {
    final TextEditingController controller = TextEditingController(
        text: initialValue != null ? initialValue.toString() : ''
    );

    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(
              width: 120,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: "---",
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  final val = int.tryParse(v);
                  if (val != null) onChanged(val);
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(unit, style: const TextStyle(fontSize: 20, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildBloodPressureInput(int idx) {
    String label = "";
    String unit = "";
    IconData icon = Icons.monitor_heart_rounded;
    TextEditingController controller;

    switch (idx) {
      case 0:
        label = "收縮壓 (Systolic)";
        unit = "mmHg";
        controller = _systolicController;
        break;
      case 1:
        label = "舒張壓 (Diastolic)";
        unit = "mmHg";
        controller = _diastolicController;
        break;
      case 2:
        label = "心率 (Pulse)";
        unit = "bpm";
        controller = _pulseController;
        break;
      default:
        return const SizedBox();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 60, color: Colors.red.shade700),
          ),
          const SizedBox(height: 24),
          Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),

          // 🚀 核心：血壓專用大輸入框
          TextField(
            controller: controller,
            textInputAction: idx < 2 ? TextInputAction.next : TextInputAction.done,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.red.shade700, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: "0",
              suffixText: unit,
              suffixStyle: const TextStyle(fontSize: 22, color: Colors.grey, fontWeight: FontWeight.normal),
              border: InputBorder.none,
            ),
            onSubmitted: (val) {
              if (idx < 2) {
                _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
              } else {
                _saveAndFinish(); // 心率填完直接存檔
              }
            },
          ),
          Container(height: 4, width: 200, decoration: BoxDecoration(color: Colors.red.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 40),
          const Text("請輸入血壓計上的數值", style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
        ],
      ),
    );
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
          // 🚀 核心：超大數字輸入框
          TextField(
            controller: controller,
            // 根據 idx 決定鍵盤按鈕顯示「下一步」還是「完成」
            textInputAction: idx < 2 ? TextInputAction.next : TextInputAction.done,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            autofocus: true,
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
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) {
              setState(() {});
            },
            // 🚀 新增：處理鍵盤按鈕點擊事件
            onSubmitted: (val) {
              if (idx < 2) {
                // 前兩題（身高、體重）直接跳下一頁
                _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut
                );
              } else {
                // 最後一題（頭圍）直接進入照片頁或觸發存檔流程
                // 如果你後面還有照片頁，就用 nextPage；如果想直接結束就調用 _saveAndFinish()
                _jumpToPhotoPage(totalPages);
              }
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
    FocusScope.of(context).unfocus(); // 🚀 關鍵：跳頁前先收起虛擬鍵盤
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
    if (_selectedScale == ScaleType.vas) {
      return VasSlider(
        value: _answers[idx] == -1 ? 0 : _answers[idx],
        onChanged: (val) => setState(() {
          _answers[idx] = val;
          _answerTimestamps[idx] = DateTime.now();
        }),
        // 🚀 關鍵修正：在這裡插上跳頁的「感應器」
        onFinished: () {
          if (_currentPage < _currentConfig.questions.length) {
            _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut
            );
          }
        },
      );
    }
    else if (_selectedScale == ScaleType.haq) {
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

                  if (_selectedScale == ScaleType.bp_log) {
                    return _buildBloodPressureInput(idx);
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
                      // 🚀 關鍵修正：兒科發展直接放行，讓家長可以隨意切換身高/體重/頭圍
                      canGoNext = true;
                    } else {
                      // 其他一般量表（如 ADCT）依然維持必填，避免漏答
                      canGoNext = _answers[_currentPage] != -1;
                    }

                    if (!canGoNext) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("請先選擇一個選項")));
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
// 🦴 疼痛管理：VAS 垂直滑桿元件 (加入自動跳轉功能)
class VasSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  // 🚀 1. 新增：完成作答的回調
  final VoidCallback? onFinished;

  const VasSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onFinished, // 🚀 2. 傳入此參數
  });

  @override
  Widget build(BuildContext context) {
    final double sliderHeight = MediaQuery.of(context).size.height * 0.45;

    return Center(
      child: SizedBox(
        height: sliderHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- 左側標籤保持不變 ---
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("極度疼痛", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                Text("$value 分", style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.blue)),
                const Text("完全不痛", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green)),
              ],
            ),
            const SizedBox(width: 50),

            // --- 右側滑桿 ---
            SizedBox(
              width: 60, height: sliderHeight,
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 20),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 32),
                    activeTrackColor: Color.lerp(Colors.green, Colors.red, value / 10),
                    thumbColor: Color.lerp(Colors.green, Colors.red, value / 10),
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: (v) => onChanged(v.toInt()),

                    // 🚀 3. 關鍵修正：當手指放開滑桿時觸發
                    onChangeEnd: (v) {
                      if (onFinished != null) {
                        // 💡 臨床 UX 小技巧：延遲 400 毫秒再跳轉
                        // 讓使用者能看清楚最後選定的分數，才不會有「被強制推走」的感覺
                        Future.delayed(const Duration(milliseconds: 400), onFinished);
                      }
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
}

// 🦴 風濕免疫：HAQ 選項選擇器
class HaqOptionSelector extends StatelessWidget {
  final String question; final int selectedValue; final ValueChanged<int> onSelected;
  const HaqOptionSelector({super.key, required this.question, required this.selectedValue, required this.onSelected});
  @override
  @override
  Widget build(BuildContext context) {
    // HAQ 的標準四個選項
    final List<String> options = ["無困難", "稍有困難", "頗為困難", "無法執行"];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🚀 1. 標題文字美化與放大
        Text(
          question,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4
          ),
        ),
        const SizedBox(height: 32),

        // 🚀 2. 垂直排列的 4 個大選項膠囊
        ...List.generate(options.length, (i) {
          final bool isSelected = selectedValue == i;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16), // 🚀 增加間距，防止誤觸
            child: InkWell(
              onTap: () => onSelected(i),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.1)
                      : (isDarkMode ? Colors.grey.shade900 : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 3 : 1.5
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                  ] : null,
                ),
                child: Row(
                  children: [
                    // 🚀 3. 字體放大到 20，並根據選中狀態加粗
                    Expanded(
                      child: Text(
                        options[i],
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            color: isSelected ? Colors.blue.shade700 : (isDarkMode ? Colors.white : Colors.black87)
                        ),
                      ),
                    ),

                    // 右側選取狀態 Icon
                    Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? Colors.blue : Colors.grey.shade400,
                        size: 28
                    )
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}