import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/poem_record.dart';
import 'export_service.dart'; // 🚀 引用以取得 ClinicalReportConfig 定義

class PdfAppendixHelper {
  static const double _fsHeader = 16.0;
  static const double _fsSmall = 12.0;

  // 🚀 核心修正：接收 Config 物件而非單一整數
  static List<pw.Widget> buildAppendix(ScaleType type, ClinicalReportConfig config) {
    String scaleName = type.name.toUpperCase();

    return [
      pw.Text("Appendix: Methodology & Formulas", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Text("針對 $scaleName 臨床報告所使用的數據計算方法與定義說明。", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey800)),
      pw.SizedBox(height: 24),

      // 1. 閾值配置
      _buildBox("Threshold Configuration", [
        _row("Rapid Increase Threshold", "${config.rapidIncreaseThreshold} pts"),
        _row("Consecutive Streak", "${config.streakThreshold} records"),
        if (type == ScaleType.adct) _row("臨床警戒切點 (ADCT 控制不佳)", ">= 7 pts"),
        if (type == ScaleType.poem) _row("重度病灶切點 (POEM Severity)", ">= 17 pts"),
        if (type == ScaleType.uas7) _row("嚴重活性切點 (UAS7 Severity)", ">= 28 pts"),
      ]),
      pw.SizedBox(height: 24),

      // 2. 趨勢公式 (線性迴歸)
      _buildFormulaSection(
          title: "1. Score Trend (Linear Regression)",
          formula: "Slope = Sum((x - mean_x) * (y - mean_y)) / Sum((x - mean_x)^2)",
          description: "使用最小平方法計算 Slope。代表平均每日分數變化。負值代表病情趨向穩定，正值則代表趨向惡化。"
      ),

      // 3. 變異係數 (CV%)
      _buildFormulaSection(
          title: "2. Score Variability (CV%)",
          formula: "CV% = (StdDev / Mean) * 100",
          description: "衡量病情波動程度。百分比越低代表疾病控制越穩定，較不受評分絕對值高低的影響。"
      ),

      // 4. 急性發作定義 (Rapid Increase)
      _buildFormulaSection(
          title: "3. Rapid Increase Event (Acute Flare)",
          formula: "Delta_Score = Current_Score - Previous_Score >= ${config.rapidIncreaseThreshold}",
          description: "識別臨床上的急性發作。當連續兩次檢測間的分數增幅超過門檻時觸發警示。"
      ),

      pw.Spacer(),
      pw.Divider(color: PdfColors.grey600),
      pw.Text("註：所有計算指標均由數學公式衍生，僅供醫師臨床評估參考，不具備自動診斷功能。",
          style: pw.TextStyle(fontSize: 10, color: PdfColors.indigo900, fontWeight: pw.FontWeight.bold)),
    ];
  }

  static pw.Widget _buildBox(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title, style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
        pw.Divider(color: PdfColors.blue200),
        ...children,
      ]),
    );
  }

  static pw.Widget _buildFormulaSection({required String title, required String formula, required String description}) {
    return pw.Container(margin: const pw.EdgeInsets.only(bottom: 20), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title, style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(10), decoration: const pw.BoxDecoration(color: PdfColors.grey100), child: pw.Text(formula, style: pw.TextStyle(font: pw.Font.courier(), fontSize: _fsSmall, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Text(description, style: const pw.TextStyle(fontSize: _fsSmall, color: PdfColors.grey900))
    ]));
  }

  static pw.Widget _row(String l, String v) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l, style: const pw.TextStyle(fontSize: _fsSmall)), pw.Text(v, style: pw.TextStyle(fontSize: _fsSmall, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900))]));
}