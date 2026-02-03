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
  final int streakThresholdUsed;
  final int totalThresholdUsed;
  ConsecutiveIncreaseAlert(this.detected, this.streak, this.totalIncrease, this.lastDate, this.streakThresholdUsed, this.totalThresholdUsed);
}

class ExportService {
  // 🎨 字體大小常數
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

    if (records.isEmpty) {
      debugPrint("❌ [ExportService] No records to export.");
      return;
    }

    final pdf = pw.Document();

    // 載入字型
    final font = await PdfGoogleFonts.notoSansTCRegular();
    final boldFont = await PdfGoogleFonts.notoSansTCBold();

    debugPrint("📄 [DEBUG] PDF 接收到圖片大小: ${chartImageBytes?.length} bytes");

    Uint8List? logoBytes;
    try {
      final logo = await rootBundle.load('assets/logo_clinic.png');
      logoBytes = logo.buffer.asUint8List();
    } catch (e) {
      debugPrint("⚠️ Logo not found, skipping.");
    }

    // 圖片預載
    final Map<dynamic, Uint8List> photoCache = {};
    for (var record in records) {
      if (record.imagePath != null && record.imagePath!.isNotEmpty) {
        try {
          final file = File(record.imagePath!);
          if (await file.exists()) {
            photoCache[record.id] = await file.readAsBytes();
          }
        } catch (e) {
          debugPrint("❌ Error loading photo: $e");
        }
      }
    }

    records.sort((a, b) => a.date.compareTo(b.date));

    // 限制範圍：最近 28 天
    final cutoffDate = DateTime.now().subtract(const Duration(days: 28));
    final recentRecords = records.where((r) => r.date.isAfter(cutoffDate)).toList();
    final analysisRecords = recentRecords.length >= 2 ? recentRecords : records;

    final trend = _analyzeTrend(analysisRecords);
    final cv = _calculateCV(analysisRecords);
    final weeklyStats = _buildWeeklyStats(records);
    final patientID = _generateAnonID(records);

    final rapidIncreaseStat = _calculateRapidIncreases(analysisRecords, finalConfig);
    final consecutiveAlert = _detectConsecutiveIncreases(analysisRecords, finalConfig);

    final reversedRecords = List<PoemRecord>.from(records.reversed);

    // --- Page 1: 封面 ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                if (logoBytes != null) pw.Image(pw.MemoryImage(logoBytes), height: 60),
                pw.Text("Clinical Monitoring Report", style: const pw.TextStyle(fontSize: _fsHeader, color: PdfColors.grey800)),
              ]),
              pw.Spacer(),
              pw.Text("POEM 濕疹追蹤報告", style: pw.TextStyle(fontSize: _fsLarge, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 12),
              pw.Text("Patient-Reported Outcome Visualization", style: const pw.TextStyle(fontSize: _fsHeader, color: PdfColors.grey800)),
              pw.Divider(color: PdfColors.blue900, thickness: 2.5),
              pw.SizedBox(height: 30),

              _coverField("Patient ID (Anonymized)", patientID, boldFont),
              _coverField("Observation Period", "${DateFormat('yyyy/MM/dd').format(records.first.date)} - ${DateFormat('yyyy/MM/dd').format(records.last.date)}", boldFont),
              _coverField("Generated At", DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()), boldFont),

              pw.SizedBox(height: 30),

              // Calculated Metrics Summary Box
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12))),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("Calculated Metrics Summary (Last 28 Days)", style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Divider(color: PdfColors.blue200, thickness: 1.5),
                  pw.SizedBox(height: 12),

                  // Score Trend
                  pw.Row(children: [
                    pw.SizedBox(width: 200, child: pw.Text("Score Trend (calculated)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsBody))),
                    pw.Text(trend.label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsBody, color: _getTrendColor(trend.label))),
                    pw.SizedBox(width: 10),
                    pw.Text("(Slope: ${trend.slope.toStringAsFixed(2)} pts/day)", style: const pw.TextStyle(fontSize: _fsBody, color: PdfColors.grey900)),
                  ]),

                  _trendRow("28-day Score Change %", "${trend.changeRate.toStringAsFixed(1)}%"),
                  _trendRow("Score Variability (CV%)", "${cv.toStringAsFixed(1)}%"),

                  pw.SizedBox(height: 6),

                  _trendRow(
                      "Rapid Increase Events",
                      "${rapidIncreaseStat.count} (Threshold: >= ${finalConfig.rapidIncreaseThreshold} pts)",
                      isThreshold: true
                  ),

                  if (consecutiveAlert.detected)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 6, left: 200),
                      child: pw.Text(
                        "Pattern detected: ${consecutiveAlert.streak} consecutive increases (+${consecutiveAlert.totalIncrease} pts, last on ${DateFormat('MM/dd').format(consecutiveAlert.lastDate!)})",
                        style: pw.TextStyle(fontSize: _fsBody, color: PdfColors.red800, fontWeight: pw.FontWeight.bold),
                      ),
                    ),

                  pw.SizedBox(height: 12),

                  pw.Text(
                    "Note: Thresholds used for alerts are configurable. Current settings: Rapid >= ${finalConfig.rapidIncreaseThreshold}, Streak >= ${finalConfig.streakThreshold}.",
                    style: pw.TextStyle(fontSize: _fsTiny, color: PdfColors.indigo900, fontWeight: pw.FontWeight.bold),
                  ),
                ]),
              ),
              pw.Spacer(),

              // Disclaimer Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("DISCLAIMER", style: pw.TextStyle(fontSize: _fsTiny, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                  pw.Text(
                    "This report presents patient-recorded POEM scores and derived statistics. It is intended for data review and discussion purposes only. No diagnostic, prognostic, or treatment recommendations are provided. Clinical decisions should be made by licensed healthcare professionals.",
                    style: const pw.TextStyle(fontSize: _fsTiny, color: PdfColors.grey900),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );

    // --- Page 2: 圖表與週報表 ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (context) => _buildPdfHeader(context),
        build: (context) => [
          pw.SizedBox(height: 10),
          if (chartImageBytes != null && chartImageBytes.length > 2000) ...[
            pw.Text("POEM Score Trend Over Time", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blueGrey100, width: 1)), child: pw.Image(pw.MemoryImage(chartImageBytes), width: 480, fit: pw.BoxFit.contain))),
          ],
          if (weeklyStats.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Text("Weekly Aggregated POEM Scores (${weeklyStats.length} weeks)", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 15),
            pw.TableHelper.fromTextArray(
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: _fsBody),
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: _fsSmall),
              columnWidths: {0: const pw.FixedColumnWidth(60), 1: const pw.FlexColumnWidth(2), 2: const pw.FixedColumnWidth(60), 3: const pw.FixedColumnWidth(60), 4: const pw.FixedColumnWidth(60), 5: const pw.FixedColumnWidth(100)},
              data: <List<dynamic>>[
                ['Week', 'Date Range', 'Avg', 'Max', 'Min', 'Threshold Flag'],
                ...weeklyStats.map((w) {
                  final bool isHigh = _isHighScoreWeek(w);
                  return ["Week ${w.week}", "${DateFormat('MM/dd').format(w.start)} - ${DateFormat('MM/dd').format(w.end)}", pw.Text(w.avg.toStringAsFixed(1), style: pw.TextStyle(color: isHigh ? PdfColors.red800 : PdfColors.black, fontWeight: isHigh ? pw.FontWeight.bold : null, fontSize: _fsSmall)), w.max.toString(), w.min.toString(), pw.Text(isHigh ? "Above Threshold" : "-", style: pw.TextStyle(color: isHigh ? PdfColors.red800 : PdfColors.grey800, fontWeight: isHigh ? pw.FontWeight.bold : null, fontSize: _fsSmall))];
                }),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text("* Threshold flag is based on predefined score cutoffs (Avg>=17 or Max>=24) for visualization only.", style: pw.TextStyle(fontSize: _fsTiny, color: PdfColors.grey800, fontStyle: pw.FontStyle.italic)),
          ],
        ],
      ),
    );

    // --- Page 3+: 詳細流水帳 ---
    const int itemsPerPage = 6;
    for (int i = 0; i < reversedRecords.length; i += itemsPerPage) {
      final chunk = reversedRecords.skip(i).take(itemsPerPage).toList();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (context) => pw.Column(
            children: [
              _buildPdfHeader(context),
              if (i == 0) ...[
                pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text("Chronological POEM Entries (with Photos)", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold))),
                pw.SizedBox(height: 15),
              ],
              pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  columnWidths: {0: const pw.FixedColumnWidth(90), 1: const pw.FixedColumnWidth(50), 2: const pw.FixedColumnWidth(70), 3: const pw.FlexColumnWidth(1)},
                  children: [
                    pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue900), children: [_tableCell("Date", isHeader: true), _tableCell("Score", isHeader: true), _tableCell("Severity", isHeader: true), _tableCell("Observation Image", isHeader: true)]),
                    ...chunk.map((r) {
                      final imageBytes = photoCache[r.id];
                      return pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.middle, children: [
                        _tableCell(DateFormat('yyyy-MM-dd\nHH:mm').format(r.date)),
                        _tableCell("${r.totalScore}/28", isBold: true),
                        _tableCell(r.severityLabel, color: _getSeverityColor(r.totalScore)),
                        pw.Container(height: 100, padding: const pw.EdgeInsets.all(6), child: imageBytes != null ? pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain) : pw.Center(child: pw.Text("No Image", style: const pw.TextStyle(color: PdfColors.grey600, fontSize: _fsSmall)))),
                      ]);
                    })
                  ]
              ),
              pw.Spacer(),
              pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text("Page ${context.pageNumber}", style: const pw.TextStyle(fontSize: _fsTiny))),
            ],
          ),
        ),
      );
    }

    // --- Page Last: 附錄 (🔥 V13.1 論文級附錄) ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (context) => _buildPdfHeader(context),
        build: (context) => [
          pw.Text("Appendix: Methodology & Formulas", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text("Technical reference for calculation methods used in this report.", style: const pw.TextStyle(fontSize: _fsBody, color: PdfColors.grey800)),
          pw.SizedBox(height: 16),

          // 🔥 新增：參數配置表 (Configuration Table) - 讓報告可稽核
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Threshold Configuration Used in This Report", style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                pw.SizedBox(height: 8),
                pw.Row(children: [pw.Expanded(child: pw.Text("Parameter", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsSmall))), pw.Text("Value", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsSmall))]),
                pw.Divider(color: PdfColors.blue200),
                _configRow("Rapid Increase Threshold", "${finalConfig.rapidIncreaseThreshold} pts"),
                _configRow("Consecutive Streak Threshold", "${finalConfig.streakThreshold} records"),
                _configRow("Consecutive Total Increase", "${finalConfig.streakTotalIncrease} pts"),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          _buildFormulaSection(
              title: "1. Score Trend (Linear Regression Slope)",
              formula: "Slope = Sum((x - mean_x) * (y - mean_y)) / Sum((x - mean_x)^2)",
              definitions: {
                "mean_x": "Average value of day indices (time).",
                "mean_y": "Average value of POEM scores.",
              },
              description: "Calculated using the Least Squares Method where 'x' is the day index (whole days elapsed since the first record) and 'y' is the POEM score. Represents the average daily change in score. A negative slope indicates a downward trend."
          ),

          _buildFormulaSection(
              title: "2. 28-day Score Change %",
              formula: "Change % = ((Avg_initial - Avg_recent) / Avg_initial) * 100",
              definitions: {
                "Avg_initial": "Mean score of the first half of the selected period.",
                "Avg_recent": "Mean score of the second half of the selected period.",
              },
              description: "Compares the average score of the first half of the selected period against the second half. Positive values indicate score reduction."
          ),

          _buildFormulaSection(
              title: "3. Score Variability (CV%)",
              formula: "CV% = (StdDev / Mean) * 100",
              definitions: {
                "StdDev": "Standard deviation of recorded scores.",
                "Mean": "Average score of the latter half of the selected period.",
              },
              description: "Coefficient of Variation. Measures the relative variability of scores independent of score magnitude. Lower percentage indicates more stable disease control."
          ),

          _buildFormulaSection(
              title: "4. Rapid Increase Event",
              formula: "Delta_Score = Score_current - Score_prev >= ${finalConfig.rapidIncreaseThreshold}",
              definitions: {
                "Score_current": "POEM score of the record being evaluated.",
                "Score_prev": "POEM score of the strictly preceding record.",
              },
              description: "Identifies acute episodes where the POEM score increases by >= ${finalConfig.rapidIncreaseThreshold} points. This threshold is configurable based on clinical preference (default 8, approx. 2x MCID)."
          ),

          _buildFormulaSection(
              title: "5. Consecutive Increase Pattern",
              formula: "Triggered if: (Streak >= ${finalConfig.streakThreshold}) AND (Total Increase >= ${finalConfig.streakTotalIncrease})",
              definitions: {
                "Streak": "Count of consecutive records where score increased.",
                "Total Increase": "Sum of score differences during the streak.",
              },
              description: "Detects persistent worsening. The streak criteria (>=${finalConfig.streakThreshold}) filters out single-point measurement noise. The cumulative increase (>=${finalConfig.streakTotalIncrease}) ensures the change distinguishes clinically meaningful deterioration from minor fluctuations."
          ),

          pw.Spacer(),
          pw.Divider(color: PdfColors.grey600),
          pw.Text("Note: All metrics are derived mathematically from user-inputted data without clinical interpretation. Thresholds shown above are based on current configuration settings.", style: pw.TextStyle(fontSize: _fsTiny, color: PdfColors.indigo900, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic)),
        ],
      ),
    );

    final String filename = "POEM_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: '分享 POEM 症狀追蹤報告');
  }

  // --- Helper Functions ---

  // 🔥 新增：配置表列 Helper
  static pw.Widget _configRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: _fsSmall, color: PdfColors.grey900)),
          pw.Text(value, style: pw.TextStyle(fontSize: _fsSmall, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        ],
      ),
    );
  }

  static pw.Widget _buildFormulaSection({
    required String title,
    required String formula,
    required String description,
    Map<String, String>? definitions,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Text(formula, style: pw.TextStyle(font: pw.Font.courier(), fontSize: _fsSmall, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          if (definitions != null) ...[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: definitions.entries.map((e) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 110,
                        child: pw.Text("• ${e.key}:", style: pw.TextStyle(fontSize: _fsSmall, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                      ),
                      pw.Expanded(
                        child: pw.Text(e.value, style: const pw.TextStyle(fontSize: _fsSmall, color: PdfColors.grey900)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 8),
          ],
          pw.Text(description, style: const pw.TextStyle(fontSize: _fsSmall, color: PdfColors.grey900)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfHeader(pw.Context context) { return pw.Column(children: [pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("POEM Symptom Tracking Report", style: pw.TextStyle(fontSize: _fsTitle, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)), pw.Text("Page ${context.pageNumber}", style: const pw.TextStyle(fontSize: _fsSmall))]), pw.Divider(thickness: 1.5, color: PdfColors.blueGrey), pw.SizedBox(height: 12)]); }
  static pw.Widget _tableCell(String text, {bool isHeader = false, bool isBold = false, PdfColor? color}) { return pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Center(child: pw.Text(text, textAlign: pw.TextAlign.center, style: pw.TextStyle(color: isHeader ? PdfColors.white : (color ?? PdfColors.black), fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: isHeader ? _fsBody : _fsSmall)))); }
  static pw.Widget _coverField(String label, String value, pw.Font font) { return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 12), child: pw.Row(children: [pw.SizedBox(width: 200, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsBody, color: PdfColors.blueGrey800))), pw.Text(value, style: const pw.TextStyle(fontSize: _fsBody, color: PdfColors.black))])); }
  static pw.Widget _trendRow(String label, String value, {bool isThreshold = false}) { return pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: pw.Row(children: [pw.SizedBox(width: 200, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _fsBody, color: isThreshold ? PdfColors.indigo900 : PdfColors.black))), pw.Text(value, style: pw.TextStyle(fontSize: _fsBody, fontWeight: isThreshold ? pw.FontWeight.bold : pw.FontWeight.normal, color: isThreshold ? PdfColors.indigo900 : PdfColors.grey900))])); }
  static PdfColor _getTrendColor(String label) { if (label == "Decreasing") return PdfColors.green700; if (label == "Increasing") return PdfColors.red700; return PdfColors.grey800; }
  static PdfColor _getSeverityColor(int score) { if (score <= 2) return PdfColors.blue700; if (score <= 7) return PdfColors.green700; if (score <= 16) return PdfColors.amber700; if (score <= 24) return PdfColors.orange700; return PdfColors.red700; }
  static bool _isHighScoreWeek(WeeklyStat w) => w.avg >= 17 || w.max >= 24;
  static String _generateAnonID(List<PoemRecord> records) { if(records.isEmpty) return "AD-00000"; final hash = records.fold<int>(0, (h, r) => h ^ r.date.millisecondsSinceEpoch); return "AD-${(hash.abs() % 100000).toString().padLeft(5, '0')}"; }

  static ScoreTrend _analyzeTrend(List<PoemRecord> sortedRecords) {
    if (sortedRecords.length < 2) return ScoreTrend("Insufficient Data", 0, 0, 0);
    final mid = sortedRecords.length ~/ 2;
    final first = sortedRecords.sublist(0, mid);
    final second = sortedRecords.sublist(mid);
    final firstAvg = first.map((e) => e.totalScore).reduce((a, b) => a + b) / first.length;
    final secondAvg = second.map((e) => e.totalScore).reduce((a, b) => a + b) / second.length;
    double changeRate = 0;
    if (firstAvg >= 1) changeRate = ((firstAvg - secondAvg) / firstAvg) * 100;
    changeRate = changeRate.clamp(-100.0, 100.0);
    final start = sortedRecords.first.date;
    final xs = <double>[]; final ys = <double>[];
    for (final r in sortedRecords) { xs.add(r.date.difference(start).inDays.toDouble()); ys.add(r.totalScore.toDouble()); }
    final meanX = xs.reduce((a, b) => a + b) / xs.length;
    final meanY = ys.reduce((a, b) => a + b) / ys.length;
    double num = 0; double den = 0;
    for (int i = 0; i < xs.length; i++) { num += (xs[i] - meanX) * (ys[i] - meanY); den += (xs[i] - meanX) * (xs[i] - meanX); }
    final slope = den == 0 ? 0.0 : num / den;
    String label = "Stable";
    if (slope <= -0.1) label = "Decreasing"; else if (slope >= 0.1) label = "Increasing";
    return ScoreTrend(label, secondAvg - firstAvg, changeRate, slope);
  }

  static double _calculateCV(List<PoemRecord> records) {
    if (records.length < 4) return 0;
    final recent = records.sublist(records.length ~/ 2);
    final mean = recent.map((e) => e.totalScore).reduce((a, b) => a + b) / recent.length;
    if (mean == 0) return 0;
    final variance = recent.map((e) => (e.totalScore - mean) * (e.totalScore - mean)).reduce((a, b) => a + b) / recent.length;
    return (sqrt(variance) / mean) * 100;
  }

  static RapidIncreaseStat _calculateRapidIncreases(List<PoemRecord> sortedRecords, PoemReportConfig config) {
    if (sortedRecords.length < 2) return RapidIncreaseStat(0, [], config.rapidIncreaseThreshold);
    int count = 0;
    final List<DateTime> dates = [];
    for (int i = 1; i < sortedRecords.length; i++) {
      if ((sortedRecords[i].totalScore - sortedRecords[i - 1].totalScore) >= config.rapidIncreaseThreshold) {
        count++;
        dates.add(sortedRecords[i].date);
      }
    }
    return RapidIncreaseStat(count, dates, config.rapidIncreaseThreshold);
  }

  static ConsecutiveIncreaseAlert _detectConsecutiveIncreases(List<PoemRecord> sortedRecords, PoemReportConfig config) {
    if (sortedRecords.length < 3) return ConsecutiveIncreaseAlert(false, 0, 0, null, config.streakThreshold, config.streakTotalIncrease);
    int streak = 0;
    int totalIncrease = 0;
    int maxStreak = 0;
    int maxIncrease = 0;
    DateTime? lastDate;
    for (int i = 1; i < sortedRecords.length; i++) {
      final diff = sortedRecords[i].totalScore - sortedRecords[i - 1].totalScore;
      if (diff > 0) {
        streak++;
        totalIncrease += diff;
        if (streak > maxStreak) {
          maxStreak = streak;
          maxIncrease = totalIncrease;
          lastDate = sortedRecords[i].date;
        }
      } else {
        streak = 0;
        totalIncrease = 0;
      }
    }
    final detected = maxStreak >= config.streakThreshold && maxIncrease >= config.streakTotalIncrease;
    return ConsecutiveIncreaseAlert(detected, maxStreak, maxIncrease, lastDate, config.streakThreshold, config.streakTotalIncrease);
  }

  static List<WeeklyStat> _buildWeeklyStats(List<PoemRecord> records) {
    if (records.isEmpty) return [];
    final rawStart = records.first.date;
    final start = DateTime(rawStart.year, rawStart.month, rawStart.day);
    final end = records.last.date;
    final int totalDays = end.difference(start).inDays + 1;
    final int weeksCount = (totalDays / 7).ceil();
    final List<WeeklyStat> stats = [];
    for (int w = 0; w < weeksCount; w++) {
      final weekStart = start.add(Duration(days: w * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final weekRecords = records.where((r) => r.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) && r.date.isBefore(weekEnd)).toList();
      if (weekRecords.isNotEmpty) {
        final scores = weekRecords.map((e) => e.totalScore).toList();
        stats.add(WeeklyStat(week: w + 1, start: weekStart, end: weekEnd.subtract(const Duration(days: 1)), avg: scores.reduce((a, b) => a + b) / scores.length, min: scores.reduce((a, b) => a < b ? a : b), max: scores.reduce((a, b) => a > b ? a : b)));
      }
    }
    return stats;
  }
}