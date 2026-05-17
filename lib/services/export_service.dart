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
import '../models/poem_record.dart'; // 確保路徑正確
import 'pdf_appendix_helper.dart';   // 確保路徑正確

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
  ScoreTrend({
    required this.labelKey,
    required this.displayLabel,
    required this.delta,
    required this.changeRate,
    required this.slope,
  });
}

class WeeklyStat {
  final int week;
  final DateTime start;
  final DateTime end;
  final double avg;
  final int min;
  final int max;
  WeeklyStat({
    required this.week,
    required this.start,
    required this.end,
    required this.avg,
    required this.min,
    required this.max,
  });
}

class ClinicalAlerts {
  final int rapidCount;
  final bool isStreakDetected;
  final int streakMagnitude;
  ClinicalAlerts({
    required this.rapidCount,
    required this.isStreakDetected,
    required this.streakMagnitude,
  });
}

// --- 核心服務 ---

class ExportService {
  static const double _fsHeader = 16.0;
  static const double _fsTitle = 20.0;
  static const double _fsLarge = 36.0;

  static pw.Font? _cachedFontTC;
  static pw.Font? _cachedBoldFontTC;
  static pw.Font? _cachedMathFont;
  static pw.Font? _cachedEmojiFont;

  static Future<void> _ensureResourcesLoaded() async {
    _cachedFontTC ??= pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansTC-Regular.ttf"));
    _cachedBoldFontTC ??= pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansTC-Bold.ttf"));
    _cachedMathFont ??= pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansMath-Regular.ttf"));
    _cachedEmojiFont ??= pw.Font.ttf(await rootBundle.load("assets/fonts/NotoColorEmoji-Regular.ttf"));
  }

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

  static ClinicalReportConfig _getConfigForScale(ScaleType type) {
    switch (type) {
      case ScaleType.phq9:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 5, streakThreshold: 2, streakTotalIncrease: 5);
      case ScaleType.gad7:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 4, streakThreshold: 2, streakTotalIncrease: 4);
      case ScaleType.vas:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 3, streakThreshold: 2, streakTotalIncrease: 3);
      case ScaleType.adct:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 5, streakThreshold: 2, streakTotalIncrease: 4);
      case ScaleType.uas7:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 11, streakThreshold: 3, streakTotalIncrease: 9);
      case ScaleType.scorad:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 18, streakThreshold: 3, streakTotalIncrease: 15);
      case ScaleType.isi: // 失眠嚴重度
        return const ClinicalReportConfig(rapidIncreaseThreshold: 7, streakThreshold: 2, streakTotalIncrease: 8);
      case ScaleType.psqi: // 睡眠品質
        return const ClinicalReportConfig(rapidIncreaseThreshold: 3, streakThreshold: 2, streakTotalIncrease: 4);
      case ScaleType.bp_log: // 血壓 (收縮壓跳動)
        return const ClinicalReportConfig(rapidIncreaseThreshold: 20, streakThreshold: 3, streakTotalIncrease: 25);
      case ScaleType.cat: // 慢阻肺
        return const ClinicalReportConfig(rapidIncreaseThreshold: 5, streakThreshold: 2, streakTotalIncrease: 6);
      case ScaleType.poem:
      default:
        return const ClinicalReportConfig(rapidIncreaseThreshold: 7, streakThreshold: 3, streakTotalIncrease: 6);
    }
  }

  static Future<void> generateClinicalReport(
      List<PoemRecord> records,
      Uint8List? chartImageBytes,
      ScaleType targetScale, {
        ClinicalReportConfig? config,
        bool isEnglish = false,
        String? growthMode,
      }) async {
    try {
      final activeConfig = config ?? _getConfigForScale(targetScale);
      final labels = _getLabels(isEnglish);
      final dateFmt = isEnglish ? 'MMM dd, yyyy' : 'yyyy/MM/dd';

      // --- 1. 數據過濾與分流 (正確關閉 where 括號) ---
      final validRecords = records.where((r) {
        final date = r.targetDate ?? r.date;
        if (date == null || r.scaleType != targetScale) return false;

        if (targetScale == ScaleType.growth) {
          if (growthMode == 'weight') return r.weight != null;
          if (growthMode == 'head') return r.headCircumference != null;
          return r.height != null;
        }
        if (targetScale == ScaleType.bp_log) return r.systolic != null;
        return r.score != null;
      }).toList();

      if (validRecords.isEmpty) return;

      // --- 2. 數據副本處理 (防止 Side-effect，確保不改動原始 score) ---
      // 我們建立一組「報表專用紀錄」，這樣改動 score 不會影響到 App 畫面顯示
      final reportRecords = validRecords.map((r) {
        // 複製關鍵欄位
        final tempScore = (targetScale == ScaleType.growth)
            ? (growthMode == 'weight' ? r.weight : (growthMode == 'head' ? r.headCircumference : r.height))?.toInt()
            : (targetScale == ScaleType.bp_log ? r.systolic : r.score);

        return PoemRecord()
          ..id = r.id
          ..date = r.date
          ..targetDate = r.targetDate
          ..scaleType = r.scaleType
          ..score = tempScore ?? 0
          ..systolic = r.systolic
          ..diastolic = r.diastolic
          ..pulse = r.pulse
          ..height = r.height
          ..weight = r.weight
          ..headCircumference = r.headCircumference
          ..note = r.note
          ..imagePath = r.imagePath
          ..imageConsent = r.imageConsent;
      }).toList();

      // 排序副本
      reportRecords.sort((a, b) => (a.targetDate ?? a.date!).compareTo((b.targetDate ?? b.date!)));

      // 取得近 28 天數據進行趨勢分析
      final recentRecords = reportRecords.where((r) =>
          (r.targetDate ?? r.date!).isAfter(DateTime.now().subtract(const Duration(days: 28)))).toList();

      // 使用副本進行分析與計算
      final trend = _analyzeTrend(recentRecords.isEmpty ? reportRecords : recentRecords, labels, targetScale);
      final alerts = _calculateAlerts(reportRecords, activeConfig);
      final cvText = recentRecords.length >= 3
          ? "${_calculateCV(recentRecords).toStringAsFixed(1)}%"
          : labels['insufficient']!;
      final weeklyStats = _buildWeeklyStats(reportRecords);

      // --- 3. PDF 頁面構建 ---
      await _ensureResourcesLoaded();

      final reportTheme = pw.ThemeData.withFont(
        base: _cachedFontTC!,
        bold: _cachedBoldFontTC!,
        fontFallback: [_cachedMathFont!, _cachedEmojiFont!],
      );

      final pdf = pw.Document();
      final scaleMeta = _getScaleMetadata(targetScale, isEnglish, growthMode);
      final photoCache = await _loadPhotoCache(validRecords); // 照片快取使用原始紀錄 ID 即可

      // --- Page 1: 封面與摘要 ---
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
              pw.Text(scaleMeta['full_name']!, style: pw.TextStyle(fontSize: _fsLarge, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Divider(color: PdfColors.blue900, thickness: 2.5),
              pw.SizedBox(height: 20),
              _coverField(labels['anon_id']!, _generateAnonID(reportRecords)),
              _coverField(labels['obs_period']!, "${DateFormat(dateFmt).format(reportRecords.first.targetDate ?? reportRecords.first.date!)} - ${DateFormat(dateFmt).format(reportRecords.last.targetDate ?? reportRecords.last.date!)}"),
              pw.Spacer(flex: 1),
              // 🚀 傳入 reportRecords 進行風險判斷
              _buildTrendSummary(targetScale, trend, cvText, alerts, activeConfig, reportRecords.length, labels, isEnglish, growthMode, reportRecords),
              pw.Spacer(flex: 3),
              _buildDisclaimerBox(labels['clinical_alert']!, scaleMeta['disclaimer']!),
            ],
          ),
        ),
      ));

      // --- Page 2: 圖表與統計 ---
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

      // --- Page 3+: 歷史明細 (由副本生成) ---
      final reversedRecords = List<PoemRecord>.from(reportRecords.reversed);
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

      // --- Appendix ---
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: reportTheme,
        header: (context) => _buildPdfHeader("${scaleMeta['title']} Appendix", context),
        build: (context) => [
          ...PdfAppendixHelper.buildAppendix(targetScale, activeConfig, _cachedMathFont!),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey600),
          pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text("End of Report | Total Sample Size N=${reportRecords.length}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500))),
        ],
      ));

      // --- 4. 生成檔案與分享 (專業命名邏輯) ---
      final bytes = await pdf.save();
      final directory = await getTemporaryDirectory();

      final String anonId = _generateAnonID(reportRecords);
      final String scaleLabel = targetScale.name.toUpperCase();
      final String dateStamp = DateFormat('yyyyMMdd').format(DateTime.now());

      // 生成你要的格式：CareSync_[患者ID]_[量表名稱]_20260328.pdf
      final String fileName = "CareSync_${anonId}_${scaleLabel}_$dateStamp.pdf";
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: isEnglish ? 'Clinical Data Report' : '臨床數據報告');

    } catch (e) {
      print("Clinical Report Export Error: $e");
      rethrow;
    }
  }

  // --- 運算邏輯 ---

  static ScoreTrend _analyzeTrend(List<PoemRecord> sorted, Map<String, String> labels, ScaleType type) {
    if (sorted.length < 2) return ScoreTrend(labelKey: 'none', displayLabel: labels['insufficient']!, delta: 0, changeRate: 0, slope: 0);

    final scores = sorted.map((e) => (e.score ?? 0).toDouble()).toList();
    final mid = scores.length ~/ 2;
    final firstAvg = scores.sublist(0, mid).reduce((a, b) => a + b) / mid;
    final secondAvg = scores.sublist(mid).reduce((a, b) => a + b) / (scores.length - mid);

    final firstDate = sorted.first.targetDate ?? sorted.first.date!;
    final xs = sorted.map((r) => (r.targetDate ?? r.date!).difference(firstDate).inDays.toDouble()).toList();

    final double mx = xs.reduce((a, b) => a + b) / xs.length;
    final double my = scores.reduce((a, b) => a + b) / scores.length;
    double num = 0, den = 0;
    for (int i = 0; i < xs.length; i++) {
      num += (xs[i] - mx) * (scores[i] - my);
      den += pow(xs[i] - mx, 2);
    }
    final slope = den == 0 ? 0.0 : num / den;
    bool isGrowth = type == ScaleType.growth;

// 🚀 關鍵優化：血壓的斜率門檻要放寬 (1.0 代表每天跳動 1 mmHg)
    double worseningThreshold = (type == ScaleType.bp_log) ? 1.0 : 0.1;
    if (type == ScaleType.scorad) worseningThreshold = 0.3;
    if (type == ScaleType.vas) worseningThreshold = 0.05;

    String key;
    if (isGrowth) {
      key = (slope <= -worseningThreshold) ? 'worsening' : (slope >= worseningThreshold ? 'improving' : 'stable');
    } else {
      key = (slope >= worseningThreshold) ? 'worsening' : (slope <= -worseningThreshold ? 'improving' : 'stable');
    }

    return ScoreTrend(
        labelKey: key,
        displayLabel: labels[key]!,
        delta: secondAvg - firstAvg,
        changeRate: firstAvg > 0 ? ((secondAvg - firstAvg) / firstAvg) * 100 : 0,
        slope: slope
    );
  }

  static ClinicalAlerts _calculateAlerts(List<PoemRecord> sorted, ClinicalReportConfig config) {
    int rapid = 0;
    int currentStreak = 0;
    int currentIncrease = 0;
    int maxStreakLength = 0;
    int maxStreakIncrease = 0;

    for (int i = 1; i < sorted.length; i++) {
      final diff = (sorted[i].score ?? 0) - (sorted[i - 1].score ?? 0);
      if (diff >= config.rapidIncreaseThreshold) rapid++;

      if (diff > 0) {
        currentStreak++;
        currentIncrease += diff;
        if (currentStreak > maxStreakLength || (currentStreak == maxStreakLength && currentIncrease > maxStreakIncrease)) {
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
      isStreakDetected: maxStreakLength >= config.streakThreshold && maxStreakIncrease >= config.streakTotalIncrease,
      streakMagnitude: maxStreakIncrease,
    );
  }

  static String? _getClinicalRiskText(ScaleType type, List<PoemRecord> records, bool isEn) {
    if (records.isEmpty) return null;
    final last = records.last;
    if (type == ScaleType.bp_log) {
      final sys = last.systolic ?? 0;
      final dia = last.diastolic ?? 0;
      if (sys >= 140 || dia >= 90) return isEn ? "BP Risk Observed (High)" : "觀察到高血壓風險";
      // 🚀 合併後的簡潔邏輯
      if (sys > 0 && (sys < 90 || dia < 60)) return isEn ? "BP Risk Observed (Low)" : "觀察到低血壓風險";
    }
    if ((type == ScaleType.phq9 || type == ScaleType.gad7) && (last.score ?? 0) >= 10) {
      return isEn ? "Mental Health Care Needed" : "情緒狀況需留意";
    }
    return null;
  }

  static int _getClinicalThreshold(ScaleType t) {
    switch (t) {
      case ScaleType.psqi: return 5;
      case ScaleType.isi: return 15;
      case ScaleType.bp_log: return 140;
      case ScaleType.phq9: return 10;
      case ScaleType.gad7: return 10;
      case ScaleType.vas: return 7;
      case ScaleType.cat: return 10; // 🚀 補上 CAT 的臨床警戒門檻
      case ScaleType.uas7: return 5;
      case ScaleType.adct: return 7;
      case ScaleType.poem: return 17;
      case ScaleType.scorad: return 25;
      default: return 0;
    }
  }

  // --- UI 組件 ---

  static pw.Widget _buildTrendSummary(ScaleType type, ScoreTrend t, String cv, ClinicalAlerts alerts, ClinicalReportConfig c, int n, Map<String, String> labels, bool isEn, String? growthMode, List<PoemRecord> validRecords) {
    final unit = _getUnit(type, growthMode);
    final riskText = _getClinicalRiskText(type, validRecords, isEn);

    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: const pw.BoxDecoration(color: PdfColors.blue50, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text("${type.name.toUpperCase()} ${labels['trend_analysis']}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          if (riskText != null)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: const pw.BoxDecoration(color: PdfColors.amber100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Text(riskText, style: pw.TextStyle(color: PdfColors.amber900, fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
        ]),
        pw.Divider(color: PdfColors.blue200),

        // 🚀 使用 labels 取代硬編碼文字
// 🚀 優化 1：標註斜率單位
        _trendRow(labels['score_trend']!, "${t.displayLabel} (Slope: ${t.slope.toStringAsFixed(2)} /day)",
            valueColor: t.labelKey == 'worsening' ? PdfColors.red700 : (t.labelKey == 'improving' ? PdfColors.green700 : null)),

        if (type == ScaleType.bp_log)
          _trendRow(isEn ? "Latest Value" : "最新量測值", "${validRecords.last.systolic}/${validRecords.last.diastolic} $unit")
        else
          _trendRow(labels['change_mag']!, "${t.delta > 0 ? '↑ +' : '↓ '}${t.delta.toStringAsFixed(1)} $unit"),

        _trendRow(labels['cv']!, "$cv (${labels['sample_size']}: $n)"),
        _trendRow(labels['sample_size']!, "$n"), // 🚀 把樣本數放進來，醫師比較好判斷趨勢可信度

        // 🚀 補回臨床警報顯示
        if (type != ScaleType.growth) ...[
          _trendRow(labels['rapid_event']!, "${alerts.rapidCount} ${isEn ? 'Times' : '次'}"),
          if (alerts.isStreakDetected)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 8), padding: const pw.EdgeInsets.all(6),
              decoration: const pw.BoxDecoration(color: PdfColors.red100),
              child: pw.Text(isEn ? "⚠️ Deterioration Trend Detected" : "⚠️ 偵測到連續惡化趨勢", style: pw.TextStyle(color: PdfColors.red900, fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
        ],
      ]),
    );
  }

  static pw.Widget _buildHistoryTable(List<PoemRecord> chunk, Map<dynamic, Uint8List> photos, Map<String, String> labels, String dateFmt) {
    final bool isEn = labels['report_title']!.contains("Clinical");

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {0: const pw.FixedColumnWidth(90), 1: const pw.FixedColumnWidth(115), 2: const pw.FlexColumnWidth()},
      children: [
        pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey200), children: [
          _tableCell(labels['date']!, isBold: true), _tableCell(labels['score']!, isBold: true), _tableCell(labels['note']!, isBold: true),
        ]),
        ...chunk.map((r) {
          bool isAbnormal = false;
          String valText = "";

          if (r.scaleType == ScaleType.bp_log) {
            valText = "${r.systolic ?? '-'}/${r.diastolic ?? '-'} mmHg";
            if (r.pulse != null) valText += "\n(${r.pulse} bpm)";
            final sys = r.systolic ?? 0;
            final dia = r.diastolic ?? 0;
            if (sys >= 140 || dia >= 90 || (sys > 0 && sys < 90)) isAbnormal = true;
          }
          else if (r.scaleType == ScaleType.growth) {
            if (r.height != null) valText = "${r.height} cm";
            else if (r.weight != null) valText = "${r.weight} kg";
            else if (r.headCircumference != null) valText = "${r.headCircumference} cm";
          }
          else if (r.scaleType == ScaleType.bristol) {
            valText = isEn ? "Type ${r.score}" : "第 ${r.score} 型";
          }
          else {
            valText = "${r.score}${isEn ? " pts" : " 分"}";
          }

          return pw.TableRow(
            decoration: isAbnormal ? const pw.BoxDecoration(color: PdfColors.red50) : null,
            children: [
              _tableCell(DateFormat(dateFmt).format(r.targetDate ?? r.date!)),
              _tableCell(valText, isBold: true, textColor: isAbnormal ? PdfColors.red900 : null),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  if (r.note != null && r.note!.isNotEmpty) pw.Text(r.note!, style: const pw.TextStyle(fontSize: 9)),
                  if (photos.containsKey(r.id)) pw.Padding(padding: const pw.EdgeInsets.only(top: 5), child: pw.Image(pw.MemoryImage(photos[r.id]!), height: 90, fit: pw.BoxFit.contain)),
                ]),
              ),
            ],
          );
        }),
      ],
    );
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

  // --- 輔助工具 ---

  static pw.Widget _buildPdfHeader(String title, pw.Context context) => pw.Container(
    alignment: pw.Alignment.centerRight,
    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
    margin: const pw.EdgeInsets.only(bottom: 20),
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Text("$title | Page ${context.pageNumber}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
  );

  static pw.Widget _buildHeaderTitle(String type, String title) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(title, style: const pw.TextStyle(fontSize: _fsHeader, color: PdfColors.grey800)), pw.Text(type, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))]);
  static pw.Widget _coverField(String l, String v) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.Row(children: [pw.SizedBox(width: 150, child: pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))), pw.Text(v)]));
  static pw.Widget _trendRow(String l, String v, {PdfColor? valueColor}) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Row(children: [pw.SizedBox(width: 140, child: pw.Text(l, style: const pw.TextStyle(fontSize: 12))), pw.Text(v, style: pw.TextStyle(fontSize: 12, color: valueColor, fontWeight: valueColor != null ? pw.FontWeight.bold : null))]));
  static pw.Widget _buildDisclaimerBox(String title, String msg) => pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)), pw.Text(msg, style: const pw.TextStyle(fontSize: 12))]));
  static pw.Widget _tableCell(String t, {bool isHeader = false, bool isBold = false, PdfColor? textColor}) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Center(child: pw.Text(t, style: pw.TextStyle(color: isHeader ? PdfColors.white : (textColor ?? PdfColors.black), fontSize: 10, fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : null))));

  static String _generateAnonID(List<PoemRecord> r) => "CL-${(r.fold<int>(0, (a, b) => a ^ b.id.hashCode).abs() % 100000).toString().padLeft(5, '0')}";
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

  static Map<String, String> _getScaleMetadata(ScaleType t, bool isEn, String? growthMode) {
    if (t == ScaleType.growth) {
      String name = growthMode == 'weight' ? (isEn ? "Weight" : "體重") : (growthMode == 'head' ? (isEn ? "Head" : "頭圍") : (isEn ? "Height" : "身高"));
      return {
        'title': isEn ? 'Growth: $growthMode' : '生長數據: $name',
        'full_name': isEn ? 'WHO Growth Standards' : 'WHO 兒童生長發育標準',
        'disclaimer': isEn ? 'Compared against WHO standard percentiles.' : '生長數據建議與 WHO 標準百分位曲線對照。'
      };
    }
    switch (t) {
      case ScaleType.uas7: // 🚀 補上 UAS7
        return {
          'title': 'UAS7',
          'full_name': isEn ? 'Urticaria Activity Score' : 'UAS7 每日蕁麻疹活性量表',
          'disclaimer': isEn ? 'Weekly total ≥ 28 indicates severe activity.' : '週總分 ≥ 28 分通常代表蕁麻疹處於高度疾病活性。'
        };
      case ScaleType.bristol: // 🚀 補上腸胃科
        return {'title': 'Bristol', 'full_name': isEn ? 'Bristol Stool Form Scale' : '布里斯托大便分類法', 'disclaimer': isEn ? 'Types 3-4 are considered ideal.' : '第 3, 4 型為理想狀態。'};
      case ScaleType.cat: // 🚀 補上英文翻譯
        return {
          'title': 'CAT',
          'full_name': isEn ? 'COPD Assessment Test' : 'CAT 慢阻肺評估測試',
          'disclaimer': isEn ? 'Higher scores indicate greater impact of COPD.' : '分數越高代表呼吸道症狀影響越大。'
        };
      case ScaleType.isi:
        return {
          'title': 'ISI',
          'full_name': isEn ? 'Insomnia Severity Index' : 'ISI 失眠嚴重度量表',
          'disclaimer': isEn ? 'Score ≥ 15 indicates clinical insomnia.' : '總分 ≥ 15 分代表臨床顯著失眠。'
        };
      case ScaleType.psqi: return {'title': 'PSQI', 'full_name': isEn ? 'Pittsburgh Sleep Quality Index' : 'PSQI 匹茲堡睡眠品質指數', 'disclaimer': isEn ? 'Global score > 5 indicates poor sleep.' : '總分 > 5 分代表睡眠品質欠佳。'};
      case ScaleType.bp_log: return {'title': 'Blood Pressure', 'full_name': isEn ? 'Blood Pressure Log' : '血壓與心率監測紀錄', 'disclaimer': isEn ? 'Target BP is usually < 130/80 mmHg.' : '血壓控制目標通常建議在 130/80 mmHg 以下。'};
      case ScaleType.phq9: return {'title': 'PHQ-9', 'full_name': isEn ? 'PHQ-9: Patient Health Questionnaire' : 'PHQ-9 憂鬱情緒篩檢量表', 'disclaimer': isEn ? 'Score ≥ 10 suggests moderate depression.' : '總分 ≥ 10 分建議尋求專業諮詢。'};
      case ScaleType.vas: return {'title': 'VAS', 'full_name': isEn ? 'Visual Analogue Scale' : 'VAS 疼痛視覺類比量表', 'disclaimer': isEn ? 'Score ≥ 7 indicates severe pain.' : '數值 ≥ 7 分通常代表重度疼痛。'};
      case ScaleType.adct: return {'title': 'ADCT', 'full_name': isEn ? 'ADCT Weekly Tool' : 'ADCT 每周異膚控制量表', 'disclaimer': isEn ? 'Score ≥ 7 indicates poor control.' : '7 分為病情未控制之警示切點。'};
      case ScaleType.scorad: return {'title': 'SCORAD', 'full_name': isEn ? 'Scoring Atopic Dermatitis' : 'SCORAD 異膚綜合嚴重程度評分', 'disclaimer': isEn ? 'Total > 50 indicates severe disease.' : '總分超過 50 分代表目前處於重度狀態。'};
      default: return {'title': 'CareSync', 'full_name': isEn ? 'Clinical Report' : '臨床數據報告', 'disclaimer': ''};
    }
  }

  static String _getUnit(ScaleType type, String? growthMode) {
    if (type == ScaleType.growth) return growthMode == 'weight' ? "kg" : "cm";
    if (type == ScaleType.bp_log) return "mmHg";
    if (type == ScaleType.bristol) return "型";
    return "pts";
  }

  static List<WeeklyStat> _buildWeeklyStats(List<PoemRecord> records) {
    if (records.isEmpty) return [];
    final first = records.first.targetDate ?? records.first.date!;
    final start = DateTime(first.year, first.month, first.day);
    final stats = <WeeklyStat>[];
    final lastDate = records.last.targetDate ?? records.last.date!;
    int weekCount = (lastDate.difference(start).inDays / 7).ceil() + 1;

    for (int w = 0; w < weekCount; w++) {
      final wS = start.add(Duration(days: w * 7));
      final wE = wS.add(const Duration(days: 7));
      final wR = records.where((r) {
        final d = r.targetDate ?? r.date!;
        return (d.isAtSameMomentAs(wS) || (d.isAfter(wS) && d.isBefore(wE)));
      }).toList();

      if (wR.isNotEmpty) {
        final sc = wR.map((e) => e.score ?? 0).toList();
        stats.add(WeeklyStat(
            week: w + 1,
            start: wS,
            end: wE.subtract(const Duration(days: 1)),
            avg: sc.reduce((a, b) => a + b) / sc.length,
            min: sc.reduce((a, b) => a < b ? a : b),
            max: sc.reduce((a, b) => a > b ? a : b)
        ));
      }
    }
    stats.sort((a, b) => a.week.compareTo(b.week));
    return stats;
  }
}