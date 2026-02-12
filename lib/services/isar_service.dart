import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🚀 新增：處理登入狀態
import 'package:cloud_firestore/cloud_firestore.dart'; // 🚀 確保這行不報紅
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

  // 🚀 核心修正 1：查詢範圍統一改用 targetDate (歸屬日期)
  Future<List<PoemRecord>> getRecordsInRange(DateTime start, DateTime end) async {
    final isar = await db;
    return await isar.poemRecords
        .filter()
        .targetDateBetween(start, end) // 改用歸屬日，統計才精確
        .findAll();
  }

  // 獲取所有紀錄
  Future<List<PoemRecord>> getAllRecords() async {
    final isar = await db;
    return await isar.poemRecords.where().findAll();
  }

  // 🚀 核心修正 2：儲存紀錄時自動標記 UID 並同步雲端
  Future<void> saveRecord(PoemRecord record) async {
    final isar = await db;
    final user = FirebaseAuth.instance.currentUser;

    // 自動標記當前使用者 ID
    if (user != null) {
      record.userId = user.uid;
    }

    // 本地儲存
    await isar.writeTxn(() async {
      await isar.poemRecords.put(record);
    });

    // 🚀 同步至雲端 Firestore
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('records')
            .add(record.toFirestore());
      } catch (e) {
        print("雲端備份失敗，但本地已儲存: $e");
      }
    }
  }

  // 🚀 核心新增 3：批次儲存 (用於登入後從雲端下載資料)
  Future<void> saveAllRecords(List<PoemRecord> records) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.poemRecords.putAll(records);
    });
  }

  // 刪除紀錄
  Future<void> deleteRecord(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.poemRecords.delete(id);
    });
    // 💡 註：雲端同步刪除建議透過 cloudDocId 進行，此處先維持基礎本地刪除
  }

  // 更新照片授權狀態
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

  // 🚀 核心修正 4：根據歸屬日與類型查詢
  Future<List<PoemRecord>> getRecordsByDateAndType(DateTime date, ScaleType type) async {
    final isar = await db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    return await isar.poemRecords
        .filter()
        .scaleTypeEqualTo(type)
        .targetDateBetween(startOfDay, endOfDay) // 關鍵：對齊歸屬日
        .findAll();
  }
}