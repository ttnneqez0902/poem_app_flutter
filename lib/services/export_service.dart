import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/poem_record.dart';
import 'pdf_appendix_helper.dart';

// --- 臨床模型區 ---

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

class ScoreTrend {
  final String labelKey;
  final String displayLabel;
  final double delta;
  final double changeRate;
  final double slope;
  ScoreTrend({required this.labelKey, required this.displayLabel, required this.delta, required this.changeRate, required this.slope});
}

class WeeklyStat {
  final int week;
  final DateTime start; final DateTime end;
  final double avg; final int min; final int max;
  WeeklyStat({required this.week, required this.start, required this.end, required this.avg, required this.min, required this.max});
}

class ClinicalAlerts {
  final int rapidCount;
  final bool isStreakDetected;
  final int streakMagnitude;
  ClinicalAlerts({required this.rapidCount, required this.isStreakDetected, required this.streakMagnitude});
}

// --- 核心服務 ---

class ExportService {
  static const double _fsHeader = 16.0;
  static const double _fsTitle = 20.0;
  static const double _fsLarge = 36.0;

  // 🚀 優化 1：靜態變數緩存字體，避免重複加載佔用記憶體
  static pw.Font? _cachedFontTC;
  static pw.Font? _cachedBoldFontTC;
  static pw.Font? _cachedMathFont;
  static pw.Font? _cachedEmojiFont;

  // 🚀 優化 2：私有方法負責加載資源（僅在第一次執行時加載）
  static Future<void> _ensureResourcesLoaded() async {
  _cachedFontTC ??= pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansTC-Regular.ttf"));
  _cachedBoldFontTC ??= pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansTC-Bold.ttf"));
  _cachedMathFont ??= pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansMath-Regular.ttf"));
  _cachedEmojiFont ??= pw.Font.ttf(await rootBundle.load("assets/fonts/NotoColorEmoji-Regular.ttf"));
  }

  // 補齊所有缺失的 Key
  static Map<String, String> _getLabels(bool isEn) => {
    'report_title': isEn ? "Clinical Data Report" : "臨床數據報告",
    'anon_id': isEn ? "Patient ID (Anon)" : "患者編號 (匿名)",
    'obs_period': isEn ? "Observation Period" : "觀察區間",
    'trend_analysis': isEn ? "Trend Analysis" : "趨勢深度分析",
    'sample_size': isEn ? "Sample Size (N)" : "樣本數 (N)",
    'score_trend': isEn ? "Clinical Trend" : "病情趨勢",
    'change_mag': isEn ? "Magnitude" : "變化幅度",
    'cv': isEn ? "Variation (CV%)" : "變異係數 (CV%)",
    'rapid_event': isEn ? "Rapid Increases" : "急性發作事件",
    'clinical_alert': isEn ? "⚠️ CLINICAL ALERT" : "⚠️ 臨床警訊",
    'visual_title': isEn ? "Trend Visualization" : "病情趨勢視覺化",
    'weekly_summary': isEn ? "Weekly Summary" : "週期統計摘要",
    'stable': isEn ? "Stable" : "穩定趨勢",
    'improving': isEn ? "Improving" : "趨於改善",
    'worsening': isEn ? "Worsening" : "趨於惡化",
    'insufficient': isEn ? "N/A" : "數據不足",
    'week_prefix': isEn ? "Week " : "第 ",
    'week_suffix': isEn ? "" : " 週",
    'avg': isEn ? "Avg" : "平均值",
    'range': isEn ? "Range" : "範圍",
    'date': isEn ? "Date" : "日期",
    'score': isEn ? "Score" : "數值",
    'note': isEn ? "Clinical Notes" : "臨床紀錄",
  };

  // 🚀 [核心改動 1]：自動根據量表類型返回對應的臨床配置
  static ClinicalReportConfig _getConfigForScale(ScaleType type) {
    switch (type) {
      case ScaleType.adct:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 5, streakThreshold: 2, streakTotalIncrease: 4);
      case ScaleType.uas7:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 11, streakThreshold: 3, streakTotalIncrease: 9);
      case ScaleType.scorad:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 18, streakThreshold: 3, streakTotalIncrease: 15);
      case ScaleType.poem:
      default:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 7, streakThreshold: 3, streakTotalIncrease: 6);
    }
  }

  static Future<void> generateClinicalReport(
      List<PoemRecord> records,
      Uint8List? chartImageBytes,
      ScaleType targetScale, {
        ClinicalReportConfig? config, // 改為可選
        bool isEnglish = false,
      }) async {
    // 🚀 整體包覆 try-catch，確保任何資源加載或渲染錯誤不會導致 App 閃退
    try {
      // 🚀 [核心改動 2]：優先使用傳入的 config，若無則自動匹配
      final activeConfig = config ?? _getConfigForScale(targetScale); // 🚀 自動選取配置

      final labels = _getLabels(isEnglish);
      final dateFmt = isEnglish ? 'MMM dd, yyyy' : 'yyyy/MM/dd';

      final validRecords = records.where((r) =>
      (r.targetDate ?? r.date) != null &&
          r.scaleType == targetScale &&
          r.score != null
      ).toList();

      if (validRecords.isEmpty) return;

      validRecords.sort((a, b) => (a.targetDate ?? a.date!).compareTo((b.targetDate ?? b.date!)));

      final recentRecords = validRecords.where((r) =>
          (r.targetDate ?? r.date!).isAfter(DateTime.now().subtract(const Duration(days: 28)))
      ).toList();

      // 🚀 [核心改動 3]：傳入 targetScale 給分析方法
      final trend = _analyzeTrend(
          recentRecords.isEmpty ? validRecords : recentRecords,
          labels,
          targetScale // 👈 補上這個參數
      );
      final alerts = _calculateAlerts(validRecords, activeConfig);
      final cvText = recentRecords.length >= 3
          ? "${_calculateCV(recentRecords).toStringAsFixed(1)}%"
          : labels['insufficient']!;
      final weeklyStats = _buildWeeklyStats(validRecords);

      // 3. 資源加載：調用緩存機制，確保字體只加載一次且離線可用
      await _ensureResourcesLoaded();

      // 建立 PDF 主題，配置字體回退機制 (Fallback) 處理數學符號與 Emoji
      final reportTheme = pw.ThemeData.withFont(
        base: _cachedFontTC!,
        bold: _cachedBoldFontTC!,
        fontFallback: [_cachedMathFont!, _cachedEmojiFont!],
      );

      final pdf = pw.Document();
      final scaleMeta = _getScaleMetadata(targetScale, isEnglish);
      final photoCache = await _loadPhotoCache(validRecords);

      // --- Page 1: 封面與核心趨勢摘要 ---
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: reportTheme,
        build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderTitle(scaleMeta['title']!, labels['report_title']!),
              pw.Spacer(flex: 2),
              pw.Text(scaleMeta['full_name']!,
                  style: pw.TextStyle(fontSize: _fsLarge, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Divider(color: PdfColors.blue900, thickness: 2.5),
              pw.SizedBox(height: 20),
              _coverField(labels['anon_id']!, _generateAnonID(validRecords)),
              _coverField(labels['obs_period']!,
                  "${DateFormat(dateFmt).format(validRecords.first.targetDate ?? validRecords.first.date!)} - ${DateFormat(dateFmt).format(validRecords.last.targetDate ?? validRecords.last.date!)}"),
              pw.Spacer(flex: 1),
              _buildTrendSummary(targetScale, trend, cvText, alerts, activeConfig, recentRecords.length, labels, isEnglish),
              pw.Spacer(flex: 3),
              _buildDisclaimerBox(labels['clinical_alert']!, scaleMeta['disclaimer']!),
            ],
          ),
        ),
      ));

      // --- Page 2: 圖表趨勢視覺化與週期統計 ---
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: reportTheme,
        header: (context) => _buildPdfHeader(scaleMeta['title']!, context),
        build: (context) => [
          if (chartImageBytes != null) ...[
            pw.Text(labels['visual_title']!, style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 15),
            pw.Center(child: pw.Image(pw.MemoryImage(chartImageBytes), width: 450)),
            pw.SizedBox(height: 30),
          ],
          pw.Text(labels['weekly_summary']!, style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),
          _buildWeeklyTable(weeklyStats, labels),
        ],
      ));

      // --- Page 3+: 歷史明細紀錄 (含臨床照片與筆記) ---
      final reversedRecords = List<PoemRecord>.from(validRecords.reversed);
      for (int i = 0; i < reversedRecords.length; i += 6) {
        final chunk = reversedRecords.skip(i).take(6).toList();
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: reportTheme,
          build: (context) => pw.Column(children: [
            _buildPdfHeader(scaleMeta['title']!, context),
            _buildHistoryTable(chunk, photoCache, labels, dateFmt),
          ]),
        ));
      }

      // --- Appendix: 運算邏輯、公式說明與免責聲明 ---
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: reportTheme,
        header: (context) => _buildPdfHeader("${scaleMeta['title']} Appendix", context),
        build: (context) => [
          // 使用專屬 Helper 建立附錄內容，傳入快取的數學字體以渲染公式符號
          ...PdfAppendixHelper.buildAppendix(targetScale, activeConfig, _cachedMathFont!),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey600),
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
                "End of Report | Total Sample Size N=${validRecords.length}",
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)
            ),
          ),
        ],
      ));

      // 4. 生成二進制數據並啟動分享
      final bytes = await pdf.save();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/Report_${targetScale.name.toUpperCase()}.pdf');

      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);

    } catch (e) {
      // 輸出錯誤日誌以便除錯 (例如資產路徑錯誤或圖片解碼失敗)
      print("Clinical Report Export Error: $e");
      rethrow; // 拋出錯誤讓 UI 層能捕捉並顯示 SnackBar
    }
  }

  // --- 運算邏輯 ---

// 🚀 [核心改動 4]：修正方法簽名，加入 ScaleType type
  // 🚀 修正 1：補上 ScaleType type 參數定義
  static ScoreTrend _analyzeTrend(List<PoemRecord> sorted, Map<String, String> labels, ScaleType type) {
    if (sorted.length < 2) return ScoreTrend(labelKey: 'none', displayLabel: labels['insufficient']!, delta: 0, changeRate: 0, slope: 0);

    final scores = sorted.map((e) => (e.score ?? 0).toDouble()).toList();
    final mid = scores.length ~/ 2;
    final firstAvg = scores.sublist(0, mid).reduce((a, b) => a + b) / mid;
    final secondAvg = scores.sublist(mid).reduce((a, b) => a + b) / (scores.length - mid);

    final firstDate = sorted.first.targetDate ?? sorted.first.date!;

    // 🚀 修正 2：補上 xs 的計算，這對斜率運算至關重要
    final xs = sorted.map((r) => (r.targetDate ?? r.date!).difference(firstDate).inDays.toDouble()).toList();

    final double mx = xs.reduce((a, b) => a + b) / xs.length;
    final double my = scores.reduce((a, b) => a + b) / scores.length;
    double num = 0, den = 0;
    for (int i = 0; i < xs.length; i++) {
      num += (xs[i] - mx) * (scores[i] - my);
      den += pow(xs[i] - mx, 2);
    }
    final slope = den == 0 ? 0.0 : num / den;
    // 🚀 根據量表總分調整斜率門檻
    double worseningThreshold = 0.1;
    if (type == ScaleType.scorad) worseningThreshold = 0.3; // SCORAD 需更顯著的斜率才算惡化

    String key = (slope >= worseningThreshold) ? 'worsening' : (slope <= -worseningThreshold ? 'improving' : 'stable');

    return ScoreTrend(labelKey: key, displayLabel: labels[key]!, delta: secondAvg - firstAvg, changeRate: firstAvg > 0 ? ((secondAvg - firstAvg) / firstAvg) * 100 : 0, slope: slope);
  }
  static ClinicalAlerts _calculateAlerts(
      List<PoemRecord> sorted,
      ClinicalReportConfig config,
      ) {
    int rapid = 0;

    int currentStreak = 0;
    int currentIncrease = 0;

    int maxStreakLength = 0;
    int maxStreakIncrease = 0;

    for (int i = 1; i < sorted.length; i++) {
      final diff =
          (sorted[i].score ?? 0) - (sorted[i - 1].score ?? 0);

      // ✅ 急性惡化事件
      if (diff >= config.rapidIncreaseThreshold) {
        rapid++;
      }

      // ✅ 連續惡化偵測（保留「最嚴重的一段」）
      if (diff > 0) {
        currentStreak++;
        currentIncrease += diff;

        if (currentStreak > maxStreakLength ||
            (currentStreak == maxStreakLength &&
                currentIncrease > maxStreakIncrease)) {
          maxStreakLength = currentStreak;
          maxStreakIncrease = currentIncrease;
        }
      } else {
        currentStreak = 0;
        currentIncrease = 0;
      }
    }

    return ClinicalAlerts(
      rapidCount: rapid,
      isStreakDetected:
      maxStreakLength >= config.streakThreshold &&
          maxStreakIncrease >= config.streakTotalIncrease,
      streakMagnitude: maxStreakIncrease,
    );
  }


  // --- UI 組件 (已修正參數一致性) ---

  static pw.Widget _buildTrendSummary(ScaleType type, ScoreTrend t, String cv, ClinicalAlerts alerts, ClinicalReportConfig c, int n, Map<String, String> labels, bool isEn) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: const pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text("${type.name.toUpperCase()} ${labels['trend_analysis']}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.Text("${labels['sample_size']}: $n", style: const pw.TextStyle(fontSize: 10)),
        ]),
        pw.Divider(color: PdfColors.blue200),
        _trendRow(labels['score_trend']!, "${t.displayLabel} (Slope: ${t.slope.toStringAsFixed(2)} /day)", valueColor: t.labelKey == 'worsening' ? PdfColors.red700 : (t.labelKey == 'improving' ? PdfColors.green700 : null)),
        _trendRow(labels['change_mag']!, "${t.delta > 0 ? '↑ +' : '↓ '}${t.delta.toStringAsFixed(1)} pts (${t.changeRate.toStringAsFixed(1)}%)"),
        _trendRow(labels['cv']!, cv),
        _trendRow(
          isEn ? "Clinical Threshold" : "臨床警戒值",
            "≥ ${_getClinicalThreshold(type)} pts"
        ),
        _trendRow(labels['rapid_event']!, "${alerts.rapidCount} ${isEn ? 'Events' : '次'} (Limit: ${c.rapidIncreaseThreshold})"),

        if (alerts.isStreakDetected)
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 8), padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const pw.BoxDecoration(color: PdfColors.red100),
            child: pw.Text(isEn ? "Continuous Deterioration Alert (+${alerts.streakMagnitude} pts)" : "連續惡化警示 (累計增加 ${alerts.streakMagnitude} 分)", style: pw.TextStyle(color: PdfColors.red900, fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
      ]),
    );
  }

  static int _getClinicalThreshold(ScaleType t) {
    switch (t) {
      case ScaleType.uas7:
        return 5;
      case ScaleType.adct:
        return 7;
      case ScaleType.poem:
        return 17;
      case ScaleType.scorad:
        return 25;
      default:
        return 0;
    }
  }

  static pw.Widget _buildWeeklyTable(List<WeeklyStat> stats, Map<String, String> labels) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800), children: [
          _tableCell(labels['week_prefix']!, isHeader: true),
          _tableCell(labels['obs_period']!, isHeader: true),
          _tableCell(labels['avg']!, isHeader: true),
          _tableCell(labels['range']!, isHeader: true),
        ]),
        ...stats.map((s) => pw.TableRow(children: [
          _tableCell("${labels['week_prefix']}${s.week}${labels['week_suffix']}"),
          _tableCell("${DateFormat('MM/dd').format(s.start)} - ${DateFormat('MM/dd').format(s.end)}"),
          _tableCell(s.avg.toStringAsFixed(1), isBold: true),
          _tableCell("${s.min} - ${s.max}"),
        ])),
      ],
    );
  }

  static pw.Widget _buildHistoryTable(List<PoemRecord> chunk, Map<dynamic, Uint8List> photos, Map<String, String> labels, String dateFmt) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(90),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FlexColumnWidth()
      },
      children: [
        pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
          _tableCell(labels['date']!, isBold: true),
          _tableCell(labels['score']!, isBold: true),
          _tableCell(labels['note']!, isBold: true),
        ]),
        ...chunk.map((r) => pw.TableRow(children: [
          _tableCell(DateFormat(dateFmt).format(r.targetDate ?? r.date!)),
          _tableCell(r.score?.toString() ?? "-", isBold: true),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (r.note != null && r.note!.isNotEmpty) pw.Text(r.note!, style: const pw.TextStyle(fontSize: 12)),
            if (photos.containsKey(r.id)) pw.Padding(padding: const pw.EdgeInsets.only(top: 5), child: pw.Image(pw.MemoryImage(photos[r.id]!), height: 80)),
          ])),
        ])),
      ],
    );
  }

  // --- 輔助小組件 ---

  static pw.Widget _buildPdfHeader(String title, pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        "$title | Page ${context.pageNumber}",
        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
      ),
    );
  }


  static pw.Widget _buildHeaderTitle(String type, String title) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(title, style: const pw.TextStyle(fontSize: _fsHeader, color: PdfColors.grey800)), pw.Text(type, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))]);
  static pw.Widget _coverField(String l, String v) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.Row(children: [pw.SizedBox(width: 150, child: pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))), pw.Text(v)]));
  static pw.Widget _trendRow(String l, String v, {PdfColor? valueColor}) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Row(children: [pw.SizedBox(width: 140, child: pw.Text(l, style: const pw.TextStyle(fontSize: 12))), pw.Text(v, style: pw.TextStyle(fontSize: 12, color: valueColor, fontWeight: valueColor != null ? pw.FontWeight.bold : null))]));
  static pw.Widget _buildDisclaimerBox(String title, String msg) => pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)), pw.Text(msg, style: const pw.TextStyle(fontSize: 12))]));
  static pw.Widget _tableCell(String t, {bool isHeader = false, bool isBold = false}) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text(t, style: pw.TextStyle(color: isHeader ? PdfColors.white : PdfColors.black, fontSize: 12, fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : null))));

  static String _generateAnonID(List<PoemRecord> r) => "CL-${(r.fold<int>(0, (a, b) => a ^ b.id).abs() % 100000).toString().padLeft(5, '0')}";
  static double _calculateCV(List<PoemRecord> r) {
    final s = r.map((e) => (e.score ?? 0).toDouble()).toList();
    final m = s.reduce((a, b) => a + b) / s.length;
    if (m == 0) return 0.0;
    final sd = sqrt(s.map((x) => pow(x - m, 2)).reduce((a, b) => a + b) / (s.length - 1));
    return (sd / m) * 100;
  }

  static Future<Map<dynamic, Uint8List>> _loadPhotoCache(List<PoemRecord> records) async {
    final Map<dynamic, Uint8List> cache = {};
    for (var r in records) {
      if (r.imagePath != null && r.imagePath!.isNotEmpty && (r.imageConsent ?? true)) {
        final f = File(r.imagePath!);
        if (await f.exists()) cache[r.id] = await f.readAsBytes();
      }
    }
    return cache;
  }

  static Map<String, String> _getScaleMetadata(ScaleType t, bool isEn) {
    switch (t) {
      case ScaleType.adct: return {'title': 'ADCT', 'full_name': isEn ? 'ADCT: Atopic Dermatitis Control Tool' : 'ADCT 每周異膚控制量表', 'disclaimer': isEn ? 'Clinical alert threshold is 7 points.' : '臨床研究顯示 7 分為病情未控制之警示切點。'};
      case ScaleType.uas7: return {'title': 'UAS7', 'full_name': isEn ? 'UAS7: Urticaria Activity Score' : 'UAS7 每日蕁麻疹活性量表', 'disclaimer': isEn ? 'Weekly total ≥ 28 indicates severe urticaria activity.' : '週總分 ≥ 28 分通常代表蕁麻疹處於高度疾病活性狀態。'};
      case ScaleType.scorad:
        return {
          'title': 'SCORAD',
          'full_name': isEn ? 'SCORAD: Scoring Atopic Dermatitis' : 'SCORAD 異膚綜合嚴重程度評分',
          'disclaimer': isEn ? 'Total > 50 indicates severe disease.' : '臨床上總分超過 50 分代表目前處於重度異位性皮膚炎狀態。'
        };
      default: return {'title': 'POEM', 'full_name': isEn ? 'POEM: Patient-Oriented Eczema Measure' : 'POEM 每周濕疹檢測量表', 'disclaimer': isEn ? 'Total > 16 indicates severe eczema.' : '總分超過 16 分代表目前處於重度濕疹病灶。'};
    }
  }

  static List<WeeklyStat> _buildWeeklyStats(List<PoemRecord> records) {
    if (records.isEmpty) return [];
    final first = records.first.targetDate ?? records.first.date!;
    final start = DateTime(first.year, first.month, first.day);
    final stats = <WeeklyStat>[];
    for (int w = 0; w < (records.last.targetDate ?? records.last.date!).difference(start).inDays / 7 + 1; w++) {
      final wS = start.add(Duration(days: w * 7));
      final wE = wS.add(const Duration(days: 7));
      final wR = records.where((r) => (r.targetDate ?? r.date!).isAtSameMomentAs(wS) || ((r.targetDate ?? r.date!).isAfter(wS) && (r.targetDate ?? r.date!).isBefore(wE))).toList();
      if (wR.isNotEmpty) {
        final sc = wR.map((e) => e.score ?? 0).toList();
        stats.add(WeeklyStat(week: w + 1, start: wS, end: wE.subtract(const Duration(days: 1)), avg: sc.reduce((a, b) => a + b) / sc.length, min: sc.reduce((a, b) => a < b ? a : b), max: sc.reduce((a, b) => a > b ? a : b)));
      }
    }
    return stats;
  }
}