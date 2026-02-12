import 'package:isar/isar.dart';
part 'poem_record.g.dart';
// 🚀 修正 1: 確保 part 檔名與檔名一致 (假設此檔名為 poem_record.dart)


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

  @Index()
  bool isSynced = false; // 🚀 新增同步標記

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

  // 🚀 新增這個欄位來儲存臨床備註
  String? note;

  int get totalScore => score ?? 0;

  // 🚀 4. Firestore 同步方法：將物件轉為雲端 Map 格式
  // 🚀 修正 3: Firestore 轉換邏輯優化
  Map<String, dynamic> toFirestore() {
    return {
      // 'userId': userId, // 💡 其實可以不傳，因為 JSON 是存在該使用者的路徑下，省流量
      'score': score,
      'scaleType': scaleType.name,
      'type': type.name,
      'date': date?.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'imageConsent': imageConsent,
      'answers': answers,
      'note': note, // 🚀 同步備註到雲端
      // 'imagePath': imagePath, // 💡 手機路徑換手機就失效了，雲端紀錄建議不存這項
    };
  }

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