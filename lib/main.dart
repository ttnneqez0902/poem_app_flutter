import 'package:flutter/material.dart';
import 'controllers/bootstrap_controller.dart';
import 'services/isar_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/consent_screen.dart';

// ✅ 全域實例 (確保其他 Screen 能透過 import '../main.dart' 存取)
final isarService = IsarService();
final notificationService = NotificationService();
final bootstrapController = BootstrapController();
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  bootstrapController.start();
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
        if (bootstrapController.stage.value == BootStage.ready) return const HomeScreen();
        if (bootstrapController.error.value != BootstrapError.none) return _buildErrorUI();
        if (bootstrapController.needsConsent.value) return const ConsentScreen();
        return _buildLoadingUI();
      },
    );
  }

  Widget _buildLoadingUI() {
    return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.health_and_safety, size: 80, color: Colors.blue),
      const SizedBox(height: 24),
      LinearProgressIndicator(value: bootstrapController.progress.value, minHeight: 6),
      const SizedBox(height: 16),
      const Text("臨床引擎啟動中...", style: TextStyle(fontWeight: FontWeight.bold)),
    ])));
  }

  Widget _buildErrorUI() {
    return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error, color: Colors.red, size: 60),
      Text(bootstrapController.errorMessage.value),
      ElevatedButton(onPressed: () => bootstrapController.start(), child: const Text("重試")),
    ])));
  }
}