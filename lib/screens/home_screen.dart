import 'dart:ui';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../services/cloud_backup_service.dart';
import '../widgets/backup_dialogs.dart';
import '../services/backup_error_dialog.dart';
import '../services/notification_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _appVersion = "1.0.0";
  static const int _virtualInitialPage = 500;
  final int _virtualTotalCount = 1000;
  String? _localPhotoPath;
  bool _isSyncing = false;

  late final PageController _pageController = PageController(
    initialPage: _virtualInitialPage,
    viewportFraction: 0.9,
  );

  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  bool _isManagementMode = false;
  final Map<ScaleType, TimeOfDay> _reminderTimes = {};
  final Map<ScaleType, int> _reminderDays = {};
  final Map<ScaleType, bool> _reminderEnabled = {};

  Map<ScaleType, bool> _enabledScales = {
    ScaleType.adct: true,
    ScaleType.poem: true,
    ScaleType.uas7: true,
    ScaleType.scorad: true,
  };

  // 2. 加入廣告相關變數
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

// 🚀 2. 使用 kReleaseMode 自動切換正式與測試 ID
  final String _adUnitId = kReleaseMode
      ? (Platform.isAndroid
      ? 'ca-app-pub-6250825906693072/8000200207' // ✅ 正式 Android ID
      : 'ca-app-pub-6250825906693072/1102931009') // ✅ 正式 iOS ID
      : (Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // 🧪 測試 Android ID
      : 'ca-app-pub-3940256099942544/2934735716'); // 🧪 測試 iOS ID

  Future<Map<String, dynamic>>? _trackerDataFuture;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    _loadSettings();
    _loadLocalPhoto();
    _refreshData();
    _loadBannerAd(); // 🚀 啟動載入

    // 🚀 初始化完成後執行備份檢查
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkBackupRequirement();
        if (pendingPayload != null) {
          handleNotificationJump(pendingPayload!);
          pendingPayload = null;
        }
      }
    });

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.offset;
      if (offset > 10 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (offset <= 10 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isAdLoaded = true);
          debugPrint('廣告載入成功');
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          debugPrint('廣告載入失敗: ${err.message}');
        },
      ),
    )..load();
  }

  void _refreshData() {
    setState(() {
      _trackerDataFuture = _getTrackerData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _bannerAd?.dispose(); // 🚀 釋放廣告資源，避免記憶體洩漏
    super.dispose();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.appdata'],
  );

  late final CloudBackupService cloudBackupService = CloudBackupService(
    isar: isarService.isar,
    isarFactory: () async => await isarService.openDB(),
    googleSignIn: _googleSignIn,
    onDbSwapped: (newIsar) => isarService.updateInstance(newIsar),
  );

  Future<void> _loadLocalPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('user_custom_photo');
    if (savedPath != null) {
      final file = File(savedPath);
      if (!await file.exists()) {
        final docDir = await getApplicationDocumentsDirectory();
        final newPath = p.join(docDir.path, p.basename(savedPath));
        if (await File(newPath).exists()) {
          savedPath = newPath;
          await prefs.setString('user_custom_photo', newPath);
        }
      }
    }
    setState(() => _localPhotoPath = savedPath);
  }

  Future<void> _handleChangePhoto() async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('從相簿選擇'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('開啟相機'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          ],
        ),
      ),
    );
    if (source == null) return;
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: '編輯大頭照', toolbarColor: Colors.blue, toolbarWidgetColor: Colors.white, cropStyle: CropStyle.circle, showCropGrid: false, hideBottomControls: true, aspectRatioPresets: [CropAspectRatioPreset.square], lockAspectRatio: true, initAspectRatio: CropAspectRatioPreset.square),
        IOSUiSettings(title: '編輯大頭照', aspectRatioLockEnabled: true, resetAspectRatioEnabled: false),
      ],
    );
    if (croppedFile != null) {
      setState(() => _localPhotoPath = croppedFile.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_custom_photo', croppedFile.path);
    }
  }

  void _checkUserStatus() {
    if (FirebaseAuth.instance.currentUser == null) debugPrint("訪客模式");
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var type in ScaleType.values) {
        _enabledScales[type] = prefs.getBool('enable_${type.name}') ?? true;
        _reminderEnabled[type] = prefs.getBool('reminder_enabled_${type.name}') ?? true;
        _reminderDays[type] = prefs.getInt('reminder_day_${type.name}') ?? DateTime.sunday;
        final savedHour = prefs.getInt('reminder_hour_${type.name}') ?? 20;
        final savedMinute = prefs.getInt('reminder_minute_${type.name}') ?? 0;
        _reminderTimes[type] = TimeOfDay(hour: savedHour, minute: savedMinute);
      }
    });
    _scheduleClinicalReminders();
  }

  Future<void> _scheduleClinicalReminders() async {
    for (var type in ScaleType.values) {
      await NotificationService().cancel(type.index);
      if (_enabledScales[type] == true && _reminderEnabled[type] == true) {
        final time = _reminderTimes[type]!;
        if (type == ScaleType.uas7) {
          await NotificationService().scheduleDailyReminder(id: type.index, title: '${type.name.toUpperCase()} 追蹤提醒', body: '請記錄今天的狀況。', hour: time.hour, minute: time.minute, payload: type.name);
        } else {
          await NotificationService().scheduleWeeklyReminder(id: type.index, title: '${type.name.toUpperCase()} 追蹤提醒', body: '今天是紀錄日。', dayOfWeek: _reminderDays[type]!, hour: time.hour, minute: time.minute, payload: type.name);
        }
      }
    }
  }

  Future<void> _saveReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (var type in ScaleType.values) {
      await prefs.setBool('reminder_enabled_${type.name}', _reminderEnabled[type] ?? true);
      await prefs.setInt('reminder_day_${type.name}', _reminderDays[type] ?? DateTime.sunday);
      await prefs.setInt('reminder_hour_${type.name}', _reminderTimes[type]?.hour ?? 20);
      await prefs.setInt('reminder_minute_${type.name}', _reminderTimes[type]?.minute ?? 0);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (var entry in _enabledScales.entries) {
      await prefs.setBool('enable_${entry.key.name}', entry.value);
    }
  }

  Future<Map<String, dynamic>> _getTrackerData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allRecords = await isarService.getAllRecords();
    final uas7Records = allRecords.where((r) => r.scaleType == ScaleType.uas7).toList();
    DateTime uas7Start = today.subtract(const Duration(days: 8));
    return {
      'uas7Start': uas7Start,
      'uas7Status': List.generate(14, (i) => uas7Records.any((r) => DateUtils.isSameDay(r.targetDate ?? r.date, uas7Start.add(Duration(days: i))))),
      'uas7Records': uas7Records,
      'adct': allRecords.where((r) => r.scaleType == ScaleType.adct).toList()..sort((a, b) => b.date!.compareTo(a.date!)),
      'poem': allRecords.where((r) => r.scaleType == ScaleType.poem).toList()..sort((a, b) => b.date!.compareTo(a.date!)),
      'scorad': allRecords.where((r) => r.scaleType == ScaleType.scorad).toList()..sort((a, b) => b.date!.compareTo(a.date!)),
    };
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(title: const Text("確認登出"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("登出", style: TextStyle(color: Colors.red)))]),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (ctx) => const LoginScreen()), (route) => false);
    }
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    int total = 0; if (!await dir.exists()) return 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) { if (entity is File) total += await entity.length(); }
    return total;
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1048576) return "${(bytes / 1048576).toStringAsFixed(1)} MB";
    if (bytes >= 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "$bytes B";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double topPadding = MediaQuery.of(context).padding.top;

    ImageProvider? avatarImage;
    if (_localPhotoPath != null && File(_localPhotoPath!).existsSync()) {
      avatarImage = FileImage(File(_localPhotoPath!));
    } else if (user?.photoURL != null) {
      avatarImage = NetworkImage(user!.photoURL!);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          elevation: _isScrolled ? 2 : 0,
          shadowColor: Colors.black.withOpacity(0.1),
          title: Container(
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. 左側：頭像選單 (功能完整回歸版)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    offset: const Offset(0, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (val) async {
                      if (!mounted) return;

                      // --- 功能 A：更換頭像 ---
                      if (val == 'photo') { _handleChangePhoto(); return; }

                      // --- 功能 B：同步至雲端 (完整版) ---
                      if (val == 'sync') {
                        final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
                        if (account == null) { await _googleSignIn.signIn(); return; }
                        if (_isSyncing) return;

                        final docDir = await getApplicationDocumentsDirectory();
                        final dbFile = File(p.join(docDir.path, 'eczema_data.isar'));
                        final photoDir = Directory(p.join(docDir.path, 'photos'));
                        final totalSize = (await dbFile.exists() ? await dbFile.length() : 0) + await _calculateDirectorySize(photoDir);

                        final bool confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("雲端備份說明"),
                            content: Text("將加密備份紀錄至 Google Drive。\n\n📦 預估大小：${_formatBytes(totalSize)}\n\n建議在 Wi-Fi 環境下執行。確定開始？"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("開始備份")),
                            ],
                          ),
                        ) ?? false;

                        if (!confirmed) return;

                        setState(() => _isSyncing = true);
                        try {
                          final progressNotifier = ValueNotifier<String>("準備中...");
                          final percentNotifier = ValueNotifier<double>(0.0);
                          await BackupDialogs.showProcessingDialog(
                            context: context,
                            title: "正在同步至雲端",
                            progressNotifier: progressNotifier,
                            percentNotifier: percentNotifier,
                            action: () async {
                              await cloudBackupService.runBackup(
                                photoDir.path,
                                appVersion: _appVersion,
                                onProgress: (p) {
                                  progressNotifier.value = p.message;
                                  percentNotifier.value = p.progress;
                                },
                              );
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
                            },
                          );
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ 雲端備份完成")));
                        } catch (e) {
                          if (mounted && e is BackupException) BackupErrorDialog.show(context, e);
                        } finally {
                          if (mounted) setState(() => _isSyncing = false);
                        }
                        return;
                      }

                      // --- 功能 C：從雲端恢復 (補回版) ---
                      if (val == 'restore') {
                        final bool confirmed = await BackupDialogs.confirmRestore(context);
                        if (!confirmed) return;

                        setState(() => _isSyncing = true);
                        try {
                          final progressNotifier = ValueNotifier<String>("正在聯繫雲端...");
                          final percentNotifier = ValueNotifier<double>(0.0);
                          await BackupDialogs.showProcessingDialog(
                            context: context,
                            title: "正在恢復數據",
                            progressNotifier: progressNotifier,
                            percentNotifier: percentNotifier,
                            action: () async {
                              final docDir = await getApplicationDocumentsDirectory();
                              final String photoPath = p.join(docDir.path, 'photos');
                              await cloudBackupService.runRestore(
                                photoPath,
                                onProgress: (p) {
                                  progressNotifier.value = p.message;
                                  percentNotifier.value = p.progress;
                                },
                              );
                              if (mounted) _refreshData();
                            },
                          );
                        } catch (e) {
                          if (mounted && e is BackupException) BackupErrorDialog.show(context, e);
                        } finally {
                          if (mounted) setState(() => _isSyncing = false);
                        }
                        return;
                      }

                      // --- 功能 D：登出系統 ---
                      if (val == 'logout') _handleLogout(context);
                    },
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: avatarImage,
                        child: (avatarImage == null) ? Text((user?.displayName != null && user!.displayName!.trim().isNotEmpty) ? user.displayName!.trim().substring(0, 1).toUpperCase() : "U", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blueGrey)) : null,
                      ),
                    ),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'photo', child: Row(children: [Icon(Icons.photo_library_rounded, color: Colors.blue), SizedBox(width: 12), Text("更換頭像")])),
                      const PopupMenuDivider(),
                      PopupMenuItem(value: 'sync', child: Row(children: [
                        _isSyncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_outlined, color: Colors.green),
                        const SizedBox(width: 12), const Text("同步至雲端")
                      ])),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'restore', child: Row(children: [Icon(Icons.cloud_download_outlined, color: Colors.orange), SizedBox(width: 12), Text("從雲端恢復數據")])), // 補回這行
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout_rounded, color: Colors.redAccent), SizedBox(width: 12), Text("登出系統")])),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // 2. 中間：標題與信箱 (維持 top: 15.0 對齊)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "CareSync 健康隨行",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: isDarkMode ? Colors.white : Colors.blueGrey.shade900, letterSpacing: 0.3),
                          ),
                        ),
                        if (user != null && user.email != null)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              user.email!,
                              style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.grey.shade600, height: 1.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 3. 右側：設定按鈕 (維持 bottom: 5.0 對齊)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isManagementMode ? Icons.check_circle : Icons.settings_suggest_rounded,
                      color: _isManagementMode ? Colors.green : (isDarkMode ? Colors.white : Colors.blueGrey.shade700),
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        _isManagementMode = !_isManagementMode;
                        if (!_isManagementMode) _saveSettings();
                      });
                      if (_isManagementMode) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已進入管理員模式"), behavior: SnackBarBehavior.floating));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // 🚀 核心修正：使用 Column 讓廣告與滾動區域分離
        body: Column(
          children: [
            // 1. 滾動內容區：使用 Expanded 佔滿剩餘空間
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildScaleGrid(context),
                    const SizedBox(height: 12),
                    _buildSecondaryNavigation(context),
                    const SizedBox(height: 16),
                    _buildSwiperHeader(),
                    _buildProgressSwiper(),
                    const SizedBox(height: 40), // 給內容留一點底部間距
                  ],
                ),
              ),
            ),

            // 2. 固定廣告區：放在 Expanded 之外，它就會永遠「貼」在螢幕最下方
            if (_isAdLoaded && _bannerAd != null)
              Container(
                color: isDarkMode ? Colors.black : Colors.white, // 確保背景色與主題一致
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8, // 🚀 自動避開 iPhone 底部的白條
                ),
                width: double.infinity,
                alignment: Alignment.center,
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- 補回所有業務方法 ---

  Future<void> _checkBackupRequirement() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupStr = prefs.getString('last_backup_time');
    final recentRecords = await isarService.getRecordsCountInLastDays(28);
    if (lastBackupStr == null && recentRecords > 0) {
      _showBackupHint();
    } else if (lastBackupStr != null) {
      final days = DateTime.now().difference(DateTime.parse(lastBackupStr)).inDays;
      if (days >= 28 && recentRecords > 0) _showBackupHint();
    }
  }

  void _showBackupHint() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("您已有四週的紀錄未備份。"), action: SnackBarAction(label: "立即同步", onPressed: () => _handleManualBackup())));
  }

  Future<void> _handleManualBackup() async {
    final docDir = await getApplicationDocumentsDirectory();
    await BackupDialogs.showProcessingDialog(context: context, title: "同步中", progressNotifier: ValueNotifier(""), percentNotifier: ValueNotifier(0.0), action: () async {
      await cloudBackupService.runBackup(p.join(docDir.path, 'photos'), appVersion: _appVersion, onProgress: (p) {});
      final prefs = await SharedPreferences.getInstance(); await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
    });
  }

  Future<void> _checkAndSilentBackup() async {
    final user = FirebaseAuth.instance.currentUser; if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastSyncStr = prefs.getString('last_silent_backup');
    if (lastSyncStr != null && now.difference(DateTime.parse(lastSyncStr)).inDays < 28) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      await cloudBackupService.runBackup(p.join(docDir.path, 'photos'), appVersion: _appVersion);
      await prefs.setString('last_silent_backup', now.toIso8601String());
    } catch (e) { debugPrint("靜默備份失敗: $e"); }
  }

  Widget _buildScaleGrid(BuildContext context) {
    final scales = [
      {'type': ScaleType.adct, 'title': 'ADCT', 'sub': '每周異膚控制', 'color': Colors.blue, 'icon': Icons.assignment_turned_in},
      {'type': ScaleType.poem, 'title': 'POEM', 'sub': '每周濕疹檢測', 'color': Colors.orange, 'icon': Icons.opacity},
      {'type': ScaleType.uas7, 'title': 'UAS7', 'sub': '每日蕁麻疹量表', 'color': Colors.teal, 'icon': Icons.calendar_month},
      {'type': ScaleType.scorad, 'title': 'SCORAD', 'sub': '每周異膚綜合', 'color': Colors.purple, 'icon': Icons.biotech},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.2),
        itemCount: scales.length,
        itemBuilder: (ctx, i) {
          final type = scales[i]['type'] as ScaleType;
          return _AnimatedScaleCard(
            scale: scales[i], isEnabled: _enabledScales[type] ?? true, isManagementMode: _isManagementMode,
            onTap: () async {
              if (_isManagementMode) { setState(() => _enabledScales[type] = !(_enabledScales[type] ?? true)); }
              else if (_enabledScales[type] ?? true) {
                final res = await Navigator.push<bool>(context, MaterialPageRoute(builder: (ctx) => PoemSurveyScreen(initialType: type)));
                if (res == true && mounted) { _refreshData(); _checkAndSilentBackup(); Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _jumpToScalePage(type); }); }
              } else { _showDisabledScaleNotice(scales[i]['title'] as String, scales[i]['sub'] as String); }
            },
          );
        },
      ),
    );
  }

  void _showDisabledScaleNotice(String title, String sub) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text("$title 功能已關閉"), content: Text("目前的病患照護計畫中，不需要執行「$sub」。\n\n如有需求，請洽詢主治醫師或護理人員開啟此量表。"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("確定"))]));
  }

  Widget _buildSecondaryNavigation(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
      Expanded(child: _buildSmallMenuButton(context, "查看趨勢", Icons.bar_chart_rounded, Colors.teal.shade700, () async { await Navigator.push(context, MaterialPageRoute(builder: (ctx) => const TrendChartScreen())); if (mounted) _refreshData(); })),
      const SizedBox(width: 12),
      Expanded(child: _buildSmallMenuButton(context, "歷史紀錄", Icons.list_alt_rounded, Colors.blueGrey.shade700, () async { await Navigator.push(context, MaterialPageRoute(builder: (ctx) => const HistoryListScreen())); if (mounted) _refreshData(); })),
    ]));
  }

  Widget _buildSmallMenuButton(BuildContext ctx, String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Material(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15), child: InkWell(borderRadius: BorderRadius.circular(15), onTap: () { HapticFeedback.lightImpact(); onTap(); }, child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 22, color: color), const SizedBox(width: 6), Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: color))))])))),
    );
  }

  Widget _buildSwiperHeader() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Row(children: [
      const Icon(Icons.auto_awesome, size: 20, color: Colors.orangeAccent), const SizedBox(width: 8),
      const Expanded(child: Text("臨床進度週期追蹤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
      InkWell(onTap: _showReminderSettingsModal, child: Row(children: [Icon(Icons.alarm_rounded, size: 16, color: Colors.blue.shade600), const SizedBox(width: 4), Text("提醒", style: TextStyle(fontSize: 14, color: Colors.blue.shade700, fontWeight: FontWeight.bold))])),
    ]));
  }

  void _showReminderSettingsModal() {
    const Map<int, String> weekdays = {1: '週一', 2: '週二', 3: '週三', 4: '週四', 5: '週五', 6: '週六', 7: '週日'};
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
      return StatefulBuilder(builder: (context, setModalState) {
        final activeTypes = ScaleType.values.where((t) => _enabledScales[t] == true).toList();
        return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 20, right: 20, top: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("⏰ 各項量表提醒設定", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
          ...activeTypes.map((type) {
            return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text("${type.name.toUpperCase()} (${type == ScaleType.uas7 ? '每日' : '每週'})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Switch(value: _reminderEnabled[type] ?? true, onChanged: (val) { setModalState(() => _reminderEnabled[type] = val); setState(() => _reminderEnabled[type] = val); })]),
              if (_reminderEnabled[type] == true) Row(children: [
                if (type != ScaleType.uas7) ...[Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: DropdownButtonHideUnderline(child: DropdownButton<int>(value: _reminderDays[type], items: weekdays.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (val) { if (val != null) { setModalState(() => _reminderDays[type] = val); setState(() => _reminderDays[type] = val); } }))), const SizedBox(width: 12)],
                Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.access_time), label: Text(_reminderTimes[type]!.format(context)), style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: Colors.blue.withOpacity(0.1), foregroundColor: Colors.blue.shade700), onPressed: () async { final time = await showTimePicker(context: context, initialTime: _reminderTimes[type]!); if (time != null) { setModalState(() => _reminderTimes[type] = time); setState(() => _reminderTimes[type] = time); } }))
              ])
            ])));
          }).toList(),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { Navigator.pop(ctx); await _saveReminderSettings(); await _scheduleClinicalReminders(); }, child: const Text("儲存設定", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))
        ]));
      });
    });
  }

  Widget _buildProgressSwiper() {
    final enabledTypes = ScaleType.values.where((t) => _enabledScales[t] == true).toList();
    if (enabledTypes.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      SizedBox(height: 295, child: FutureBuilder<Map<String, dynamic>>(future: _trackerDataFuture, builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        return PageView.builder(controller: _pageController, itemCount: _virtualTotalCount, itemBuilder: (ctx, i) => _buildCardByType(enabledTypes[i % enabledTypes.length], data));
      })),
      const SizedBox(height: 12),
      ListenableBuilder(listenable: _pageController, builder: (ctx, child) {
        int current = (_pageController.hasClients ? (_pageController.page ?? 0).round() : 0) % enabledTypes.length;
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(enabledTypes.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), height: 8, width: current == i ? 20 : 8, decoration: BoxDecoration(color: current == i ? Colors.blue : Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))));
      }),
    ]);
  }

  Widget _buildCardByType(ScaleType type, Map<String, dynamic> data) {
    const Map<int, String> weekdaysShort = {1: '一', 2: '二', 3: '三', 4: '四', 5: '五', 6: '六', 7: '日'};
    String? reminderText;
    if (_reminderEnabled[type] == true && _reminderTimes.containsKey(type)) {
      final timeStr = _reminderTimes[type]!.format(context);
      reminderText = type == ScaleType.uas7 ? timeStr : "${weekdaysShort[_reminderDays[type] ?? 7]} $timeStr";
    }
    final onRemTap = () => _showReminderSettingsModal();
    switch (type) {
      case ScaleType.uas7: return Uas7TrackerCard(startDate: data['uas7Start'], completionStatus: data['uas7Status'], history: data['uas7Records'], onRefresh: _refreshData, reminderText: reminderText, onReminderTap: onRemTap);
      case ScaleType.adct: return WeeklyTrackerCard(type: ScaleType.adct, history: data['adct'], onRefresh: _refreshData, reminderText: reminderText, onReminderTap: onRemTap);
      case ScaleType.poem: return WeeklyTrackerCard(type: ScaleType.poem, history: data['poem'], onRefresh: _refreshData, reminderText: reminderText, onReminderTap: onRemTap);
      case ScaleType.scorad: return WeeklyTrackerCard(type: ScaleType.scorad, history: data['scorad'], onRefresh: _refreshData, reminderText: reminderText, onReminderTap: onRemTap);
      default: return const SizedBox.shrink();
    }
  }

  void _jumpToScalePage(ScaleType type) {
    if (!_pageController.hasClients) return;
    final enabled = ScaleType.values.where((t) => _enabledScales[t] == true).toList();
    int target = enabled.indexOf(type); if (target == -1) return;
    int current = _pageController.page!.round();
    _pageController.animateToPage(current + (target - (current % enabled.length)), duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
  }
}

class _AnimatedScaleCard extends StatefulWidget {
  final Map<String, dynamic> scale; final bool isEnabled; final bool isManagementMode; final VoidCallback onTap;
  const _AnimatedScaleCard({required this.scale, required this.isEnabled, required this.isManagementMode, required this.onTap});
  @override State<_AnimatedScaleCard> createState() => _AnimatedScaleCardState();
}

class _AnimatedScaleCardState extends State<_AnimatedScaleCard> {
  double _scale = 1.0; double _elevation = 2.0;
  @override Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTapDown: (_) => setState(() { _scale = 0.96; _elevation = 8.0; }),
      onTapUp: (_) => setState(() { _scale = 1.0; _elevation = 2.0; }),
      onTapCancel: () => setState(() { _scale = 1.0; _elevation = 2.0; }),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale, duration: const Duration(milliseconds: 120), curve: Curves.easeOut,
        child: AnimatedPhysicalModel(
          duration: const Duration(milliseconds: 120), shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(24),
          elevation: widget.isEnabled ? _elevation : 0, color: Colors.transparent, shadowColor: (widget.scale['color'] as Color).withOpacity(0.3),
          child: Stack(children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(widget.isEnabled ? Colors.transparent : Colors.grey, BlendMode.saturation),
              child: Container(
                width: double.infinity, decoration: BoxDecoration(color: widget.isEnabled ? Theme.of(context).cardColor : Theme.of(context).disabledColor.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: widget.isEnabled ? widget.scale['color'].withOpacity(0.4) : Colors.grey.shade300, width: 1.5)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(widget.scale['icon'], size: 40, color: widget.isEnabled ? widget.scale['color'] : Colors.grey), const SizedBox(height: 8),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(widget.scale['title'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: widget.isEnabled ? widget.scale['color'] : Colors.grey))),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(widget.scale['sub'] as String, style: TextStyle(fontSize: 14, color: widget.isEnabled ? widget.scale['color'].withOpacity(0.8) : Colors.grey, fontWeight: FontWeight.bold)))
                ]),
              ),
            ),
            if (widget.isManagementMode) Positioned(top: 10, right: 10, child: CircleAvatar(radius: 12, backgroundColor: widget.isEnabled ? Colors.green : Colors.red, child: Icon(widget.isEnabled ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.white)))
          ]),
        ),
      ),
    );
  }
}