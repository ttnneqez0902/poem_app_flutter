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
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:marquee/marquee.dart';

import '../services/cloud_backup_service.dart';
import '../widgets/backup_dialogs.dart';
import '../services/backup_error_dialog.dart';
import '../services/notification_service.dart';
import '../models/scale_config.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- 核心狀態與配置 ---
  AppCategory _currentCategory = AppCategory.dermatology;
  final String _appVersion = "1.0.0";
  static const int _virtualInitialPage = 500;
  final int _virtualTotalCount = 1000;
  String? _localPhotoPath;
  bool _isSyncing = false;
  bool _isScrolled = false;
  bool _isManagementMode = false;
  bool _isBoy = true;             // 🚀 2. 補上這個漏掉的性別變數
  DateTime? _childBirthday;
  DateTime? _childDueDate; // 🚀 新增這行：預產期

  late final PageController _pageController = PageController(
    initialPage: _virtualInitialPage,
    viewportFraction: 0.9,
  );
  final ScrollController _scrollController = ScrollController();

  // --- 提醒與量表開關設定 ---
  final Map<ScaleType, TimeOfDay> _reminderTimes = {};
  final Map<ScaleType, int> _reminderDays = {};
  final Map<ScaleType, bool> _reminderEnabled = {};

// ✅ 修改後 (用迴圈自動包含所有量表)
  Map<ScaleType, bool> _enabledScales = {
    for (var type in ScaleType.values) type: true
  };

  // --- 廣告相關變數 ---
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  final String _adUnitId = kReleaseMode
      ? (Platform.isAndroid
      ? 'ca-app-pub-6250825906693072/8000200207'
      : 'ca-app-pub-6250825906693072/1102931009')
      : (Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716');

  final String _interstitialAdUnitId = kReleaseMode
      ? (Platform.isAndroid
      ? 'ca-app-pub-6250825906693072/6233433793'
      : 'ca-app-pub-6250825906693072/9597963737')
      : (Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910');

  Future<Map<String, dynamic>>? _trackerDataFuture;

  // --- 雲端備份服務 ---
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.appdata'],
  );

  late final CloudBackupService cloudBackupService = CloudBackupService(
    isar: isarService.isar,
    isarFactory: () async => await isarService.openDB(),
    googleSignIn: _googleSignIn,
    onDbSwapped: (newIsar) => isarService.updateInstance(newIsar),
  );

  // --- 科別內容配置表 (親民圖示版) ---
  Map<AppCategory, List<Map<String, dynamic>>> get _categoryConfigs => {
    AppCategory.dermatology: [
      {'type': ScaleType.adct, 'title': 'ADCT', 'sub': '肌膚穩定追蹤', 'color': Colors.blue, 'icon': Icons.health_and_safety_rounded},
      {'type': ScaleType.poem, 'title': 'POEM', 'sub': '這週皮膚還好嗎？', 'color': Colors.orange, 'icon': Icons.water_drop_rounded},
      {'type': ScaleType.uas7, 'title': 'UAS7', 'sub': '今日小紅點紀錄', 'color': Colors.teal, 'icon': Icons.flare_rounded},
      {'type': ScaleType.scorad, 'title': 'SCORAD', 'sub': '全身狀況掃描', 'color': Colors.purple, 'icon': Icons.person_search_rounded},
    ],

// 🚀 新增：睡眠健康 (必做核心)
    AppCategory.sleep: [
      {'type': ScaleType.psqi, 'title': 'PSQI', 'sub': '專業睡眠品質指數', 'color': Colors.indigo, 'icon': Icons.bedtime_rounded},
      {'type': ScaleType.isi, 'title': 'ISI', 'sub': '失眠嚴重程度評估', 'color': Colors.deepPurple, 'icon': Icons.nights_stay_rounded},
      {'type': ScaleType.ess, 'title': 'Epworth', 'sub': '白天嗜睡程度檢查', 'color': Colors.blueGrey, 'icon': Icons.wb_twilight_rounded},
    ],

    // 🚀 補上 BPI，讓慢性病管理的網格與趨勢圖同步
    AppCategory.chronic: [
      {'type': ScaleType.bp_log, 'title': '血壓紀錄', 'sub': '心血管規律追蹤', 'color': Colors.red, 'icon': Icons.monitor_heart_rounded},
      {'type': ScaleType.cat, 'title': 'CAT', 'sub': '慢性呼吸道評估', 'color': Colors.cyan, 'icon': Icons.air_rounded},
      {'type': ScaleType.dds, 'title': 'DDS', 'sub': '糖尿病心理壓力', 'color': Colors.orange, 'icon': Icons.psychology_alt_rounded},
      {'type': ScaleType.bpi, 'title': 'BPI', 'sub': '簡明疼痛量表', 'color': Colors.redAccent.shade400, 'icon': Icons.personal_injury_rounded}, // 👈 補上這行
    ],

    AppCategory.psychiatry: [
      {'type': ScaleType.phq9, 'title': 'PHQ-9', 'sub': '心情起伏觀察', 'color': Colors.indigo, 'icon': Icons.face_retouching_natural_rounded},
      {'type': ScaleType.gad7, 'title': 'GAD-7', 'sub': '讓身體放輕鬆', 'color': Colors.green.shade700, 'icon': Icons.self_improvement_rounded},
    ],
    AppCategory.pain: [
      {'type': ScaleType.vas, 'title': 'VAS', 'sub': '痛痛程度紀錄', 'color': Colors.redAccent, 'icon': Icons.healing_rounded},
    ],
    // 🚀 新增：風濕免疫
    AppCategory.rheumatology: [
      {'type': ScaleType.haq, 'title': 'HAQ', 'sub': '日常活動評估', 'color': Colors.brown, 'icon': Icons.accessibility_new_rounded},
      {'type': ScaleType.vas, 'title': 'VAS', 'sub': '關節疼痛追蹤', 'color': Colors.redAccent, 'icon': Icons.bolt_rounded},
    ],
    // 🚀 新增：腸胃科
    AppCategory.gastro: [
      {'type': ScaleType.bristol, 'title': 'Bristol', 'sub': '便便形態紀錄', 'color': Colors.brown.shade700, 'icon': Icons.water_drop_rounded},
      {'type': ScaleType.ibs_sss, 'title': 'IBS-SSS', 'sub': '腸胃嚴重度', 'color': Colors.teal, 'icon': Icons.monitor_heart_rounded},
    ],
    // 🚀 新增：女性健康
    AppCategory.womens: [
      {'type': ScaleType.cycle, 'title': '週期紀錄', 'sub': '生理期規律觀察', 'color': Colors.pinkAccent, 'icon': Icons.calendar_month_rounded},
    ],
    // 🚀 檢查 HomeScreen.dart 這裡的配置
    AppCategory.peds: [
      {
        'type': ScaleType.growth, // 👈 這裡千萬不能寫成 ScaleType.poem
        'title': '生長數據',
        'sub': '身高體重頭圍',
        'color': Colors.lightBlue,
        'icon': Icons.child_care_rounded
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _checkUserStatus(); // 補回：Debug 狀態檢查
    _loadSettings();
    _loadLocalPhoto();
    _refreshData();
    _loadBannerAd();
    _createInterstitialAd();
    _requestTrackingPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkBackupRequirement();
        if (pendingPayload != null) {
          handleNotificationJump(pendingPayload!);
          pendingPayload = null;
        }
        _showWelcomeMessage();
      }
    });

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.offset;
      if (offset > 10 && !_isScrolled)
        setState(() => _isScrolled = true);
      else if (offset <= 10 && _isScrolled) setState(() => _isScrolled = false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _bannerAd?.dispose();
    _interstitialAd?.dispose(); // 🚀 記得釋放插頁廣告
    super.dispose();
  }

  // --- 🔐 權限與身份檢查 ---
  void _checkUserStatus() {
    if (FirebaseAuth.instance.currentUser == null) debugPrint(
        "⚠️ 訪客模式：未登入");
  }


  Future<void> _requestTrackingPermission() async {
    if (!Platform.isIOS) return;
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 500));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  Future<void> _showWelcomeMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    final prefs = await SharedPreferences.getInstance();
    String welcomeKey = 'has_shown_welcome_${user.uid}';
    if (!(prefs.getBool(welcomeKey) ?? false)) {
      bool isGoogleUser = user.providerData.any((p) =>
      p.providerId == 'google.com');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(isGoogleUser ? Icons.g_mobiledata_rounded : Icons.apple_rounded,
              color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(child: Text("歡迎回來，${user.displayName ?? "使用者"}！",
              style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue.shade700,
        margin: EdgeInsets.only(bottom: MediaQuery
            .of(context)
            .size
            .height * 0.1, left: 20, right: 20),
      ));
      await prefs.setBool(welcomeKey, true);
    }
  }

  // --- 💰 廣告邏輯 (完整回饋版) ---
  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
          onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
          onAdFailedToLoad: (ad, err) {
            ad.dispose();
            Future.delayed(const Duration(seconds: 30), () {
              if (mounted) _loadBannerAd();
            });
          }
      ),
    )
      ..load();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('🚀 插頁廣告預載成功');
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (err) {
          _numInterstitialLoadAttempts++;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts <=
              maxFailedLoadAttempts) _createInterstitialAd();
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) return;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('廣告顯示中'),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // --- 📸 頭像管理 ---
  Future<void> _loadLocalPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    String? path = prefs.getString('user_custom_photo');
    if (path != null && File(path).existsSync()) setState(() =>
    _localPhotoPath = path);
  }

  Future<void> _handleChangePhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context, builder: (ctx) =>
        SafeArea(child: Wrap(children: [
          ListTile(leading: const Icon(Icons.photo_library),
              title: const Text('從相簿選擇'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ListTile(leading: const Icon(Icons.camera_alt),
              title: const Text('開啟相機'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        ])),
    );
    if (source == null) return;
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: '編輯大頭照',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            cropStyle: CropStyle.circle),
        IOSUiSettings(title: '編輯大頭照', aspectRatioLockEnabled: true),
      ],
    );
    if (croppedFile != null) {
      setState(() => _localPhotoPath = croppedFile.path);
      (await SharedPreferences.getInstance()).setString(
          'user_custom_photo', croppedFile.path);
    }
  }

  // --- ⚙️ 設定持久化 (補回關鍵修正) ---
  // 🚀 2. 修正：讀取最後一次使用的科別
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var type in ScaleType.values) {
        _enabledScales[type] = prefs.getBool('enable_${type.name}') ?? true;
        _reminderEnabled[type] = prefs.getBool('reminder_enabled_${type.name}') ?? true;
        _reminderDays[type] = prefs.getInt('reminder_day_${type.name}') ?? DateTime.sunday;
        final h = prefs.getInt('reminder_hour_${type.name}') ?? 20;
        final m = prefs.getInt('reminder_minute_${type.name}') ?? 0;
        _reminderTimes[type] = TimeOfDay(hour: h, minute: m);
      }
      _isBoy = prefs.getBool('child_is_boy') ?? true;
      final bStr = prefs.getString('child_birthday');
      if (bStr != null) _childBirthday = DateTime.parse(bStr);
      final dStr = prefs.getString('child_due_date'); // 補回預產期
      if (dStr != null) _childDueDate = DateTime.parse(dStr);

      // 關鍵：讀取記憶的科別
      final catIdx = prefs.getInt('last_category_index') ?? AppCategory.dermatology.index;
      _currentCategory = AppCategory.values[catIdx];
    });
    _scheduleClinicalReminders();
  }

  Future<void> _saveSettings() async {
    // 補回：存下管理模式的修改
    final prefs = await SharedPreferences.getInstance();
    for (var entry in _enabledScales.entries) {
      await prefs.setBool('enable_${entry.key.name}', entry.value);
    }
  }

  Future<void> _saveReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (var type in ScaleType.values) {
      await prefs.setBool(
          'reminder_enabled_${type.name}', _reminderEnabled[type] ?? true);
      await prefs.setInt(
          'reminder_day_${type.name}', _reminderDays[type] ?? DateTime.sunday);
      await prefs.setInt(
          'reminder_hour_${type.name}', _reminderTimes[type]?.hour ?? 20);
      await prefs.setInt(
          'reminder_minute_${type.name}', _reminderTimes[type]?.minute ?? 0);
    }
  }

  Future<void> _scheduleClinicalReminders() async {
    for (var type in ScaleType.values) {
      await NotificationService().cancel(type.index);
      if (_enabledScales[type] == true && _reminderEnabled[type] == true) {
        final t = _reminderTimes[type]!;
        if (type == ScaleType.uas7) {
          await NotificationService().scheduleDailyReminder(id: type.index,
              title: 'UAS7 追蹤提醒',
              body: '請記錄今天的狀況。',
              hour: t.hour,
              minute: t.minute,
              payload: type.name);
        } else {
          await NotificationService().scheduleWeeklyReminder(id: type.index,
              title: '${type.name.toUpperCase()} 追蹤提醒',
              body: '今天是紀錄日。',
              dayOfWeek: _reminderDays[type]!,
              hour: t.hour,
              minute: t.minute,
              payload: type.name);
        }
      }
    }
  }

  // --- ☁️ 數據備份與還原系統 (完整回歸) ---
  void _refreshData() {
    setState(() {
      _trackerDataFuture = _getTrackerData(); // 🚀 這樣才能確保 Future 只在資料變動時觸發
    });
  }

  Future<Map<String, dynamic>> _getTrackerData() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 8));
    final all = await isarService.getAllRecords();

    // 建立基礎 Map
    Map<String, dynamic> data = {
      'uas7Start': start,
      'uas7Status': List.generate(14, (i) => all.any((r) =>
      r.scaleType == ScaleType.uas7 &&
          DateUtils.isSameDay(r.targetDate ?? r.date, start.add(Duration(days: i))))),
      'uas7Records': all.where((r) => r.scaleType == ScaleType.uas7).toList(),
    };

    // 🚀 關鍵修正：自動抓取 ScaleType 清單中的所有數據
    for (var type in ScaleType.values) {
      data[type.name] = all.where((r) => r.scaleType == type).toList()
        ..sort((a, b) => (b.targetDate ?? b.date ?? DateTime.now())
            .compareTo(a.targetDate ?? a.date ?? DateTime.now()));
    }

    return data;
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    int total = 0;
    if (!await dir.exists()) return 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1048576) return "${(bytes / 1048576).toStringAsFixed(1)} MB";
    if (bytes >= 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "$bytes B";
  }

  Future<void> _handleManualBackup() async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently() ??
        await _googleSignIn.signIn();
    if (account == null) return;
    if (_isSyncing) return;

    final docDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docDir.path, 'eczema_data.isar'));
    final photoDir = Directory(p.join(docDir.path, 'photos'));
    final totalSize = (await dbFile.exists() ? await dbFile.length() : 0) +
        await _calculateDirectorySize(photoDir);

    final bool confirmed = await showDialog<bool>(
        context: context, builder: (ctx) =>
        AlertDialog(
          title: const Text("雲端備份說明"),
          content: Text(
              "將加密備份紀錄至 Google Drive。\n\n📦 預估大小：${_formatBytes(
                  totalSize)}\n\n確定開始？"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text("取消")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text("開始備份")),
          ],
        )
    ) ?? false;

    if (!confirmed) return;
    setState(() => _isSyncing = true);
    try {
      final prog = ValueNotifier<String>("準備中...");
      final per = ValueNotifier<double>(0.0);
      await BackupDialogs.showProcessingDialog(context: context,
          title: "同步至雲端",
          progressNotifier: prog,
          percentNotifier: per,
          action: () async {
            await cloudBackupService.runBackup(
                photoDir.path, appVersion: _appVersion, onProgress: (p) {
              prog.value = p.message;
              per.value = p.progress;
            });
            (await SharedPreferences.getInstance()).setString(
                'last_backup_time', DateTime.now().toIso8601String());
          });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ 備份完成")));
    } catch (e) {
      if (mounted && e is BackupException) BackupErrorDialog.show(context, e);
    }
    finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleRestore() async {
    final bool confirmed = await BackupDialogs.confirmRestore(context);
    if (!confirmed) return;
    setState(() => _isSyncing = true);
    try {
      final prog = ValueNotifier<String>("正在聯繫雲端...");
      final per = ValueNotifier<double>(0.0);
      await BackupDialogs.showProcessingDialog(context: context,
          title: "還原數據中",
          progressNotifier: prog,
          percentNotifier: per,
          action: () async {
            await cloudBackupService.runRestore(p.join(
                (await getApplicationDocumentsDirectory()).path, 'photos'),
                onProgress: (p) {
                  prog.value = p.message;
                  per.value = p.progress;
                });
            if (mounted) _refreshData();
          });
    } catch (e) {
      if (mounted && e is BackupException) BackupErrorDialog.show(context, e);
    }
    finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _checkBackupRequirement() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString('last_backup_time');
    final lastHint = prefs.getString('last_hint_show_time');
    final recentCount = await isarService.getRecordsCountInLastDays(28);
    DateTime now = DateTime.now();

    if (recentCount > 0 && (lastBackup == null || now
        .difference(DateTime.parse(lastBackup))
        .inDays >= 28)) {
      if (lastHint == null || now
          .difference(DateTime.parse(lastHint))
          .inDays >= 28) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("您已有四週的紀錄未備份。"),
            action: SnackBarAction(
                label: "立即備份", onPressed: () => _handleManualBackup())));
        await prefs.setString('last_hint_show_time', now.toIso8601String());
      }
    }
  }

  Future<void> _checkAndSilentBackup() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('last_silent_backup');
    if (lastSync != null && DateTime
        .now()
        .difference(DateTime.parse(lastSync))
        .inDays < 28) return;
    try {
      await cloudBackupService.runBackup(
          p.join((await getApplicationDocumentsDirectory()).path, 'photos'),
          appVersion: _appVersion);
      await prefs.setString(
          'last_silent_backup', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint("靜默備份失敗");
    }
  }

  // --- 🖥 UI 組件 (模組化拆分) ---

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;
    ImageProvider? avatar;
    if (_localPhotoPath != null)
      avatar = FileImage(File(_localPhotoPath!));
    else if (user?.photoURL != null) avatar = NetworkImage(user!.photoURL!);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle
          .dark).copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          elevation: _isScrolled ? 3 : 0,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildAvatarMenu(user, avatar, isDarkMode),
                const SizedBox(width: 16),
                _buildTitleSelector(user, isDarkMode),
                _buildSettingsButton(isDarkMode),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _refreshData(); // 🚀 重新抓取資料庫數據
                    await Future.delayed(const Duration(milliseconds: 600)); // 給點緩衝時間
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(), // 🚀 關鍵：確保內容少也能拉
                    child: Column(
                      children: [
                    const SizedBox(height: 16),
                    _buildScaleGrid(context),
                    const SizedBox(height: 4),
                    _buildSecondaryNavigation(context),
                    //if (_currentCategory == AppCategory.dermatology) ...[
                    const SizedBox(height: 8),
                    _buildSwiperHeader(),
                    _buildProgressSwiper(),
                    // ],
                    const SizedBox(height: 40),
                      ],
                    ), // 1. 關閉 Column
                  ), // 2. 關閉 SingleChildScrollView
                ), // 3. 關閉 RefreshIndicator
            ), // 4. 關鍵修正：補上這個關閉 Expanded 的括號
            if (_isAdLoaded && _bannerAd != null) _buildAdBanner(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarMenu(User? user, ImageProvider? avatar, bool isDark) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2))
          ]
      ),
      child: PopupMenuButton<String>(
        onSelected: (val) {
          if (val == 'photo')
            _handleChangePhoto();
          else if (val == 'sync')
            _handleManualBackup();
          else if (val == 'restore')
            _handleRestore();
          else if (val == 'logout') _handleLogout(context);
        },
        child: CircleAvatar(
          radius: 26,
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
          backgroundImage: avatar,
          // 🚀 預設圖示也換成圓潤的臉孔
          child: avatar == null
              ? (user?.displayName != null
              ? Text(user!.displayName!.substring(0, 1).toUpperCase())
              : const Icon(Icons.face_rounded, color: Colors.blueGrey))
              : null,
        ),
        itemBuilder: (ctx) =>
        [
          // 🚀 從「更換頭像」改為「換個頭像」，感覺更隨性
          const PopupMenuItem(value: 'photo', child: Row(children: [
            Icon(Icons.face_retouching_natural_rounded, color: Colors.blue),
            SizedBox(width: 12),
            Text("更換頭像")
          ])),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'sync', child: Row(children: [
            _isSyncing
                ? const SizedBox(width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_done_rounded, color: Colors.green),
            // 🚀 使用完成感圖標
            const SizedBox(width: 12),
            const Text("把資料存進雲端")
            // 🚀 生活化的語氣
          ])),
          const PopupMenuItem(value: 'restore', child: Row(children: [
            Icon(Icons.settings_backup_restore_rounded, color: Colors.orange),
            // 🚀 更有「找回」的感覺
            const SizedBox(width: 12),
            Text("找回雲端資料")
          ])),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'logout', child: Row(children: [
            Icon(Icons.meeting_room_rounded, color: Colors.redAccent),
            // 🚀 改用這個，這在所有版本都有
            SizedBox(width: 12),
            Text("登出帳號")
          ])),
        ],
      ),
    );
  }

  // 🚀 3. 修正：記憶切換的科別
  Widget _buildTitleSelector(User? user, bool isDark) {
    // 🚀 關鍵修正：在這裡補上缺失的分類，並按照你想要的順序排列
    final Map<AppCategory, String> catNames = {
      AppCategory.dermatology: "肌膚照護",
      AppCategory.sleep: "睡眠健康",      // 👈 補上這行
      AppCategory.chronic: "慢性病管理",  // 👈 補上這行
      AppCategory.psychiatry: "情緒照護",
      AppCategory.pain: "疼痛管理",
      AppCategory.rheumatology: "風濕免疫",
      AppCategory.gastro: "腸胃紀錄",
      AppCategory.womens: "女性健康",
      AppCategory.peds: "兒科發展",
    };

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: PopupMenuButton<AppCategory>(
          onSelected: (cat) async {
            setState(() {
              _currentCategory = cat;
              _pageController.jumpToPage(_virtualInitialPage);
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('last_category_index', cat.index);
            HapticFeedback.mediumImpact();
          },
          // 這裡會自動根據上面的 catNames 生成選單項目
          itemBuilder: (ctx) => catNames.entries
              .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                    catNames[_currentCategory] ?? "健康追蹤",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: isDark ? Colors.white : Colors.blueGrey.shade900
                    )
                ),
                Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey),
              ]),
              if (user?.email != null)
                Text(user!.email!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: IconButton(
        icon: Icon(_isManagementMode ? Icons.check_circle : Icons
            .settings_suggest_rounded,
            color: _isManagementMode ? Colors.green : (isDark
                ? Colors.white
                : Colors.blueGrey.shade700)),
        onPressed: () {
          setState(() => _isManagementMode = !_isManagementMode);
          if (!_isManagementMode) _saveSettings(); // 🚀 補回：退出時存下修改
        },
      ),
    );
  }

  Widget _buildScaleGrid(BuildContext context) {
    final List<Map<String, dynamic>> scales = _categoryConfigs[_currentCategory]!;

    // 🚀 計算總數：如果是兒科手動加 1（為了插入寶寶資料按鈕）
    int totalCount = scales.length;
    if (_currentCategory == AppCategory.peds) totalCount += 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1
        ),
        itemCount: totalCount,
        itemBuilder: (ctx, i) {
          // 🚀 1. 兒科特殊處理：固定在第二個位置 (Index 1) 插入「寶寶資料」按鈕
          if (_currentCategory == AppCategory.peds && i == 1) {
            return _buildChildProfileButton();
          }

          // 🚀 2. 計算正確的資料索引 (兒科 Index 1 被佔走，後面的要往回扣)
          int configIndex = (_currentCategory == AppCategory.peds && i > 1) ? i - 1 : i;
          if (configIndex >= scales.length) return const SizedBox.shrink();

          final config = scales[configIndex];
          final dynamic targetType = config['type']; // 確保抓到的是上面配置的 type

          // 🚀 3. 判斷是否啟用 (只有 ScaleType 才需要檢查開關)
          bool isEnabled = (targetType is ScaleType)
              ? (_enabledScales[targetType] ?? true)
              : true;

          return _AnimatedScaleCard(
            scale: config,
            isEnabled: isEnabled,
            isManagementMode: _isManagementMode,
            onTap: () async {
              // 管理員模式：切換顯示/隱藏
              if (_isManagementMode && targetType is ScaleType) {
                setState(() => _enabledScales[targetType] = !(_enabledScales[targetType] ?? true));
                return;
              }

              // 停用提示
              if (!isEnabled) {
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                        title: Text("${config['title']} 已關閉"),
                        content: const Text("目前無需執行此量表。")
                    )
                );
                return;
              }

              // 🚀 4. 進入問卷邏輯
              if (targetType is ScaleType) {
                debugPrint("🚀 準備進入問卷，傳入類型：$targetType"); // 加上這行 Debug
                // 💡 這裡最關鍵：確保傳入的是 targetType，這樣存檔才不會變成 ScaleType.poem
                final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      // 🚀 關鍵修正 2：這裡一定要傳 targetType
                        builder: (ctx) => PoemSurveyScreen(initialType: targetType)
                    )
                );

                if (res == true && mounted) {
                  _showInterstitialAd();
                  _refreshData();
                  _checkAndSilentBackup();

                  // 皮膚科特殊邏輯：自動跳轉到對應的圖表卡片
                  if (_currentCategory == AppCategory.dermatology) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) _jumpToScalePage(targetType);
                    });
                  }
                }
              } else {
                // 如果 type 不是 ScaleType (例如是自訂 Function)，可以在這裡處理
                if (config['onTap'] != null) config['onTap']();
              }
            },
            category: _currentCategory,
          );
        },
      ),
    );
  }

  // 🚀 新增一個輔助方法計算年齡
  String _getChildAgeStr() {
    if (_childBirthday == null) return "點擊設定資料";
    final now = DateTime.now();
    final diff = now.difference(_childBirthday!);
    final totalMonths = (diff.inDays / 30.4375).floor(); // 🚀 使用更精確的平均月天數

    if (totalMonths < 1) return "${diff.inDays} 天大";
    if (totalMonths < 24) return "$totalMonths 個月大";

    // 🚀 超過兩歲顯示：X 歲 Y 個月
    int years = totalMonths ~/ 12;
    int remainingMonths = totalMonths % 12;
    return remainingMonths == 0 ? "$years 歲" : "$years 歲 $remainingMonths 個月";
  }

  // 🚀 4. 修正：寶寶資料按鈕改用月齡顯示
  Widget _buildChildProfileButton() {
    final bool isSet = _childBirthday != null;
    return _AnimatedScaleCard(
      category: _currentCategory,
      isEnabled: true,
      isManagementMode: false,
      scale: {
        'title': '寶寶資料',
        'sub': isSet ? '${_isBoy ? "男寶" : "女寶"} · ${_getChildAgeStr()}' : '點擊設定資料',
        'color': Colors.orangeAccent,
        'icon': Icons.settings_accessibility_rounded,
      },
      onTap: _showChildProfileEditor,
    );
  }

  // 🚀 彈出的編輯器畫面 (含預產期)
  void _showChildProfileEditor() {
    bool tempIsBoy = _isBoy;
    DateTime tempBirthday = _childBirthday ?? DateTime.now();
    DateTime tempDueDate = _childDueDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("寶寶基本資料設定", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // 1. 性別切換
                ListTile(
                  leading: Icon(tempIsBoy ? Icons.boy_rounded : Icons.girl_rounded, color: tempIsBoy ? Colors.blue : Colors.pink),
                  title: const Text("寶寶性別"),
                  trailing: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text("男"), icon: Icon(Icons.male)),
                      ButtonSegment(value: false, label: Text("女"), icon: Icon(Icons.female)),
                    ],
                    selected: {tempIsBoy},
                    onSelectionChanged: (v) => setModalState(() => tempIsBoy = v.first),
                  ),
                ),
                const Divider(),

                // 2. 出生日期
                ListTile(
                  leading: const Icon(Icons.cake_rounded, color: Colors.orange),
                  title: const Text("出生日期"),
                  subtitle: Text(DateFormat('yyyy / MM / dd').format(tempBirthday)),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: tempBirthday, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (picked != null) setModalState(() => tempBirthday = picked);
                  },
                ),

                // 3. 預產期
                ListTile(
                  leading: const Icon(Icons.child_friendly_rounded, color: Colors.teal),
                  title: const Text("預產期"),
                  subtitle: Text(DateFormat('yyyy / MM / dd').format(tempDueDate)),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: tempDueDate, firstDate: DateTime(2020), lastDate: DateTime(2027));
                    if (picked != null) setModalState(() => tempDueDate = picked);
                  },
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('child_is_boy', tempIsBoy);
                      await prefs.setString('child_birthday', tempBirthday.toIso8601String());
                      await prefs.setString('child_due_date', tempDueDate.toIso8601String());

                      setState(() {
                        _isBoy = tempIsBoy;
                        _childBirthday = tempBirthday;
                        _childDueDate = tempDueDate;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text("確認儲存", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildSecondaryNavigation(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 8),
      child: Row(
        children: [
          _buildThemeButton( // 🚀 使用助手方法
            context,
            label: "趨勢變化",
            icon: Icons.auto_graph_rounded,
            color: Colors.teal,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrendChartScreen(currentCategory: _currentCategory)));
            },
          ),
          const SizedBox(width: 12),
          _buildThemeButton(
            context,
            label: "全部回顧",
            icon: Icons.history_edu_rounded,
            color: Colors.blueGrey,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => HistoryListScreen(currentCategory: _currentCategory)));
            },
          ),
        ],
      ),
    );
  }

  // 🚀 核心助手：建立「有按鈕感」且「適應主題」的按鈕
  Widget _buildThemeButton(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          // 🚀 自動使用主題卡片色 (淺色模式=白/淺灰, 深色模式=深灰)
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              // 🚀 加上一層極細微的邊框，增加質感
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: isDark ? color.withOpacity(0.8) : color, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : color.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwiperHeader() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(children: [
          const Icon(Icons.auto_awesome, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          const Expanded(child: Text(
              "我的健康筆記", style: TextStyle(fontWeight: FontWeight.bold))),
          InkWell(onTap: _showReminderSettingsModal,
              child: const Text("設定提醒", style: TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.bold))),
        ]));
  }

  Widget _buildProgressSwiper() {
    // 🚀 修改點：只過濾出「屬於當前科別」且「已啟用」的量表類型
    final enabledTypes = ScaleType.values.where((t) =>
    _isScaleInCategory(t, _currentCategory) && // 🚀 加入科別過濾
        _enabledScales[t] == true
    ).toList();

    if (enabledTypes.isEmpty) return const SizedBox.shrink();

    return SizedBox(
        height: 295,
        child: FutureBuilder<Map<String, dynamic>>(
            future: _trackerDataFuture ?? _getTrackerData(),
            builder: (ctx, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              // 這裡會循環顯示該科別下的量表 (例如：PHQ-9 -> GAD-7 -> PHQ-9)
              return PageView.builder(
                  controller: _pageController,
                  itemCount: _virtualTotalCount,
                  itemBuilder: (ctx, i) =>
                      _buildCardByType(
                          enabledTypes[i % enabledTypes.length], snapshot.data!)
              );
            }
        )
    );
  }


  // 🚀 請確保這是你程式碼中唯一的 _isScaleInCategory 方法
  bool _isScaleInCategory(ScaleType type, AppCategory category) {
    switch (category) {
      case AppCategory.dermatology:
        return [ScaleType.adct, ScaleType.poem, ScaleType.uas7, ScaleType.scorad].contains(type);
      // 🚀 補上睡眠健康
      case AppCategory.sleep:
        return [ScaleType.psqi, ScaleType.isi, ScaleType.ess].contains(type);
       // 🚀 補上慢性病管理
      case AppCategory.chronic:
        return [ScaleType.bp_log, ScaleType.cat, ScaleType.dds, ScaleType.bpi].contains(type);
      case AppCategory.psychiatry:
        return [ScaleType.phq9, ScaleType.gad7].contains(type);
      case AppCategory.pain:
        return type == ScaleType.vas;
      case AppCategory.rheumatology:
        return [ScaleType.haq, ScaleType.vas].contains(type);
      case AppCategory.gastro:
        return [ScaleType.bristol, ScaleType.ibs_sss].contains(type);
      case AppCategory.womens:
        return type == ScaleType.cycle;
      case AppCategory.peds:
        return type == ScaleType.growth;
      default:
        return false;
    }
  }

  Widget _buildCardByType(ScaleType type, Map<String, dynamic> data) {
    final history = data[type.name] as List<PoemRecord>? ?? [];

    switch (type) {
    // 1. 蕁麻疹專用卡片 (保持不變)
      case ScaleType.uas7:
        return Uas7TrackerCard(
            startDate: data['uas7Start'],
            completionStatus: data['uas7Status'],
            history: data['uas7Records'],
            onRefresh: _refreshData
        );

    // 2. 兒科：生長數據 (cm/kg 動態切換)
      case ScaleType.growth:
        String unit = "cm";
        if (history.isNotEmpty) {
          final last = history.first;
          // 🚀 權重：通常體重變化頻率高，有體重就先秀體重趨勢
          if (last.weight != null) unit = "kg";
          else if (last.height != null) unit = "cm";
          else if (last.headCircumference != null) unit = "cm";
        }
        return WeeklyTrackerCard(
            type: type,
            history: history,
            unit: unit,
            onRefresh: _refreshData
        );

    // 3. 慢性病：血壓紀錄 (mmHg)
      case ScaleType.bp_log:
        return WeeklyTrackerCard(
            type: type,
            history: history,
            unit: "mmHg", // 🚀 血壓專用標籤
            onRefresh: _refreshData
        );

    // 4. 腸胃科：布里斯托便便分類 (型)
      case ScaleType.bristol:
        return WeeklyTrackerCard(
            type: type,
            history: history,
            unit: "型", // 🚀 第一型～第七型
            onRefresh: _refreshData
        );

    // 5. 所有的「評分型」量表 (統一使用「分」)
    // 🚀 這裡包含你新增的：睡眠(PSQI/ISI)、慢性病(CAT/DDS)、疼痛(BPI/VAS)
      case ScaleType.adct:
      case ScaleType.poem:
      case ScaleType.scorad:
      case ScaleType.phq9:
      case ScaleType.gad7:
      case ScaleType.psqi: // 睡眠品質
      case ScaleType.isi:  // 失眠程度
      case ScaleType.ess:  // 嗜睡量表
      case ScaleType.cat:  // 呼吸道
      case ScaleType.dds:  // 糖尿病壓力
      case ScaleType.bpi:  // 簡明疼痛
      case ScaleType.vas:  // 疼痛強度
      case ScaleType.haq:  // 功能評估
        return WeeklyTrackerCard(
            type: type,
            history: history,
            unit: "分",
            onRefresh: _refreshData
        );

    // 6. 其他與預設
      default:
        return WeeklyTrackerCard(
            type: type,
            history: history,
            unit: "分", // 醫學量表標準單位
            onRefresh: _refreshData
        );
    }
  }

  Widget _buildAdBanner(BuildContext context) {
    return Container(
      color: Theme
          .of(context)
          .scaffoldBackgroundColor,
      padding: EdgeInsets.only(top: 8, bottom: MediaQuery
          .of(context)
          .padding
          .bottom + 8),
      width: double.infinity,
      alignment: Alignment.center,
      child: SizedBox(width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!)),
    );
  }

  // --- 其餘輔助邏輯 ---
  void _jumpToScalePage(ScaleType type) {
    if (!_pageController.hasClients) return;
    // 🚀 核心修正：跳轉時也要根據「當前科別」來計算索引
    final enabled = ScaleType.values.where((t) =>
    _isScaleInCategory(t, _currentCategory) && // 門神：只算這科的
        _enabledScales[t] == true
    ).toList();

    int target = enabled.indexOf(type);
    if (target != -1) {
      int current = _pageController.page!.round();
      // 計算循環 PageView 中的正確目標頁面
      _pageController.animateToPage(
          current + (target - (current % enabled.length)),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(context: context,
        builder: (ctx) =>
            AlertDialog(title: const Text("確定登出？"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("取消")),
                  TextButton(onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                          "登出", style: TextStyle(color: Colors.red)))
                ]));
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      if (context.mounted) Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const LoginScreen()), (
          r) => false);
    }
  }

  void _showReminderSettingsModal() {
    const Map<int, String> weekdays = {
      1: '週一',
      2: '週二',
      3: '週三',
      4: '週四',
      5: '週五',
      6: '週六',
      7: '週日'
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // 🚀 允許調整高度
      backgroundColor: Theme
          .of(context)
          .scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          // 1. 只過濾出目前科別的量表
          final activeTypes = ScaleType.values.where((t) =>
          _isScaleInCategory(t, _currentCategory) &&
              (_enabledScales[t] ?? true)
          ).toList();

          return Container(
            // 🚀 限制最大高度為螢幕的 80%，避免蓋過頂部
            constraints: BoxConstraints(maxHeight: MediaQuery
                .of(ctx)
                .size
                .height * 0.8),
            padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery
                .of(ctx)
                .viewInsets
                .bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 🚀 內容少時縮小，內容多時捲動
              children: [
                const Text("⏰ 貼心提醒時間", style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                if (activeTypes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text("目前此分類尚未開啟提醒項目",
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                // 🚀 2. 使用 Flexible + SingleChildScrollView 解決 Overflow
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: activeTypes.map((type) {
                          // 🚀 3. 使用你在 ScaleConfig 定義的親民標題
                          final friendlyTitle = ScaleConfig.allScales[type]
                              ?.title ?? "量表紀錄";

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade300)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Expanded(
                                          child: Text(
                                              "$friendlyTitle (${type ==
                                                  ScaleType.uas7
                                                  ? '每日'
                                                  : '每週'})",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)
                                          )
                                      ),
                                      Switch(
                                          value: _reminderEnabled[type] ?? true,
                                          onChanged: (val) {
                                            setModalState(() =>
                                            _reminderEnabled[type] = val);
                                            setState(() =>
                                            _reminderEnabled[type] = val);
                                          }
                                      )
                                    ],
                                  ),
                                  if (_reminderEnabled[type] == true)
                                    Row(
                                      children: [
                                        if (type != ScaleType.uas7) ...[
                                          Container(
                                              padding: const EdgeInsets
                                                  .symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.1),
                                                  borderRadius: BorderRadius
                                                      .circular(8)),
                                              child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<int>(
                                                      value: _reminderDays[type],
                                                      items: weekdays.entries
                                                          .map((e) =>
                                                          DropdownMenuItem(
                                                              value: e.key,
                                                              child: Text(
                                                                  e.value)))
                                                          .toList(),
                                                      onChanged: (val) {
                                                        if (val != null) {
                                                          setModalState(() =>
                                                          _reminderDays[type] =
                                                              val);
                                                          setState(() =>
                                                          _reminderDays[type] =
                                                              val);
                                                        }
                                                      }
                                                  )
                                              )
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Expanded(
                                            child: ElevatedButton.icon(
                                                icon: const Icon(
                                                    Icons.access_time_rounded),
                                                label: Text(
                                                    _reminderTimes[type]!
                                                        .format(context)),
                                                style: ElevatedButton.styleFrom(
                                                    elevation: 0,
                                                    backgroundColor: Colors.blue
                                                        .withOpacity(0.1),
                                                    foregroundColor: Colors.blue
                                                        .shade700,
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius
                                                            .circular(8))
                                                ),
                                                onPressed: () async {
                                                  final time = await showTimePicker(
                                                      context: context,
                                                      initialTime: _reminderTimes[type]!);
                                                  if (time != null) {
                                                    setModalState(() =>
                                                    _reminderTimes[type] =
                                                        time);
                                                    setState(() =>
                                                    _reminderTimes[type] =
                                                        time);
                                                  }
                                                }
                                            )
                                        )
                                      ],
                                    )
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                // 🚀 儲存按鈕
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(16)),
                        elevation: 0
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _saveReminderSettings();
                      await _scheduleClinicalReminders();
                    },
                    child: const Text("設定好了",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight
                            .bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

// 🚀 親民跑馬燈：如果文字沒超過長度就不會動，超過了才慢慢跑
Widget _buildMarquee(String text, TextStyle style) {
  return SizedBox(
    height: style.fontSize! * 1.5, // 根據字體高度自動調整高度
    child: Marquee(
      text: text,
      style: style,
      scrollAxis: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      blankSpace: 30.0,      // 文字循環間距
      velocity: 30.0,        // 跑動速度
      pauseAfterRound: const Duration(seconds: 2), // 跑完一圈停 2 秒
      startPadding: 0.0,
      accelerationDuration: const Duration(seconds: 1),
      accelerationCurve: Curves.linear,
      decelerationDuration: const Duration(milliseconds: 500),
      decelerationCurve: Curves.easeOut,
    ),
  );
}

class _AnimatedScaleCard extends StatelessWidget {
  final Map<String, dynamic> scale;
  final bool isEnabled;
  final bool isManagementMode;
  final VoidCallback onTap;
  final AppCategory category; // 🚀 1. 增加這行

  const _AnimatedScaleCard({
    required this.scale,
    required this.isEnabled,
    required this.isManagementMode,
    required this.onTap,
    required this.category, // 🚀 2. 增加這行
  });

  @override
  Widget build(BuildContext context) {
    final color = scale['color'] as Color;

    // 🚀 先定義好子標題的樣式，方便跑馬燈使用
    final subTextStyle = TextStyle(
      fontSize: 14,
      color: isEnabled ? color.withOpacity(0.8) : Colors.grey,
      fontWeight: FontWeight.bold,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: isEnabled ? Theme.of(context).cardColor : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.4) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12), // 🚀 左右留點白，跑馬燈才不會貼邊
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(scale['icon'], size: 40, color: isEnabled ? color : Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      scale['title'],
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isEnabled ? color : Colors.grey,
                      ),
                    ),

                    // 🚀 關鍵修改點：使用跑馬燈顯示子標題
                    SizedBox(
                      height: 30,
                      child: Marquee(
                        // 🚀 使用 UniqueKey 或包含類別名稱的 Key，確保切換科別時會重整
                        key: ValueKey("${scale['sub']}_${category.name}"),
                        text: scale['sub'],
                        style: subTextStyle,
                        scrollAxis: Axis.horizontal,
                        blankSpace: 80.0,
                        velocity: 35.0,
                        // 🚀 跑完一圈停 5 秒，使用者才能看清楚「身高/體重」數據
                        pauseAfterRound: const Duration(seconds: 5),
                        accelerationDuration: const Duration(seconds: 1),
                        accelerationCurve: Curves.linear,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isManagementMode && scale['type'] is ScaleType)
              Positioned(
                top: 10,
                right: 10,
                child: Icon(
                  isEnabled ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                  color: isEnabled ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}