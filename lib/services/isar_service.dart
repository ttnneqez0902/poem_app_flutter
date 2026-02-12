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

  // 🚀 補回缺失的方法：更新照片授權狀態
  Future<void> updateImageConsent(Id id, bool consent) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final record = await isar.poemRecords.get(id);
      if (record != null) {
        record.imageConsent = consent; // 確保你的模型裡欄位是叫 imageConsent
        await isar.poemRecords.put(record);
      }
    });
  }

  // 🚀 優化 1：獲取未同步紀錄 (供 UI 打包上傳使用)
  // 🚀 同時檢查：確保 getUnsyncedRecords 裡的欄位名稱正確
  Future<List<PoemRecord>> getUnsyncedRecords(String? uid) async {
    if (uid == null) return [];
    final isar = await db;
    return await isar.poemRecords
        .filter()
        .userIdEqualTo(uid)
        .isSyncedEqualTo(false) // 👈 執行完 build_runner 後這行就不會報錯了
        .findAll();
  }

  // 🚀 優化 2：單純化儲存邏輯
  // 不要在 Service 裡面直接寫 Firestore.add，這會破壞「每 2 筆才同步」的規則
  Future<void> saveRecord(PoemRecord record) async {
    final isar = await db;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      record.userId = user.uid;
    }

    await isar.writeTxn(() async {
      await isar.poemRecords.put(record); // 本地存檔是唯一的真理
    });

    // 💡 註：Firestore 的同步現在由 UI 層的 syncRecordsOptimized() 負責調度
  }

  // --- 其他查詢方法保持不變 ---

  Future<List<PoemRecord>> getRecordsInRange(DateTime start, DateTime end) async {
    final isar = await db;
    return await isar.poemRecords
        .filter()
        .targetDateBetween(start, end)
        .findAll();
  }

  Future<List<PoemRecord>> getAllRecords() async {
    final isar = await db;
    return await isar.poemRecords.where().findAll();
  }

// 🚀 優化：批次儲存並防止重複
  Future<void> saveAllRecords(List<PoemRecord> records) async {
    final isar = await db;
    await isar.writeTxn(() async {
      for (var record in records) {
        // 檢查本地是否已經有「同日期、同類型」的紀錄
        final existing = await isar.poemRecords
            .filter()
            .targetDateEqualTo(record.targetDate)
            .scaleTypeEqualTo(record.scaleType)
            .findFirst();

        if (existing == null) {
          await isar.poemRecords.put(record);
        } else {
          // 如果已存在，可以選擇更新或是跳過
          record.id = existing.id; // 保持 ID 一致，進行覆蓋更新
          await isar.poemRecords.put(record);
        }
      }
    });
  }

  Future<void> markAsSynced(List<int> ids) async {
    final isar = await db;
    await isar.writeTxn(() async {
      // 一次抓出所有需要更新的對象
      final records = await isar.poemRecords.getAll(ids);
      final toUpdate = <PoemRecord>[];

      for (var r in records) {
        if (r != null) {
          r.isSynced = true;
          toUpdate.add(r);
        }
      }
      // 使用 putAll 效能更好
      await isar.poemRecords.putAll(toUpdate);
    });
  }

  // 🚀 新增：登出時清空本地快取
  Future<void> clearAllData() async {
    final isar = await db;
    await isar.writeTxn(() => isar.poemRecords.clear());
  }

  Future<void> deleteRecord(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.poemRecords.delete(id);
    });
  }

  Future<List<PoemRecord>> getRecordsByDateAndType(DateTime date, ScaleType type) async {
    final isar = await db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    return await isar.poemRecords
        .filter()
        .scaleTypeEqualTo(type)
        .targetDateBetween(startOfDay, endOfDay)
        .findAll();
  }
}