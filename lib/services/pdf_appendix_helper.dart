import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/poem_record.dart';
import 'export_service.dart'; // 🚀 引用以取得 ClinicalReportConfig 定義

class PdfAppendixHelper {
  static const double _fsHeader = 14.0;
  static const double _fsSmall = 11.0;

  // 🚀 核心修正 1：增加 pw.Font mathFont 參數，解決 ExportService 呼叫時的參數數量錯誤
  static List<pw.Widget> buildAppendix(ScaleType type, ClinicalReportConfig config, pw.Font mathFont) {
    String scaleName = type.name.toUpperCase();

    return [
      pw.Text("Appendix: Methodology & Formulas", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Text("針對 $scaleName 臨床報告所使用的數據計算方法。所有數據點均依「病程歸屬日 (Target Date)」進行時間序列對齊。",
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
      pw.SizedBox(height: 12),

      // 1. 閾值配置 (保持不變)
      _buildBox("Threshold Configuration", [
        _row("Rapid Increase Threshold", "${config.rapidIncreaseThreshold} pts"),
        _row("Consecutive Streak", "${config.streakThreshold} records"),
        if (type == ScaleType.adct) _row("臨床警戒切點 (ADCT 控制不佳)", ">= 7 pts"),
        if (type == ScaleType.poem) _row("重度病灶切點 (POEM Severity)", ">= 17 pts"),
        if (type == ScaleType.uas7) _row("嚴重活性切點 (UAS7 Severity)", ">= 28 pts"),
      ]),
      pw.SizedBox(height: 12),

      // 🚀 修正序號 1：變化幅度 (這是 ExportService 報告中呈現的第一個指標)
      _buildFormulaSection(
          title: "1. Magnitude of Change (二分法平均比較)",
          formula: "Delta (Δ) = Average(Post-period) - Average(Pre-period)",
          description: "將選定觀察區間數據平分為前後兩段，計算後期相較於前期的平均分差。負值代表整體改善，正值代表病況轉差。",
          mathFont: mathFont
      ),

      // 🚀 修正序號 2：線性回歸
      _buildFormulaSection(
          title: "2. Score Trend (Linear Regression)",
          formula: "Slope (β) = Σ((xi - avg_x) * (yi - avg_y)) / Σ(xi - avg_x)²",
          description: "使用最小平方法計算每日分數變化的斜率。負值代表趨於穩定 (Improving)，正值代表趨向惡化 (Worsening)。",
          mathFont: mathFont
      ),

      // 🚀 修正序號 3：CV%
      _buildFormulaSection(
          title: "3. Score Variability (CV%)",
          formula: "CV% = (StdDev / Mean) * 100",
          description: "衡量病情波動程度。百分比越高代表症狀起伏越大，可能受環境誘發因子影響較深。",
          mathFont: mathFont
      ),

      // 🚀 修正序號 4：Flare 偵測
      _buildFormulaSection(
          title: "4. Flare Detection (Rapid & Streak)",
          formula: "Flare Alert if: (ΔScore >= ${config.rapidIncreaseThreshold}) OR (Accumulated Streak Increase >= ${config.streakTotalIncrease})",
          description: "用於捕捉臨床急性發作。包含單日爆發性增幅 (Rapid) 與多日連續惡化走勢 (Streak) 的雙重監測。",
          mathFont: mathFont
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

  // 🚀 核心修正 4：新增 mathFont 參數並在 TextStyle 中設定 fontFallback
  static pw.Widget _buildFormulaSection({
    required String title,
    required String formula,
    required String description,
    required pw.Font mathFont,
  }) {
    return pw.Container(margin: const pw.EdgeInsets.only(bottom: 4), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title, style: pw.TextStyle(fontSize: _fsHeader, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
      pw.SizedBox(height: 4),
      pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(6),
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          child: pw.Text(
              formula,
              style: pw.TextStyle(
                fontSize: _fsSmall,
                fontWeight: pw.FontWeight.bold,
                // 🚀 關鍵：當預設字體找不到數學符號時，回退到 mathFont 尋找
                fontFallback: [mathFont],
              )
          )
      ),
      pw.SizedBox(height: 4),
      pw.Text(description, style: const pw.TextStyle(fontSize: _fsSmall, color: PdfColors.grey900))
    ]));
  }

  static pw.Widget _row(String l, String v) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l, style: const pw.TextStyle(fontSize: _fsSmall)), pw.Text(v, style: pw.TextStyle(fontSize: _fsSmall, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900))]));
}