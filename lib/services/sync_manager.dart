import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'isar_service.dart';
import '../models/poem_record.dart';

class SyncResult {
  final int total;
  final int success;
  final int failed;
  SyncResult({this.total = 0, this.success = 0, this.failed = 0});
}

class SyncManager {
  final IsarService isarService;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isSyncing = false;

  SyncManager(this.isarService);

  Future<SyncResult> performPushSync() async {
    if (_isSyncing) return SyncResult();

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return SyncResult();

    // 🚀 這裡會對應到 IsarService 的公開 getter
    final uid = isarService.currentUid;
    if (uid == null) return SyncResult();

    _isSyncing = true;
    int totalProcessed = 0;
    int successCount = 0;

    try {
      final records = await isarService.getUnsyncedRecords();
      if (records.isEmpty) return SyncResult();

      totalProcessed = records.length;
      const int batchLimit = 400;

      for (int i = 0; i < records.length; i += batchLimit) {
        final chunk = records.skip(i).take(batchLimit).toList();

        await isarService.isar.writeTxn(() async {
          for (var r in chunk) {
            r.syncStatus = SyncStatus.syncing;
            r.lastSyncAttempt = DateTime.now();
          }
          await isarService.isar.poemRecords.putAll(chunk);
        });

        final batch = firestore.batch();
        for (var record in chunk) {
          final docRef = firestore.collection('users').doc(uid).collection('records').doc(record.recordId!);
          batch.set(docRef, record.toFirestore());
        }

        try {
          await batch.commit();
          await isarService.markAsSynced(chunk.map((e) => e.id).toList());
          successCount += chunk.length;
        } catch (e) {
          // 🚀 Fallback 單筆處理
          await _performIndividualFallback(isarService.isar, uid, chunk);
        }
      }
      return SyncResult(total: totalProcessed, success: successCount, failed: totalProcessed - successCount);
    } finally {
      _isSyncing = false;
    }
  } // <--- 這是 performPushSync 的結束

  // 🚀 修正點：確保以下方法在大括號內，這樣才能抓到 class 內的 firestore
  Future<void> _performIndividualFallback(Isar isar, String uid, List<PoemRecord> chunk) async {
    for (var record in chunk) {
      try {
        await firestore.collection('users').doc(uid).collection('records').doc(record.recordId!).set(record.toFirestore());
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
} // <--- 這是 SyncManager class 的唯一結束大括號