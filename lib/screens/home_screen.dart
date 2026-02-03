import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'poem_survey_screen.dart';
import 'trend_chart_screen.dart';
import 'history_list_screen.dart';
import '../main.dart'; // 引用全域 notificationService 與 themeNotifier
// ✂️ 已移除 ExportService 的引用

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isReminderOn = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // --- 資料持久化邏輯 ---

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

  // --- 主題切換邏輯 ---

  Future<void> _updateTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    themeNotifier.value = mode;
  }

  // --- 提醒功能邏輯 ---

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
      await _saveSettings();
      if (_isReminderOn) await _updateReminder();
    }
  }

  Future<void> _updateReminder() async {
    await notificationService.requestPermissions();
    await notificationService.scheduleDailyReminder(
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
    );
  }

  // --- UI 建構 ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("POEM 自我檢測"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? null
            : Colors.blue.shade50,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.health_and_safety, size: 100, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              "濕疹症狀追蹤",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // 主要功能按鈕區
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildMenuButton(
                    context,
                    "開始新的檢測",
                    Icons.add_task,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PoemSurveyScreen())),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    context,
                    "查看趨勢圖表",
                    Icons.show_chart,
                    // 這裡進入 TrendChartScreen 後，右上角有新的 PDF 匯出功能
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
            ),

            const SizedBox(height: 30),
            const Divider(),

            // 設定區塊：主題與提醒
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                return ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Colors.blue),
                  title: const Text("外觀主題設定"),
                  subtitle: Text(_getThemeName(currentMode)),
                  onTap: _showThemePickerDialog,
                );
              },
            ),

            ListTile(
              onTap: _pickTime,
              leading: Icon(
                _isReminderOn ? Icons.notifications_active : Icons.notifications_off,
                color: _isReminderOn ? Colors.blue : Colors.grey,
              ),
              title: const Text("每日提醒時間"),
              subtitle: Text("目前設定：${_selectedTime.format(context)} (點擊可修改)"),
              trailing: Switch(
                value: _isReminderOn,
                onChanged: (bool value) async {
                  if (value) {
                    bool hasPermission = await notificationService.checkExactAlarmPermission();
                    if (!hasPermission) {
                      if (!mounted) return;
                      _showPermissionDialog();
                      return;
                    }
                    await _updateReminder();
                  } else {
                    await notificationService.cancelAll();
                  }
                  setState(() => _isReminderOn = value);
                  await _saveSettings();
                },
              ),
            ),

            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => notificationService.showInstantNotification(),
              icon: const Icon(Icons.vibration),
              label: const Text("測試通知功能"),
            ),
            const SizedBox(height: 40), // 底部留白
          ],
        ),
      ),
    );
  }

  // --- 輔助組件與對話框 ---

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
          elevation: 2,
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
              title: const Text("跟隨系統設定"),
              value: ThemeMode.system,
              groupValue: themeNotifier.value,
              onChanged: (mode) { _updateTheme(mode!); Navigator.pop(context); },
            ),
            RadioListTile<ThemeMode>(
              title: const Text("淺色模式"),
              value: ThemeMode.light,
              groupValue: themeNotifier.value,
              onChanged: (mode) { _updateTheme(mode!); Navigator.pop(context); },
            ),
            RadioListTile<ThemeMode>(
              title: const Text("深色模式"),
              value: ThemeMode.dark,
              groupValue: themeNotifier.value,
              onChanged: (mode) { _updateTheme(mode!); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return "跟隨系統";
      case ThemeMode.light: return "淺色模式";
      case ThemeMode.dark: return "深色模式";
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm_on, color: Colors.blue),
            SizedBox(width: 10),
            Text("需要鬧鐘權限"),
          ],
        ),
        content: const Text("為了確保 POEM 檢測提醒能準時發送，請在系統設定中開啟「鬧鐘與提醒」權限。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("稍後再說")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              notificationService.requestPermissions();
            },
            child: const Text("前往設定"),
          ),
        ],
      ),
    );
  }
}