import 'package:isar/isar.dart';

part 'poem_record.g.dart';

@collection
class PoemRecord {
  Id id = Isar.autoIncrement; // 自動生成 ID

  @Index()
  DateTime? date;

  int? score;          // 儲存總分 (這對應到您 Survey 頁面算出來的 totalScore)

  List<int>? answers;  // 儲存 7 題的答案細項 (這對應到您 Survey 頁面的 _answers)

  String? imagePath;   // 儲存照片路徑

  int get totalScore => score ?? 0;

  // 📋 嚴重程度判定邏輯 (getter)
  // 自動根據 score 欄位回傳文字
  String get severityLabel {
    final s = score ?? 0; // 防呆：如果是 null 就當作 0 分

    if (s <= 2) return "無濕疹或極輕微";
    if (s <= 7) return "輕微";
    if (s <= 16) return "中度";
    if (s <= 24) return "重度";
    return "極重度";
  }
}