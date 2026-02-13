import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
// 🚀 核心關鍵：確保這一行沒有紅字，它是擴充方法的來源
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:isar/isar.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

enum BackupExceptionType {
  network,
  permission,
  storage,
  unknown,
}

class BackupException implements Exception {
  final BackupExceptionType type;
  final Object originalError;

  BackupException(this.type, this.originalError);

  @override
  String toString() => originalError.toString();
}


class CloudBackupService {
  // 🚀 注意：這裡不使用 final，因為熱切換會更換實例
  Isar isar;
  final Future<Isar> Function() isarFactory; // 傳入一個重新產生 Isar 的方法

  CloudBackupService({required this.isar, required this.isarFactory});

  static const String _dbFileName = 'eczema_data.isar';
  static const String _iCloudContainer = 'iCloud.com.your.app.bundle.id';


  Future<void> _clearAppDataFolder(drive.DriveApi api) async {
    final fileList = await api.files.list(
      spaces: 'appDataFolder',
    );

    if (fileList.files == null) return;

    for (final file in fileList.files!) {
      try {
        await api.files.delete(file.id!);
        debugPrint("🧹 Deleted old backup: ${file.name}");
      } catch (e) {
        debugPrint("⚠️ Failed to delete ${file.name}: $e");
      }
    }
  }



  Future<void> _verifyRestoredDatabase(String dbPath) async {
    final file = File(dbPath);

    if (!await file.exists()) {
      throw BackupException(
        BackupExceptionType.unknown,
        "Restore failed: database file not found",
      );
    }

    final size = await file.length();

    if (size == 0) {
      throw BackupException(
        BackupExceptionType.unknown,
        "Restore failed: database file is empty (0 byte)",
      );
    }

    // 🚀 安全下限（Isar 空 DB 通常 > 32KB）
    if (size < 32 * 1024) {
      throw BackupException(
        BackupExceptionType.unknown,
        "Restore failed: database file too small ($size bytes)",
      );
    }

    debugPrint("✅ Restore DB integrity check passed (${size} bytes)");
  }


  // --- [備份邏輯區] ---

  Future<void> performFullBackup(String photoDirPath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      // 💡 修正：備份時先建立一個 temp 檔，避免與正在讀取的 db 檔名衝突
      final dbBackupFile = File(p.join(docDir.path, 'temp_for_upload.isar'));

      if (await dbBackupFile.exists()) await dbBackupFile.delete();
      await isar.copyToFile(dbBackupFile.path);

      final photoDir = Directory(photoDirPath);
      List<File> photos = [];
      if (await photoDir.exists()) {
        photos = photoDir.listSync().whereType<File>().toList();
      }

      if (Platform.isAndroid) {
        await _backupToGoogleDrive(dbBackupFile, photos);
      } else if (Platform.isIOS) {
        //await _backupToICloud(dbBackupFile, photos);
        debugPrint("目前環境為 iOS，iCloud 功能暫時關閉");
      }

      if (await dbBackupFile.exists()) await dbBackupFile.delete();
    } catch (e) {
      debugPrint("備份失敗: $e");

      final msg = e.toString().toLowerCase();

      if (msg.contains('socket') ||
          msg.contains('timeout') ||
          msg.contains('network')) {
        throw BackupException(BackupExceptionType.network, e);
      }

      if (msg.contains('403') ||
          msg.contains('permission') ||
          msg.contains('unauthorized')) {
        throw BackupException(BackupExceptionType.permission, e);
      }

      if (msg.contains('quota') ||
          msg.contains('storage') ||
          msg.contains('space')) {
        throw BackupException(BackupExceptionType.storage, e);
      }

      throw BackupException(BackupExceptionType.unknown, e);
    }
  }




  Future<void> _uploadSingleFileToDrive(drive.DriveApi api, File file) async {
    final fileName = p.basename(file.path);
    final query = "name = '$fileName' and 'appDataFolder' in parents";
    final fileList = await api.files.list(q: query, spaces: 'appDataFolder');

    final driveFile = drive.File()..name = fileName..parents = ['appDataFolder'];
    final media = drive.Media(file.openRead(), file.lengthSync());

    if (fileList.files?.isNotEmpty ?? false) {
      await api.files.update(driveFile, fileList.files!.first.id!, uploadMedia: media);
    } else {
      await api.files.create(driveFile, uploadMedia: media);
    }
  }

  // --- [iCloud 實作] ---

  Future<void> _backupToICloud(File dbFile, List<File> photos) async {
    // 暫時清空內容
  }

  // --- [恢復邏輯區] ---

  // --- [ 核心：熱切換恢復邏輯 ] ---

  Future<void> performFullRestore(String photoDirPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempDbPath = p.join(tempDir.path, 'restored_db.isar');

      if (Platform.isAndroid) {
        await _restoreFromGoogleDrive(photoDirPath, tempDbPath);
      } else if (Platform.isIOS) {
        await _restoreFromICloud(photoDirPath, tempDbPath);
      }

      // 🔍 新增：完整性檢查（重點）
      await _verifyRestoredDatabase(tempDbPath);

      // 🔁 通過才允許熱切換
      await _hotSwapDatabase(tempDbPath);

      debugPrint("資料庫熱切換成功！");
    } catch (e) {
      debugPrint("恢復失敗: $e");
      rethrow;
    }
  }


  Future<void> _hotSwapDatabase(String tempDbPath) async {
    // 取得正式資料庫的路徑
    final docDir = await getApplicationDocumentsDirectory();
    final actualDbPath = p.join(docDir.path, _dbFileName);

    // A. 關閉當前 Isar 連線 (解鎖檔案)
    await isar.close();

    // 💡 建議：給作業系統一點點時間釋放檔案
    await Future.delayed(const Duration(milliseconds: 200));

    // 2. 搬移檔案
    final tempFile = File(tempDbPath);
    if (await tempFile.exists()) {
      // 💡 使用 copy 確保即便搬移失敗，tempFile 還在
      await tempFile.copy(actualDbPath);
      await tempFile.delete();
    }

    // 3. 重新打開連線
    isar = await isarFactory();
  }

  // --- [ Google Drive 恢復實作 ] ---
  Future<void> _restoreFromGoogleDrive(String photoDirPath, String tempDbPath) async {
    final photoDir = Directory(photoDirPath);
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    final googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope]);
    final account = await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
    if (account == null) return;

// ✅ 修正點：同樣使用此方式
    final headers = await account.authHeaders;

    final authClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          headers['Authorization']!.split(' ').last,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [drive.DriveApi.driveAppdataScope],
      ),
    );


    if (authClient == null) return;

    final api = drive.DriveApi(authClient);

    final fileList = await api.files.list(spaces: 'appDataFolder');
    if (fileList.files == null) return;

    for (var driveFile in fileList.files!) {
      final response = await api.files.get(
        driveFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final name = driveFile.name;

      String savePath =
      (name == _dbFileName || name == 'temp_for_upload.isar')
          ? tempDbPath
          : p.join(photoDirPath, name!);

      final file = File(savePath);
      final List<int> dataStore = [];
      await for (final data in response.stream) { dataStore.addAll(data); }
      await file.writeAsBytes(dataStore);
    }
  }

  // --- [Google Drive 實作] ---

  Future<void> _backupToGoogleDrive(File dbFile, List<File> photos) async {
    final googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveAppdataScope],
    );

    final account =
        await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
    if (account == null) return;

    final headers = await account.authHeaders;

    final authClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          headers['Authorization']!.split(' ').last,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [drive.DriveApi.driveAppdataScope],
      ),
    );

    if (authClient == null) {
      debugPrint("無法取得驗證客戶端");
      return;
    }

    // ✅ authClient 已存在，現在才能建 api
    final api = drive.DriveApi(authClient);

    // 🧹 清空舊備份
    await _clearAppDataFolder(api);

    // ⬆️ 上傳 DB
    await _uploadSingleFileToDrive(api, dbFile);

    // ⬆️ 上傳照片
    for (final photo in photos) {
      await _uploadSingleFileToDrive(api, photo);
    }
  }

  // --- [ iCloud 恢復實作 ] ---
  Future<void> _restoreFromICloud(String photoDirPath, String tempDbPath) async {
    // 🚀 修正：因為 import 被註解了，這裡也要先註解掉，否則編譯會失敗
    /* final fileList = await ICloudStoragePlus.gather(containerId: _iCloudContainer);

    for (var fileName in fileList) {
      String savePath = (fileName == _dbFileName) ? tempDbPath : p.join(photoDirPath, fileName);

      await ICloudStoragePlus.download(
        containerId: _iCloudContainer,
        fileName: fileName,
        destinationFilePath: savePath,
      );
    }
    */
    debugPrint("目前環境 iOS iCloud 恢復功能暫時關閉");
  }
}