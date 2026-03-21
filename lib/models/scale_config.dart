import 'package:flutter/material.dart'; // 🚀 必須引入，才能使用 Color
import 'poem_record.dart';

// 1. 定義科別枚舉
enum AppCategory { dermatology, psychiatry, pain }

class ScaleQuestion {
  final String label;
  final List<String>? options;
  ScaleQuestion(this.label, {this.options});
}

class ScaleConfig {
  final String title;
  final List<ScaleQuestion> questions;
  final int maxScore;
  final String description;
  final Color color; // 🚀 補上這行，解決卡片顏色報錯

  ScaleConfig({
    required this.title,
    required this.questions,
    required this.maxScore,
    required this.description,
    required this.color, // 🚀 構造函數也要加
  });

  static Map<ScaleType, ScaleConfig> allScales = {
    // ==========================================
    // 🟦 肌膚照護 (Dermatology)
    // ==========================================

    ScaleType.adct: ScaleConfig(
      title: "肌膚穩定追蹤", // 🚀 親民化
      color: Colors.blue,
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

    ScaleType.poem: ScaleConfig(
      title: "這週皮膚還好嗎？", // 🚀 親民化
      color: Colors.orange,
      maxScore: 4,
      description: "過去一週皮膚受損程度評估",
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

    ScaleType.uas7: ScaleConfig(
      title: "今日小紅點紀錄", // 🚀 親民化
      color: Colors.teal,
      maxScore: 3,
      description: "依照過去 24 小時內症狀進行評分",
      questions: [
        ScaleQuestion("膨疹數量 (24小時內)", options: ["沒有 (0分)", "輕微: <20個 (1分)", "中度: 20-50個 (2分)", "嚴重: >50個 (3分)"]),
        ScaleQuestion("搔癢程度", options: ["完全不癢 (0分)", "輕微: 不困擾 (1分)", "中度: 困擾但不影響生活 (2分)", "嚴重: 影響生活/睡眠 (3分)"]),
      ],
    ),

    ScaleType.scorad: ScaleConfig(
      title: "全身狀況掃描", // 🚀 親民化
      color: Colors.purple,
      maxScore: 10,
      description: "主觀症狀強度評估",
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
    // 🧠 情緒照護 (Psychiatry)
    // ==========================================

    ScaleType.phq9: ScaleConfig(
      title: "心情起伏觀察", // 🚀 親民化
      color: Colors.indigo,
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

    ScaleType.gad7: ScaleConfig(
      title: "讓身體放輕鬆", // 🚀 親民化
      color: Colors.green.shade700,
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
    // ⚡ 疼痛管理 (Pain Management)
    // ==========================================

    ScaleType.vas: ScaleConfig(
      title: "痛痛程度紀錄", // 🚀 親民化
      color: Colors.redAccent,
      maxScore: 10,
      description: "請評估您目前的疼痛程度 (0:無痛, 10:想像中最痛)",
      questions: [
        ScaleQuestion("目前的疼痛強度程度"),
      ],
    ),
  };
}