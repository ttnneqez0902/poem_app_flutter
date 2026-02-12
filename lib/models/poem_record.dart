import 'package:isar/isar.dart';
part 'poem_record.g.dart';

enum RecordType { daily, weekly }
enum ScaleType { poem, uas7, scorad, adct }

@collection
class PoemRecord {
  Id id = Isar.autoIncrement;

  // 🚀 1. 實際錄入時間 (系統自動紀錄，用於顯示 02/12 12:45)
  // 這對應你截圖中想要標示「錄入於何時」的功能
  @Index()
  DateTime? date;

  // 🚀 2. 目標歸屬日期 (使用者在日曆上選的那一天，例如補填 01/29 的資料)
  // 如果沒有補填，通常會跟 date 是同一天
  @Index()
  DateTime? targetDate;

  @enumerated
  @Index()
  ScaleType scaleType = ScaleType.adct;

  @enumerated
  RecordType type = RecordType.weekly;

  int? score;
  List<int>? answers;
  int? dailyItch;
  int? dailySleep;
  int? whealsCount;
  String? imagePath;
  bool? imageConsent = true;

  int get totalScore => score ?? 0;

  // 🩺 臨床嚴重度標籤邏輯
  String get severityLabel {
    final s = score ?? 0;
    if (scaleType == ScaleType.adct) return s >= 7 ? "控制不佳" : "控制良好";
    if (scaleType == ScaleType.uas7) {
      if (s >= 28) return "嚴重活性";
      if (s >= 16) return "中度活性";
      return "輕微/無活性";
    }
    if (scaleType == ScaleType.poem) {
      if (s <= 2) return "無或極輕微";
      if (s <= 7) return "輕微";
      if (s <= 16) return "中度";
      if (s <= 24) return "重度";
      return "極重度";
    }
    return "已紀錄";
  }
}