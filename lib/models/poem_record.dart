import 'package:isar/isar.dart';

part 'poem_record.g.dart';

@collection
class PoemRecord {
  Id id = Isar.autoIncrement; // 自動生成 ID
// 在 PoemRecord 類別大括號內加入
  String get severity {
    if (totalScore <= 2) return "無濕疹或極輕微";
    if (totalScore <= 7) return "輕微";
    if (totalScore <= 16) return "中度";
    if (totalScore <= 24) return "重度";
    return "極重度";
  }

  @Index()
  late DateTime date; // 紀錄日期

  late List<int> scores; // 儲存 7 題的分數
  String? imagePath; // 新增：儲存本地照片路徑

  // 計算總分 $S = \sum_{i=1}^{n} score_i$
  int get totalScore => scores.reduce((a, b) => a + b);

  // 嚴重程度判定邏輯
  String get severityLabel {
    if (totalScore <= 2) return "極輕微";
    if (totalScore <= 7) return "輕微";
    if (totalScore <= 16) return "中度";
    if (totalScore <= 24) return "重度";
    return "極重度";
  }
}