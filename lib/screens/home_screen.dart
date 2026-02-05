import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'poem_survey_screen.dart';
import 'trend_chart_screen.dart';
import 'history_list_screen.dart';
import 'daily_check_in_screen.dart';
import '../main.dart'; // 引用全域服務
import '../models/poem_record.dart'; // 引用資料模型
import '../widgets/uas7_tracker_card.dart'; // 🚀 引用新開發的進度卡片組件

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 📍 提醒與主題狀態
  bool _isReminderOn = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // --- 🚀 核心邏輯：計算 UAS7 週期完成度 ---
  // 此邏輯確保第一次做會算成 D1，符合七日累計定義
  Future<Map<String, dynamic>> _getUas7Status() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 6));

    // 1. 從 Isar 抓取過去 7 天的所有量表紀錄
    final allRecords = await isarService.getRecordsInRange(sevenDaysAgo, now);

    // 2. 僅過濾出 UAS7 類型的紀錄
    final uas7Records = allRecords.where((r) => r.scaleType == ScaleType.uas7).toList();

    // 3. 檢查今天是否已經完成過紀錄
    bool isTodayDone = uas7Records.any((r) =>
    r.date!.year == now.year &&
        r.date!.month == now.month &&
        r.date!.day == now.day
    );

    return {
      'completedCount': uas7Records.length, // 累計完成天數 (1~7)，決定點亮幾顆球
      'isTodayDone': isTodayDone,           // 決定標題文字與圖示狀態
    };
  }

  // --- ⚙️ 設定持久化邏輯 ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isReminderOn = prefs.getBool('isReminderOn') ?? false;
      int hour = prefs.getInt('reminderHour') ?? 21;
      int minute = prefs.getInt('reminderMinute') ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isReminderOn', _isReminderOn);
    await prefs.setInt('reminderHour', _selectedTime.hour);
    await prefs.setInt('reminderMinute', _selectedTime.minute);
  }

  Future<void> _updateTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    themeNotifier.value = mode;
  }

  Future<void> _updateReminder() async {
    await notificationService.requestPermissions();
    await notificationService.scheduleDailyReminder(
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
    );
  }

  // --- 🎨 UI 建構 ---

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("皮膚健康管理"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? null : Colors.blue.shade50,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 📍 1. 臨床進度卡片：動態顯示 UAS7 完成度
            // 使用 FutureBuilder 確保資料庫查詢完畢後才渲染
            FutureBuilder<Map<String, dynamic>>(
              future: _getUas7Status(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 160);

                final data = snapshot.data!;
                return Uas7TrackerCard(
                  completedCount: data['completedCount'],
                  isTodayDone: data['isTodayDone'],
                );
              },
            ),

            const SizedBox(height: 10),
            Text(
              "症狀紀錄與追蹤",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // 📍 2. 主要導航按鈕區
            _buildNavigationMenu(context),

            const SizedBox(height: 30),
            const Divider(),

            // 📍 3. 下方設定與偏好區塊
            _buildSettingsSection(context, isDarkMode),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildMenuButton(
            context,
            "開始自我檢測",
            Icons.add_task,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PoemSurveyScreen())),
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            context,
            "每日快速打卡",
            Icons.today,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyCheckInScreen())),
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            context,
            "查看趨勢圖表",
            Icons.show_chart,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrendChartScreen())),
          ),
          const SizedBox(height: 16),
          _buildMenuButton(
            context,
            "歷史紀錄列表",
            Icons.history,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryListScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, _) {
            return ListTile(
              leading: const Icon(Icons.palette_outlined, color: Colors.blue),
              title: const Text("外觀主題設定"),
              onTap: _showThemePickerDialog,
            );
          },
        ),
        ListTile(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime);
            if (picked != null) {
              setState(() => _selectedTime = picked);
              await _saveSettings();
              if (_isReminderOn) await _updateReminder();
            }
          },
          leading: Icon(
              _isReminderOn ? Icons.notifications_active : Icons.notifications_off,
              color: _isReminderOn ? Colors.blue : Colors.grey
          ),
          title: const Text("每日提醒時間"),
          subtitle: Text("目前設定：${_selectedTime.format(context)}"),
          trailing: Switch(
            value: _isReminderOn,
            onChanged: (bool value) async {
              if (value) {
                await _updateReminder();
              } else {
                await notificationService.cancelAll();
              }
              setState(() => _isReminderOn = value);
              await _saveSettings();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 1,
        ),
      ),
    );
  }

  void _showThemePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("選擇外觀模式"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
                title: const Text("跟隨系統"),
                value: ThemeMode.system,
                groupValue: themeNotifier.value,
                onChanged: (mode) { _updateTheme(mode!); Navigator.pop(context); }
            ),
            RadioListTile<ThemeMode>(
                title: const Text("淺色模式"),
                value: ThemeMode.light,
                groupValue: themeNotifier.value,
                onChanged: (mode) { _updateTheme(mode!); Navigator.pop(context); }
            ),
            RadioListTile<ThemeMode>(
                title: const Text("深色模式"),
                value: ThemeMode.dark,
                groupValue: themeNotifier.value,
                onChanged: (mode) { _updateTheme(mode!); Navigator.pop(context); }
            ),
          ],
        ),
      ),
    );
  }
}