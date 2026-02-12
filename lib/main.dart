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
          return const HomeScreen();
        }
        // 否則，導向登入頁面
        return const LoginScreen();
      },
    );
  }
}