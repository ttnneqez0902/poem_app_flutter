import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'isar_service.dart';
import '../models/poem_record.dart';

class SyncManager {
  final IsarService isarService;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isSyncing = false; // 🚀 節流鎖

  SyncManager(this.isarService);

  Future<void> performPushSync() async {
    if (_isSyncing) return;

    // 1. 網路前置檢查
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    final uid = isarService._currentUid;
    if (uid == null) return;

    _isSyncing = true;
    final records = await isarService.getUnsyncedRecords();
    if (records.isEmpty) { _isSyncing = false; return; }

    final instance = await isarService.openDB();
    const int batchLimit = 400; // 避開 Firestore 500 限制

    try {
      for (int i = 0; i < records.length; i += batchLimit) {
        final chunk = records.skip(i).take(batchLimit).toList();

        // 2. 狀態鎖定 (使用原子寫入)
        await instance.writeTxn(() async {
          for (var r in chunk) {
            r.syncStatus = SyncStatus.syncing;
            r.lastSyncAttempt = DateTime.now(); // 🔒 不碰 updatedAt
          }
          await instance.poemRecords.putAll(chunk);
        });

        // 3. 執行 Batch Commit
        final batch = firestore.batch();
        for (var record in chunk) {
          final docRef = firestore.collection('users').doc(uid).collection('records').doc(record.recordId);
          batch.set(docRef, record.toFirestore());
        }

        try {
          await batch.commit();
          // 4. 批次成功：標記已同步
          await _updateLocalStatus(instance, chunk, SyncStatus.synced);
        } catch (e) {
          // 🚀 5. 單筆 Fallback：如果批次中有「毒藥資料」損毀，則改為單筆逐一嘗試
          await _performIndividualFallback(instance, uid, chunk);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _performIndividualFallback(Isar isar, String uid, List<PoemRecord> chunk) async {
    for (var record in chunk) {
      try {
        await firestore.collection('users').doc(uid).collection('records').doc(record.recordId).set(record.toFirestore());
        await isar.writeTxn(() async {
          record.syncStatus = SyncStatus.synced;
          await isar.poemRecords.put(record);
        });
      } catch (e) {
        await isar.writeTxn(() async {
          record.syncStatus = SyncStatus.failed;
          await isar.poemRecords.put(record);
        });
      }
    }
  }

  Future<void> _updateLocalStatus(Isar isar, List<PoemRecord> chunk, SyncStatus status) async {
    await isar.writeTxn(() async {
      for (var r in chunk) r.syncStatus = status;
      await isar.poemRecords.putAll(chunk);
    });
  }
}