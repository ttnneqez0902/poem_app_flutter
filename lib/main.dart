import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'dart:async'; // 🔥 加這行

import 'firebase_options.dart';
import 'controllers/bootstrap_controller.dart';
import 'services/isar_service.dart';
import 'services/notification_service.dart';
import 'services/sync_manager.dart';
import 'models/poem_record.dart';
import 'screens/home_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/login_screen.dart';
import 'screens/poem_survey_screen.dart';

// --- 全域實例 ---
final isarService = IsarService();
final syncManager = SyncManager(isarService);
final notificationService = NotificationService();
final bootstrapController = BootstrapController();
final appLifecycleHandler = AppLifecycleHandler();

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
// 🚀 關鍵修正：補回這兩行！
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

bool hasPendingSync = false;
bool _hasTriggeredSync = false;
String? pendingPayload;
late final String myDeviceId;

void handleNotificationJump(String payload) {
  // 🚀 Defensive Coding: 確保 Enum 解析永遠安全
  final targetType = ScaleType.values.firstWhere(
          (e) => e.name == payload,
      orElse: () => ScaleType.adct
  );

  if (navigatorKey.currentState != null) {
    debugPrint("🔔 [Nav] 通知觸發：清理堆疊並跳轉至 ${targetType.name}");

    // 使用 pushAndRemoveUntil 或是先 pop 到首頁再 push，避免頁面無限疊加
    navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // 先回到首頁
    );

    // 再推入問卷頁
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: targetType)),
    );
  }
}


StreamSubscription<User?>? _authSub;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌗 系統亮度
  final Brightness systemBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;
  final bool isDarkMode = systemBrightness == Brightness.dark;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness:
    isDarkMode ? Brightness.light : Brightness.dark,
    systemNavigationBarColor:
    isDarkMode ? const Color(0xFF121212) : Colors.white,
    systemNavigationBarIconBrightness:
    isDarkMode ? Brightness.light : Brightness.dark,
  ));

  // 🔥 Firebase 初始化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 正確位置：這裡才監聽 auth
  _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user == null) {
      _hasTriggeredSync = false;
    }
  });

  WidgetsBinding.instance.addObserver(appLifecycleHandler);

  await _initServices();

  runApp(const MyApp());
}

Future<void> _initServices() async {
  try {
    // 🔥 1. 初始化 deviceId（最重要）
    final prefs = await SharedPreferences.getInstance();

    myDeviceId = prefs.getString('device_id') ??
        DateTime.now().millisecondsSinceEpoch.toString();

    await prefs.setString('device_id', myDeviceId);

    // 🔥 2. 原本流程
    await MobileAds.instance.initialize();
    await initializeDateFormatting('zh_TW', null);
    await isarService.init();

    await notificationService.init(
      onPayloadReceived: (payload) {
        if (payload == null) return;
        if (navigatorKey.currentState?.overlay != null) {
          handleNotificationJump(payload);
        } else {
          pendingPayload = payload;
        }
      },
    );

    await notificationService.requestPermissions();

    debugPrint("✨ [System] 臨床同步引擎已就緒");
  } catch (e) {
    debugPrint("💥 [System] 初始化關鍵錯誤: $e");
  }
}

// --- 🔄 封神版全域同步任務 ---
bool _isSyncingGlobal = false;
DateTime? _lastSync;

// 🚀 修改建議：支援強制觸發與視覺回饋
Future<void> globalSyncTask({bool force = false}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // 🔥 沒新資料 → 不 sync
  if (!force && !hasPendingSync) {
    debugPrint("📭 [Sync Skip] 沒有新資料");
    return;
  }

  // 🔥 節流（30分鐘）
  if (!force && _lastSync != null &&
      DateTime.now().difference(_lastSync!) < const Duration(minutes: 30)) {
    debugPrint("⏳ [Sync Skip] 距離上次同步不到 30 分鐘，跳過。");
    return;
  }

  if (_isSyncingGlobal) return;
  _isSyncingGlobal = true;

  try {
    debugPrint("📡 [Sync Start] 正在上傳臨床數據...");

    final result = await syncManager.performPushSync();

    // 🔥 成功
    if (result.success > 0) {
      debugPrint("🏁 [Sync Success] 成功同步 ${result.success} 筆資料");

      hasPendingSync = false; // 🔥 核心

      if (force) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text("✅ 已安全同步 ${result.success} 筆紀錄至雲端"),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }

      // ⚠️ 部分失敗
    } else if (result.total > 0 && result.failed > 0) {
      debugPrint("⚠️ [Sync Partial] 部分失敗：${result.failed} 筆");

      // 📭 沒東西同步
    } else {
      debugPrint("📭 [Sync Skip] 無需同步新數據");
    }

    _lastSync = DateTime.now();

  } catch (e) {
    debugPrint("⚠️ [Sync Failed] 網路或權限異常: $e");

    if (force) {
      messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text("❌ 同步失敗，請檢查網路連線")),
      );
    }
  } finally {
    _isSyncingGlobal = false;
  }
}

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  Future<void> _handleResume() async {
    final prefs = await SharedPreferences.getInstance();
    final autoSync = prefs.getBool('auto_sync') ?? false;

    // 🔥 沒開自動同步 → 不做
    if (!autoSync) return;

    // 🔥 沒新資料 → 不做（超重要）
    if (!hasPendingSync) return;

    Future.delayed(
      const Duration(seconds: 1),
          () {
        if (!_isSyncingGlobal) {
          globalSyncTask();
        }
      },
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, __) {
          // 🚀 4. 根據主題自動切換狀態列圖示顏色 (深色模式配白字，淺色模式配黑字)
          final isDark = mode == ThemeMode.dark ||
              (mode == ThemeMode.system && MediaQuery.of(_).platformBrightness == Brightness.dark);

          SystemChrome.setSystemUIOverlayStyle(isDark
              ? SystemUiOverlayStyle.light // 深色模式，狀態列圖示用白色
              : SystemUiOverlayStyle.dark  // 淺色模式，狀態列圖示用黑色
          );

          return MaterialApp(
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: messengerKey, // 🚀 註冊這一行
            title: 'CareSync 健康隨行',
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            // 🚀 5. 全域主題美化 (使用具備臨床感的 Teal 色調)
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.blue.shade700,
              brightness: Brightness.light,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.blue,
              brightness: Brightness.dark,
            ),
            home: const BootstrapScreen(),
          );
        },
    );
  }
}

/// 🚀 啟動畫面：處理初始化、隱私協議與數據載入進度
class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  @override
  void initState() {
    super.initState();
    // 渲染完成後啟動引導控制器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bootstrapController.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        bootstrapController.stage,
        bootstrapController.error,
        bootstrapController.needsConsent,
      ]),
      builder: (context, _) {
        if (bootstrapController.stage.value == BootStage.ready) {
          return const AuthGate();
        }

        if (bootstrapController.error.value != BootstrapError.none) {
          return _buildErrorUI();
        }

        if (bootstrapController.needsConsent.value) {
          return const ConsentScreen();
        }

        return _buildLoadingUI();
      },
    );
  }

  Widget _buildLoadingUI() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              ValueListenableBuilder<double>(
                valueListenable: bootstrapController.progress,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              const Text("臨床引擎啟動中...", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable: bootstrapController.errorMessage,
              builder: (context, message, _) => Text(message),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => bootstrapController.start(),
              icon: const Icon(Icons.refresh),
              label: const Text("重試啟動"),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔒 權限門衛：處理 Firebase 登入狀態
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // 🚀 1️⃣ 初始化時（避免閃屏）
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // 🚀 2️⃣ 已登入
        if (snapshot.hasData) {

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleAutoSyncOnce();
          });

          return const HomeScreen();
        }

        // 🚀 3️⃣ 未登入
        return const LoginScreen();
      },
    );
  }

  // 🔥 把副作用抽出去（更乾淨）
  void _handleAutoSyncOnce() {
    if (_hasTriggeredSync) return;

    _hasTriggeredSync = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final autoSync = prefs.getBool('auto_sync') ?? false;

      if (autoSync) {
        globalSyncTask();
      }
    });
  }
}