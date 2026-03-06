import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poem_record.dart';

class IsarService {
  Isar? _isar;

  // 🚀 核心 Getter：供 Controller 與外部訪問
  Isar get db => _isar ?? (Isar.getInstance() ?? (throw Exception("Isar 尚未初始化")));
  Isar get isar => db;

  // 🚀 修正 1：對齊 main.dart 的初始化名稱
  Future<void> init() async {
    await openDB();
  }

  Future<Isar> openDB() async {
    // 檢查是否已經有實例在跑
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [PoemRecordSchema],
        directory: dir.path,
      );
    } else {
      // 🚀 優化點：如果 getInstance 回傳 null，可以試著重新執行一次開檔
      _isar = Isar.getInstance() ?? await Isar.open(
        [PoemRecordSchema],
        directory: (await getApplicationDocumentsDirectory()).path,
      );
    }
    return _isar!;
  }

  // 🚀 修正 2：新增熱切換方法 (供 CloudBackupService 使用)
  // 當雲端還原成功後，調用此方法讓全域實例指向新資料庫
  void updateInstance(Isar newIsar) {
    _isar = newIsar;
  }

  // 輔助方法：確保每次操作前 Isar 是開著的
  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    return await openDB();
  }

  // --- [ 數據管理架構圖 ] ---
  //

  // --- 以下功能邏輯保持不變，但確保使用 _ensureIsar() ---

  Future<int> getRecordsCountInLastDays(int days) async {
    final startTime = DateTime.now().subtract(Duration(days: days));
    final instance = await _ensureIsar();
    return await instance.poemRecords
        .filter()
        .dateGreaterThan(startTime)
        .count();
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

// 🚀 核心修正：補上 HomeScreen 需要的 getAllRecords
  Future<List<PoemRecord>> getAllRecords() async {
    final instance = await _ensureIsar();
    // 預設按日期降序排列
    return await instance.poemRecords.where().sortByDateDesc().findAll();
  }

  // 🚀 核心修正：補上 HistoryListScreen 需要的 updateImageConsent
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

  // 🚀 這裡的邏輯很好：saveAllRecords 內建了去重檢查
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