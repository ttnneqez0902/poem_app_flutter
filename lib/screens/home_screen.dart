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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io'; // 🚀 必須 import，用於處理 File
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  static const int _virtualInitialPage = 500;
  final int _virtualTotalCount = 1000;
  String? _localPhotoPath; // 用於存放本地圖片路徑

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
    _checkUserStatus(); // 檢查登入狀態
    _loadSettings(); // 初始化時載入設定
    _loadLocalPhoto(); // 新增這行
  }

  Future<void> _loadLocalPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localPhotoPath = prefs.getString('user_custom_photo');
    });
  }

  // 🚀 2. 實作挑選圖片邏輯
  Future<void> _handleChangePhoto() async {
    final ImagePicker picker = ImagePicker();

    // 彈出選單讓使用者選相簿或相機
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery, // 預設開啟相簿
      maxWidth: 500,  // 限制寬度節省記憶體
      imageQuality: 80, // 稍微壓縮畫質
    );

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_custom_photo', pickedFile.path); // 儲存路徑

      setState(() {
        _localPhotoPath = pickedFile.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("大頭貼已更新 (僅存於此裝置)")),
        );
      }
    }
  }

  void _checkUserStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("當前為訪客模式");
    } else {
      debugPrint("登入使用者: ${user.email}");
    }
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
    final today = DateTime(now.year, now.month, now.day);
    final allRecords = await isarService.getAllRecords();

    final uas7Records = allRecords.where((r) => r.scaleType == ScaleType.uas7).toList();
    DateTime uas7Start = today.subtract(const Duration(days: 8));

    return {
      'uas7Start': uas7Start,
      'uas7Status': List.generate(14, (i) {
        final targetDate = uas7Start.add(Duration(days: i));

        // 🚀 核心修正：比對紀錄時，必須優先使用 targetDate
        // 這樣你 2/12 補填 1/29 的資料，1/29 那一格才會正確顯示「已填寫」
        return uas7Records.any((r) =>
            DateUtils.isSameDay(r.targetDate ?? r.date, targetDate)
        );
      }),
      'uas7Records': uas7Records,
      'adct': allRecords.where((r) => r.scaleType == ScaleType.adct).toList()..sort((a,b) => b.date!.compareTo(a.date!)),
      'poem': allRecords.where((r) => r.scaleType == ScaleType.poem).toList()..sort((a,b) => b.date!.compareTo(a.date!)),
      'scorad': allRecords.where((r) => r.scaleType == ScaleType.scorad).toList()..sort((a,b) => b.date!.compareTo(a.date!)),
    };
  }

  // 🚀 執行登出邏輯
  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("確認登出"),
        content: const Text("您確定要登出系統嗎？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("登出", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut(); // 確保 Google 帳號也一併登出，下次可切換帳號
      // 由於我們在 main.dart 有 AuthGate，Firebase 會自動偵測狀態並跳回登入頁
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 獲取當前登入的使用者資訊
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(

      appBar: AppBar(
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
          child: PhysicalModel(
            color: Colors.transparent,
            shape: BoxShape.circle,
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.4),
            // 🚀 核心改動：使用 PopupMenuButton 讓選單在頭像旁跳出
            child: PopupMenuButton<String>(
              offset: const Offset(0, 56), // 調整彈出位置在頭像下方一點
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) {
                if (value == 'photo') {
                  _handleChangePhoto();
                } else if (value == 'logout') {
                  _handleLogout(context);
                }
              },
              // 這是原本的頭像 UI
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: (_localPhotoPath != null && File(_localPhotoPath!).existsSync()
                      ? FileImage(File(_localPhotoPath!))
                      : (user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null)) as ImageProvider?,
                  child: (_localPhotoPath == null && user?.photoURL == null)
                      ? Text(
                    user?.displayName?.substring(0, 1).toUpperCase() ?? "U",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  )
                      : null,
                ),
              ),
              // 🚀 定義彈出的選單內容
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'photo',
                  child: Row(
                    children: [
                      Icon(Icons.photo_library_rounded, color: Colors.blue),
                      SizedBox(width: 12),
                      Text("更換頭像"),
                    ],
                  ),
                ),
                const PopupMenuDivider(), // 分割線
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Text("登出系統"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Column(
          children: [
            const Text("皮膚健康管理", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (user != null)
              Text(
                user.email ?? "",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey),
              ),
          ],
        ),
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

            // 🚀 修正 1：縮小間隔，將 24 改為 12
            const SizedBox(height: 0),
            const Divider(thickness: 0.5, height: 1), // 讓線條更精緻
            const SizedBox(height: 12),

            // 次要導覽按鈕 (趨勢圖、歷史紀錄)
            _buildSecondaryNavigation(context),

            // 🚀 修正 2：縮小按鈕與輪播標題間的距離，將 24 改為 16
            const SizedBox(height: 16),
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
                HapticFeedback.mediumImpact();
                setState(() => _enabledScales[type] = !isEnabled);
              } else if (isEnabled) {
                HapticFeedback.lightImpact();

                // 🚀 1. 執行導航並明確指定期待回傳 bool
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: type)),
                );

                // 🚀 2. 核心修正：處理返回後的資料更新
                // 只要 result 為 true，代表資料庫已有變動（包含補填或正常填寫）
                if (result == true && mounted) {
                  // 第一步：立即觸發 setState。這會讓父層的 FutureBuilder 重新執行 _getTrackerData()
                  // 這樣從資料庫撈出來的最新 uas7Status 才會反應在日曆上
                  setState(() {});

                  // 第二步：稍微延遲，等待新的數據渲染完成後，再執行 PageView 的自動對齊動畫
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      _jumpToScalePage(type);
                    }
                  });
                }
              } else {
                HapticFeedback.vibrate();
                _showDisabledScaleNotice(scale['title'], scale['sub']); // 使用您之前定義的彈窗提示
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
        // 使用 ColorFiltered 處理禁用時的灰階效果
        ColorFiltered(
          colorFilter: isEnabled
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0
          ]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), // 增加切換模式時的平滑感
            width: double.infinity,
            decoration: BoxDecoration(
              // 🚀 改為白色底色或極淡的主題色，陰影才顯眼
              color: isEnabled ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              // 🚀 核心修改：加入動態陰影
              boxShadow: [
                BoxShadow(
                  color: isEnabled
                      ? (scale['color'] as Color).withOpacity(0.15)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6), // 向下偏移，增加懸浮感
                ),
              ],
              // 邊框稍微調淡，讓陰影當主角
              border: Border.all(
                  color: isEnabled ? scale['color'].withOpacity(0.4) : Colors.grey.shade300,
                  width: 1.5
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(scale['icon'], size: 40, color: isEnabled ? scale['color'] : Colors.grey),
                const SizedBox(height: 8),
                Text(
                    scale['title'],
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isEnabled ? scale['color'] : Colors.grey
                    )
                ),
                Text(
                    scale['sub'],
                    style: TextStyle(
                        fontSize: 14,
                        color: isEnabled ? scale['color'].withOpacity(0.8) : Colors.grey,
                        fontWeight: FontWeight.bold
                    )
                ),
              ],
            ),
          ),
        ),
        // 🚀 管理模式的小眼睛標記
        if (_isManagementMode)
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: isEnabled ? Colors.green : Colors.red,
              child: Icon(
                  isEnabled ? Icons.visibility : Icons.visibility_off,
                  size: 16,
                  color: Colors.white
              ),
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
          height: 295,
          child: FutureBuilder<Map<String, dynamic>>(
            // 🚀 確保每次 setState 都會重新執行數據庫查詢
            future: _getTrackerData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              // 這裡拿到的 data 已經是根據新的 targetDate 比對過的結果
              final data = snapshot.data!;

              return PageView.builder(
                controller: _pageController,
                itemCount: _virtualTotalCount,
                itemBuilder: (context, index) {
                  final type = enabledTypes[index % enabledTypes.length];
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
    // 🚀 核心邏輯：定義一個刷新函式，當子組件完成填寫返回時調用
    final VoidCallback onRefresh = () {
      if (mounted) {
        setState(() {
          // 觸發 build，進而讓 FutureBuilder 重新執行 _getTrackerData()
        });
      }
    };

    switch (type) {
      case ScaleType.uas7:
        return Uas7TrackerCard(
          startDate: data['uas7Start'],
          completionStatus: data['uas7Status'],
          history: data['uas7Records'],
          // 🚀 如果你有在 Uas7TrackerCard 定義回標，請傳入
          onRefresh: onRefresh, // 🚀 記得在 Uas7TrackerCard.dart 裡補上這個參數定義
        );
      case ScaleType.adct:
        return WeeklyTrackerCard(
          type: ScaleType.adct,
          history: data['adct'],
          // onRefresh: onRefresh,
        );
      case ScaleType.poem:
        return WeeklyTrackerCard(
          type: ScaleType.poem,
          history: data['poem'],
          // onRefresh: onRefresh,
        );
      case ScaleType.scorad:
        return WeeklyTrackerCard(
          type: ScaleType.scorad,
          history: data['scorad'],
          // onRefresh: onRefresh,
        );
      default:
        return const SizedBox.shrink();
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
                    () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const TrendChartScreen()));
                  if (mounted) setState(() {}); // 返回時刷新，確保資料一致
                }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSmallMenuButton(context, "歷史紀錄", Icons.list_alt_rounded, Colors.blueGrey.shade700,
                    () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryListScreen()));
                  if (mounted) setState(() {}); // 歷史紀錄最常發生刪除/修改，務必刷新
                }),
          ),
        ],
      )
    );
  }

  Widget _buildSmallMenuButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(
          label,
          style: const TextStyle(
            fontSize: 18, // 🚀 字體放大
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2, // 增加字距讓質感更好
          )
      ),
      style: ElevatedButton.styleFrom(
        // 🚀 垂直 Padding 從 12 增加到 18，讓按鈕看起來更厚實
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 2,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // 圓角稍微加大一點點
            side: BorderSide(color: color.withOpacity(0.3), width: 1.5)
        ),
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