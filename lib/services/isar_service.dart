import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/poem_record.dart';

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

  // 1. 新增：刪除單筆紀錄的方法
  Future<void> deleteRecord(Id id) async {
    final isar = await db;
    // 使用寫入事務執行刪除動作
    await isar.writeTxn(() => isar.poemRecords.delete(id));
  }
}