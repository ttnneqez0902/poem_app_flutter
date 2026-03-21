import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

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
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? pendingPayload;

void handleNotificationJump(String payload) {
  // 🚀 Defensive Coding: 確保 Enum 解析永遠安全
  final targetType = ScaleType.values.firstWhere(
          (e) => e.name == payload,
      orElse: () => ScaleType.adct
  );

  if (navigatorKey.currentState != null) {
    debugPrint("🔔 [Nav] 通知觸發：跳轉至 ${targetType.name}");
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: targetType)),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🚀 註冊監聽器
  WidgetsBinding.instance.addObserver(appLifecycleHandler);

  await _initServices();
  runApp(const MyApp());
}

Future<void> _initServices() async {
  try {
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

Future<void> globalSyncTask() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // 1. 🚀 節流鎖 (2 分鐘)
  if (_lastSync != null &&
      DateTime.now().difference(_lastSync!) < const Duration(minutes: 2)) {
    debugPrint("⏳ [Sync Skip] 距離上次同步不到 2 分鐘，跳過。");
    return;
  }

  if (_isSyncingGlobal) return;

  _isSyncingGlobal = true;

  try {
    // 🚀 先列印啟動資訊
    debugPrint("📡 [Sync Start] User: ${user.uid} | Time: ${DateTime.now().toIso8601String()}");

    // 2. 🚀 執行同步並接收數據化結果
    final result = await syncManager.performPushSync();

    if (result.total > 0) {
      debugPrint("🏁 [Sync Success] 處理: ${result.total} | 成功: ${result.success} | 失敗: ${result.failed}");
    } else {
      debugPrint("📭 [Sync Skip] 目前無待同步數據");
    }

    // ✅ 全部執行完畢且沒拋出異常，才更新「最後同步時間」
    _lastSync = DateTime.now();

  } catch (e) {
    debugPrint("⚠️ [Sync Failed] 將於下次週期重試: $e");
  } finally {
    _isSyncingGlobal = false;
  }
}

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("📱 [Lifecycle] App Resumed - 1s 緩衝後觸發同步");
      // 🚀 關鍵優化：給予 1 秒緩衝，確保 Socket 穩定與 UI 渲染完畢
      Future.delayed(const Duration(seconds: 1), () => globalSyncTask());
    }
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'CareSync 健康隨行',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue, brightness: Brightness.light),
        darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue, brightness: Brightness.dark),
        home: const BootstrapScreen(),
      ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint("🔐 [Auth] 使用者登入成功 - 啟動首波同步");
            globalSyncTask();

            // 🚀 處理冷啟動通知
            if (pendingPayload != null) {
              handleNotificationJump(pendingPayload!);
              pendingPayload = null;
            }
          });
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}