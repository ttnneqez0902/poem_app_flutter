import 'package:flutter/material.dart'; // 🚀 必須引入，才能使用 Color
import 'poem_record.dart';

// 🚀 1. 擴充科別分類
enum AppCategory { dermatology, psychiatry, pain, rheumatology, gastro, womens, peds }

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
  final Color color; // 🚀 補上這行，解決卡片顏色報錯;
  final AppCategory category; // 🚀 補上科別，方便分頁顯示

  ScaleConfig({
    required this.title,
    required this.questions,
    required this.maxScore,
    required this.description,
    required this.color, // 🚀 構造函數也要加
    required this.category,
  });

  static Map<ScaleType, ScaleConfig> allScales = {
    // ==========================================
    // 🟦 肌膚照護 (Dermatology)
    // ==========================================

    ScaleType.adct: ScaleConfig(
      title: "肌膚穩定追蹤", // 🚀 親民化
      category: AppCategory.dermatology, // ✅ 補上分類
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
      category: AppCategory.dermatology, // ✅ 補上分類
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
      category: AppCategory.dermatology, // ✅ 補上分類
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
      category: AppCategory.dermatology, // ✅ 補上分類
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
      category: AppCategory.psychiatry, // ✅ 補上分類
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
      category: AppCategory.psychiatry, // ✅ 補上分類
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
    // 🦴 風濕免疫科 (Rheumatology) - 包含疼痛管理
    // ==========================================
    ScaleType.vas: ScaleConfig(
      title: "痛痛程度紀錄",
      category: AppCategory.rheumatology, // 🚀 統一歸類在風濕科或 pain
      color: Colors.redAccent,
      maxScore: 10,
      description: "請評估您目前的疼痛程度 (0:無痛, 10:極痛)",
      questions: [
        ScaleQuestion("目前的疼痛強度 (VAS 0-10)"),
      ],
    ),

    ScaleType.haq: ScaleConfig(
      title: "日常功能評估",
      category: AppCategory.rheumatology,
      color: Colors.brown,
      maxScore: 3,
      description: "請評估您在過去一週內執行日常活動的困難程度",
      questions: [
        ScaleQuestion("自己穿衣服（包括繫鞋帶、釦子）", options: ["無困難", "有些困難", "很困難", "無法做到"]),
        ScaleQuestion("自己洗頭", options: ["無困難", "有些困難", "很困難", "無法做到"]),
        ScaleQuestion("從無扶手的椅子上站起來", options: ["無困難", "有些困難", "很困難", "無法做到"]),
        ScaleQuestion("自己上下床", options: ["無困難", "有些困難", "很困難", "無法做到"]),
        ScaleQuestion("將裝滿水的杯子拿到嘴邊", options: ["無困難", "有些困難", "很困難", "無法做到"]),
      ],
    ),

    // ==========================================
    // 💩 腸胃科 (Gastroenterology)
    // ==========================================
    ScaleType.bristol: ScaleConfig(
      title: "便便分類日誌",
      category: AppCategory.gastro,
      color: Colors.orange.shade800,
      maxScore: 7,
      description: "請根據形狀選擇最接近的一種",
      questions: [
        ScaleQuestion("今日便便形狀", options: ["第一型: 硬球狀", "第二型: 香腸狀但表面凹凸", "第三型: 香腸狀但表面有裂痕", "第四型: 表面平滑軟條狀", "第五型: 柔軟塊狀", "第六型: 糊狀", "第七型: 水狀"]),
      ],
    ),

    ScaleType.ibs_sss: ScaleConfig(
      title: "腸胃不適評分",
      category: AppCategory.gastro,
      color: Colors.deepOrange,
      maxScore: 100,
      description: "請評估過去一週腸胃不適的嚴重度 (VAS 0-100)",
      questions: [
        ScaleQuestion("腹痛的嚴重程度"),
        ScaleQuestion("腹脹的嚴重程度"),
        ScaleQuestion("對排便習慣的滿意度"),
      ],
    ),

    // ==========================================
    // 🌸 女性健康 (Women's Health)
    // ==========================================
    ScaleType.cycle: ScaleConfig(
      title: "生理週期追蹤",
      category: AppCategory.womens,
      color: Colors.pinkAccent,
      maxScore: 1,
      description: "紀錄經期狀態",
      questions: [
        ScaleQuestion("今日經期狀態", options: ["尚未開始", "經期第一天", "經期中"]),
        ScaleQuestion("流量評估", options: ["極少", "少", "普通", "多", "極多"]),
      ],
    ),

    // ==========================================
    // 👶 兒科發展 (Pediatrics)
    // ==========================================
    ScaleType.growth: ScaleConfig(
      title: "寶寶成長紀錄",
      category: AppCategory.peds,
      color: Colors.lightBlue,
      maxScore: 0,
      description: "請輸入寶寶目前的生長數據",
      questions: [
        ScaleQuestion("身高 (cm)"),
        ScaleQuestion("體重 (kg)"),
        ScaleQuestion("頭圍 (cm)"),
      ],
    ),
  };
}