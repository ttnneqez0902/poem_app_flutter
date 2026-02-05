import 'package:isar/isar.dart';

part 'poem_record.g.dart';

enum RecordType { daily, weekly }
enum ScaleType { poem, uas7, scorad }

@collection
class PoemRecord {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime? date;

  // ✅ 1. 量表類型 (POEM / UAS7 / SCORAD)
  @enumerated
  @Index()
  ScaleType scaleType = ScaleType.poem;

  // ✅ 2. 紀錄頻率 (簡易打卡 vs 完整量表)
  @enumerated
  RecordType type = RecordType.weekly;

  // --- 核心分數區 ---
  int? score;         // 量表總分 (POEM 0-28, UAS7 0-6, SCORAD自測 0-20)
  List<int>? answers; // 原始答案列表 (動態長度)

  // --- 症狀 NRS/VAS 區 (通用於各量表) ---
  int? dailyItch;     // 癢度 (通用)
  int? dailySleep;    // 睡眠影響 (通用)

  // --- UAS7 專用區 ---
  int? whealsCount;   // 蕁麻疹風疹塊數量 (0-3)

  String? imagePath;
// ✅ 核心新增：是否授權於報告中顯示照片
  // 預設為 true，符合您「預設打勾」的設計邏輯
  bool? imageConsent = true;

  // 門診呈現捷徑
  int get totalScore => score ?? 0;

  // ✅ 3. 動態嚴重度標籤
  String get severityLabel {
    if (scaleType == ScaleType.uas7) return "UAS7 每日紀錄";
    if (scaleType == ScaleType.scorad) return "SCORAD 自評";

    // 原本的 POEM 嚴重度邏輯
    if (type == RecordType.daily) return "每日打卡";
    final s = score ?? 0;
    if (s <= 2) return "無或極輕微";
    if (s <= 7) return "輕微";
    if (s <= 16) return "中度";
    if (s <= 24) return "重度";
    return "極重度";
  }
}