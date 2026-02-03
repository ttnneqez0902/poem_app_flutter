import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/isar_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

// 全域服務實例
final isarService = IsarService();
final notificationService = NotificationService();
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? 0;
  themeNotifier.value = ThemeMode.values[themeIndex];
  await isarService.db;
  await notificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'POEM 自我檢測',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.light,
          ),
          // 深色主題：特別優化高對比度
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
              surface: const Color(0xFF121212), // 底部背景
              onSurface: Colors.white, // 確保文字為純白
              // 針對選項卡片：使用較亮的灰色區分背景
              surfaceContainerLow: const Color(0xFF2C2C2C),
            ),
            // 修正錯誤：使用 CardThemeData 避開 PDF 套件衝突
            cardTheme: const CardThemeData(
              color: Color(0xFF2C2C2C),
              elevation: 0,
              margin: EdgeInsets.symmetric(vertical: 8),
            ),
            // 強度文字對比，確保問卷選項清晰
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Color(0xFFE0E0E0), fontSize: 16),
              bodyLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}