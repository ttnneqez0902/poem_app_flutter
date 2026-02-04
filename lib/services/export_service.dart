import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';

// ✅ Models
class PoemReportConfig {
  final int rapidIncreaseThreshold;
  final int streakThreshold;
  final int streakTotalIncrease;
  const PoemReportConfig({
    this.rapidIncreaseThreshold = 8,
    this.streakThreshold = 3,
    this.streakTotalIncrease = 6,
  });
}

class ScoreTrend {
  final String label;
  final double delta;
  final double changeRate;
  final double slope;
  ScoreTrend(this.label, this.delta, this.changeRate, this.slope);
}

class WeeklyStat {
  final int week;
  final DateTime start;
  final DateTime end;
  final double avg;
  final int min;
  final int max;
  WeeklyStat({required this.week, required this.start, required this.end, required this.avg, required this.min, required this.max});
}

class RapidIncreaseStat {
  final int count;
  final List<DateTime> dates;
  final int thresholdUsed;
  RapidIncreaseStat(this.count, this.dates, this.thresholdUsed);
}

class ConsecutiveIncreaseAlert {
  final bool detected;
  final int streak;
  final int totalIncrease;
  final DateTime? lastDate;
  ConsecutiveIncreaseAlert(this.detected, this.streak, this.totalIncrease, this.lastDate);
}

class DailySummary {
  final double avgItch;
  final double avgSleep;
  final int count;
  DailySummary({required this.avgItch, required this.avgSleep, required this.count});
}

class ExportService {
  static const double _fsTiny = 10.0;
  static const double _fsSmall = 12.0;
  static const double _fsBody = 14.0;
  static const double _fsHeader = 16.0;
  static const double _fsTitle = 20.0;
  static const double _fsLarge = 36.0;

  static Future<void> generatePoemReport(
      List<PoemRecord> records,
      Uint8List? chartImageBytes,
      {PoemReportConfig? config}
      ) async {
    final finalConfig = config ?? const PoemReportConfig();

    if (records.isEmpty) return;
    final validRecords = records.where((r) => r.date != null).toList();
    validRecords.sort((a, b) => a.date!.compareTo(b.date!));

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansTCRegular();
    final boldFont = await PdfGoogleFonts.notoSansTCBold();

    final weeklyRecords = validRecords.where((r) => r.type == RecordType.weekly).toList();
    final dailyRecords = validRecords.where((r) => r.type == RecordType.daily).toList();

    final cutoffDate = DateTime.now().subtract(const Duration(days: 28));
    final recentWeekly = weeklyRecords.where((r) => r.date!.isAfter(cutoffDate)).toList();

    final trend = _analyzeTrend(recentWeekly.length >= 2 ? recentWeekly : weeklyRecords);
    final cv = _calculateCV(recentWeekly.length >= 4 ? recentWeekly : weeklyRecords);
    final dailySum = _calculateDailySummary(dailyRecords);
    final weeklyStats = _buildWeeklyStats(weeklyRecords);
    final patientID = _generateAnonID(validRecords);
    final rapidIncreaseStat = _calculateRapidIncreases(recentWeekly, finalConfig);
    final consecutiveAlert = _detectConsecutiveIncreases(recentWeekly, finalConfig);

    Uint8List? logoBytes;
    try { logoBytes = (await rootBundle.load('assets/logo_clinic.png')).buffer.asUint8List(); } catch (_) {}
    final Map<dynamic, Uint8List> photoCache = {};
    for (var r in validRecords) {
      if (r.imagePath != null && r.imagePath!.isNotEmpty) {
        final file = File(r.imagePath!);
        if (await file.exists()) photoCache[r.id] = await file.readAsBytes();
      }
    }

    // --- Page 1: 封面與摘要 ---
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      build: (_) => pw.Container(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              if (logoBytes != null) pw.Image(pw.MemoryImage(logoBytes), height: 60) else pw.SizedBox(height: 60),
              pw.Text("Clinical Monitoring Report", style: const pw.TextStyle(fontSize: _fsHeader, color: PdfColors.grey800)),
            ]),
            pw.Spacer(),
            pw.Text("異位性皮膚炎追蹤報告", style: pw.TextStyle(fontSize: _fsLarge, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 12),
            pw.Text("Patient-Reported Outcome Visualization", style: const pw.TextStyle(fontSize: _fsHeader, color: PdfColors.grey800)),
            pw.Divider(color: PdfColors.blue900, thickness: 2.5),
            pw.SizedBox(height: 30),
            _coverField("Patient ID (Anonymized)", patientID),
            _coverField("Observation Period", "${DateFormat('yyyy/MM/dd').format(validRecords.first.date!)} - ${DateFormat('yyyy/MM/dd').format(validRecords.last.date!)}"),
            _coverField("Generated At", DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
            pw.SizedBox(height: 30),

            if (dailySum.count > 0) _buildDailySummaryBox(dailySum),
            _buildWeeklyTrendSummary(trend, cv, rapidIncreaseStat, consecutiveAlert, finalConfig),

            pw.Spacer(),
            _buildDisclaimerBox(),
          ],
        ),
      ),
    ));

    // --- Page 2: 圖表與數據表 ---
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      header: (context) => _buildPdfHeader(context),
      build: (context) => [
        if (chartImageBytes != null) ...[
          pw.Text("病情趨勢視覺化 (每日 vs 每週)", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),
          pw.Center(child: pw.Image(pw.MemoryImage(chartImageBytes), width: 480)),
          pw.SizedBox(height: 10),
          pw.Text("註：藍線為每週 POEM 總分 (0-28)，橘線為每日癢度 (0-10)。", style: const pw.TextStyle(fontSize: _fsTiny, color: PdfColors.grey800)),
        ],
        if (weeklyStats.isNotEmpty) ...[
          pw.SizedBox(height: 30),
          pw.Text("每週 POEM 統計摘要", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),
          _buildWeeklyTable(weeklyStats),
        ],
      ],
    ));

    // --- Page 3+: 歷史紀錄 ---
    final reversedRecords = List<PoemRecord>.from(validRecords.reversed);
    const int itemsPerPage = 8;
    for (int i = 0; i < reversedRecords.length; i += itemsPerPage) {
      final chunk = reversedRecords.skip(i).take(itemsPerPage).toList();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => pw.Column(children: [
          _buildPdfHeader(context),
          if (i == 0) pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text("歷史詳細紀錄表", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 15),
          _buildHistoryTable(chunk, photoCache),
          pw.Spacer(),
          pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("Page ${context.pageNumber}", style: const pw.TextStyle(fontSize: _fsTiny))),
        ]),
      ));
    }

    // --- Page Last: 附錄 (清楚定義版) ---
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      header: (context) => _buildPdfHeader(context),
      build: (context) => [
        pw.Text("Appendix: Methodology & Formulas", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text("Technical reference for calculation methods used in this report.", style: const pw.TextStyle(fontSize: _fsBody, color: PdfColors.grey800)),
        pw.SizedBox(height: 24),
        _buildThresholdConfigBox(finalConfig),
        pw.SizedBox(height: 24),
        _buildFormulaSection(
            title: "1. Score Trend (Linear Regression Slope)",
            formula: "Slope = Sum((x - mean_x) * (y - mean_y)) / Sum((x - mean_x)^2)",
            definitions: {"mean_x": "時間維度平均值", "mean_y": "POEM 總分平均值"},
            description: "使用最小平方法計算。Slope 代表平均每日分數變化量。負值表示病情趨向穩定，正值表示趨向嚴重。"
        ),
        _buildFormulaSection(
            title: "2. Score Variability (CV%)",
            formula: "CV% = (StdDev / Mean) * 100",
            definitions: {"StdDev": "評分期間標準差", "Mean": "評分期間平均分"},
            description: "用於衡量病情波動。百分比越低代表疾病控制越穩定，較不受評分絕對值高低的影響。"
        ),
        _buildFormulaSection(
            title: "3. Rapid Increase Event",
            formula: "Delta_Score = Current - Previous >= ${finalConfig.rapidIncreaseThreshold}",
            description: "識別急性發作 (Flare)。當兩次連續紀錄間的分數增幅超過門檻時觸發。"
        ),
        pw.Spacer(),
        pw.Divider(color: PdfColors.grey600),
        pw.Text("註：所有計算指標均由數學公式衍生，不具備自動臨床診斷功能。",
            style: pw.TextStyle(fontSize: _fsTiny, color: PdfColors.indigo900, fontWeight: pw.FontWeight.bold)),
      ],
    ));

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/POEM_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: '分享異位性皮膚炎追蹤報告');
  }

  // --- UI 元件 ---
  static pw.Widget _buildDailySummaryBox(DailySummary ds) {
    return pw.Container(padding: const pw.EdgeInsets.all(15), margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(color: PdfColors.orange50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text("每日症狀打卡摘要 (NRS 0-10)", style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
        pw.Divider(color: PdfColors.orange200, thickness: 1.5),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          _metricBox("平均搔癢程度", ds.avgItch.toStringAsFixed(1), PdfColors.orange800),
          _metricBox("平均睡眠影響", ds.avgSleep.toStringAsFixed(1), PdfColors.indigo800),
          _metricBox("總打卡天數", "${ds.count} 天", PdfColors.grey800),
        ]),
      ]),
    );
  }

  static pw.Widget _buildWeeklyTrendSummary(ScoreTrend t, double cv, RapidIncreaseStat r, ConsecutiveIncreaseAlert a, PoemReportConfig c) {
    return pw.Container(padding: const pw.EdgeInsets.all(20), decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.all(pw.Radius.circular(12))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text("POEM 每週趨勢分析 (Last 28 Days)", style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.Divider(color: PdfColors.blue200, thickness: 1.5),
        pw.SizedBox(height: 12),
        pw.Row(children: [pw.SizedBox(width: 200, child: pw.Text("Score Trend", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsBody))), pw.Text(t.label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsBody, color: _getTrendColor(t.label))), pw.Text(" (Slope: ${t.slope.toStringAsFixed(2)})", style: const pw.TextStyle(fontSize: _fsBody))]),
        _trendRow("Score Variability (CV%)", "${cv.toStringAsFixed(1)}%"),
        _trendRow("Rapid Increase Events", "${r.count} 次 (門檻: >=${c.rapidIncreaseThreshold} pts)", isThreshold: true),
        if (a.detected) pw.Padding(padding: const pw.EdgeInsets.only(top: 8, left: 200), child: pw.Text("Alert: 連續上升模式 (+${a.totalIncrease}分)", style: pw.TextStyle(fontSize: _fsBody, color: PdfColors.red800, fontWeight: pw.FontWeight.bold))),
      ]),
    );
  }

  static pw.Widget _buildWeeklyTable(List<WeeklyStat> stats) {
    return pw.TableHelper.fromTextArray(headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800), headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: _fsBody), cellAlignment: pw.Alignment.center,
        data: <List<dynamic>>[['Week', 'Date Range', 'Avg', 'Max', 'Min', 'Status'], ...stats.map((w) => ["Week ${w.week}", "${DateFormat('MM/dd').format(w.start)}-${DateFormat('MM/dd').format(w.end)}", w.avg.toStringAsFixed(1), w.max.toString(), w.min.toString(), (w.avg >= 17 || w.max >= 24) ? "高風險" : "-"])]);
  }

  static pw.Widget _buildHistoryTable(List<PoemRecord> chunk, Map<dynamic, Uint8List> photoCache) {
    return pw.Table(border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5), columnWidths: {0: const pw.FixedColumnWidth(90), 1: const pw.FixedColumnWidth(90), 2: const pw.FlexColumnWidth(1), 3: const pw.FixedColumnWidth(80)},
        children: [pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue900), children: [_tableCell("日期/類型", isHeader: true), _tableCell("評分詳情", isHeader: true), _tableCell("患部照片", isHeader: true), _tableCell("狀態", isHeader: true)]), ...chunk.map((r) {
          final isDaily = r.type == RecordType.daily;
          return pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle, children: [_tableCell("${DateFormat('MM/dd\nHH:mm').format(r.date!)}\n${isDaily ? '每日' : '每週'}"), _tableCell(isDaily ? "癢: ${r.dailyItch}\n睡: ${r.dailySleep}" : "POEM: ${r.totalScore}", isBold: true), pw.Container(height: 70, child: photoCache[r.id] != null ? pw.Image(pw.MemoryImage(photoCache[r.id]!), fit: pw.BoxFit.contain) : pw.Center(child: pw.Text("-"))), _tableCell(isDaily ? "紀錄" : r.severityLabel, color: isDaily ? PdfColors.black : _getSeverityColor(r.totalScore))]);
        })]);
  }

  static pw.Widget _buildFormulaSection({required String title, required String formula, required String description, Map<String, String>? definitions}) {
    return pw.Container(margin: const pw.EdgeInsets.only(bottom: 20), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(title, style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)), pw.SizedBox(height: 6), pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(10), decoration: const pw.BoxDecoration(color: PdfColors.grey100), child: pw.Text(formula, style: pw.TextStyle(font: pw.Font.courier(), fontSize: _fsSmall, fontWeight: pw.FontWeight.bold))), pw.SizedBox(height: 8), if (definitions != null) ...definitions.entries.map((e) => pw.Padding(padding: const pw.EdgeInsets.only(left: 10, bottom: 4), child: pw.Row(children: [pw.SizedBox(width: 110, child: pw.Text("• ${e.key}:", style: pw.TextStyle(fontSize: _fsSmall, fontWeight: pw.FontWeight.bold))), pw.Expanded(child: pw.Text(e.value, style: const pw.TextStyle(fontSize: _fsSmall)))]))), pw.Text(description, style: const pw.TextStyle(fontSize: _fsSmall, color: PdfColors.grey900))]));
  }

  static pw.Widget _buildThresholdConfigBox(PoemReportConfig config) {
    return pw.Container(padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text("Threshold Configuration", style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)), pw.Divider(color: PdfColors.blue200), _configRow("Rapid Increase Threshold", "${config.rapidIncreaseThreshold} pts"), _configRow("Consecutive Streak", "${config.streakThreshold} records"), _configRow("惡化總分門檻", "${config.streakTotalIncrease} pts")]));
  }

  // --- 計算邏輯與基礎組件 ---
  static DailySummary _calculateDailySummary(List<PoemRecord> dailyRecords) {
    if (dailyRecords.isEmpty) return DailySummary(avgItch: 0, avgSleep: 0, count: 0);
    final avgItch = dailyRecords.map((e) => e.dailyItch ?? 0).reduce((a, b) => a + b) / dailyRecords.length;
    final avgSleep = dailyRecords.map((e) => e.dailySleep ?? 0).reduce((a, b) => a + b) / dailyRecords.length;
    return DailySummary(avgItch: avgItch, avgSleep: avgSleep, count: dailyRecords.length);
  }

  static ScoreTrend _analyzeTrend(List<PoemRecord> sorted) {
    if (sorted.length < 2) return ScoreTrend("Insufficient Data", 0, 0, 0);
    final mid = sorted.length ~/ 2;
    final firstAvg = sorted.sublist(0, mid).map((e) => e.totalScore).reduce((a, b) => a + b) / mid;
    final secondAvg = sorted.sublist(mid).map((e) => e.totalScore).reduce((a, b) => a + b) / (sorted.length - mid);
    final start = sorted.first.date!;
    final xs = sorted.map((r) => r.date!.difference(start).inDays.toDouble()).toList();
    final ys = sorted.map((r) => r.totalScore.toDouble()).toList();
    final mx = xs.reduce((a, b) => a + b) / xs.length, my = ys.reduce((a, b) => a + b) / ys.length;
    double num = 0, den = 0;
    for (int i = 0; i < xs.length; i++) { num += (xs[i]-mx)*(ys[i]-my); den += (xs[i]-mx)*(xs[i]-mx); }
    final slope = den == 0 ? 0.0 : num / den;
    return ScoreTrend(slope <= -0.1 ? "Decreasing" : (slope >= 0.1 ? "Increasing" : "Stable"), secondAvg - firstAvg, (firstAvg >= 1 ? ((firstAvg - secondAvg) / firstAvg) * 100 : 0), slope);
  }

  static double _calculateCV(List<PoemRecord> records) {
    if (records.length < 4) return 0;
    final mean = records.map((e) => e.totalScore).reduce((a, b) => a + b) / records.length;
    if (mean == 0) return 0;
    final variance = records.map((e) => (e.totalScore - mean) * (e.totalScore - mean)).reduce((a, b) => a + b) / records.length;
    return (sqrt(variance) / mean) * 100;
  }

  static List<WeeklyStat> _buildWeeklyStats(List<PoemRecord> records) {
    if (records.isEmpty) return [];
    final start = DateTime(records.first.date!.year, records.first.date!.month, records.first.date!.day);
    final int weeksCount = (records.last.date!.difference(start).inDays / 7).ceil();
    final List<WeeklyStat> stats = [];
    for (int w = 0; w < weeksCount; w++) {
      final wStart = start.add(Duration(days: w * 7)), wEnd = wStart.add(const Duration(days: 7));
      final wRecords = records.where((r) => r.date!.isAfter(wStart.subtract(const Duration(seconds: 1))) && r.date!.isBefore(wEnd)).toList();
      if (wRecords.isNotEmpty) {
        final scores = wRecords.map((e) => e.totalScore).toList();
        stats.add(WeeklyStat(week: w + 1, start: wStart, end: wEnd.subtract(const Duration(days: 1)), avg: scores.reduce((a, b) => a + b) / scores.length, min: scores.reduce((a, b) => a < b ? a : b), max: scores.reduce((a, b) => a > b ? a : b)));
      }
    }
    return stats;
  }

  static RapidIncreaseStat _calculateRapidIncreases(List<PoemRecord> sorted, PoemReportConfig config) {
    int count = 0; final List<DateTime> dates = [];
    for (int i = 1; i < sorted.length; i++) {
      if ((sorted[i].totalScore - sorted[i-1].totalScore) >= config.rapidIncreaseThreshold) { count++; dates.add(sorted[i].date!); }
    }
    return RapidIncreaseStat(count, dates, config.rapidIncreaseThreshold);
  }

  static ConsecutiveIncreaseAlert _detectConsecutiveIncreases(List<PoemRecord> sorted, PoemReportConfig config) {
    int s = 0, ti = 0, ms = 0, mi = 0; DateTime? ld;
    for (int i = 1; i < sorted.length; i++) {
      final d = sorted[i].totalScore - sorted[i-1].totalScore;
      if (d > 0) { s++; ti += d; if (s > ms) { ms = s; mi = ti; ld = sorted[i].date!; } } else { s = 0; ti = 0; }
    }
    return ConsecutiveIncreaseAlert(ms >= config.streakThreshold && mi >= config.streakTotalIncrease, ms, mi, ld);
  }

  static pw.Widget _buildPdfHeader(pw.Context context) => pw.Column(children: [pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("異位性皮膚炎追蹤報告", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)), pw.Text("Page ${context.pageNumber}")]), pw.Divider(thickness: 1, color: PdfColors.blueGrey100), pw.SizedBox(height: 10)]);
  static pw.Widget _metricBox(String l, String v, PdfColor c) => pw.Column(children: [pw.Text(l, style: const pw.TextStyle(fontSize: _fsTiny)), pw.Text(v, style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: c))]);
  static pw.Widget _coverField(String l, String v) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 12), child: pw.Row(children: [pw.SizedBox(width: 200, child: pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800))), pw.Text(v)]));
  static pw.Widget _trendRow(String l, String v, {bool isThreshold = false}) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.Row(children: [pw.SizedBox(width: 200, child: pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsBody, color: isThreshold ? PdfColors.indigo900 : PdfColors.black))), pw.Text(v, style: pw.TextStyle(fontSize: _fsBody, fontWeight: isThreshold ? pw.FontWeight.bold : null, color: isThreshold ? PdfColors.indigo900 : PdfColors.black))]));
  static pw.Widget _configRow(String l, String v) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l, style: const pw.TextStyle(fontSize: _fsSmall)), pw.Text(v, style: pw.TextStyle(fontSize: _fsSmall, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900))]));
  static pw.Widget _tableCell(String t, {bool isHeader = false, bool isBold = false, PdfColor? color}) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text(t, textAlign: pw.TextAlign.center, style: pw.TextStyle(color: isHeader ? PdfColors.white : (color ?? PdfColors.black), fontSize: isHeader ? _fsSmall : _fsTiny, fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : null))));
  static pw.Widget _buildDisclaimerBox() => pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text("DISCLAIMER", style: pw.TextStyle(fontSize: _fsTiny, fontWeight: pw.FontWeight.bold)), pw.Text("本報告呈現患者紀錄之 POEM 分數與數據分析，僅供醫師臨床評估參考。", style: const pw.TextStyle(fontSize: _fsTiny))]));
  static PdfColor _getTrendColor(String l) => l == "Decreasing" ? PdfColors.green700 : (l == "Increasing" ? PdfColors.red700 : PdfColors.black);
  static PdfColor _getSeverityColor(int s) => s <= 2 ? PdfColors.blue700 : (s <= 7 ? PdfColors.green700 : (s <= 16 ? PdfColors.amber700 : (s <= 24 ? PdfColors.orange700 : PdfColors.red700)));
  static String _generateAnonID(List<PoemRecord> r) { final h = r.fold<int>(0, (a, b) => a ^ b.date!.millisecondsSinceEpoch); return "AD-${(h.abs() % 100000).toString().padLeft(5, '0')}"; }
}