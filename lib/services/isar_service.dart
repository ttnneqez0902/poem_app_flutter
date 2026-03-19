import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poem_record.dart'; // 建議未來重命名為 health_record.dart

class IsarService {
  Isar? _isar;

  Isar get db => _isar ?? (Isar.getInstance() ?? (throw Exception("Isar 尚未初始化")));
  Isar get isar => db;

  Future<void> init() async {
    await openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [
          PoemRecordSchema,
          // 🚀 未來在這裡加入新 Schema，例如：
          // PsychiatryRecordSchema,
          // PainRecordSchema,
        ],
        directory: dir.path,
        inspector: true, // 開發模式建議開啟，方便查看數據
      );
    } else {
      _isar = Isar.getInstance() ?? await _isarReopen();
    }
    return _isar!;
  }

  // 封裝重複的開檔邏輯
  Future<Isar> _isarReopen() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open([PoemRecordSchema], directory: dir.path);
  }

  void updateInstance(Isar newIsar) {
    _isar = newIsar;
  }

  Future<Isar> _ensureIsar() async {
    if (_isar != null) return _isar!;
    return await openDB();
  }

  // 🚀 核心修正 1：補回主畫面與問卷需要的同步查詢
  Future<List<PoemRecord>> getUnsyncedRecords(String? uid) async {
    if (uid == null) return [];
    final instance = await _ensureIsar();
    return await instance.poemRecords
        .filter()
        .userIdEqualTo(uid)
        .isSyncedEqualTo(false)
        .findAll();
  }

  // 🚀 核心修正 2：補回批量標記同步的方法
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

  // --- 🏥 數據查詢邏輯優化 ---

  /// 🚀 核心改進：新增依「量表類型」抓取數據
  /// 這樣身心科才能只抓 PHQ-9，皮膚科只抓 POEM
  Future<List<PoemRecord>> getRecordsByType(ScaleType type) async {
    final instance = await _ensureIsar();
    return await instance.poemRecords
        .filter()
        .scaleTypeEqualTo(type)
        .sortByDateDesc()
        .findAll();
  }

  /// 🚀 核心改進：依「科別」抓取一組量表
  /// 例如傳入 AppCategory.psychiatry，就抓出 PHQ-9 和 GAD-7
  Future<List<PoemRecord>> getRecordsByCategory(List<ScaleType> types) async {
    final instance = await _ensureIsar();
    return await instance.poemRecords
        .filter()
        .anyOf(types, (q, type) => q.scaleTypeEqualTo(type))
        .sortByDateDesc()
        .findAll();
  }

  Future<List<PoemRecord>> getAllRecords() async {
    final instance = await _ensureIsar();
    return await instance.poemRecords.where().sortByDateDesc().findAll();
  }

  // --- 📝 數據寫入邏輯 ---

  Future<void> saveRecord(PoemRecord record) async {
    final instance = await _ensureIsar();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      record.userId = user.uid;
    }
    // 儲存前確保時間戳記完整
    record.date ??= DateTime.now();

    await instance.writeTxn(() async {
      await instance.poemRecords.put(record);
    });
  }

  // 🚀 保持 saveAllRecords 的去重邏輯，這是還原數據時的關鍵
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
          record.id = existing.id; // 覆蓋舊資料
          await instance.poemRecords.put(record);
        }
      }
    });
  }

  // --- 其餘輔助方法保持不變 ---

  Future<int> getRecordsCountInLastDays(int days) async {
    final startTime = DateTime.now().subtract(Duration(days: days));
    final instance = await _ensureIsar();
    return await instance.poemRecords.filter().dateGreaterThan(startTime).count();
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

  Future<void> deleteRecord(Id id) async {
    final instance = await _ensureIsar();
    await instance.writeTxn(() => instance.poemRecords.delete(id));
  }
}