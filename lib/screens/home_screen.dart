import 'package:flutter/material.dart';
import 'poem_survey_screen.dart';
import 'trend_chart_screen.dart';
import 'history_list_screen.dart';
import '../main.dart';
import '../models/poem_record.dart';
import '../widgets/uas7_tracker_card.dart';
import '../widgets/weekly_tracker_card.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🚀 補上這行

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  static const int _virtualInitialPage = 500;
  final int _virtualTotalCount = 1000;

  late final PageController _pageController = PageController(
    initialPage: _virtualInitialPage,
    viewportFraction: 0.9, // 🚀 建議加入：讓左右卡片露出一點邊緣，引導使用者滑動
  );

  bool _isManagementMode = false; // 是否開啟管理模式
  Map<ScaleType, bool> _enabledScales = {
    ScaleType.adct: true,
    ScaleType.poem: true,
    ScaleType.uas7: true,
    ScaleType.scorad: true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings(); // 初始化時載入設定
  }

  // 載入護理師設定
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var type in ScaleType.values) {
        _enabledScales[type] = prefs.getBool('enable_${type.name}') ?? true;
      }
    });
  }

  // 儲存護理師設定
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (var entry in _enabledScales.entries) {
      await prefs.setBool('enable_${entry.key.name}', entry.value);
    }
  }

  // --- 🚀 核心數據邏輯 ---
  // --- 🚀 核心數據邏輯：改為動態滾動窗口 ---
  // --- 🚀 核心數據邏輯：動態滾動並確保涵蓋未來 2 天 ---
  Future<Map<String, dynamic>> _getTrackerData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // 假設今天是 02/12
    final allRecords = await isarService.getAllRecords();

    final uas7Records = allRecords.where((r) => r.scaleType == ScaleType.uas7).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));

    // 🚀 關鍵修改：
    // 如果從今天 (2/12) 往回推 8 天，起始日就是 2/04。
    // 搭配下方的 List.generate(14)，最後一格就會是 2/04 + 13 = 2/17。
    // 這樣 2/14 就會完美出現在清單中，且前面有足夠的 10 天空間 (2/04~2/14)。
    DateTime uas7Start = today.subtract(const Duration(days: 8));

    return {
      'uas7Start': uas7Start,
      'uas7Status': List.generate(14, (i) {
        final targetDate = uas7Start.add(Duration(days: i));
        return uas7Records.any((r) => DateUtils.isSameDay(r.date, targetDate));
      }),
      'uas7Records': uas7Records,
      'adct': allRecords.where((r) => r.scaleType == ScaleType.adct).toList()..sort((a,b) => b.date!.compareTo(a.date!)),
      'poem': allRecords.where((r) => r.scaleType == ScaleType.poem).toList()..sort((a,b) => b.date!.compareTo(a.date!)),
      'scorad': allRecords.where((r) => r.scaleType == ScaleType.scorad).toList()..sort((a,b) => b.date!.compareTo(a.date!)),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("皮膚健康管理", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            // 🚀 管理模式下顯示儲存圖示，平常顯示設定圖示
            icon: Icon(
              _isManagementMode ? Icons.check_circle : Icons.settings_suggest_rounded,
              color: _isManagementMode ? Colors.green : null,
              size: 28,
            ),
            onPressed: () {
              // 🚀 如果目前是關閉狀態，準備進入模式時跳出提示
              if (!_isManagementMode) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar(); // 清除現有的 SnackBar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("已進入管理員模式：點選方塊可開啟/關閉檢測"),
                    backgroundColor: Colors.blueAccent,
                    duration: Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating, // 懸浮樣式，更現代
                  ),
                );
              }

              setState(() {
                _isManagementMode = !_isManagementMode;
                if (!_isManagementMode) {
                  // 🚀 關閉模式並儲存
                  _saveSettings();

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("設定已儲存"),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 🚀 四個量表大方塊區域
            _buildScaleGrid(context),

            const SizedBox(height: 24),
            const Divider(),

            // 次要導覽按鈕 (趨勢圖、歷史紀錄)
            _buildSecondaryNavigation(context),

            const SizedBox(height: 24),
            _buildSwiperHeader(),

            // 下方的臨床進度輪播卡片
            _buildProgressSwiper(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- 說明彈窗實作 ---
  void _showManagementGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.settings_suggest_rounded, color: Colors.blue), SizedBox(width: 10), Text("管理員模式")],
        ),
        content: const Text("現在您可以自由點選量表方塊來「開啟」或「關閉」病患需要的檢測項目。\n\n設定完成後，請再次點擊右上角勾勾儲存。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("我知道了", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        ],
      ),
    );
  }

  Widget _buildScaleGrid(BuildContext context) {
    final List<Map<String, dynamic>> scales = [
      {'type': ScaleType.adct, 'title': 'ADCT', 'sub': '每周異膚控制', 'color': Colors.blue, 'icon': Icons.assignment_turned_in},
      {'type': ScaleType.poem, 'title': 'POEM', 'sub': '每周濕疹檢測', 'color': Colors.orange, 'icon': Icons.opacity},
      {'type': ScaleType.uas7, 'title': 'UAS7', 'sub': '每日蕁麻疹量表', 'color': Colors.teal, 'icon': Icons.calendar_month},
      {'type': ScaleType.scorad, 'title': 'SCORAD', 'sub': '每周異膚綜合', 'color': Colors.purple, 'icon': Icons.biotech},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.2,
        ),
        itemCount: scales.length,
        itemBuilder: (context, index) {
          final scale = scales[index];
          final type = scale['type'] as ScaleType;
          final bool isEnabled = _enabledScales[type] ?? true;

          return InkWell(
            onTap: () async {
              if (_isManagementMode) {
                // 1. 🔧 管理模式：切換開關
                HapticFeedback.mediumImpact();
                setState(() => _enabledScales[type] = !isEnabled);
              } else if (isEnabled) {
                // 2. 📝 正常模式且功能開啟：進入測驗
                HapticFeedback.lightImpact();

                // 🚀 A. 等待測驗結束返回
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: type)),
                );

                // 🚀 B. 返回後立即刷新首頁數據（勾勾變色與進度條更新）
                setState(() {});

                // 🚀 C. 關鍵修正：延遲一點點時間，確保 PageView 渲染完成後自動跳轉到該量表卡片
                Future.delayed(const Duration(milliseconds: 150), () {
                  _jumpToScalePage(type);
                });

              } else {
                // 3. 🚫 功能已關閉：執行您原本的震動與提示邏輯
                HapticFeedback.vibrate();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("${scale['title']} 功能已關閉"),
                      behavior: SnackBarBehavior.floating
                  ),
                );
              }
            },
            child: _buildScaleCard(scale, isEnabled),
          );
        },
      ),
    );
  }

  // --- 停用提示彈窗實作 ---
  void _showDisabledScaleNotice(String title, String sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$title 功能已關閉"),
        content: Text("目前的病患照護計畫中，不需要執行「$sub」。\n\n如有需求，請洽詢主治醫師或護理人員開啟此量表。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("確定")),
        ],
      ),
    );
  }

Widget _buildScaleCard(Map<String, dynamic> scale, bool isEnabled) {
  return Stack(
    children: [
      ColorFiltered(
        colorFilter: isEnabled
            ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
            : const ColorFilter.matrix(<double>[0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]),
        child: Container(
          width: double.infinity, // 確保填滿 Grid 空間
          decoration: BoxDecoration(
            color: isEnabled ? scale['color'].withOpacity(0.1) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isEnabled ? scale['color'] : Colors.grey.shade400, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(scale['icon'], size: 40, color: isEnabled ? scale['color'] : Colors.grey),
              const SizedBox(height: 8),
              Text(scale['title'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isEnabled ? scale['color'] : Colors.grey)),
              Text(scale['sub'], style: TextStyle(fontSize: 14, color: isEnabled ? scale['color'].withOpacity(0.8) : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      // 🚀 管理模式的小眼睛標記
      if (_isManagementMode)
        Positioned(
          top: 8, right: 8,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: isEnabled ? Colors.green : Colors.red,
            child: Icon(isEnabled ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.white),
          ),
        ),
    ],
  );
}

  Widget _buildProgressSwiper() {
    final enabledTypes = ScaleType.values.where((t) => _enabledScales[t] == true).toList();
    if (enabledTypes.isEmpty) return const SizedBox(height: 200, child: Center(child: Text("請在上方開啟檢測項目")));

    return Column(
      children: [
        SizedBox(
          height: 295, // 🚀 關鍵修正：高度從 265 提升到 295，徹底解決 Overflow
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getTrackerData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final data = snapshot.data!;
              return PageView.builder(
                controller: _pageController,
                itemCount: _virtualTotalCount, // 使用這個大數字
                itemBuilder: (context, index) {
                  if (enabledTypes.isEmpty) return const SizedBox.shrink();
                  final type = enabledTypes[index % enabledTypes.length];

                  // 🚀 關鍵：移除外層 Padding，讓卡片直接貼著 PageView 給它的邊界
                  // 這樣隔壁頁面的內容才會緊鄰著空隙出現
                  return _buildCardByType(type, data);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildDotsIndicator(enabledTypes.length),
      ],
    );
  }

// 在 HomeScreen.dart 內
  Widget _buildCardByType(ScaleType type, Map<String, dynamic> data) {
    // 🚀 統一加入 setState(() {}) 刷新邏輯
    final refresh = () => setState(() {});

    switch (type) {
      case ScaleType.uas7:
        return Uas7TrackerCard(
          startDate: data['uas7Start'],
          completionStatus: data['uas7Status'],
          history: data['uas7Records'],
        );
      case ScaleType.adct:
        return WeeklyTrackerCard(type: ScaleType.adct, history: data['adct']);
      case ScaleType.poem:
        return WeeklyTrackerCard(type: ScaleType.poem, history: data['poem']);
      case ScaleType.scorad:
        return WeeklyTrackerCard(type: ScaleType.scorad, history: data['scorad']);
    }
  }

  // 🚀 修正 2：動態生成分頁圓點指示器
  Widget _buildDotsIndicator(int count) {
    if (count <= 0) return const SizedBox.shrink(); // 如果沒量表，不顯示點點

    return ListenableBuilder(
      listenable: _pageController,
      builder: (context, child) {
        int currentPage = 0;
        if (_pageController.hasClients && _pageController.page != null) {
          currentPage = _pageController.page!.round() % count;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: currentPage == index ? 20 : 8,
              decoration: BoxDecoration(
                color: currentPage == index ? Colors.blue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  void _jumpToScalePage(ScaleType type) {
    if (!_pageController.hasClients) return;

    final enabledTypes = ScaleType.values.where((t) => _enabledScales[t] == true).toList();
    int targetIndexInEnabled = enabledTypes.indexOf(type);
    if (targetIndexInEnabled == -1) return;

    int count = enabledTypes.length;

    // 🚀 修正：參考點改為目前的實際位置，若無則參考初始值 500
    double currentPageValue = _pageController.page ?? _virtualInitialPage.toDouble();
    int currentPage = currentPageValue.round();

    int currentMode = currentPage % count;
    int delta = targetIndexInEnabled - currentMode;

    _pageController.animateToPage(
      currentPage + delta,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildSecondaryNavigation(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildSmallMenuButton(context, "查看趨勢", Icons.bar_chart_rounded, Colors.teal.shade700,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrendChartScreen()))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSmallMenuButton(context, "歷史紀錄", Icons.list_alt_rounded, Colors.blueGrey.shade700,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryListScreen()))),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMenuButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.3))),
      ),
    );
  }
// 修改 _buildSwiperHeader 增加左右提示圖示
  Widget _buildSwiperHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 20, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          const Text("臨床進度週期追蹤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          // 🚀 新增：提示可以左右滑動的圖示
          Icon(Icons.chevron_left, size: 20, color: Colors.grey.shade400),
          Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}