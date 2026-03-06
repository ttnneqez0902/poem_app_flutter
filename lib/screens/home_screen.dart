import 'package:flutter/material.dart';
import 'poem_survey_screen.dart';
import 'trend_chart_screen.dart';
import 'history_list_screen.dart';
import 'login_screen.dart';
import '../main.dart';
import '../models/poem_record.dart';
import '../widgets/uas7_tracker_card.dart';
import '../widgets/weekly_tracker_card.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🚀 補上這行
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 🚀 必備
import 'dart:io'; // 🚀 必須 import，用於處理 File
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p; // 🚀 確保有 alias 'p'
import 'package:path_provider/path_provider.dart'; // 用於 getApplicationDocumentsDirectory
import '../services/cloud_backup_service.dart'; // 🚀 補上這行
import '../widgets/backup_dialogs.dart';      // 🚀 補上這行
import '../services/backup_error_dialog.dart';
import '../services/notification_service.dart'; // 🚀 補上這行，讓 HomeScreen 認識它

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _appVersion = "1.0.0"; // 每次更新 App 時改這裡
  static const int _virtualInitialPage = 500;
  final int _virtualTotalCount = 1000;
  String? _localPhotoPath; // 用於存放本地圖片路徑
  bool _isSyncing = false; // 控制讀取中狀態

  late final PageController _pageController = PageController(
    initialPage: _virtualInitialPage,
    viewportFraction: 0.9, // 🚀 建議加入：讓左右卡片露出一點邊緣，引導使用者滑動
  );

  bool _isManagementMode = false; // 是否開啟管理模式
  // 🚀 取代原本單一的 _reminderTime
  final Map<ScaleType, TimeOfDay> _reminderTimes = {};
  final Map<ScaleType, int> _reminderDays = {}; // 1:週一 ~ 7:週日
  final Map<ScaleType, bool> _reminderEnabled = {};

  Map<ScaleType, bool> _enabledScales = {
    ScaleType.adct: true,
    ScaleType.poem: true,
    ScaleType.uas7: true,
    ScaleType.scorad: true,
  };

  Future<Map<String, dynamic>>? _trackerDataFuture;

  @override
  void initState() {
    super.initState();
    _checkUserStatus(); // 檢查登入狀態
    _loadSettings(); // 初始化時載入設定
    _loadLocalPhoto(); // 新增這行
    _refreshData();
    _checkBackupRequirement(); // 🚀 記得加上這行

// 🚀 新增：當首頁的 UI 渲染完成後，檢查是否有待處理的通知跳轉
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pendingPayload != null) {
        handleNotificationJump(pendingPayload!); // 執行跳轉
        pendingPayload = null; // 清除任務，避免下次回到首頁又跳轉一次
      }
    });
  }

  // 封裝一個刷新資料的方法，供各處調用
  void _refreshData() {
    setState(() {
      _trackerDataFuture = _getTrackerData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // 🚀 務必釋放資源
    super.dispose();
  }

// 🚀 1. 先宣告 GoogleSignIn 實例並設定權限範圍
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata', // 必備：存取 App 專用雲端空間
    ],
  );

// 🚀 修正初始化代碼，補上 onDbSwapped
  late final CloudBackupService cloudBackupService = CloudBackupService(
    isar: isarService.isar,
    isarFactory: () async => await isarService.openDB(),
    googleSignIn: _googleSignIn,
    // 🚀 加入這行：還原成功後，同步更新全域的 isar 實體
    onDbSwapped: (newIsar) => isarService.updateInstance(newIsar),
  );

  Future<void> _loadLocalPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('user_custom_photo');

    if (savedPath != null) {
      // 🚀 檢查檔案是否真的在，如果不在（路徑失效），試著從目前 App 目錄重新拼接
      final file = File(savedPath);
      if (!await file.exists()) {
        final docDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(savedPath); // 取得檔名
        final newPath = p.join(docDir.path, fileName); // 拼接目前正確的路徑

        if (await File(newPath).exists()) {
          savedPath = newPath;
          await prefs.setString('user_custom_photo', newPath); // 更新正確路徑
        }
      }
    }

    setState(() {
      _localPhotoPath = savedPath;
    });
  }

  Future<void> _handleChangePhoto() async {
    final ImagePicker picker = ImagePicker();

    // 1. 選取來源
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) =>
          SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('從相簿選擇'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('開啟相機'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    // 2. 取得圖片
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    // 3. 🚀 執行裁剪 (11.0.0 語法)
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '編輯大頭照',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,

          // 1. 設定為圓形遮罩
          cropStyle: CropStyle.circle,

          // 2. 隱藏中間的網格線 (消除方形感)
          showCropGrid: false,

          // 3. 隱藏裁剪框邊界 (讓它看起來更像純圓形)
          // 如果你希望使用者還是能看到邊界，可以留著，但我建議關掉或調淡

          // 4. 🚀 關鍵：隱藏下方所有的控制項 (那個 square 標籤會消失)
          // 因為我們已經鎖定正方形比例了，不需要讓使用者切換，隱藏後介面會非常乾淨
          hideBottomControls: true,

          aspectRatioPresets: [CropAspectRatioPreset.square],
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(
          title: '編輯大頭照',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    // 4. 更新狀態與儲存
    if (croppedFile != null) {
      setState(() {
        _localPhotoPath = croppedFile.path;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_custom_photo', croppedFile.path);
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

// 載入護理師與提醒設定
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var type in ScaleType.values) {
        _enabledScales[type] = prefs.getBool('enable_${type.name}') ?? true;

        // 🚀 載入個別量表的提醒設定
        _reminderEnabled[type] = prefs.getBool('reminder_enabled_${type.name}') ?? true;
        _reminderDays[type] = prefs.getInt('reminder_day_${type.name}') ?? DateTime.sunday; // 預設週日

        final savedHour = prefs.getInt('reminder_hour_${type.name}') ?? 20;
        final savedMinute = prefs.getInt('reminder_minute_${type.name}') ?? 0;
        _reminderTimes[type] = TimeOfDay(hour: savedHour, minute: savedMinute);
      }
    });

    _scheduleClinicalReminders();
  }


  // 🚀 新增：啟動臨床提醒排程的方法
// 🚀 替換原本的 _scheduleClinicalReminders
  Future<void> _scheduleClinicalReminders() async {
    for (var type in ScaleType.values) {
      // 每個量表給予唯一的 ID (例如 uas7=0, poem=1, adct=2, scorad=3)
      final int notificationId = type.index;

      // 先取消舊的
      await NotificationService().cancel(notificationId);

      // 只有在「管理員開啟該量表」且「使用者開啟提醒」時才排程
      if (_enabledScales[type] == true && _reminderEnabled[type] == true) {
        final time = _reminderTimes[type]!;
        final String title = '${type.name.toUpperCase()} 追蹤提醒';

        if (type == ScaleType.uas7) {
          // 🚀 UAS7 是每日量表
          await NotificationService().scheduleDailyReminder(
            id: notificationId,
            title: title,
            body: '請花一分鐘記錄今天的皮膚狀況，幫助醫師追蹤您的進度。',
            hour: time.hour,
            minute: time.minute,
            payload: type.name, // 🚀 傳遞量表名稱 (例如 'uas7')
          );
        } else {
          // 🚀 其他是每週量表
          final day = _reminderDays[type]!;
          await NotificationService().scheduleWeeklyReminder(
            id: notificationId,
            title: title,
            body: '今天是您的每週紀錄日，請撥空填寫量表。',
            dayOfWeek: day,
            hour: time.hour,
            minute: time.minute,
            payload: type.name, // 🚀 傳遞量表名稱 (例如 'poem')
          );
        }
      }
    }
  }

  // 🚀 儲存提醒設定到手機
  Future<void> _saveReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (var type in ScaleType.values) {
      await prefs.setBool('reminder_enabled_${type.name}', _reminderEnabled[type] ?? true);
      await prefs.setInt('reminder_day_${type.name}', _reminderDays[type] ?? DateTime.sunday);
      await prefs.setInt('reminder_hour_${type.name}', _reminderTimes[type]?.hour ?? 20);
      await prefs.setInt('reminder_minute_${type.name}', _reminderTimes[type]?.minute ?? 0);
    }
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

    final uas7Records = allRecords
        .where((r) => r.scaleType == ScaleType.uas7)
        .toList();
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
      'adct': allRecords.where((r) => r.scaleType == ScaleType.adct).toList()
        ..sort((a, b) => b.date!.compareTo(a.date!)),
      'poem': allRecords.where((r) => r.scaleType == ScaleType.poem).toList()
        ..sort((a, b) => b.date!.compareTo(a.date!)),
      'scorad': allRecords
          .where((r) => r.scaleType == ScaleType.scorad)
          .toList()
        ..sort((a, b) => b.date!.compareTo(a.date!)),
    };
  }

  // 🚀 執行登出邏輯
  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("確認登出"),
            content: const Text("您確定要登出系統嗎？"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("取消")),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("登出", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );


    // 🚀 關鍵：這裡必須先處理 confirm 的邏輯，然後才關閉方法
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_custom_photo');
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      if (!mounted) return;

      // 🚀 修正 5：清除所有路由堆疊，強制回到登入頁
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        // 請確保已 import LoginScreen
            (route) => false,
      );
    }
  }

// 🚀 1. 計算資料夾大小的方法
  Future<int> _calculateDirectorySize(Directory dir) async {
    int total = 0;
    if (!await dir.exists()) return 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

// 🚀 2. 格式化顯示字串
  String _formatBytes(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return "${(bytes / mb).toStringAsFixed(1)} MB";
    if (bytes >= kb) return "${(bytes / kb).toStringAsFixed(1)} KB";
    return "$bytes B";
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
              offset: const Offset(0, 56),
              // 調整彈出位置在頭像下方一點
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (value) async {
                if (!mounted) return;
                if (value == 'photo') {
                  _handleChangePhoto();
                  return;
                }

                // 🚀 建立一個進度通知器，讓對話框能動態顯示 Service 傳回來的 message
                final progressNotifier = ValueNotifier<String>("準備中...");
                final percentNotifier = ValueNotifier<double>(0.0); // 🚀 初始化為 0

                if (value == 'sync') {
                  // 🚀 核心優化：同步前先「靜默刷新」Token，預防紅框錯誤
                  final GoogleSignInAccount? account = await _googleSignIn
                      .signInSilently();
                  if (account == null) {
                    // 如果靜默登入失敗，手動彈出一次選擇帳號視窗
                    await _googleSignIn.signIn();
                    return;
                  }
                  if (_isSyncing) return;


                  // A. 計算大小 (這部分保留)
                  final docDir = await getApplicationDocumentsDirectory();
                  final dbFile = File(p.join(docDir.path, 'eczema_data.isar'));
                  final photoDir = Directory(p.join(docDir.path, 'photos'));
                  final totalSize = (await dbFile.exists() ? await dbFile
                      .length() : 0) + await _calculateDirectorySize(photoDir);

                  // B. 確認對話框
                  final bool confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) =>
                        AlertDialog(
                          title: const Text("雲端備份說明"),
                          content: Text(
                              "將加密備份紀錄至 Google Drive。\n\n📦 預估大小：${_formatBytes(
                                  totalSize)}\n\n建議在 Wi-Fi 環境下執行。確定開始？"),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("取消")),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("開始備份")),
                          ],
                        ),
                  ) ?? false;

                  if (!confirmed) return;

                  setState(() => _isSyncing = true);

                  try {
                    await BackupDialogs.showProcessingDialog(
                      context: context,
                      title: "正在同步至雲端",
                      // 🚀 傳入 notifier，讓對話框監聽文字變化
                      progressNotifier: progressNotifier,
                      percentNotifier: percentNotifier,
                      // 🚀 傳入數值監聽器
                      action: () async {
                        await cloudBackupService.runBackup(
                          photoDir.path,
                          appVersion: _appVersion,
                          onProgress: (p) {
                            progressNotifier.value = p.message; // 更新文字
                            percentNotifier.value =
                                p.progress; // 🚀 更新進度條數值 (0.0~1.0)
                          },
                        );

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('last_backup_time',
                            DateTime.now().toIso8601String());
                      },
                    );
                    // 🚀 修正 4：在 await 之後，檢查 widget 是否還在畫面內
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("雲端備份完成"))
                    );
                  } catch (e) {
                    if (!mounted) return;
                    if (e is BackupException) BackupErrorDialog.show(
                        context, e);
                  } finally {
                    if (mounted) setState(() => _isSyncing = false);
                  }
                  return;
                }

                if (value == 'restore') {
                  final bool confirmed = await BackupDialogs.confirmRestore(
                      context);
                  if (!confirmed) return;

                  final progressNotifier = ValueNotifier<String>(
                      "正在聯繫雲端...");
                  final percentNotifier = ValueNotifier<double>(0.0); // 🚀 補上這行
                  setState(() => _isSyncing = true);

                  try {
                    await BackupDialogs.showProcessingDialog(
                      context: context,
                      title: "正在恢復數據",
                      progressNotifier: progressNotifier,
                      percentNotifier: percentNotifier,
                      // 🚀 補上這行
                      action: () async {
                        final docDir = await getApplicationDocumentsDirectory();
                        final String photoPath = p.join(docDir.path, 'photos');

                        // 🚀 核心修正：只執行還原，絕對不要在這邊接 runBackup！
                        await cloudBackupService.runRestore(
                          photoPath,
                          onProgress: (p) {
                            progressNotifier.value = p.message;
                            percentNotifier.value = p.progress; // 🚀 讓還原進度條也能跑
                          },
                        );

                        if (mounted) _refreshData(); // 讓 UI 刷新顯示新抓回來的資料
                      },
                    );
                  } catch (e) {
                    if (e is BackupException) BackupErrorDialog.show(
                        context, e);
                  } finally {
                    if (mounted) setState(() => _isSyncing = false);
                  }
                  return; // 🚀 記得補 return
                }

                if (value == 'logout') {
                  _handleLogout(context);
                  return;
                }
              },

              // 這是原本的頭像 UI
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: (_localPhotoPath != null &&
                      File(_localPhotoPath!).existsSync()
                      ? FileImage(File(_localPhotoPath!))
                      : (user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null)) as ImageProvider?,
                  child: (_localPhotoPath == null && user?.photoURL == null)
                      ? Text(
                    user?.displayName?.substring(0, 1).toUpperCase() ?? "U",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  )
                      : null,
                ),
              ),
              // 🚀 定義彈出的選單內容
              itemBuilder: (context) =>
              [
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
                // 在 itemBuilder 的回傳清單中加入：
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'sync', // 🚀 確保這個 value 跟下方 onSelected 對應
                  child: Row(
                    children: [
                      _isSyncing
                          ? const SizedBox(width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_outlined,
                          color: Colors.green),
                      const SizedBox(width: 12),
                      const Text("同步至雲端"),
                    ],
                  ),
                ),
                // 在 PopupMenuButton 的 itemBuilder 內增加：
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_download_outlined, color: Colors
                          .orange),
                      SizedBox(width: 12),
                      Text("從雲端恢復數據"),
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
            const Text("皮膚健康管理",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (user != null)
              Text(
                user.email ?? "雲端帳號已登入", // 🚀 顯示登入 Email 以利確認帳號
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            // 🚀 管理模式下顯示儲存圖示，平常顯示設定圖示
            icon: Icon(
              _isManagementMode ? Icons.check_circle : Icons
                  .settings_suggest_rounded,
              color: _isManagementMode ? Colors.green : null,
              size: 28,
            ),
            onPressed: () {
              // 🚀 如果目前是關閉狀態，準備進入模式時跳出提示
              if (!_isManagementMode) {
                ScaffoldMessenger
                    .of(context)
                    .hideCurrentSnackBar(); // 清除現有的 SnackBar
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


  Future<void> _handleManualBackup() async {
    final progressNotifier = ValueNotifier<String>("正在同步...");
    final percentNotifier = ValueNotifier<double>(0.0); // 🚀 補上百分比監聽器

    await BackupDialogs.showProcessingDialog(
      context: context,
      title: "資料同步中",
      progressNotifier: progressNotifier,
      percentNotifier: percentNotifier,
      // 🚀 傳入進度條監聽器
      action: () async {
        final docDir = await getApplicationDocumentsDirectory();
        final String photoPath = p.join(docDir.path, 'photos');

        // 🚀 正確呼叫：Backup 而不是 Restore
        await cloudBackupService.runBackup(
          photoPath,
          appVersion: _appVersion,
          onProgress: (p) {
            progressNotifier.value = p.message; // 更新文字訊息
            percentNotifier.value = p.progress; // 🚀 更新百分比數值 (0.0 ~ 1.0)
          },
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'last_backup_time', DateTime.now().toIso8601String());
      },
    );
  }

  // 在 HomeScreen 或某個啟動邏輯中檢查
  Future<void> _checkBackupRequirement() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupStr = prefs.getString('last_backup_time');

    // 取得 Isar 中最近四周的紀錄數量 (假設每週至少填一筆)
    final recentRecords = await isarService.getRecordsCountInLastDays(28);

    if (lastBackupStr == null && recentRecords > 0) {
      // 從未備份過且有資料，提醒
      _showBackupHint();
    } else if (lastBackupStr != null) {
      final lastBackup = DateTime.parse(lastBackupStr);
      final daysSinceBackup = DateTime
          .now()
          .difference(lastBackup)
          .inDays;

      // 🚀 如果超過 28 天沒備份，且這段時間有新照片/紀錄
      if (daysSinceBackup >= 28 && recentRecords > 0) {
        _showBackupHint();
      }
    }
  }

  void _showBackupHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("您已有四週的紀錄未備份，建議同步至雲端以防遺失。"),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: "立即同步",
          onPressed: () => _handleManualBackup(), // 觸發你原本的備份邏輯
        ),
      ),
    );
  }

  // --- 說明彈窗實作 ---
  void _showManagementGuide() {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.settings_suggest_rounded, color: Colors.blue),
                SizedBox(width: 10),
                Text("管理員模式")
              ],
            ),
            content: const Text(
                "現在您可以自由點選量表方塊來「開啟」或「關閉」病患需要的檢測項目。\n\n設定完成後，請再次點擊右上角勾勾儲存。"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text("我知道了", style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18))),
            ],
          ),
    );
  }

  Widget _buildScaleGrid(BuildContext context) {
    final List<Map<String, dynamic>> scales = [
      {
        'type': ScaleType.adct,
        'title': 'ADCT',
        'sub': '每周異膚控制',
        'color': Colors.blue,
        'icon': Icons.assignment_turned_in
      },
      {
        'type': ScaleType.poem,
        'title': 'POEM',
        'sub': '每周濕疹檢測',
        'color': Colors.orange,
        'icon': Icons.opacity
      },
      {
        'type': ScaleType.uas7,
        'title': 'UAS7',
        'sub': '每日蕁麻疹量表',
        'color': Colors.teal,
        'icon': Icons.calendar_month
      },
      {
        'type': ScaleType.scorad,
        'title': 'SCORAD',
        'sub': '每周異膚綜合',
        'color': Colors.purple,
        'icon': Icons.biotech
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
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
                  MaterialPageRoute(builder: (context) =>
                      PoemSurveyScreen(initialType: type)),
                );

                // 🚀 2. 核心修正：處理返回後的資料更新
                // 只要 result 為 true，代表資料庫已有變動（包含補填或正常填寫）
                if (result == true && mounted) {
                  // 第一步：立即觸發 setState。這會讓父層的 FutureBuilder 重新執行 _getTrackerData()
                  // 這樣從資料庫撈出來的最新 uas7Status 才會反應在日曆上
                  _refreshData(); // 🚀 這裡原本是 setState(() {}); 改成呼叫統一方法

                  // 🚀 這裡可以加上靜默檢查
                  _checkAndSilentBackup();

                  // 第二步：稍微延遲，等待新的數據渲染完成後，再執行 PageView 的自動對齊動畫
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) _jumpToScalePage(type); // 對齊到該卡片
                  });
                }
              } else {
                HapticFeedback.vibrate();
                _showDisabledScaleNotice(
                    scale['title'], scale['sub']); // 使用您之前定義的彈窗提示
              }
            },
            child: _buildScaleCard(scale, isEnabled),
          );
        },
      ),
    );
  }

  Future<void> _checkAndSilentBackup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_silent_backup');
    final now = DateTime.now();

    // 策略：每 28 天自動備份一次
    if (lastSyncStr != null) {
      final lastSync = DateTime.parse(lastSyncStr);
      if (now
          .difference(lastSync)
          .inDays < 28) return;
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final String photoPath = p.join(docDir.path, 'photos');

      // 🚀 正確呼叫：Backup 而不是 Restore
      await cloudBackupService.runBackup(photoPath, appVersion: _appVersion);

      await prefs.setString('last_silent_backup', now.toIso8601String());
      debugPrint("✅ 自動靜默備份完成");
    } catch (e) {
      debugPrint("❌ 自動備份失敗: $e");
    }
  }

  // --- 停用提示彈窗實作 ---
  void _showDisabledScaleNotice(String title, String sub) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: Text("$title 功能已關閉"),
            content: Text(
                "目前的病患照護計畫中，不需要執行「$sub」。\n\n如有需求，請洽詢主治醫師或護理人員開啟此量表。"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text("確定")),
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
              // 修改後：使用主題色，系統切換時它會自動變色
              color: isEnabled
                  ? Theme
                  .of(context)
                  .cardColor
                  : Theme
                  .of(context)
                  .disabledColor
                  .withOpacity(0.1),
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
                  color: isEnabled ? scale['color'].withOpacity(0.4) : Colors
                      .grey.shade300,
                  width: 1.5
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(scale['icon'], size: 40,
                    color: isEnabled ? scale['color'] : Colors.grey),
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
                        color: isEnabled
                            ? scale['color'].withOpacity(0.8)
                            : Colors.grey,
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
    final enabledTypes = ScaleType.values.where((t) =>
    _enabledScales[t] == true).toList();
// 🚀 修正 6：更精美的 Empty State
    if (enabledTypes.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings_outlined, color: Colors.grey, size: 40),
              SizedBox(height: 12),
              Text("尚未開啟任何追蹤項目\n請點擊右上角設定",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 295,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _trackerDataFuture, // 🚀 修正 3：使用快取的 Future
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
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

// 🚀 修改 3：把存好的提醒文字與點擊事件傳遞給卡片
  Widget _buildCardByType(ScaleType type, Map<String, dynamic> data) {
    final VoidCallback onRefresh = () => _refreshData();

    // 定義星期轉換，用來顯示 "週三 20:00"
    const Map<int, String> weekdaysShort = {
      1: '週一', 2: '週二', 3: '週三', 4: '週四', 5: '週五', 6: '週六', 7: '週日'
    };

    // 建立顯示字串 (如果是開啟的，顯示時間；如果是關閉的，顯示尚未設定)
    String? reminderText;
    if (_reminderEnabled[type] == true && _reminderTimes.containsKey(type)) {
      final timeStr = _reminderTimes[type]!.format(context);
      if (type == ScaleType.uas7) {
        reminderText = timeStr; // 每日只顯示時間
      } else {
        final dayStr = weekdaysShort[_reminderDays[type] ?? 7];
        reminderText = "$dayStr $timeStr"; // 每週顯示 星期+時間
      }
    }

    // 當卡片右上角的按鈕被點擊時，直接呼叫剛剛寫好的底層面板
    final VoidCallback onReminderTap = () => _showReminderSettingsModal();

    switch (type) {
      case ScaleType.uas7:
        return Uas7TrackerCard(
          startDate: data['uas7Start'],
          completionStatus: data['uas7Status'],
          history: data['uas7Records'],
          onRefresh: onRefresh,
          reminderText: reminderText,    // 🚀 傳入文字
          onReminderTap: onReminderTap,  // 🚀 傳入點擊事件
        );
      case ScaleType.adct:
        return WeeklyTrackerCard(
          type: ScaleType.adct, history: data['adct'], onRefresh: onRefresh,
          reminderText: reminderText, onReminderTap: onReminderTap,
        );
      case ScaleType.poem:
        return WeeklyTrackerCard(
          type: ScaleType.poem, history: data['poem'], onRefresh: onRefresh,
          reminderText: reminderText, onReminderTap: onReminderTap,
        );
      case ScaleType.scorad:
        return WeeklyTrackerCard(
          type: ScaleType.scorad, history: data['scorad'], onRefresh: onRefresh,
          reminderText: reminderText, onReminderTap: onReminderTap,
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
                color: currentPage == index ? Colors.blue : Colors.grey
                    .shade300,
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

    final enabledTypes = ScaleType.values.where((t) =>
    _enabledScales[t] == true).toList();
    int targetIndexInEnabled = enabledTypes.indexOf(type);
    if (targetIndexInEnabled == -1) return;

    int count = enabledTypes.length;

    // 🚀 修正：參考點改為目前的實際位置，若無則參考初始值 500
    double currentPageValue = _pageController.page ??
        _virtualInitialPage.toDouble();
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
              child: _buildSmallMenuButton(
                  context, "查看趨勢", Icons.bar_chart_rounded,
                  Colors.teal.shade700,
                      () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const TrendChartScreen()));
                    if (mounted) _refreshData(); // 返回時刷新，確保資料一致
                  }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallMenuButton(
                  context, "歷史紀錄", Icons.list_alt_rounded,
                  Colors.blueGrey.shade700,
                      () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const HistoryListScreen()));
                    if (mounted) _refreshData(); // 歷史紀錄最常發生刪除/修改，務必刷新
                  }),
            ),
          ],
        )
    );
  }

// 🚀 幫按鈕補上震動
  Widget _buildSmallMenuButton(BuildContext context, String label,
      IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact(); // 🚀 加入輕微震動回饋
        onTap();
      },
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        // 🚀 改為主題卡片顏色，而非固定白色
        backgroundColor: Theme
            .of(context)
            .cardColor,
        foregroundColor: color,
        elevation: 2,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: color.withOpacity(0.3), width: 1.5)
        ),
      ),
    );
  }

// 🚀 替換原本的 _buildSwiperHeader 與時間挑選器
  Widget _buildSwiperHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 20, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          const Text("臨床進度週期追蹤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),

          // 🚀 新的「提醒設定」按鈕
          InkWell(
            onTap: _showReminderSettingsModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm_rounded, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 6),
                  Text("提醒設定", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
// 🚀 全新的量表獨立設定面板
  void _showReminderSettingsModal() {
    HapticFeedback.lightImpact();

    // 定義星期對應表
    const Map<int, String> weekdays = {
      1: '週一', 2: '週二', 3: '週三', 4: '週四', 5: '週五', 6: '週六', 7: '週日'
    };

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (BuildContext ctx) {
          return StatefulBuilder(
              builder: (context, setModalState) {
                final activeTypes = ScaleType.values.where((t) => _enabledScales[t] == true).toList();

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                    left: 20, right: 20, top: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("⏰ 各項量表提醒設定", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      if (activeTypes.isEmpty)
                        const Text("目前沒有開啟任何量表。", style: TextStyle(color: Colors.grey)),

                      // 列出所有目前啟用的量表
                      ...activeTypes.map((type) {
                        final isDaily = type == ScaleType.uas7;
                        return Card(
                          elevation: 0,
                          color: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade300)
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // 標題與開關
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${type.name.toUpperCase()} (${isDaily ? '每日' : '每週'})",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Switch(
                                      value: _reminderEnabled[type] ?? true,
                                      onChanged: (val) {
                                        setModalState(() => _reminderEnabled[type] = val);
                                        setState(() => _reminderEnabled[type] = val);
                                      },
                                    ),
                                  ],
                                ),

                                // 時間與星期選擇器
                                if (_reminderEnabled[type] == true)
                                  Row(
                                    children: [
                                      if (!isDaily) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              value: _reminderDays[type],
                                              items: weekdays.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setModalState(() => _reminderDays[type] = val);
                                                  setState(() => _reminderDays[type] = val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],

                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.access_time),
                                          label: Text(_reminderTimes[type]!.format(context)),
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: Colors.blue.withOpacity(0.1),
                                            foregroundColor: Colors.blue.shade700,
                                          ),
                                          onPressed: () async {
                                            final time = await showTimePicker(context: context, initialTime: _reminderTimes[type]!);
                                            if (time != null) {
                                              setModalState(() => _reminderTimes[type] = time);
                                              setState(() => _reminderTimes[type] = time);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _saveReminderSettings();
                            await _scheduleClinicalReminders();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ 提醒設定已儲存並生效")));
                          },
                          child: const Text("儲存設定", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

}