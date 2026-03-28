import 'package:flutter/material.dart'; // 🚀 必須引入，才能使用 Color
import 'poem_record.dart';

// 🚀 1. 擴充科別分類
enum AppCategory { dermatology, sleep, chronic, psychiatry, pain, rheumatology, gastro, womens, peds }

class ScaleQuestion {
  final String label;
  final List<String>? options;
  ScaleQuestion(this.label, {this.options});
}

class ScaleConfig {
  final String title;
  final String? unit; // 🚀 新增：單位 (如 cm, kg, 型, 分)
  final List<ScaleQuestion> questions;
  final int maxScore;
  final String description;
  final Color color; // 🚀 補上這行，解決卡片顏色報錯
  final AppCategory category; // 🚀 補上科別，方便分頁顯示

  ScaleConfig({
    required this.title,
    required this.questions,
    required this.maxScore,
    required this.description,
    required this.color, // 🚀 構造函數也要加
    required this.category,
    this.unit, // 🚀 2. 關鍵修正：構造函數一定要加上這一行！
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
// 🌙 睡眠健康 (Sleep Health)
// ==========================================

    ScaleType.psqi: ScaleConfig(
      title: "專業睡眠品質 (PSQI)",
      category: AppCategory.sleep,
      color: Colors.indigo.shade800,
      maxScore: 3,
      description: "評估過去一個月的睡眠品質與障礙",
      questions: [
        ScaleQuestion("1. 躺下到入睡需要的時間", options: ["15分鐘內", "16-30分鐘", "31-60分鐘", "超過60分鐘"]),
        ScaleQuestion("2. 半夜醒來或早醒的頻率", options: ["從未", "每週不到1次", "每週1-2次", "每週3次以上"]),
        ScaleQuestion("3. 起床去洗手間的頻率", options: ["從未", "每週不到1次", "每週1-2次", "每週3次以上"]),
        ScaleQuestion("4. 呼吸不順或咳嗽感", options: ["從未", "每週不到1次", "每週1-2次", "每週3次以上"]),
        ScaleQuestion("5. 感到太冷或太熱", options: ["從未", "每週不到1次", "每週1-2次", "每週3次以上"]),
        ScaleQuestion("6. 需服用藥物才能入睡", options: ["從未", "每週不到1次", "每週1-2次", "每週3次以上"]),
        ScaleQuestion("7. 白天工作時難以保持清醒", options: ["從未", "每週不到1次", "每週1-2次", "每週3次以上"]),
        ScaleQuestion("8. 整體自評睡眠品質", options: ["非常好", "好", "不好", "非常差"]),
      ],
    ),

    ScaleType.isi: ScaleConfig(
      title: "失眠嚴重度 (ISI)",
      category: AppCategory.sleep,
      color: Colors.deepPurple,
      maxScore: 4,
      description: "評估最近兩週對失眠症狀的感受",
      questions: [
        ScaleQuestion("入睡困難程度", options: ["無", "輕微", "中度", "嚴重", "極其嚴重"]),
        ScaleQuestion("維持睡眠困難（半夜醒來）", options: ["無", "輕微", "中度", "嚴重", "極其嚴重"]),
        ScaleQuestion("太早醒來的問題", options: ["無", "輕微", "中度", "嚴重", "極其嚴重"]),
        ScaleQuestion("對目前睡眠模式的滿意度", options: ["非常滿意", "滿意", "普通", "不滿意", "非常不滿意"]),
        ScaleQuestion("睡眠問題對日常功能的干擾", options: ["無干擾", "輕微", "中度", "嚴重", "極其嚴重"]),
      ],
    ),

    ScaleType.ess: ScaleConfig(
      title: "白天嗜睡檢查 (ESS)",
      category: AppCategory.sleep,
      color: Colors.blueGrey,
      maxScore: 3,
      description: "在以下情況中，您打瞌睡的機會有多大？",
      questions: [
        ScaleQuestion("坐著閱讀時", options: ["從不", "很少", "中等", "極大機會"]),
        ScaleQuestion("坐著看電視時", options: ["從不", "很少", "中等", "極大機會"]),
        ScaleQuestion("在公共場所坐著不動時", options: ["從不", "很少", "中等", "極大機會"]),
        ScaleQuestion("坐車連續一小時（非駕駛）", options: ["從不", "很少", "中等", "極大機會"]),
        ScaleQuestion("下午坐著靜靜休息時", options: ["從不", "很少", "中等", "極大機會"]),
        ScaleQuestion("飯後坐著（未飲酒）", options: ["從不", "很少", "中等", "極大機會"]),
      ],
    ),

// ==========================================
// 🩺 慢性病管理 (Chronic Disease)
// ==========================================

    ScaleType.bp_log: ScaleConfig(
      title: "血壓紀錄",
      unit: "mmHg",
      category: AppCategory.chronic,
      color: Colors.red.shade700,
      maxScore: 0,
      description: "請輸入早晚測量的血壓數值",
      questions: [
        ScaleQuestion("收縮壓 (Systolic)"),
        ScaleQuestion("舒張壓 (Diastolic)"),
        ScaleQuestion("心率 (Pulse)"),
      ],
    ),

    ScaleType.cat: ScaleConfig(
      title: "慢性呼吸道評估 (CAT)",
      category: AppCategory.chronic,
      color: Colors.cyan.shade800,
      maxScore: 5,
      description: "評估 COPD (慢性阻塞性肺病) 對生活的影響",
      questions: [
        ScaleQuestion("我從不咳嗽 <-> 我一直咳嗽", options: ["0", "1", "2", "3", "4", "5"]),
        ScaleQuestion("胸腔完全沒有痰 <-> 痰非常多", options: ["0", "1", "2", "3", "4", "5"]),
        ScaleQuestion("完全沒有胸悶感 <-> 胸悶非常嚴重", options: ["0", "1", "2", "3", "4", "5"]),
        ScaleQuestion("爬坡或一層樓不喘 <-> 感到非常喘", options: ["0", "1", "2", "3", "4", "5"]),
        ScaleQuestion("居家活動不受限 <-> 受限非常嚴重", options: ["0", "1", "2", "3", "4", "5"]),
        ScaleQuestion("我睡得很安穩 <-> 睡眠受呼吸影響", options: ["0", "1", "2", "3", "4", "5"]),
      ],
    ),

    ScaleType.dds: ScaleConfig(
      title: "糖尿病壓力評估 (DDS)",
      category: AppCategory.chronic,
      color: Colors.orange.shade900,
      maxScore: 6,
      description: "評估過去一個月糖尿病帶來的心理負擔",
      questions: [
        ScaleQuestion("感到糖尿病佔據了太多生活精力", options: ["沒問題", "極輕微", "輕微", "中度", "中重度", "嚴重"]),
        ScaleQuestion("擔心自己未能遵守飲食要求", options: ["沒問題", "極輕微", "輕微", "中度", "中重度", "嚴重"]),
        ScaleQuestion("覺得醫師不夠了解我的病情", options: ["沒問題", "極輕微", "輕微", "中度", "中重度", "嚴重"]),
        ScaleQuestion("對長期併發症感到恐懼", options: ["沒問題", "極輕微", "輕微", "中度", "中重度", "嚴重"]),
      ],
    ),

    ScaleType.bpi: ScaleConfig(
      title: "簡明疼痛量表 (BPI)",
      category: AppCategory.chronic, // 也可歸類在 pain
      color: Colors.redAccent.shade400,
      maxScore: 10,
      description: "評估疼痛強度及其對生活的干擾",
      questions: [
        ScaleQuestion("過去24小時最痛的程度 (0-10)"),
        ScaleQuestion("過去24小時平均疼痛程度 (0-10)"),
        ScaleQuestion("疼痛對日常工作的干擾 (0-10)"),
        ScaleQuestion("疼痛對睡眠的干擾 (0-10)"),
        ScaleQuestion("疼痛對情緒的干擾 (0-10)"),
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
      unit: "型", // 🚀 加上單位
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
      unit: "數據", // 或者根據題目動態處理
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