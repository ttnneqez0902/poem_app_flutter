import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
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
  // ✅ 放在這裡（正確位置）
  Timer? _suggestTimer;
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
  Map<AppCategory, DateTime?> _lastCompletionTimes = {};

// 🚀 根據量表類型找出它所屬的科別
  AppCategory _getCategoryFromScale(ScaleType type) {
    for (var category in AppCategory.values) {
      if (_isScaleInCategory(type, category)) return category;
    }
    return AppCategory.dermatology; // 找不到時的預設值
  }

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

  String _formatClinicalDate(DateTime? dateTime) {
    if (dateTime == null) return "";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final int diffDays = today.difference(recordDate).inDays;

    const weekDays = ["", "週一", "週二", "週三", "週四", "週五", "週六", "週日"];

    if (diffDays == 0) return " (今天)";
    if (diffDays == 1) return " (昨天)";
    if (diffDays == 2) return " (前天)";

    // 3 ~ 6 天內：顯示「週幾」
    if (diffDays < 7) {
      return " (${weekDays[recordDate.weekday]})";
    }

    // 7 ~ 13 天內：顯示「上週幾」
    if (diffDays < 14) {
      return " (上${weekDays[recordDate.weekday]})";
    }

    // 更久以前：標日期 MM/dd
    return " (${DateFormat('MM/dd').format(dateTime)})";
  }

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
    AppCategory.neurology: [
      {
        'type': ScaleType.qolie10,
        'title': 'QOLIE-10',
        'sub': '生活品質影響',
        'color': Colors.deepPurple,
        'icon': Icons.psychology_alt_rounded,
      },

      {
        'type': ScaleType.lsss,
        'title': 'LSSS',
        'sub': '發作嚴重度追蹤',
        'color': Colors.redAccent,
        'icon': Icons.bolt_rounded,
      },
    ]
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
    _suggestTimer?.cancel(); // 🚀 防 memory leak
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
        _enabledScales[type] =
            prefs.getBool('enable_${type.name}') ?? true;

        // ✅ 預設關閉提醒（正確）
        _reminderEnabled[type] =
            prefs.getBool('reminder_enabled_${type.name}') ?? false;

        _reminderDays[type] =
            prefs.getInt('reminder_day_${type.name}') ?? DateTime.sunday;

        final h = prefs.getInt('reminder_hour_${type.name}') ?? 20;
        final m = prefs.getInt('reminder_minute_${type.name}') ?? 0;
        _reminderTimes[type] = TimeOfDay(hour: h, minute: m);
      }

      // 各科別最後時間
      for (var cat in AppCategory.values) {
        final timeStr = prefs.getString('last_time_${cat.name}');
        if (timeStr != null) {
          _lastCompletionTimes[cat] = DateTime.parse(timeStr);
        }
      }

      _isBoy = prefs.getBool('child_is_boy') ?? true;

      final bStr = prefs.getString('child_birthday');
      if (bStr != null) _childBirthday = DateTime.parse(bStr);

      final dStr = prefs.getString('child_due_date');
      if (dStr != null) _childDueDate = DateTime.parse(dStr);

      final catIdx =
          prefs.getInt('last_category_index') ?? AppCategory.dermatology.index;

      _currentCategory = AppCategory.values[catIdx];
    });

    // 🚀 優化：只有有開提醒才排程
    if (_reminderEnabled.values.any((e) => e == true)) {
      _scheduleClinicalReminders();
    }
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

    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 8));

    final all = await isarService.getAllRecords();

    Map<String, dynamic> data = {};

    // 🚀 每個 ScaleType 自動建立 tracker data
    for (var type in ScaleType.values) {

      final records = all.where(
            (r) => r.scaleType == type,
      ).toList()
        ..sort(
              (a, b) =>
              (b.targetDate ?? b.date ?? DateTime.now())
                  .compareTo(
                a.targetDate ?? a.date ?? DateTime.now(),
              ),
        );

      data[type.name] = records;

      // 🚀 通用 start
      data['${type.name}Start'] = start;

      // 🚀 通用 completion status
      data['${type.name}Status'] = List.generate(
        14,
            (i) => records.any(
              (r) => DateUtils.isSameDay(
            r.targetDate ?? r.date,
            start.add(Duration(days: i)),
          ),
        ),
      );
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

    if (_isSyncing) return;

    // 🚀 iOS 不需要 Google 登入
    if (!Platform.isIOS) {

      final GoogleSignInAccount? account =
          await _googleSignIn.signInSilently() ??
              await _googleSignIn.signIn();

      if (account == null) return;
    }

    final docDir = await getApplicationDocumentsDirectory();

    final isarDir = Directory(
      p.join(docDir.path, 'isar'),
    );

    final photoDir = Directory(
      p.join(docDir.path, 'photos'),
    );

    final int isarSize =
    await _calculateDirectorySize(isarDir);

    final int photoSize =
    await _calculateDirectorySize(photoDir);

    final int totalSize =
        isarSize + photoSize;

    final String sizeText =
    totalSize == 0
        ? "小於 1 KB"
        : _formatBytes(totalSize);

    final providerText =
    Platform.isIOS
        ? "iCloud"
        : "Google Drive";

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("雲端備份說明"),
            content: Text(
              "將加密備份紀錄至 $providerText。\n\n"
                  "📦 預估大小：$sizeText\n\n"
                  "確定開始？",
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, false),
                child: const Text("取消"),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(ctx, true),
                child: const Text("開始備份"),
              ),
            ],
          ),
        ) ??
            false;

    if (!confirmed) return;

    setState(() => _isSyncing = true);

    try {

      final prog = ValueNotifier<String>("準備中...");
      final per = ValueNotifier<double>(0.0);

      await BackupDialogs.showProcessingDialog(
        context: context,
        title: "同步至雲端",
        progressNotifier: prog,
        percentNotifier: per,
        action: () async {

          await cloudBackupService.runBackup(
            photoDir.path,
            appVersion: _appVersion,
            onProgress: (p) {
              prog.value = p.message;
              per.value = p.progress;
            },
          );

          (await SharedPreferences.getInstance())
              .setString(
            'last_backup_time',
            DateTime.now().toIso8601String(),
          );
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ 備份完成"),
          ),
        );
      }

    } catch (e) {

      if (mounted && e is BackupException) {

        await BackupErrorDialog.show(
          context,
          e,
          onRetry: () async {

            if (mounted) {
              setState(() => _isSyncing = false);
            }

            await _handleManualBackup();
          },
        );
      }

    } finally {

      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    final meta = await cloudBackupService.getBackupPreview();

    bool confirmed = false;

    if (meta != null) {

      confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {

          return AlertDialog(

            title: const Text("☁️ 最近備份"),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  "時間：${DateFormat('yyyy/MM/dd HH:mm').format(meta.createdAt)}",
                ),

                const SizedBox(height: 10),

                Text(
                  "紀錄數：${meta.recordCount} 筆",
                ),

                Text(
                  "大小：${meta.readableBackupSize}",
                ),

                Text(
                  "版本：${meta.appVersion}",
                ),
              ],
            ),

            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(ctx, false);
                },
                child: const Text("取消"),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx, true);
                },
                child: const Text("開始還原"),
              ),
            ],
          );
        },
      ) ?? false;

    } else {

      confirmed =
      await BackupDialogs.confirmRestore(
        context,
      );
    }
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
            // 🚀 restore 後強制刷新
            _refreshData();

            if (mounted) {

              setState(() {

                _trackerDataFuture = _getTrackerData();

              });

              // 🚀 重置 swiper
              if (_pageController.hasClients) {
                _pageController.jumpToPage(
                  _virtualInitialPage,
                );
              }

              // 🚀 成功提示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("☁️ 雲端資料已成功還原"),
                ),
              );
            }
          });
    } catch (e) {

      if (mounted) {
        setState(() => _isSyncing = false);
      }

      if (mounted && e is BackupException) {
        await BackupErrorDialog.show(
          context,
          e,
          onRetry: () async {
            await _handleRestore();
          },
        );
      }
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
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        onSelected: (val) {
          if (val == 'photo')
            _handleChangePhoto();
          else if (val == 'sync') {
            if (Platform.isIOS) {
              _showIOSBackupDialog();
            } else {
              _handleManualBackup();
            }
          }
          else if (val == 'restore')
            _handleRestore();
          else if (val == 'auto_sync')
            _showAutoSyncDialog();
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
          PopupMenuItem(
            value: 'sync',
            child: Row(
              children: [
                _isSyncing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(
                  Icons.cloud_done_rounded,
                  color: Colors.green,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    Platform.isAndroid
                        ? "☁️ Google Drive 備份"
                        : "☁️ 備份到雲端",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem(value: 'restore', child: Row(children: [
            Icon(Icons.settings_backup_restore_rounded, color: Colors.orange),
            // 🚀 更有「找回」的感覺
            const SizedBox(width: 12),
            Text("☁️ 找回雲端資料")
          ])),

          const PopupMenuItem(
            value: 'auto_sync',
            child: Row(
              children: [
                Icon(Icons.sync, color: Colors.blue),
                SizedBox(width: 12),
                Text("🔄 多裝置同步 (自動)"),
              ],
            ),
          ),

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

  Widget _buildTitleSelector(User? user, bool isDark) {
    final Map<AppCategory, String> catNames = {
      AppCategory.dermatology: "肌膚照護",
      AppCategory.sleep: "睡眠健康",
      AppCategory.chronic: "慢性病管理",
      AppCategory.psychiatry: "情緒照護",
      AppCategory.pain: "疼痛管理",
      AppCategory.rheumatology: "風濕免疫",
      AppCategory.gastro: "腸胃紀錄",
      AppCategory.womens: "女性健康",
      AppCategory.peds: "兒科發展",
      AppCategory.neurology: "神經健康",
    };

    // 🚀 核心排序邏輯：複製一份清單來排序，不破壞原本的 AppCategory.values
    List<AppCategory> sortedCategories = [
      AppCategory.dermatology,
      AppCategory.sleep,
      AppCategory.neurology,
      AppCategory.chronic,
      AppCategory.psychiatry,
      AppCategory.pain,
      AppCategory.rheumatology,
      AppCategory.gastro,
      AppCategory.womens,
      AppCategory.peds,
    ];
    sortedCategories.sort((a, b) {
      // 取得時間，若沒填過就給一個遠古時代的日期 (2000年) 讓它墊底
      DateTime timeA = _lastCompletionTimes[a] ?? DateTime(2000);
      DateTime timeB = _lastCompletionTimes[b] ?? DateTime(2000);
      return timeB.compareTo(timeA); // 最新時間排在最上面 (降冪)
    });

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: PopupMenuButton<AppCategory>(
          onSelected: (cat) async {
            setState(() {
              _currentCategory = cat;
              if (_pageController.hasClients) _pageController.jumpToPage(_virtualInitialPage);
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('last_category_index', cat.index);
            HapticFeedback.mediumImpact();
          },
          itemBuilder: (ctx) => sortedCategories.map((cat) {
            // 1. 取得該科別的人性化日期註記 (如： (今天), (上週一))
            final String dateNote = _formatClinicalDate(_lastCompletionTimes[cat]);

            return PopupMenuItem(
              value: cat,
              child: Text.rich(
                TextSpan(
                  children: [
                    // 科別名稱
                    TextSpan(
                      text: catNames[cat]!,
                      style: TextStyle(
                        // 當前選中的科別加粗變色
                        fontWeight: _currentCategory == cat ? FontWeight.bold : FontWeight.normal,
                        color: _currentCategory == cat ? Colors.blue.shade700 : (isDark ? Colors.white : Colors.black87),
                        fontSize: 16,
                      ),
                    ),
                    // 🚀 括號日期註記 (縮小並變灰，產生視覺層次)
                    TextSpan(
                      text: dateNote,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
                Text(user!.email!, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showIOSBackupDialog() async {

    final provider = cloudBackupService.effectiveProvider;

    final providerName = switch (provider) {
      CloudProvider.googleDrive => "Google Drive",
      CloudProvider.iCloud => "iCloud",
      CloudProvider.none => "未設定",
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("☁️ 雲端備份"),
        content: Text(
          "目前雲端備份功能使用 $providerName。\n\n未來版本可能支援更多雲端服務。",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _handleManualBackup();
            },
            child: const Text("繼續"),
          ),
        ],
      ),
    );
  }

  Future<void> _showAutoSyncDialog() async {
    final prefs = await SharedPreferences.getInstance();
    bool autoSync = prefs.getBool('auto_sync') ?? false;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// HEADER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.cloud_sync_rounded,
                            color: Color(0xFF7CC6FF),
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              const Text(
                                "多裝置同步",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "自動同步您的資料與照片",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    /// DESCRIPTION
                    Text(
                      "開啟後會自動同步資料到您的雲端帳號，\n並在其他裝置上保持最新狀態。",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),

                    const SizedBox(height: 28),

                    /// SWITCH CARD
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Row(
                        children: [

                          const Expanded(
                            child: Text(
                              "自動同步",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          Transform.scale(
                            scale: 1.05,
                            child: Switch(
                              value: autoSync,

                              onChanged: (value) async {

                                await prefs.setBool(
                                  'auto_sync',
                                  value,
                                );

                                setState(() {
                                  autoSync = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    /// CLOSE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF2C2C2E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(18),
                          ),
                        ),

                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: const Text(
                          "完成",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
              // 🚀 4. 進入問卷邏輯
              if (targetType is ScaleType) {
                final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (ctx) => PoemSurveyScreen(initialType: targetType))
                );

                // 🎯 當問卷成功儲存並返回時
                if (res == true && mounted) {
                  final now = DateTime.now();

                  await _recordUsage(targetType, now);

                  final targetCategory = _getCategoryFromScale(targetType);
                  final prefs = await SharedPreferences.getInstance();

                  // 🚀 只有第一次才設定提醒時間（避免覆蓋使用者設定）
                  final hasCustomTime =
                  prefs.containsKey('reminder_hour_${targetType.name}');

                  if (!hasCustomTime) {
                    final nowTime = TimeOfDay.now();

                    setState(() {
                      _reminderTimes[targetType] = nowTime;
                    });

                    await prefs.setInt(
                      'reminder_hour_${targetType.name}',
                      nowTime.hour,
                    );

                    await prefs.setInt(
                      'reminder_minute_${targetType.name}',
                      nowTime.minute,
                    );
                  }

                  // 1. 💾 永久儲存最後紀錄時間
                  await prefs.setString('last_time_${targetCategory.name}', now.toIso8601String());

                  setState(() {
                    // 2. 更新 UI
                    _currentCategory = targetCategory;
                    _lastCompletionTimes[targetCategory] = now;

                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(_virtualInitialPage);
                    }
                  });

                  // 3. 記憶最後科別
                  await prefs.setInt('last_category_index', targetCategory.index);

                  // 🚀 4. 新增：詢問提醒（核心）
                  final isReminderOn =
                      prefs.getBool('reminder_enabled_${targetType.name}') ?? false;

                  final hasAsked =
                      prefs.getBool('asked_reminder_${targetType.name}') ?? false;

                  if (!isReminderOn && !hasAsked) {
                    // 記錄已詢問（避免一直問）
                    await prefs.setBool('asked_reminder_${targetType.name}', true);

                    // 延遲一點避免卡 UI
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _askEnableReminder(targetType);
                    });
                  }

                  // 5. 原本流程
                  _refreshData();

                  await Future.delayed(
                    const Duration(milliseconds: 300),
                  );

// 先往下滑
                  if (_scrollController.hasClients) {
                    await _scrollController.animateTo(
                      700,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                    );
                  }

                  // 再切換到底下對應卡片
                  if (_pageController.hasClients) {

                    final currentScales =
                        _categoryConfigs[_currentCategory] ?? [];

                    int targetPage = currentScales.indexWhere(
                          (e) => e['type'] == targetType,
                    );

                    if (targetPage < 0) {
                      targetPage = 0;
                    }

                    await _pageController.animateToPage(
                      targetPage,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    );
                  }

                  _showInterstitialAd();

                  _checkAndSilentBackup();
                }
              } else {
                if (config['onTap'] != null) config['onTap']();
              }
            },
            category: _currentCategory,
          );
        },
      ),
    );
  }

  void _askEnableReminder(ScaleType type) {
    final title = ScaleConfig.allScales[type]?.title ?? type.name;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("需要提醒嗎？"),
        content: Text("之後可以提醒您完成「$title」紀錄"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("不用"),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('reminder_enabled_${type.name}', true);

              setState(() {
                _reminderEnabled[type] = true;
              });

              await _scheduleClinicalReminders();

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$title 提醒已開啟")),
              );
            },
            child: const Text("開啟提醒"),
          ),
        ],
      ),
    );
  }

  Future<void> _recordUsage(ScaleType type, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();

    final key = 'usage_${type.name}';
    final list = prefs.getStringList(key) ?? [];

    // 存成 ISO string
    list.add(time.toIso8601String());

    // 👉 限制最多保留 20 筆（避免爆）
    if (list.length > 20) {
      list.removeAt(0);
    }

    await prefs.setStringList(key, list);

    // 🔥 記完就嘗試學習
    await _analyzeAndAdjustReminder(type, list);
  }

  Future<void> _analyzeAndAdjustReminder(
      ScaleType type,
      List<String> rawList,
      ) async {
    if (rawList.length < 5) return;

    final prefs = await SharedPreferences.getInstance();

    // 🚀 使用者已手動調整 → 永遠不再提示
    final userAdjusted =
        prefs.getBool('user_adjusted_${type.name}') ?? false;
    if (userAdjusted) return;

    final times = rawList.map((e) => DateTime.parse(e)).toList();

    final Map<int, int> hourCount = {};
    final Map<int, int> weekdayCount = {};

    for (var t in times) {
      hourCount[t.hour] = (hourCount[t.hour] ?? 0) + 1;
      weekdayCount[t.weekday] = (weekdayCount[t.weekday] ?? 0) + 1;
    }

    int bestHour =
        hourCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    int bestDay =
        weekdayCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    if (hourCount[bestHour]! < 3) return;
    if (weekdayCount[bestDay]! < 3) return;

    final currentHour =
    prefs.getInt('reminder_hour_${type.name}');
    final currentDay =
    prefs.getInt('reminder_day_${type.name}');

    if (currentHour != null &&
        currentDay != null &&
        (currentHour - bestHour).abs() <= 1 &&
        currentDay == bestDay) {
      return;
    }

    // 🚀 冷卻機制
    final rejectCount =
        prefs.getInt('reject_count_${type.name}') ?? 0;

// 👉 拒絕2次 → 永遠不再提示
    if (rejectCount >= 2) return;

    int cooldownDays = rejectCount == 0 ? 14 : 28;

    final lastSuggestTime =
    prefs.getString('last_suggest_${type.name}');

    if (lastSuggestTime != null) {
      final last = DateTime.parse(lastSuggestTime);
      if (DateTime.now().difference(last).inDays < cooldownDays) {
        return;
      }
    }

    if (!mounted) return;

    final period = _getTimePeriod(bestHour);
    final title = ScaleConfig.allScales[type]?.title ?? "";

    bool userInteracted = false;

// ⏱ 3秒後才算「拒絕」
    _suggestTimer?.cancel();

    _suggestTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      if (userInteracted) return;

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'last_suggest_${type.name}',
        DateTime.now().toIso8601String(),
      );

      final rejectCount =
          prefs.getInt('reject_count_${type.name}') ?? 0;

      await prefs.setInt(
        'reject_count_${type.name}',
        rejectCount + 1,
      );
    });

    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(
          "你最近都在$period記錄「$title」，要幫你之後在這個時候提醒嗎？",
        ),
        action: SnackBarAction(
          label: "調整",
          onPressed: () async {
            userInteracted = true;

            _suggestTimer?.cancel(); // 🔥 這行要加

            final prefs = await SharedPreferences.getInstance();

            await prefs.setInt(
                'reminder_hour_${type.name}', bestHour);
            await prefs.setInt(
                'reminder_day_${type.name}', bestDay);

            await prefs.setBool(
                'user_adjusted_${type.name}', true);

            setState(() {
              _reminderTimes[type] =
                  TimeOfDay(hour: bestHour, minute: 0);
              _reminderDays[type] = bestDay;
            });

            await _scheduleClinicalReminders();

            messenger.showSnackBar(
              const SnackBar(content: Text("提醒時間已更新")),
            );
          },
        ),
      ),
    );
  }

  String _getTimePeriod(int hour) {
    if (hour >= 6 && hour < 11) return "早上";
    if (hour >= 11 && hour < 14) return "中午";
    if (hour >= 14 && hour < 18) return "下午";
    if (hour >= 18 && hour < 22) return "晚上";
    return "深夜";
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
        (_enabledScales[t] ?? true)
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
        return [
          ScaleType.adct,
          ScaleType.poem,
          ScaleType.uas7,
          ScaleType.scorad,
        ].contains(type);

    // 🚀 睡眠健康
      case AppCategory.sleep:
        return [
          ScaleType.psqi,
          ScaleType.isi,
          ScaleType.ess,
        ].contains(type);

    // 🚀 神經健康（新增這段）
      case AppCategory.neurology:
        return [
          ScaleType.qolie10,
          ScaleType.lsss,
        ].contains(type);

    // 🚀 慢性病管理
      case AppCategory.chronic:
        return [
          ScaleType.bp_log,
          ScaleType.cat,
          ScaleType.dds,
          ScaleType.bpi,
        ].contains(type);

      case AppCategory.psychiatry:
        return [
          ScaleType.phq9,
          ScaleType.gad7,
        ].contains(type);

      case AppCategory.pain:
        return [
          ScaleType.vas,
        ].contains(type);

      case AppCategory.rheumatology:
        return [
          ScaleType.haq,
          ScaleType.vas,
        ].contains(type);

      case AppCategory.gastro:
        return [
          ScaleType.bristol,
          ScaleType.ibs_sss,
        ].contains(type);

      case AppCategory.womens:
        return [
          ScaleType.cycle,
        ].contains(type);

      case AppCategory.peds:
        return [
          ScaleType.growth,
        ].contains(type);

      default:
        return false;
    }
  }

  Widget _buildCardByType(ScaleType type, Map<String, dynamic> data) {
    final history = data[type.name] as List<PoemRecord>? ?? [];

    switch (type) {
    // 1. 蕁麻疹專用卡片 (保持不變)
      case ScaleType.uas7:
      case ScaleType.qolie10:
      case ScaleType.lsss:
      case ScaleType.psqi:
      case ScaleType.isi:
      case ScaleType.ess:
        return ScaleTrackerCard(
          scaleType: type,
          startDate: data['${type.name}Start'],
          completionStatus: data['${type.name}Status'],
          history: history,
          onRefresh: _refreshData,
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
                    SizedBox(
                      height: 48,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          scale['title'],
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isEnabled ? color : Colors.grey,
                          ),
                        ),
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