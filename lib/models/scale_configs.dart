import 'poem_record.dart';

class ScaleQuestion {
  final String label;
  final List<String>? options; // 如果為 null 則顯示 Slider
  ScaleQuestion(this.label, {this.options});
}

class ScaleConfig {
  final String title;
  final List<ScaleQuestion> questions;
  final int maxScore;        // 單題最高分
  final String description;

  ScaleConfig({
    required this.title,
    required this.questions,
    required this.maxScore,
    required this.description,
  });

  static Map<ScaleType, ScaleConfig> allScales = {
    // 1. POEM: 0-4 分 (一週總結)
    ScaleType.poem: ScaleConfig(
      title: "POEM 檢測",
      maxScore: 4,
      description: "過去一週皮膚受損程度評估 (異位性皮膚炎指標)",
      questions: [
        ScaleQuestion("搔癢 (Itch)", options: ["0天", "1-2天", "3-4天", "5-6天", "每天"]),
        ScaleQuestion("睡眠障礙 (Sleep)", options: ["0天", "1-2天", "3-4天", "5-6天", "每天"]),
        ScaleQuestion("出血情況 (Bleeding)", options: ["0天", "1-2天", "3-4天", "5-6天", "每天"]),
        ScaleQuestion("流膿/湯 (Oozing)", options: ["0天", "1-2天", "3-4天", "5-6天", "每天"]),
        ScaleQuestion("皮膚龜裂 (Cracking)", options: ["0天", "1-2天", "3-4天", "5-6天", "每天"]),
        ScaleQuestion("皮膚脫皮 (Flaking)", options: ["0天", "1-2天", "3-4天", "5-6天", "每天"]),
        ScaleQuestion("皮膚乾澀 (Dryness)", options: ["0天", "1-2天", "3-4天", "5-6天", "每天"]),
      ],
    ),

    // 2. UAS7: 0-3 分 (每日記錄)
    ScaleType.uas7: ScaleConfig(
      title: "蕁麻疹 UAS7",
      maxScore: 3,
      description: "依照過去 24 小時內症狀，圈選對應的分數",
      questions: [
        ScaleQuestion(
            "膨疹數量 (24小時內)",
            options: [
              "沒有 (0分)",
              "輕微：少於20個 (1分)",
              "中度：出現20-50個 (2分)",
              "嚴重：超過50個或融合成大面積 (3分)"
            ]
        ),
        ScaleQuestion(
            "搔癢程度",
            options: [
              "完全不癢 (0分)",
              "輕微：有點癢感但不造成困擾 (1分)",
              "中度：癢感困擾但不影響生活睡眠 (2分)",
              "嚴重：癢感嚴重且影響生活或睡眠 (3分)"
            ]
        ),
      ],
    ),

    // 3. SCORAD 自測: 0-10 VAS
    ScaleType.scorad: ScaleConfig(
      title: "SCORAD 自評",
      maxScore: 10, // 用於定義 Slider 的最大範圍 (VAS)
      description: "請根據過去三天皮膚狀況進行強度與主觀感覺評估",
      questions: [
        // 📍 第二步：皮膚病變強度評估 (0-3 分)
        ScaleQuestion("1. 紅斑 (皮膚紅腫)", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("2. 水腫 / 丘疹", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("3. 滲出 / 結痂", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("4. 抓痕 (抓傷痕跡)", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("5. 皮膚增厚 (苔癬化)", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("6. 乾燥程度 (非病變處)", options: ["無", "輕微", "中度", "嚴重"]),

        // 📍 第三步：主觀症狀評估 (0-10 分 VAS)
        ScaleQuestion("7. 搔癢程度 (0:不癢, 10:極癢)"),
        ScaleQuestion("8. 睡眠影響 (0:無影響, 10:完全失眠)"),
      ],
    ),
  };
}