import 'poem_record.dart';
// 1. 定義科別枚舉
enum AppCategory { dermatology, psychiatry, pain }

class ScaleQuestion {
  final String label;
  final List<String>? options; // 如果為 null 則顯示 Slider (如 VAS)
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
    // ==========================================
    // 🟦 皮膚科量表 (Dermatology)
    // ==========================================

    // 1. ADCT: 0-4 分 (異膚控制工具)
    ScaleType.adct: ScaleConfig(
      title: "ADCT 評估",
      maxScore: 4,
      description: "請根據過去一週的異位性皮膚炎控制狀況回答",
      questions: [
        ScaleQuestion("皮膚搔癢的天數", options: ["0天", "1-2天", "3-4天", "5-6天", "每天"]),
        ScaleQuestion("睡眠受影響的天數", options: ["0天", "1-2天", "3-4天", "5-6天", "每天"]),
        ScaleQuestion("對社交/休閒的影響", options: ["完全沒有", "輕微", "中度", "嚴重", "極度嚴重"]),
        ScaleQuestion("對工作或學習的影響", options: ["完全沒有", "輕微", "中度", "嚴重", "極度嚴重"]),
        ScaleQuestion("皮膚發紅或紅腫的程度", options: ["完全沒有", "輕微", "中度", "嚴重", "極度嚴重"]),
        ScaleQuestion("整體控制的信心程度", options: ["非常有信心", "有信心", "普通", "沒信心", "完全沒信心"]),
      ],
    ),

    // 2. POEM: 0-4 分
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

    // 3. UAS7: 0-3 分
    ScaleType.uas7: ScaleConfig(
      title: "蕁麻疹 UAS7",
      maxScore: 3,
      description: "依照過去 24 小時內症狀進行評分",
      questions: [
        ScaleQuestion("膨疹數量 (24小時內)", options: ["沒有 (0分)", "輕微: <20個 (1分)", "中度: 20-50個 (2分)", "嚴重: >50個 (3分)"]),
        ScaleQuestion("搔癢程度", options: ["完全不癢 (0分)", "輕微: 不困擾 (1分)", "中度: 困擾但不影響生活 (2分)", "嚴重: 影響生活/睡眠 (3分)"]),
      ],
    ),

    // 4. SCORAD 自測: 0-10 VAS
    ScaleType.scorad: ScaleConfig(
      title: "SCORAD 自評",
      maxScore: 10,
      description: "主觀症狀強度評估 (強度 0-3 分，感官 0-10 分)",
      questions: [
        ScaleQuestion("1. 紅斑 (皮膚紅腫)", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("2. 水腫 / 丘疹", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("3. 滲出 / 結痂", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("4. 抓痕 (抓傷痕跡)", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("5. 皮膚增厚 (苔癬化)", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("6. 乾燥程度 (非病變處)", options: ["無", "輕微", "中度", "嚴重"]),
        ScaleQuestion("7. 搔癢程度 (VAS 0-10)"),
        ScaleQuestion("8. 睡眠影響 (VAS 0-10)"),
      ],
    ),

    // ==========================================
    // 🧠 身心科量表 (Psychiatry)
    // ==========================================

    // PHQ-9: 憂鬱情緒篩檢 (0-3 分制)
    ScaleType.phq9: ScaleConfig(
      title: "PHQ-9 憂鬱量表",
      maxScore: 3,
      description: "在過去兩星期，有多少時間受以下問題困擾？",
      questions: [
        ScaleQuestion("1. 做事時提不起勁或沒有興趣", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("2. 感到情緒低落、抑鬱或絕望", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("3. 入睡困難、睡得不穩或睡眠過多", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("4. 感到疲倦或沒有活力", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("5. 胃口不佳或進食過量", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("6. 覺得自己很糟、覺得失敗或讓家人失望", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("7. 對事物專注有困難（例如看報紙或看電視）", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("8. 說話或行動速度緩慢到別人都察覺，或剛好相反：異常煩躁不安", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("9. 想到死或傷害自己的念頭", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
      ],
    ),

    // GAD-7: 焦慮狀況評估 (0-3 分制)
    ScaleType.gad7: ScaleConfig(
      title: "GAD-7 焦慮量表",
      maxScore: 3,
      description: "在過去兩星期，有多少時間受以下問題困擾？",
      questions: [
        ScaleQuestion("1. 感到緊張、焦慮或急躁", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("2. 無法停止或控制憂慮", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("3. 對各樣事物憂慮太多", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("4. 難以放鬆", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("5. 心煩意亂，以致坐立難安", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("6. 容易煩躁或易怒", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
        ScaleQuestion("7. 感到害怕，好像有可怕的事發生", options: ["完全沒有", "幾天", "一半以上天數", "幾乎每天"]),
      ],
    ),

    // ==========================================
    // ⚡ 疼痛管理 (Pain Management) - 🚀 新增
    // ==========================================

    // 7. VAS: 0-10 分
    ScaleType.vas: ScaleConfig(
      title: "疼痛 VAS 評估",
      maxScore: 10,
      description: "請評估您目前的疼痛程度 (0:無痛, 10:想像中最痛)",
      questions: [
        ScaleQuestion("目前的疼痛強度程度"),
      ],
    ),
  };
}