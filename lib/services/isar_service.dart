import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/poem_record.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

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

  // 🚀 核心新增：獲取特定日期範圍內的紀錄
  // 用於 HomeScreen 計算 UAS7 七日進度
  Future<List<PoemRecord>> getRecordsInRange(DateTime start, DateTime end) async {
    final isar = await db;
    return await isar.poemRecords
        .filter()
        .dateBetween(start, end)
        .findAll();
  }

  // 獲取所有紀錄
  Future<List<PoemRecord>> getAllRecords() async {
    final isar = await db;
    return await isar.poemRecords.where().findAll();
  }

  // 儲存新紀錄
  Future<void> saveRecord(PoemRecord record) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.poemRecords.put(record);
    });
  }

  // 刪除紀錄
  Future<void> deleteRecord(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.poemRecords.delete(id);
    });
  }

  // 🚀 核心新增：更新照片授權狀態
  // 讓使用者能在歷史紀錄中隨時撤回報告顯示權限
  Future<void> updateImageConsent(Id id, bool consent) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final record = await isar.poemRecords.get(id);
      if (record != null) {
        record.imageConsent = consent;
        await isar.poemRecords.put(record);
      }
    });
  }

  // 根據日期與類型查詢（備用）
  Future<List<PoemRecord>> getRecordsByDateAndType(DateTime date, ScaleType type) async {
    final isar = await db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    return await isar.poemRecords
        .filter()
        .scaleTypeEqualTo(type)
        .dateBetween(startOfDay, endOfDay)
        .findAll();
  }
}