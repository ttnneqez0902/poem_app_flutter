import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 🚀 核心修正 1：引入自動產生的檔案
import 'firebase_options.dart';

import 'controllers/bootstrap_controller.dart';
import 'services/isar_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🚀 補上

// ✅ 全域實例
final isarService = IsarService();
final notificationService = NotificationService();
final bootstrapController = BootstrapController();
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 核心修正 2：使用 FlutterFire 產生的 options 初始化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 建議將 bootstrap 啟動放在 runApp 之前或裡面
  // 確保初始化邏輯正確跑完
  bootstrapController.start();

  runApp(const MyApp());
}

bool _isSyncingGlobal = false; // 全域旗標
// 🚀 新增：全域同步方法，供 AuthGate 或各個 Screen 調用
// 這裡直接複用你之前寫在 SurveyScreen 裡的邏輯，但放在全域更方便
Future<void> globalSyncTask() async {
  if (_isSyncingGlobal) return; // 如果正在跑，就不要重複進來
  _isSyncingGlobal = true;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // 1. 抓取所有未同步資料
    final unsynced = await isarService.getUnsyncedRecords(user.uid);
    if (unsynced.isEmpty) return;

    debugPrint("🚀 [啟動同步] 發現 ${unsynced.length} 筆未備份資料，開始自動補傳...");

    // 2. 按月份打包 (JSON 打包法)
    Map<String, List<dynamic>> groupedData = {};
    Map<String, List<int>> groupedIds = {};

    for (var rec in unsynced) {
      String monthKey = "${rec.targetDate?.year}_${rec.targetDate?.month.toString().padLeft(2, '0')}";
      groupedData.putIfAbsent(monthKey, () => []).add(rec.toFirestore());
      groupedIds.putIfAbsent(monthKey, () => []).add(rec.id);
    }

    // 3. 執行 Firestore 寫入
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

      // 4. 更新本地標記
      await isarService.markAsSynced(groupedIds[monthKey]!);
    }
    debugPrint("✅ [啟動同步] 自動補漏完成");
  } catch (e) {
    debugPrint("❌ [啟動同步] 失敗: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: '皮膚健康追蹤',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
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
        // 當 Bootstrap 完成後，進入驗證邏輯
        if (bootstrapController.stage.value == BootStage.ready) {
          return const AuthGate();
        }

        if (bootstrapController.error.value != BootstrapError.none) return _buildErrorUI();
        if (bootstrapController.needsConsent.value) return const ConsentScreen();
        return _buildLoadingUI();
      },
    );
  }

  Widget _buildLoadingUI() {
    return Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.health_and_safety, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        ValueListenableBuilder<double>(
          valueListenable: bootstrapController.progress,
          builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 6),
        ),
        const SizedBox(height: 16),
        const Text("臨床引擎啟動中...", style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
    )));
  }

  Widget _buildErrorUI() {
    return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error, color: Colors.red, size: 60),
      const SizedBox(height: 16),
      ValueListenableBuilder<String>(
        valueListenable: bootstrapController.errorMessage,
        builder: (context, message, _) => Text(message),
      ),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: () => bootstrapController.start(), child: const Text("重試")),
    ])));
  }
}

// 驗證大門 (AuthGate)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 檢查連線狀態，避免在讀取時瞬間跳轉
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 如果有資料，代表已登入
        if (snapshot.hasData) {
          // 🚀 核心優化：當檢測到已登入，立即在背景啟動一次「補漏同步」
          // 這會處理那些上次因為未達 2 筆而沒上傳的資料
          globalSyncTask();

          return const HomeScreen();
        }
        // 否則，導向登入頁面
        return const LoginScreen();
      },
    );
  }
}