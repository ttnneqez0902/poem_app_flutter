import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'controllers/bootstrap_controller.dart';
import 'services/isar_service.dart';
import 'services/notification_service.dart';

import 'screens/home_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/login_screen.dart';

import 'models/poem_record.dart';
import 'screens/poem_survey_screen.dart';

// 全域實例
final isarService = IsarService();
final notificationService = NotificationService();
final bootstrapController = BootstrapController();
final appLifecycleHandler = AppLifecycleHandler();

final ValueNotifier<ThemeMode> themeNotifier =
ValueNotifier(ThemeMode.system);

// 🚀 1. 新增：用來記住冷啟動時的目標量表
String? pendingPayload;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🚀 2. 封裝一個全域的跳轉方法
void handleNotificationJump(String payload) {
  ScaleType? targetType;
  for (var type in ScaleType.values) {
    if (type.name == payload) targetType = type;
  }

  if (targetType != null && navigatorKey.currentState != null) {
    debugPrint("🚀 執行通知跳轉至 ${targetType.name} 量表");
    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (context) => PoemSurveyScreen(initialType: targetType!),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await isarService.init();

  // 🚀 3. 修改 init：如果在背景就直接跳，如果還在開機就先記在 pendingPayload
  await notificationService.init(
      onPayloadReceived: (String? payload) {
        if (payload == null) return;
        if (navigatorKey.currentState?.overlay != null) {
          handleNotificationJump(payload); // App 已經在畫面上了，直接跳
        } else {
          pendingPayload = payload; // App 還在冷啟動，先記下來
        }
      }
  );

  // 🚀 4. 檢查是否是「點擊通知才喚醒 App」的冷啟動
  final coldPayload = await notificationService.getColdStartPayload();
  if (coldPayload != null) {
    pendingPayload = coldPayload;
  }

  await notificationService.requestPermissions();
  WidgetsBinding.instance.addObserver(appLifecycleHandler);
  bootstrapController.start();

  runApp(const MyApp()); // 🚀 補上右括號與分號
  debugPrint("🚀 App Boot Completed");
}


bool _isSyncingGlobal = false;

DateTime? _lastSync;

Future<void> globalSyncTask() async {

  if (_lastSync != null &&
      DateTime.now().difference(_lastSync!) < const Duration(minutes: 2)) {
    return;
  }

  if (_isSyncingGlobal) return;

  _lastSync = DateTime.now();
  _isSyncingGlobal = true;

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    _isSyncingGlobal = false;
    return;
  }

  try {
    final unsynced =
    await isarService.getUnsyncedRecords(user.uid);

    if (unsynced.isEmpty) {
      debugPrint("📭 沒有需要同步資料");
      _isSyncingGlobal = false;
      return;
    }

    debugPrint("🚀 發現 ${unsynced.length} 筆未同步資料");

    Map<String, List<dynamic>> groupedData = {};
    Map<String, List<int>> groupedIds = {};

    for (var rec in unsynced) {
      String monthKey =
          "${rec.targetDate?.year}_${rec.targetDate?.month.toString().padLeft(2, '0')}";

      groupedData.putIfAbsent(monthKey, () => []);
      groupedIds.putIfAbsent(monthKey, () => []);

      groupedData[monthKey]!.add(rec.toFirestore());
      groupedIds[monthKey]!.add(rec.id);
    }

    for (var monthKey in groupedData.keys) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('monthly_data')
          .doc(monthKey);

      await docRef.set({
        'records': FieldValue.arrayUnion(groupedData[monthKey]!),
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await isarService.markAsSynced(groupedIds[monthKey]!);
    }

    debugPrint("✅ 自動同步完成");
  } catch (e) {
    debugPrint("❌ 同步失敗: $e");
  } finally {
    _isSyncingGlobal = false;
  }
}

class AppLifecycleHandler extends WidgetsBindingObserver {

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.resumed) {

      Future.delayed(const Duration(seconds: 2), () {
        globalSyncTask();
      });

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
        navigatorKey: navigatorKey, // 🚀 4. 把全域鑰匙交給 MaterialApp
        title: '皮膚健康管理',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          brightness: Brightness.dark,
        ),
        home: const BootstrapScreen(),
      ),
    );
  }
}

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        bootstrapController.stage,
        bootstrapController.error,
        bootstrapController.needsConsent,
      ]),
      builder: (context, _) {
        if (bootstrapController.stage.value ==
            BootStage.ready) {
          return const AuthGate();
        }

        if (bootstrapController.error.value !=
            BootstrapError.none) {
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
          padding:
          const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety,
                  size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              ValueListenableBuilder<double>(
                valueListenable: bootstrapController.progress,
                builder: (context, value, _) =>
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                    ),
              ),
              const SizedBox(height: 16),
              const Text(
                "臨床引擎啟動中...",
                style:
                TextStyle(fontWeight: FontWeight.bold),
              ),
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
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(Icons.error,
                color: Colors.red, size: 60),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable:
              bootstrapController.errorMessage,
              builder: (context, message, _) =>
                  Text(message),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  bootstrapController.start(),
              child: const Text("重試"),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            globalSyncTask();
          });
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}