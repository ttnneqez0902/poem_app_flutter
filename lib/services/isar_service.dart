import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/poem_record.dart';
import '../models/poem_record.dart'; // 確保這行路徑正確

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  // 初始化資料庫
  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [PoemRecordSchema],
        directory: dir.path,
      );
    }
    return Isar.getInstance()!;
  }

  // 儲存檢測紀錄
  Future<void> saveRecord(PoemRecord record) async {
    final isar = await db;
    isar.writeTxnSync(() => isar.poemRecords.putSync(record));
  }

  // 獲取所有紀錄（依日期排序，給趨勢圖用）
  Future<List<PoemRecord>> getAllRecords() async {
    final isar = await db;
    return await isar.poemRecords.where().sortByDate().findAll();
  }

  // ✅ 新增：僅獲取每日紀錄 (給每日曲線用)
  Future<List<PoemRecord>> getDailyLogs() async {
    final isar = await db;
    // 確保 .g.dart 更新後，這裡就不會噴紅字了
    return await isar.poemRecords.filter().typeEqualTo(RecordType.daily).sortByDate().findAll();
  }

  // ✅ 新增：僅獲取每週 POEM (給長線趨勢用)
  Future<List<PoemRecord>> getWeeklyPoems() async {
    final isar = await db;
    return await isar.poemRecords.filter().typeEqualTo(RecordType.weekly).sortByDate().findAll();
  }

  // 1. 新增：刪除單筆紀錄的方法
  Future<void> deleteRecord(Id id) async {
    final isar = await db;
    // 使用寫入事務執行刪除動作
    await isar.writeTxn(() => isar.poemRecords.delete(id));
  }
}