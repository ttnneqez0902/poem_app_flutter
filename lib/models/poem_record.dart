import 'package:isar/isar.dart';
part 'poem_record.g.dart';

enum RecordType { daily, weekly }
enum ScaleType { poem, uas7, scorad, adct }

@collection
class PoemRecord {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime? date;

  @enumerated
  @Index()
  ScaleType scaleType = ScaleType.adct; // 🚀 修正：移除重複宣告

  @enumerated
  RecordType type = RecordType.weekly;

  int? score;         // 量表總分
  List<int>? answers; // 原始答案
  int? dailyItch;
  int? dailySleep;
  int? whealsCount;
  String? imagePath;
  bool? imageConsent = true;

  int get totalScore => score ?? 0;

  // 🩺 各量表臨床判定邏輯
  String get severityLabel {
    final s = score ?? 0;
    if (scaleType == ScaleType.adct) return s >= 7 ? "控制不佳" : "控制良好";
    if (scaleType == ScaleType.uas7) return s >= 28 ? "嚴重活性" : (s >= 16 ? "中度活性" : "輕微/無活性");
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