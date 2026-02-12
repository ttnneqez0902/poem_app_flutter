import 'package:isar/isar.dart';
part 'poem_record.g.dart';

enum RecordType { daily, weekly }
enum ScaleType { poem, uas7, scorad, adct }

@collection
class PoemRecord {
  Id id = Isar.autoIncrement;

  // 🚀 1. 核心帳號關聯：儲存 Firebase UID，用於換手機同步
  @Index()
  String? userId;

  // 🚀 2. 實際錄入時間：系統自動紀錄 (用於顯示「錄入於 02/12 12:45」)
  @Index()
  DateTime? date;

  // 🚀 3. 目標歸屬日期：使用者選定的日期 (用於趨勢圖 X 軸與 3/14 天統計)
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

  // 🚀 4. Firestore 同步方法：將物件轉為雲端 Map 格式
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'score': score,
    'scaleType': scaleType.name,
    'type': type.name,
    'date': date?.toIso8601String(),
    'targetDate': targetDate?.toIso8601String(),
    'imagePath': imagePath, // 注意：換手機路徑會失效，需另行處理 Storage
    'imageConsent': imageConsent,
    'answers': answers,
  };

  // 🩺 5. 臨床嚴重度標籤邏輯
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