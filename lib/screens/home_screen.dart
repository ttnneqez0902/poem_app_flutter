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
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

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

  late final PageController _pageController = PageController(
    initialPage: _virtualInitialPage,
    viewportFraction: 0.9,
  );
  final ScrollController _scrollController = ScrollController();

  // --- 提醒與量表開關設定 ---
  final Map<ScaleType, TimeOfDay> _reminderTimes = {};
  final Map<ScaleType, int> _reminderDays = {};
  final Map<ScaleType, bool> _reminderEnabled = {};
  Map<ScaleType, bool> _enabledScales = {
    ScaleType.adct: true,
    ScaleType.poem: true,
    ScaleType.uas7: true,
    ScaleType.scorad: true,
  };

  // --- 廣告相關變數 ---
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  final String _adUnitId = kReleaseMode
      ? (Platform.isAndroid ? 'ca-app-pub-6250825906693072/8000200207' : 'ca-app-pub-6250825906693072/1102931009')
      : (Platform.isAndroid ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3940256099942544/2934735716');

  final String _interstitialAdUnitId = kReleaseMode
      ? (Platform.isAndroid ? 'ca-app-pub-6250825906693072/6233433793' : 'ca-app-pub-6250825906693072/9597963737')
      : (Platform.isAndroid ? 'ca-app-pub-3940256099942544/1033173712' : 'ca-app-pub-3940256099942544/4411468910');

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

  // --- 科別內容配置表 ---
  Map<AppCategory, List<Map<String, dynamic>>> get _categoryConfigs => {
    AppCategory.dermatology: [
      {'type': ScaleType.adct, 'title': 'ADCT', 'sub': '每周異膚控制', 'color': Colors.blue, 'icon': Icons.assignment_turned_in},
      {'type': ScaleType.poem, 'title': 'POEM', 'sub': '每周濕疹檢測', 'color': Colors.orange, 'icon': Icons.opacity},
      {'type': ScaleType.uas7, 'title': 'UAS7', 'sub': '每日蕁麻疹量表', 'color': Colors.teal, 'icon': Icons.calendar_month},
      {'type': ScaleType.scorad, 'title': 'SCORAD', 'sub': '每周異膚綜合', 'color': Colors.purple, 'icon': Icons.biotech},
    ],
    AppCategory.psychiatry: [
      // 🚀 關鍵：確保這裡使用的是 ScaleType.phq9 而不是字串
      {'type': ScaleType.phq9, 'title': 'PHQ-9', 'sub': '憂鬱情緒篩檢', 'color': Colors.indigo, 'icon': Icons.psychology},
      {'type': ScaleType.gad7, 'title': 'GAD-7', 'sub': '焦慮狀況評估', 'color': Colors.green.shade700, 'icon': Icons.sentiment_dissatisfied},
    ],
    AppCategory.pain: [
      {'type': ScaleType.vas, 'title': 'VAS', 'sub': '疼痛視覺類比', 'color': Colors.redAccent, 'icon': Icons.bolt},
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
      if (offset > 10 && !_isScrolled) setState(() => _isScrolled = true);
      else if (offset <= 10 && _isScrolled) setState(() => _isScrolled = false);
    });
  }

  // --- 🔐 權限與身份檢查 ---
  void _checkUserStatus() {
    if (FirebaseAuth.instance.currentUser == null) debugPrint("⚠️ 訪客模式：未登入");
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
      bool isGoogleUser = user.providerData.any((p) => p.providerId == 'google.com');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(isGoogleUser ? Icons.g_mobiledata_rounded : Icons.apple_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(child: Text("歡迎回來，${user.displayName ?? "使用者"}！", style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue.shade700,
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.1, left: 20, right: 20),
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
            Future.delayed(const Duration(seconds: 30), () { if (mounted) _loadBannerAd(); });
          }
      ),
    )..load();
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
          if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) _createInterstitialAd();
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) return;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('廣告顯示中'),
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); _createInterstitialAd(); },
      onAdFailedToShowFullScreenContent: (ad, err) { ad.dispose(); _createInterstitialAd(); },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // --- 📸 頭像管理 ---
  Future<void> _loadLocalPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    String? path = prefs.getString('user_custom_photo');
    if (path != null && File(path).existsSync()) setState(() => _localPhotoPath = path);
  }

  Future<void> _handleChangePhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context, builder: (ctx) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.photo_library), title: const Text('從相簿選擇'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('開啟相機'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
    ])),
    );
    if (source == null) return;
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: '編輯大頭照', toolbarColor: Colors.blue, toolbarWidgetColor: Colors.white, cropStyle: CropStyle.circle),
        IOSUiSettings(title: '編輯大頭照', aspectRatioLockEnabled: true),
      ],
    );
    if (croppedFile != null) {
      setState(() => _localPhotoPath = croppedFile.path);
      (await SharedPreferences.getInstance()).setString('user_custom_photo', croppedFile.path);
    }
  }

  // --- ⚙️ 設定持久化 (補回關鍵修正) ---
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
    });
    _scheduleClinicalReminders();
  }

  Future<void> _saveSettings() async { // 補回：存下管理模式的修改
    final prefs = await SharedPreferences.getInstance();
    for (var entry in _enabledScales.entries) {
      await prefs.setBool('enable_${entry.key.name}', entry.value);
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

  Future<void> _scheduleClinicalReminders() async {
    for (var type in ScaleType.values) {
      await NotificationService().cancel(type.index);
      if (_enabledScales[type] == true && _reminderEnabled[type] == true) {
        final t = _reminderTimes[type]!;
        if (type == ScaleType.uas7) {
          await NotificationService().scheduleDailyReminder(id: type.index, title: 'UAS7 追蹤提醒', body: '請記錄今天的狀況。', hour: t.hour, minute: t.minute, payload: type.name);
        } else {
          await NotificationService().scheduleWeeklyReminder(id: type.index, title: '${type.name.toUpperCase()} 追蹤提醒', body: '今天是紀錄日。', dayOfWeek: _reminderDays[type]!, hour: t.hour, minute: t.minute, payload: type.name);
        }
      }
    }
  }

  // --- ☁️ 數據備份與還原系統 (完整回歸) ---
  void _refreshData() => setState(() { _trackerDataFuture = _getTrackerData(); });

  Future<Map<String, dynamic>> _getTrackerData() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 8));
    final all = await isarService.getAllRecords();
    final uas7 = all.where((r) => r.scaleType == ScaleType.uas7).toList();
    return {
      'uas7Start': start,
      'uas7Status': List.generate(14, (i) => uas7.any((r) => DateUtils.isSameDay(r.targetDate ?? r.date, start.add(Duration(days: i))))),
      'uas7Records': uas7,
      'adct': all.where((r) => r.scaleType == ScaleType.adct).toList()..sort((a, b) => b.date!.compareTo(a.date!)),
      'poem': all.where((r) => r.scaleType == ScaleType.poem).toList()..sort((a, b) => b.date!.compareTo(a.date!)),
      'scorad': all.where((r) => r.scaleType == ScaleType.scorad).toList()..sort((a, b) => b.date!.compareTo(a.date!)),
    };
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    int total = 0; if (!await dir.exists()) return 0;
    await for (final entity in dir.list(recursive: true)) { if (entity is File) total += await entity.length(); }
    return total;
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1048576) return "${(bytes / 1048576).toStringAsFixed(1)} MB";
    if (bytes >= 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "$bytes B";
  }

  Future<void> _handleManualBackup() async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) return;
    if (_isSyncing) return;

    final docDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docDir.path, 'eczema_data.isar'));
    final photoDir = Directory(p.join(docDir.path, 'photos'));
    final totalSize = (await dbFile.exists() ? await dbFile.length() : 0) + await _calculateDirectorySize(photoDir);

    final bool confirmed = await showDialog<bool>(
        context: context, builder: (ctx) => AlertDialog(
      title: const Text("雲端備份說明"),
      content: Text("將加密備份紀錄至 Google Drive。\n\n📦 預估大小：${_formatBytes(totalSize)}\n\n確定開始？"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("開始備份")),
      ],
    )
    ) ?? false;

    if (!confirmed) return;
    setState(() => _isSyncing = true);
    try {
      final prog = ValueNotifier<String>("準備中...");
      final per = ValueNotifier<double>(0.0);
      await BackupDialogs.showProcessingDialog(context: context, title: "同步至雲端", progressNotifier: prog, percentNotifier: per, action: () async {
        await cloudBackupService.runBackup(photoDir.path, appVersion: _appVersion, onProgress: (p) { prog.value = p.message; per.value = p.progress; });
        (await SharedPreferences.getInstance()).setString('last_backup_time', DateTime.now().toIso8601String());
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ 備份完成")));
    } catch (e) { if (mounted && e is BackupException) BackupErrorDialog.show(context, e); }
    finally { if (mounted) setState(() => _isSyncing = false); }
  }

  Future<void> _handleRestore() async {
    final bool confirmed = await BackupDialogs.confirmRestore(context);
    if (!confirmed) return;
    setState(() => _isSyncing = true);
    try {
      final prog = ValueNotifier<String>("正在聯繫雲端...");
      final per = ValueNotifier<double>(0.0);
      await BackupDialogs.showProcessingDialog(context: context, title: "還原數據中", progressNotifier: prog, percentNotifier: per, action: () async {
        await cloudBackupService.runRestore(p.join((await getApplicationDocumentsDirectory()).path, 'photos'), onProgress: (p) { prog.value = p.message; per.value = p.progress; });
        if (mounted) _refreshData();
      });
    } catch (e) { if (mounted && e is BackupException) BackupErrorDialog.show(context, e); }
    finally { if (mounted) setState(() => _isSyncing = false); }
  }

  Future<void> _checkBackupRequirement() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString('last_backup_time');
    final lastHint = prefs.getString('last_hint_show_time');
    final recentCount = await isarService.getRecordsCountInLastDays(28);
    DateTime now = DateTime.now();

    if (recentCount > 0 && (lastBackup == null || now.difference(DateTime.parse(lastBackup)).inDays >= 28)) {
      if (lastHint == null || now.difference(DateTime.parse(lastHint)).inDays >= 28) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("您已有四週的紀錄未備份。"), action: SnackBarAction(label: "立即備份", onPressed: () => _handleManualBackup())));
        await prefs.setString('last_hint_show_time', now.toIso8601String());
      }
    }
  }

  Future<void> _checkAndSilentBackup() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('last_silent_backup');
    if (lastSync != null && DateTime.now().difference(DateTime.parse(lastSync)).inDays < 28) return;
    try {
      await cloudBackupService.runBackup(p.join((await getApplicationDocumentsDirectory()).path, 'photos'), appVersion: _appVersion);
      await prefs.setString('last_silent_backup', DateTime.now().toIso8601String());
    } catch (e) { debugPrint("靜默備份失敗"); }
  }

  // --- 🖥 UI 組件 (模組化拆分) ---

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    ImageProvider? avatar;
    if (_localPhotoPath != null) avatar = FileImage(File(_localPhotoPath!));
    else if (user?.photoURL != null) avatar = NetworkImage(user!.photoURL!);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent),
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
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildScaleGrid(context),
                    const SizedBox(height: 12),
                    _buildSecondaryNavigation(context),
                    if (_currentCategory == AppCategory.dermatology) ...[
                      const SizedBox(height: 16),
                      _buildSwiperHeader(),
                      _buildProgressSwiper(),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (_isAdLoaded && _bannerAd != null) _buildAdBanner(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarMenu(User? user, ImageProvider? avatar, bool isDark) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]),
      child: PopupMenuButton<String>(
        onSelected: (val) {
          if (val == 'photo') _handleChangePhoto();
          else if (val == 'sync') _handleManualBackup();
          else if (val == 'restore') _handleRestore();
          else if (val == 'logout') _handleLogout(context);
        },
        child: CircleAvatar(
          radius: 26, backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
          backgroundImage: avatar,
          child: avatar == null ? Text(user?.displayName?.substring(0,1).toUpperCase() ?? "U") : null,
        ),
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'photo', child: Row(children: [Icon(Icons.photo_library, color: Colors.blue), SizedBox(width: 12), Text("更換頭像")])),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'sync', child: Row(children: [
            _isSyncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload, color: Colors.green),
            const SizedBox(width: 12), const Text("雲端備份數據")
          ])),
          const PopupMenuItem(value: 'restore', child: Row(children: [Icon(Icons.cloud_download, color: Colors.orange), SizedBox(width: 12), Text("從雲端還原數據")])),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.redAccent), SizedBox(width: 12), Text("登出系統")])),
        ],
      ),
    );
  }

  Widget _buildTitleSelector(User? user, bool isDark) {
    String title = _currentCategory == AppCategory.dermatology ? "皮膚科" : _currentCategory == AppCategory.psychiatry ? "身心科" : "疼痛管理";
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: PopupMenuButton<AppCategory>(
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (cat) { setState(() => _currentCategory = cat); HapticFeedback.mediumImpact(); },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: AppCategory.dermatology, child: Text("皮膚科")),
            const PopupMenuItem(value: AppCategory.psychiatry, child: Text("身心科")),
            const PopupMenuItem(value: AppCategory.pain, child: Text("疼痛管理")),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: isDark ? Colors.white : Colors.blueGrey.shade900)),
                Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey),
              ]),
              if (user?.email != null) Text(user!.email!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600)),
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
        icon: Icon(_isManagementMode ? Icons.check_circle : Icons.settings_suggest_rounded, color: _isManagementMode ? Colors.green : (isDark ? Colors.white : Colors.blueGrey.shade700)),
        onPressed: () {
          setState(() => _isManagementMode = !_isManagementMode);
          if (!_isManagementMode) _saveSettings(); // 🚀 補回：退出時存下修改
        },
      ),
    );
  }

  Widget _buildScaleGrid(BuildContext context) {
    final List<Map<String, dynamic>> scales = _categoryConfigs[_currentCategory]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2
        ),
        itemCount: scales.length,
        itemBuilder: (ctx, i) {
          final config = scales[i];
          final dynamic type = config['type'];

          // 判斷是否啟用 (皮膚科看設定，其餘預設開啟)
          bool isEnabled = (type is ScaleType) ? (_enabledScales[type] ?? true) : true;

          return _AnimatedScaleCard(
            scale: config,
            isEnabled: isEnabled,
            isManagementMode: _isManagementMode,
            onTap: () async {
              // 1. 管理員模式：切換開關 (僅限皮膚科)
              if (_isManagementMode && type is ScaleType) {
                setState(() => _enabledScales[type] = !(_enabledScales[type] ?? true));
                return;
              }

              // 2. 停用狀態提示
              if (!isEnabled) {
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(title: Text("${config['title']} 已關閉"), content: const Text("目前無需執行此量表。"))
                );
                return;
              }

              // 🚀 3. 統一進入問卷 (現在 PHQ-9 也是 ScaleType 了，會直接跑這段)
              if (type is ScaleType) {
                final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (ctx) => PoemSurveyScreen(initialType: type))
                );

                if (res == true && mounted) {
                  _showInterstitialAd();
                  _refreshData();
                  _checkAndSilentBackup();

                  // 只有皮膚科有進度 Swiper，需要滑動回饋
                  if (_currentCategory == AppCategory.dermatology) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) _jumpToScalePage(type);
                    });
                  }
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSecondaryNavigation(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 🚀 建議趨勢圖也傳入科別，這樣圖表才不會混亂
          Expanded(
            child: _buildSmallMenuButton(
                context,
                "查看趨勢",
                Icons.bar_chart_rounded,
                Colors.teal.shade700,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => TrendChartScreen(currentCategory: _currentCategory))
                )
            ),
          ),
          const SizedBox(width: 12),
          // ✅ 歷史紀錄：你補上的參數是正確的！
          Expanded(
            child: _buildSmallMenuButton(
                context,
                "歷史紀錄",
                Icons.list_alt_rounded,
                Colors.blueGrey.shade700,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => HistoryListScreen(currentCategory: _currentCategory))
                )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMenuButton(BuildContext ctx, String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(color: Theme.of(ctx).cardColor, borderRadius: BorderRadius.circular(15), child: InkWell(borderRadius: BorderRadius.circular(15), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 22), const SizedBox(width: 6), Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 17))]))));
  }

  Widget _buildSwiperHeader() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Row(children: [
      const Icon(Icons.auto_awesome, color: Colors.orangeAccent), const SizedBox(width: 8),
      const Expanded(child: Text("臨床進度週期追蹤", style: TextStyle(fontWeight: FontWeight.bold))),
      InkWell(onTap: _showReminderSettingsModal, child: const Text("設定提醒", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
    ]));
  }

  Widget _buildProgressSwiper() {
    final enabledTypes = ScaleType.values.where((t) => _enabledScales[t] == true).toList();
    if (enabledTypes.isEmpty) return const SizedBox.shrink();
    return SizedBox(height: 295, child: FutureBuilder<Map<String, dynamic>>(future: _trackerDataFuture ?? _getTrackerData(), builder: (ctx, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      return PageView.builder(controller: _pageController, itemCount: _virtualTotalCount, itemBuilder: (ctx, i) => _buildCardByType(enabledTypes[i % enabledTypes.length], snapshot.data!));
    }));
  }

  Widget _buildCardByType(ScaleType type, Map<String, dynamic> data) {
    switch (type) {
      case ScaleType.uas7: return Uas7TrackerCard(startDate: data['uas7Start'], completionStatus: data['uas7Status'], history: data['uas7Records'], onRefresh: _refreshData);
      default: return WeeklyTrackerCard(type: type, history: data[type.name] ?? [], onRefresh: _refreshData);
    }
  }

  Widget _buildAdBanner(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.only(top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
      width: double.infinity, alignment: Alignment.center,
      child: SizedBox(width: _bannerAd!.size.width.toDouble(), height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!)),
    );
  }

  // --- 其餘輔助邏輯 ---
  void _jumpToScalePage(ScaleType type) {
    if (!_pageController.hasClients) return;
    final enabled = ScaleType.values.where((t) => _enabledScales[t] == true).toList();
    int target = enabled.indexOf(type);
    if (target != -1) {
      int current = _pageController.page!.round();
      _pageController.animateToPage(current + (target - (current % enabled.length)), duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text("確定登出？"), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("登出", style: TextStyle(color: Colors.red)))]));
    if (confirm == true) {
      await FirebaseAuth.instance.signOut(); await _googleSignIn.signOut();
      if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (ctx) => const LoginScreen()), (r) => false);
    }
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

}

class _AnimatedScaleCard extends StatelessWidget {
  final Map<String, dynamic> scale; final bool isEnabled; final bool isManagementMode; final VoidCallback onTap;
  const _AnimatedScaleCard({required this.scale, required this.isEnabled, required this.isManagementMode, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = scale['color'] as Color;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: Container(
      decoration: BoxDecoration(color: isEnabled ? Theme.of(context).cardColor : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: isEnabled ? color.withOpacity(0.4) : Colors.grey.shade300, width: 1.5)),
      child: Stack(children: [
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(scale['icon'], size: 40, color: isEnabled ? color : Colors.grey), const SizedBox(height: 8), Text(scale['title'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isEnabled ? color : Colors.grey)), Text(scale['sub'], style: TextStyle(fontSize: 14, color: isEnabled ? color.withOpacity(0.8) : Colors.grey, fontWeight: FontWeight.bold))])),
        if (isManagementMode && scale['type'] is ScaleType) Positioned(top: 10, right: 10, child: Icon(isEnabled ? Icons.visibility : Icons.visibility_off, size: 18, color: isEnabled ? Colors.green : Colors.red)),
      ]),
    ));
  }
}