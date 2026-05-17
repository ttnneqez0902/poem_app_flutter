import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // 🚀 加上這行，才能使用 debugPrint
import '../models/poem_record.dart';

class IsarService {
  Isar? _isar;
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  // 🚀 補回：UI 層需要的 getter
  Isar get isar => _isar ?? (Isar.getInstance() ?? (throw "Isar not ready"));

  // 🚀 補回：UI 層需要的 init
  Future<void> init() async => await openDB();

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {

      final dir =
      await getApplicationDocumentsDirectory();

      _isar = await Isar.open(
        [PoemRecordSchema],
        directory: dir.path,

        // 🚀 關鍵修正
        name: 'eczema_data',

        inspector: true,
      );

    } else {

      _isar = Isar.getInstance(
        'eczema_data',
      );

    }

    return _isar!;
  }

  // 🚀 補回：UI 層需要的 updateInstance
  void updateInstance(Isar newIsar) => _isar = newIsar;

  // --- 🏥 查詢邏輯 ---

  Future<List<PoemRecord>> getAllRecords() async {
    final uid = currentUid;
    if (uid == null) return [];
    return await isar.poemRecords.filter().userIdEqualTo(uid).isDeletedEqualTo(false).sortByTargetDateDesc().findAll();
  }

  Future<List<PoemRecord>> getRecordsByCategory(List<ScaleType> types) async {
    final uid = currentUid;
    if (uid == null) return [];
    return await isar.poemRecords
        .filter()
        .userIdEqualTo(uid)
        .isDeletedEqualTo(false)
        .group((q) => q.anyOf(types, (q, t) => q.scaleTypeEqualTo(t)))
        .sortByTargetDateDesc()
        .findAll();
  }

  // 🚀 補回：統計過去幾天的紀錄數 (HomeScreen 用)
  Future<int> getRecordsCountInLastDays(int days) async {
    final uid = currentUid;
    if (uid == null) return 0;
    final startTime = DateTime.now().subtract(Duration(days: days));
    return await isar.poemRecords
        .filter()
        .userIdEqualTo(uid)
        .isDeletedEqualTo(false)
        .targetDateGreaterThan(startTime)
        .count();
  }

  // --- 📝 寫入與同步 ---

  Future<void> saveRecord(PoemRecord record) async {
    final uid = currentUid;
    if (uid == null) {
      debugPrint("❌ [IsarService] 存檔失敗：UID 為空");
      throw Exception("Unauthorized");
    }

    record
      ..userId = uid
      ..ensureId()
      ..updatedAt = DateTime.now()
      ..syncStatus = SyncStatus.pending
      ..isSynced = false
      ..isDeleted = record.isDeleted ?? false;

    debugPrint("💾 [IsarService] 準備寫入：類型=${record.scaleType}, 日期=${record.targetDate}, 身高=${record.height}");

    // 🚀 修正：只保留這一個寫入區塊即可
    await isar.writeTxn(() async {
      final generatedId = await isar.poemRecords.put(record);
      debugPrint("✅ [IsarService] 寫入完成！原生 ID 為: $generatedId");
    });

    // 🚀 診斷 Log 移到寫入後
    debugPrint("🚨 [存檔最後確認] 類型名字: ${record.scaleType.name}, 索引值: ${record.scaleType.index}");

  }

  // 🚀 補回：更新照片授權 (HistoryScreen 用)
  Future<void> updateImageConsent(Id id, bool consent) async {
    await isar.writeTxn(() async {
      final record = await isar.poemRecords.get(id);
      if (record != null) {
        record.imageConsent = consent;
        await isar.poemRecords.put(record);
      }
    });
  }

  Future<void> deleteRecord(Id id) async {
    final uid = currentUid;
    if (uid == null) return;
    await isar.writeTxn(() async {
      final record = await isar.poemRecords.get(id);
      if (record != null && record.userId == uid) {
        record.isDeleted = true;
        record.updatedAt = DateTime.now();
        record.syncStatus = SyncStatus.pending;
        await isar.poemRecords.put(record);
      }
    });
  }

  // 🚀 修正：移除參數 uid，改由內部自動獲取
  Future<List<PoemRecord>> getUnsyncedRecords() async {
    if (currentUid == null) return [];
    final now = DateTime.now();
    return await isar.poemRecords
        .filter()
        .userIdEqualTo(currentUid)
        .group((q) =>
        q.syncStatusEqualTo(SyncStatus.pending)
            .or().syncStatusEqualTo(SyncStatus.failed)
            .or().group((q) =>
            q.syncStatusEqualTo(SyncStatus.syncing)
                .and().lastSyncAttemptLessThan(now.subtract(const Duration(minutes: 10)))
        )
    ).findAll();
  }

  // 🚀 補回：批量標記同步的方法
  Future<void> markAsSynced(List<int> ids) async {
    final uid = currentUid;
    if (uid == null) return;
    await isar.writeTxn(() async {
      final records = await isar.poemRecords.getAll(ids);
      final toUpdate = records.whereType<PoemRecord>().where((r) => r.userId == uid).toList();
      for (var r in toUpdate) {
        r.syncStatus = SyncStatus.synced;
        r.isSynced = true;
      }
      await isar.poemRecords.putAll(toUpdate);
    });
  }
}