import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'poem_survey_screen.dart';
import 'trend_chart_screen.dart';
import 'history_list_screen.dart';
import '../main.dart';
import '../models/poem_record.dart';
import '../widgets/uas7_tracker_card.dart';
import '../widgets/weekly_tracker_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🚀 支援四項量表無限滑動 (UAS7, ADCT, POEM, SCORAD)
  final PageController _pageController = PageController(initialPage: 400);
  ScaleType _selectedScaleTask = ScaleType.adct;

  @override
  void initState() {
    super.initState();
  }

  // --- 🚀 核心數據邏輯：計算各量表狀態與 UAS7 日期鎖定 ---
  Future<Map<String, dynamic>> _getTrackerData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allRecords = await isarService.getAllRecords();

    // 1. UAS7 邏輯：鎖定 7 天週期的起始日
    final uas7Records = allRecords.where((r) => r.scaleType == ScaleType.uas7).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));

    DateTime uas7Start;
    if (uas7Records.isEmpty) {
      uas7Start = today;
    } else {
      final firstDate = uas7Records.first.date!;
      final DateTime firstDayStart = DateTime(firstDate.year, firstDate.month, firstDate.day);
      int offset = (today.difference(firstDayStart).inDays / 7).floor() * 7;
      uas7Start = firstDayStart.add(Duration(days: offset));
    }

    return {
      'uas7Start': uas7Start,
      'uas7Status': List.generate(7, (i) => uas7Records.any((r) =>
      r.date!.year == uas7Start.add(Duration(days: i)).year &&
          r.date!.day == uas7Start.add(Duration(days: i)).day)),
      'adct': allRecords.where((r) => r.scaleType == ScaleType.adct).toList()..sort((a,b) => b.date!.compareTo(a.date!)),
      'poem': allRecords.where((r) => r.scaleType == ScaleType.poem).toList()..sort((a,b) => b.date!.compareTo(a.date!)),
      'scorad': allRecords.where((r) => r.scaleType == ScaleType.scorad).toList()..sort((a,b) => b.date!.compareTo(a.date!)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          title: const Text("皮膚健康管理", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: isDarkMode ? null : Colors.blue.shade50
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildElderlyFriendlyDropdown(),
            const SizedBox(height: 20),
            _buildLargeNavigationMenu(context),
            const SizedBox(height: 24),
            const Divider(),
            _buildSwiperHeader(),
            SizedBox(
              height: 265,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _getTrackerData(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final data = snapshot.data!;
                  return PageView.builder(
                    controller: _pageController,
                    itemBuilder: (context, index) {
                      final mode = index % 4; // 🚀 四卡片循環
                      if (mode == 0) return Uas7TrackerCard(startDate: data['uas7Start'], completionStatus: data['uas7Status']);
                      if (mode == 1) return WeeklyTrackerCard(type: ScaleType.adct, history: data['adct']);
                      if (mode == 2) return WeeklyTrackerCard(type: ScaleType.poem, history: data['poem']);
                      return WeeklyTrackerCard(type: ScaleType.scorad, history: data['scorad']);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildElderlyFriendlyDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade200, width: 2)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ScaleType>(
            value: _selectedScaleTask,
            isExpanded: true,
            icon: const Icon(Icons.arrow_circle_down_rounded, color: Colors.blue, size: 30),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            items: [
              DropdownMenuItem(value: ScaleType.adct, child: const Text("ADCT 每週控制評估")),
              DropdownMenuItem(value: ScaleType.poem, child: const Text("POEM 每週濕疹評估")),
              DropdownMenuItem(value: ScaleType.uas7, child: const Text("UAS7 每日活性紀錄")),
              DropdownMenuItem(value: ScaleType.scorad, child: const Text("SCORAD 綜合評分")),
            ],
            onChanged: (val) => setState(() => _selectedScaleTask = val!),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeNavigationMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(children: [
        _buildLargeMenuButton(context, "開始自我檢測", Icons.play_circle_fill_rounded, Colors.blue.shade700,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => PoemSurveyScreen(initialType: _selectedScaleTask)))),
        const SizedBox(height: 16),
        _buildLargeMenuButton(context, "查看趨勢圖表", Icons.bar_chart_rounded, Colors.teal.shade700,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrendChartScreen()))),
        const SizedBox(height: 16),
        _buildLargeMenuButton(context, "歷史紀錄列表", Icons.list_alt_rounded, Colors.blueGrey.shade700,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryListScreen()))),
      ]),
    );
  }

  Widget _buildLargeMenuButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(width: double.infinity, height: 85, child: ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: color, elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), side: BorderSide(color: color.withOpacity(0.3), width: 1.5)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 34), const SizedBox(width: 16), Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))])));
  }

  Widget _buildSwiperHeader() => const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Row(children: [Icon(Icons.auto_awesome, size: 20, color: Colors.orangeAccent), SizedBox(width: 8), Text("臨床進度週期追蹤", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]));
}