import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poem_record.dart';

class IsarService {
  Isar? _isar;

  // 🚀 關鍵修正：將 getter 名稱改為 db，解決 BootstrapController 的報錯
  // 這樣 `isarService.db` 就會指向 `_isar`
  Isar get db {
    if (_isar == null) {
      // 這裡不丟 Exception，而是嘗試自動回傳實例或拋出更有用的訊息
      return Isar.getInstance() ?? (throw Exception("Isar 尚未初始化"));
    }
    return _isar!;
  }

  // 為了保險起見，也可以保留 isar 這個名字（如果你其他地方有用到）
  Isar get isar => db;

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [PoemRecordSchema],
        directory: dir.path,
      );
    } else {
      _isar = Isar.getInstance()!;
    }
    return _isar!;
  }

  // 輔助方法：確保每次操作前 Isar 是開著的
  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    return await openDB();
  }

  // --- 以下是原本的功能，確保都使用 _ensureIsar() 以保證安全 ---

  Future<int> getRecordsCountInLastDays(int days) async {
    final startTime = DateTime.now().subtract(Duration(days: days));
    final instance = await _ensureIsar();
    return await instance.poemRecords
        .filter()
        .dateGreaterThan(startTime)
        .count();
  }

  Future<void> updateImageConsent(Id id, bool consent) async {
    final instance = await _ensureIsar();
    await instance.writeTxn(() async {
      final record = await instance.poemRecords.get(id);
      if (record != null) {
        record.imageConsent = consent;
        await instance.poemRecords.put(record);
      }
    });
  }

  Future<List<PoemRecord>> getUnsyncedRecords(String? uid) async {
    if (uid == null) return [];
    final instance = await _ensureIsar();
    return await instance.poemRecords
        .filter()
        .userIdEqualTo(uid)
        .isSyncedEqualTo(false)
        .findAll();
  }

  Future<void> saveRecord(PoemRecord record) async {
    final instance = await _ensureIsar();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      record.userId = user.uid;
    }
    await instance.writeTxn(() async {
      await instance.poemRecords.put(record);
    });
  }

  Future<List<PoemRecord>> getRecordsInRange(DateTime start, DateTime end) async {
    final instance = await _ensureIsar();
    return await instance.poemRecords
        .filter()
        .targetDateBetween(start, end)
        .findAll();
  }

  Future<List<PoemRecord>> getAllRecords() async {
    final instance = await _ensureIsar();
    return await instance.poemRecords.where().findAll();
  }

  Future<void> saveAllRecords(List<PoemRecord> records) async {
    final instance = await _ensureIsar();
    await instance.writeTxn(() async {
      for (var record in records) {
        final existing = await instance.poemRecords
            .filter()
            .targetDateEqualTo(record.targetDate)
            .scaleTypeEqualTo(record.scaleType)
            .findFirst();

        if (existing == null) {
          await instance.poemRecords.put(record);
        } else {
          record.id = existing.id;
          await instance.poemRecords.put(record);
        }
      }
    });
  }

  Future<void> markAsSynced(List<int> ids) async {
    final instance = await _ensureIsar();
    await instance.writeTxn(() async {
      final records = await instance.poemRecords.getAll(ids);
      final toUpdate = <PoemRecord>[];
      for (var r in records) {
        if (r != null) {
          r.isSynced = true;
          toUpdate.add(r);
        }
      }
      await instance.poemRecords.putAll(toUpdate);
    });
  }

  Future<void> clearAllData() async {
    final instance = await _ensureIsar();
    await instance.writeTxn(() => instance.poemRecords.clear());
  }

  Future<void> deleteRecord(Id id) async {
    final instance = await _ensureIsar();
    await instance.writeTxn(() async {
      await instance.poemRecords.delete(id);
    });
  }
}