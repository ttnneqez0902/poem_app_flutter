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
import 'pdf_appendix_helper.dart';

// ✅ 臨床配置模型
class ClinicalReportConfig {
  final int rapidIncreaseThreshold;
  final int streakThreshold;
  final int streakTotalIncrease;
  const ClinicalReportConfig({
    this.rapidIncreaseThreshold = 8,
    this.streakThreshold = 3,
    this.streakTotalIncrease = 6,
  });
}

// ✅ 統計模型 (包含復原的急性發作模型)
class ScoreTrend {
  final String label;
  final double delta;
  final double changeRate;
  final double slope;
  ScoreTrend(this.label, this.delta, this.changeRate, this.slope);
}

class WeeklyStat {
  final int week;
  final DateTime start; final DateTime end;
  final double avg; final int min; final int max;
  WeeklyStat({required this.week, required this.start, required this.end, required this.avg, required this.min, required this.max});
}

class RapidIncreaseStat {
  final int count; final List<DateTime> dates;
  RapidIncreaseStat(this.count, this.dates);
}

class ConsecutiveIncreaseAlert {
  final bool detected; final int totalIncrease;
  ConsecutiveIncreaseAlert(this.detected, this.totalIncrease);
}

class ExportService {
  static const double _fsTiny = 10.0;
  static const double _fsBody = 14.0;
  static const double _fsHeader = 16.0;
  static const double _fsTitle = 20.0;
  static const double _fsLarge = 36.0;

  static Future<void> generateClinicalReport(
      List<PoemRecord> records,
      Uint8List? chartImageBytes,
      ScaleType targetScale,
      {ClinicalReportConfig? config}
      ) async {
    final finalConfig = config ?? const ClinicalReportConfig();

    if (records.isEmpty) return;
    final validRecords = records.where((r) => r.date != null && r.scaleType == targetScale).toList();
    if (validRecords.isEmpty) return;
    validRecords.sort((a, b) => a.date!.compareTo(b.date!));

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansTCRegular();
    final boldFont = await PdfGoogleFonts.notoSansTCBold();

    final scaleMeta = _getScaleMetadata(targetScale);
    final cutoffDate = DateTime.now().subtract(const Duration(days: 28));
    final recentRecords = validRecords.where((r) => r.date!.isAfter(cutoffDate)).toList();

    // 🚀 數據統計與急性發作計算
    final trend = _analyzeTrend(recentRecords.length >= 2 ? recentRecords : validRecords);
    final cv = _calculateCV(recentRecords.length >= 4 ? recentRecords : validRecords);
    final rapidStat = _calculateRapidIncreases(recentRecords, finalConfig);
    final streakAlert = _detectConsecutiveIncreases(recentRecords, finalConfig);
    final weeklyStats = _buildWeeklyStats(validRecords);
    final patientID = _generateAnonID(validRecords);

    final Map<dynamic, Uint8List> photoCache = {};
    for (var r in validRecords) {
      if (r.imagePath != null && r.imagePath!.isNotEmpty && (r.imageConsent ?? true)) {
        final file = File(r.imagePath!);
        if (await file.exists()) photoCache[r.id] = await file.readAsBytes();
      }
    }

    // --- Page 1: 封面與復原的趨勢分析 ---
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      build: (_) => pw.Container(
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text("Clinical Monitoring Report", style: const pw.TextStyle(fontSize: _fsHeader, color: PdfColors.grey800)),
              pw.Text(scaleMeta['title']!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            ]),
            pw.Spacer(),
            pw.Text(scaleMeta['full_name']!, style: pw.TextStyle(fontSize: _fsLarge, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 12),
            pw.Text("Patient-Reported Outcome Visualization", style: const pw.TextStyle(fontSize: _fsHeader, color: PdfColors.grey800)),
            pw.Divider(color: PdfColors.blue900, thickness: 2.5),
            pw.SizedBox(height: 30),
            _coverField("Patient ID (Anon)", patientID),
            _coverField("觀察區間", "${DateFormat('yyyy/MM/dd').format(validRecords.first.date!)} - ${DateFormat('yyyy/MM/dd').format(validRecords.last.date!)}"),
            _coverField("產出時間", DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
            pw.SizedBox(height: 30),

            // 🚀 復原點：帶入趨勢與急性發作警示
            _buildTrendSummary(targetScale, trend, cv, rapidStat, streakAlert, finalConfig),

            pw.Spacer(),
            _buildDisclaimerBox(scaleMeta['disclaimer']!),
          ],
        ),
      ),
    ));

    // --- Page 2: 圖表與統計表 ---
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      header: (context) => _buildPdfHeader(scaleMeta['title']!, context),
      build: (context) => [
        if (chartImageBytes != null) ...[
          pw.Text("病情趨勢視覺化", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),
          pw.Center(child: pw.Image(pw.MemoryImage(chartImageBytes), width: 480)),
          pw.SizedBox(height: 10),
          pw.Text("註：顯示過去期間內 ${scaleMeta['title']} 總分之日/週波動。", style: const pw.TextStyle(fontSize: _fsTiny, color: PdfColors.grey800)),
        ],
        if (weeklyStats.isNotEmpty) ...[
          pw.SizedBox(height: 30),
          pw.Text("週期統計摘要", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),
          _buildWeeklyTable(targetScale, weeklyStats),
        ],
      ],
    ));

    // --- Page 3+: 歷史紀錄明細 (分頁邏輯) ---
    final reversedRecords = List<PoemRecord>.from(validRecords.reversed);
    const int itemsPerPage = 6; // 有照片時建議 6 筆一頁
    for (int i = 0; i < reversedRecords.length; i += itemsPerPage) {
      final chunk = reversedRecords.skip(i).take(itemsPerPage).toList();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => pw.Column(children: [
          _buildPdfHeader(scaleMeta['title']!, context),
          _buildHistoryTable(targetScale, chunk, photoCache),
          pw.Spacer(),
          pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("Page ${context.pageNumber}", style: const pw.TextStyle(fontSize: _fsTiny))),
        ]),
      ));
    }

    // --- Page Last: 附錄 (參數對接修正處) ---
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      build: (context) => pw.Column(children: [
        _buildPdfHeader(scaleMeta['title']!, context),
        // 🚀 核心修正：將 finalConfig 傳入 Helper
        ...PdfAppendixHelper.buildAppendix(targetScale, finalConfig),
      ]),
    ));

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${targetScale.name.toUpperCase()}_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: '分享${scaleMeta['title']}臨床數據報告');
  }

  // --- 🎨 UI 元件與統計方法 ---

  static pw.Widget _buildTrendSummary(ScaleType type, ScoreTrend t, double cv, RapidIncreaseStat r, ConsecutiveIncreaseAlert a, ClinicalReportConfig c) {
    return pw.Container(padding: const pw.EdgeInsets.all(20), decoration: const pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.all(pw.Radius.circular(12))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text("${type.name.toUpperCase()} 趨勢深度分析 (Last 28 Days)", style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.Divider(color: PdfColors.blue200, thickness: 1.5),
        pw.SizedBox(height: 12),
        pw.Row(children: [
          pw.SizedBox(width: 180, child: pw.Text("Score Trend", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsBody))),
          pw.Text(t.label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsBody, color: _getTrendColor(t.label))),
          pw.Text(" (Slope: ${t.slope.toStringAsFixed(2)})", style: const pw.TextStyle(fontSize: _fsBody))
        ]),
        _trendRow("變異係數 (CV%)", "${cv.toStringAsFixed(1)}%"),
        _trendRow("Rapid Increase Events", "${r.count} 次 (門檻: >=${c.rapidIncreaseThreshold} pts)", isThreshold: true),
        if (a.detected) pw.Padding(padding: const pw.EdgeInsets.only(top: 8, left: 180), child: pw.Text("Alert: 連續惡化模式 (+${a.totalIncrease}分)", style: pw.TextStyle(fontSize: _fsBody, color: PdfColors.red800, fontWeight: pw.FontWeight.bold))),
      ]),
    );
  }

  static pw.Widget _buildWeeklyTable(ScaleType type, List<WeeklyStat> stats) {
    return pw.TableHelper.fromTextArray(
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
        headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12),
        cellAlignment: pw.Alignment.center,
        data: <List<dynamic>>[
          ['週期', '日期範圍', '平均分', '最高分', '最低分', '臨床建議'],
          ...stats.map((w) {
            String advice = "-";
            if (type == ScaleType.adct && w.avg >= 7) advice = "建議回診";
            if (type == ScaleType.poem && w.avg >= 17) advice = "重度病灶";
            if (type == ScaleType.uas7 && w.avg >= 28) advice = "嚴重活性";
            return ["Week ${w.week}", "${DateFormat('MM/dd').format(w.start)}-${DateFormat('MM/dd').format(w.end)}", w.avg.toStringAsFixed(1), w.max.toString(), w.min.toString(), advice];
          })
        ]);
  }

  static pw.Widget _buildHistoryTable(ScaleType type, List<PoemRecord> chunk, Map<dynamic, Uint8List> photoCache) {
    return pw.Table(border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5), columnWidths: {0: const pw.FixedColumnWidth(90), 1: const pw.FixedColumnWidth(90), 2: const pw.FlexColumnWidth(1), 3: const pw.FixedColumnWidth(80)},
        children: [
          pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue900), children: [_tableCell("日期", isHeader: true), _tableCell("總分詳情", isHeader: true), _tableCell("患部照片", isHeader: true), _tableCell("分級判定", isHeader: true)]),
          ...chunk.map((r) {
            return pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle, children: [
              _tableCell(DateFormat('MM/dd\nHH:mm').format(r.date!)),
              _tableCell("${type.name.toUpperCase()}: ${r.score ?? 0}", isBold: true),
              pw.Container(height: 70, child: photoCache[r.id] != null ? pw.Image(pw.MemoryImage(photoCache[r.id]!), fit: pw.BoxFit.contain) : pw.Center(child: pw.Text("-"))),
              _tableCell(_getSeverityText(type, r.score ?? 0), color: _getSeverityColor(type, r.score ?? 0))
            ]);
          })
        ]);
  }

  // --- 🩺 計算與輔助方法 ---

  static RapidIncreaseStat _calculateRapidIncreases(List<PoemRecord> sorted, ClinicalReportConfig config) {
    int count = 0; final dates = <DateTime>[];
    for (int i = 1; i < sorted.length; i++) {
      if (((sorted[i].score ?? 0) - (sorted[i-1].score ?? 0)) >= config.rapidIncreaseThreshold) {
        count++; dates.add(sorted[i].date!);
      }
    }
    return RapidIncreaseStat(count, dates);
  }

  static ConsecutiveIncreaseAlert _detectConsecutiveIncreases(List<PoemRecord> sorted, ClinicalReportConfig config) {
    int s = 0, ti = 0, ms = 0, mi = 0;
    for (int i = 1; i < sorted.length; i++) {
      final d = (sorted[i].score ?? 0) - (sorted[i-1].score ?? 0);
      if (d > 0) { s++; ti += d; if (s > ms) { ms = s; mi = ti; } } else { s = 0; ti = 0; }
    }
    return ConsecutiveIncreaseAlert(ms >= config.streakThreshold && mi >= config.streakTotalIncrease, mi);
  }

  static ScoreTrend _analyzeTrend(List<PoemRecord> sorted) {
    if (sorted.length < 2) return ScoreTrend("數據不足", 0, 0, 0);
    final mid = sorted.length ~/ 2;
    final firstAvg = sorted.sublist(0, mid).map((e) => e.score ?? 0).reduce((a, b) => a + b) / mid;
    final secondAvg = sorted.sublist(mid).map((e) => e.score ?? 0).reduce((a, b) => a + b) / (sorted.length - mid);
    final start = sorted.first.date!;
    final xs = sorted.map((r) => r.date!.difference(start).inDays.toDouble()).toList();
    final ys = sorted.map((r) => (r.score ?? 0).toDouble()).toList();
    final mx = xs.reduce((a, b) => a + b) / xs.length, my = ys.reduce((a, b) => a + b) / ys.length;
    double num = 0, den = 0;
    for (int i = 0; i < xs.length; i++) { num += (xs[i]-mx)*(ys[i]-my); den += (xs[i]-mx)*(xs[i]-mx); }
    final slope = den == 0 ? 0.0 : num / den;
    return ScoreTrend(slope <= -0.1 ? "趨於穩定" : (slope >= 0.1 ? "趨於嚴重" : "穩定"), secondAvg - firstAvg, (firstAvg >= 1 ? ((firstAvg - secondAvg) / firstAvg) * 100 : 0), slope);
  }

  static double _calculateCV(List<PoemRecord> records) {
    if (records.length < 4) return 0;
    final scores = records.map((e) => (e.score ?? 0).toDouble()).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    if (mean == 0) return 0;
    final variance = scores.map((s) => pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
    return (sqrt(variance) / mean) * 100;
  }

  static Map<String, String> _getScaleMetadata(ScaleType t) {
    switch (t) {
      case ScaleType.adct:
        return {
          'title': 'ADCT',
          'full_name': 'ADCT 每周異膚控制報告', // 🚀 對接：每周異膚控制
          'disclaimer': 'ADCT 評估異位性皮膚炎控制狀況，7分為臨床警戒切點'
        };
      case ScaleType.uas7:
        return {
          'title': 'UAS7',
          'full_name': 'UAS7 每日蕁麻疹量表報告', // 🚀 對接：每日蕁麻疹量表
          'disclaimer': 'UAS7 紀錄每日蕁麻疹活性，週總分 28 分以上為嚴重活性'
        };
      case ScaleType.scorad:
        return {
          'title': 'SCORAD',
          'full_name': 'SCORAD 每周異膚綜合報告', // 🚀 對接：每周異膚綜合
          'disclaimer': '呈現患者異位性皮膚炎之主觀感官與臨床綜合評分'
        };
      default: // ScaleType.poem
        return {
          'title': 'POEM',
          'full_name': 'POEM 每周濕疹檢測報告', // 🚀 對接：每周濕疹檢測
          'disclaimer': '評估濕疹症狀出現頻率，週總分 17 分以上為重度病灶'
        };
    }
  }

  static String _getSeverityText(ScaleType t, int s) {
    if (t == ScaleType.adct) return s >= 7 ? "控制不佳" : "控制良好";
    if (t == ScaleType.uas7) return s >= 28 ? "嚴重" : (s >= 16 ? "中度" : "輕微");
    return s >= 17 ? "重度" : (s >= 8 ? "中度" : "中輕度");
  }

  static PdfColor _getSeverityColor(ScaleType t, int s) {
    if (t == ScaleType.adct) return s >= 7 ? PdfColors.red700 : PdfColors.green700;
    return s >= 17 ? PdfColors.red700 : (s >= 8 ? PdfColors.orange700 : PdfColors.green700);
  }

  static List<WeeklyStat> _buildWeeklyStats(List<PoemRecord> records) {
    if (records.isEmpty) return [];
    final start = DateTime(records.first.date!.year, records.first.date!.month, records.first.date!.day);
    final days = records.last.date!.difference(start).inDays;
    final int weeksCount = (days / 7).ceil() + 1;
    final stats = <WeeklyStat>[];
    for (int w = 0; w < weeksCount; w++) {
      final wStart = start.add(Duration(days: w * 7)), wEnd = wStart.add(const Duration(days: 7));
      final wRecords = records.where((r) => r.date!.isAfter(wStart.subtract(const Duration(seconds: 1))) && r.date!.isBefore(wEnd)).toList();
      if (wRecords.isNotEmpty) {
        final scores = wRecords.map((e) => e.score ?? 0).toList();
        stats.add(WeeklyStat(week: w + 1, start: wStart, end: wEnd.subtract(const Duration(days: 1)), avg: scores.reduce((a, b) => a + b) / scores.length, min: scores.reduce((a, b) => a < b ? a : b), max: scores.reduce((a, b) => a > b ? a : b)));
      }
    }
    return stats;
  }

  static pw.Widget _buildPdfHeader(String title, pw.Context context) => pw.Column(children: [pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("$title 臨床數據報告", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)), pw.Text("Page ${context.pageNumber}")]), pw.Divider(thickness: 1, color: PdfColors.blueGrey100), pw.SizedBox(height: 10)]);
  static pw.Widget _coverField(String l, String v) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 12), child: pw.Row(children: [pw.SizedBox(width: 180, child: pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800))), pw.Text(v)]));
  static pw.Widget _trendRow(String l, String v, {bool isThreshold = false}) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.Row(children: [pw.SizedBox(width: 180, child: pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: isThreshold ? PdfColors.indigo900 : PdfColors.black))), pw.Text(v, style: pw.TextStyle(fontSize: 12, fontWeight: isThreshold ? pw.FontWeight.bold : null, color: isThreshold ? PdfColors.indigo900 : PdfColors.black))]));
  static pw.Widget _tableCell(String t, {bool isHeader = false, bool isBold = false, PdfColor? color}) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text(t, textAlign: pw.TextAlign.center, style: pw.TextStyle(color: isHeader ? PdfColors.white : (color ?? PdfColors.black), fontSize: isHeader ? 11 : 10, fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : null))));
  static pw.Widget _buildDisclaimerBox(String msg) => pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text("臨床免責聲明", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)), pw.Text(msg, style: const pw.TextStyle(fontSize: 10))]));
  static PdfColor _getTrendColor(String l) => l == "趨於穩定" ? PdfColors.green700 : (l == "趨於嚴重" ? PdfColors.red700 : PdfColors.black);
  static String _generateAnonID(List<PoemRecord> r) { final h = r.fold<int>(0, (a, b) => a ^ b.date!.millisecondsSinceEpoch); return "CL-${(h.abs() % 100000).toString().padLeft(5, '0')}"; }
}