import 'package:isar/isar.dart';

part 'poem_record.g.dart';

// 定義紀錄類型：每日簡易 vs 每週 POEM
enum RecordType { daily, weekly }

@collection
class PoemRecord {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime? date;

  // ✅ 新增：紀錄類型 (預設為每週，相容舊資料)
  @enumerated
  RecordType type = RecordType.weekly;

  // --- 每週 POEM 專用 ---
  int? score;
  List<int>? answers;

  // --- 每日問卷專用 (0-10 分) ---
  int? dailyItch;     // 癢度 NRS
  int? dailySleep;    // 睡眠影響 NRS

  String? imagePath;

  // 門診呈現捷徑
  int get totalScore => score ?? 0;

  String get severityLabel {
    if (type == RecordType.daily) return "每日打卡";
    final s = score ?? 0;
    if (s <= 2) return "無或極輕微";
    if (s <= 7) return "輕微";
    if (s <= 16) return "中度";
    if (s <= 24) return "重度";
    return "極重度";
  }
}