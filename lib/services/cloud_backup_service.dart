import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:isar/isar.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:icloud_storage/icloud_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- [ 1. 數據模型與異常定義 ] ---

class BackupProgress {
  final String message;
  final int current;
  final int total;
  final double progress;

  BackupProgress({required this.message, required this.current, required this.total})
      : progress = total > 0 ? current / total : 0;
}

class BackupMetadata {
  final DateTime createdAt;
  final String appVersion;
  final int schemaVersion;
  final String provider;

  BackupMetadata({
    required this.createdAt,
    required this.appVersion,
    this.schemaVersion = 1,
    required this.provider,
  });

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'provider': provider,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    createdAt: DateTime.parse(json['createdAt']),
    appVersion: json['appVersion'] ?? 'unknown',
    schemaVersion: json['schemaVersion'] ?? 1,
    provider: json['provider'] ?? 'unknown',
  );
}

enum BackupExceptionType { network, permission, storage, incomplete, unknown }

class BackupException implements Exception {
  final BackupExceptionType type;
  final String message;
  final Object? originalError;

  BackupException(this.type, this.message, [this.originalError]);

  @override
  String toString() => "BackupException($type): $message";
}

enum CloudProvider { googleDrive, iCloud, none }

// --- [ 2. 核心服務實作 ] ---

/// 🚀 CloudBackupService 產品級終極定版
class CloudBackupService {
  Isar isar;
  final Future<Isar> Function() isarFactory;
  final GoogleSignIn googleSignIn;
  // 🚀 新增：當資料庫切換完成時的通知，確保全局實體同步
  final Function(Isar newIsar)? onDbSwapped;

  static const int currentSchemaVersion = 1;
  static const String _dbFileName = 'eczema_data.isar';
  static const String _metaFileName = 'backup_info.json';
  static const String _progressFlag = '.backup_in_progress';
  static const String _iCloudContainer = 'iCloud.com.your.app.bundle.id';

  CloudBackupService({
    required this.isar,
    required this.isarFactory,
    required this.googleSignIn,
    this.onDbSwapped,
  });

  CloudProvider get effectiveProvider {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return CloudProvider.none;
    for (final info in user.providerData) {
      if (info.providerId == 'apple.com') return CloudProvider.iCloud;
      if (info.providerId == 'google.com') return CloudProvider.googleDrive;
    }
    return Platform.isIOS ? CloudProvider.iCloud : CloudProvider.googleDrive;
  }

  // --- [ 3. 統一對外接口 ] ---

  Future<void> runBackup(String photoDirPath, {required String appVersion, void Function(BackupProgress)? onProgress}) async {
    final provider = effectiveProvider;
    if (provider == CloudProvider.none) throw BackupException(BackupExceptionType.permission, "請先登入雲端帳號");

    try {
      onProgress?.call(BackupProgress(message: "正在快照數據庫...", current: 0, total: 100));
      final docDir = await getApplicationDocumentsDirectory();
      final dbBackupFile = File(p.join(docDir.path, 'temp_for_upload.isar'));

      if (await dbBackupFile.exists()) await dbBackupFile.delete();
      await isar.copyToFile(dbBackupFile.path);

      // 🚀 修正 1：非同步處理照片列表
      final List<File> photos = [];
      final photoDir = Directory(photoDirPath);
      if (await photoDir.exists()) {
        await for (var entity in photoDir.list()) {
          if (entity is File) photos.add(entity);
        }
      }

      final meta = BackupMetadata(
        createdAt: DateTime.now(),
        appVersion: appVersion,
        schemaVersion: currentSchemaVersion,
        provider: provider.name,
      );

      if (provider == CloudProvider.googleDrive) {
        await _backupToGoogleDrive(dbBackupFile, photos, meta, onProgress);
      } else {
        await _backupToICloud(dbBackupFile, photos, meta, onProgress);
      }

      if (await dbBackupFile.exists()) await dbBackupFile.delete();
      onProgress?.call(BackupProgress(message: "雲端備份完成", current: 100, total: 100));
    } catch (e) {
      throw _parseException(e);
    }
  }

  Future<void> runRestore(String photoDirPath, {void Function(BackupProgress)? onProgress}) async {
    final provider = effectiveProvider;
    if (provider == CloudProvider.none) throw BackupException(BackupExceptionType.permission, "請先登入");

    try {
      onProgress?.call(BackupProgress(message: "正在核對備份資訊...", current: 5, total: 100));
      final meta = await getBackupPreview();
      if (meta == null) throw BackupException(BackupExceptionType.incomplete, "找不到雲端備份紀錄");

      if (meta.schemaVersion > currentSchemaVersion) {
        throw BackupException(BackupExceptionType.incomplete, "備份檔案較新，請先更新 App 再還原");
      }

      await _safeClearLocalPhotos(photoDirPath);
      final tempDir = await getTemporaryDirectory();
      final tempDbPath = p.join(tempDir.path, 'restored_db.isar');

      if (provider == CloudProvider.googleDrive) {
        await _restoreFromGoogleDrive(photoDirPath, tempDbPath, onProgress);
      } else {
        await _restoreFromICloud(photoDirPath, tempDbPath, onProgress);
      }

      onProgress?.call(BackupProgress(message: "完成還原切換中...", current: 95, total: 100));
      await _verifyRestoredDatabase(tempDbPath);
      await _hotSwapDatabase(tempDbPath);

      final backupDir = Directory("${photoDirPath}_backup");
      if (await backupDir.exists()) await backupDir.delete(recursive: true);

      onProgress?.call(BackupProgress(message: "數據還原成功", current: 100, total: 100));
    } catch (e) {
      final backupDir = Directory("${photoDirPath}_backup");
      if (await backupDir.exists()) {
        final dir = Directory(photoDirPath);
        if (await dir.exists()) await dir.delete(recursive: true);
        await backupDir.rename(dir.path);
      }
      throw _parseException(e);
    }
  }

  Future<BackupMetadata?> getBackupPreview() async {
    final provider = effectiveProvider;
    if (provider == CloudProvider.none) return null;
    try {
      return (provider == CloudProvider.googleDrive) ? await _getGoogleMeta() : await _getICloudMeta();
    } catch (_) {
      return null;
    }
  }

  // --- [ 4. Google Drive 實作細節 ] ---

  Future<void> _backupToGoogleDrive(File dbFile, List<File> photos, BackupMetadata meta, void Function(BackupProgress)? onProgress) async {
    final account = await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
    if (account == null) throw BackupException(BackupExceptionType.permission, "Google 登入取消");

    final authClient = await _getGoogleAuthClient(account);
    try {
      final api = drive.DriveApi(authClient);

      onProgress?.call(BackupProgress(message: "建立原子標記...", current: 10, total: 100));
      final flagJson = jsonEncode({'startedAt': DateTime.now().toIso8601String()});
      await _uploadToDriveRaw(api, _progressFlag, utf8.encode(flagJson), 'application/json');

      await _clearAppDataFolder(api, excludeFlag: true);
      // 🚀 新增：資料庫上傳時給予 20% 的進度感
      onProgress?.call(BackupProgress(message: "正在同步核心數據...", current: 20, total: 100));
      await _uploadToDriveFile(api, dbFile);

      if (photos.isEmpty) {
        // 🚀 如果沒照片，讓進度緩步爬升到 90%
        onProgress?.call(BackupProgress(message: "整理雲端空間...", current: 80, total: 100));
      } else {
        for (int i = 0; i < photos.length; i++) {
          final pNum = i + 1;
          onProgress?.call(BackupProgress(
              message: "正在上傳照片 ($pNum/${photos.length})",
              current: 30 + ((pNum / photos.length) * 60).toInt(),
              total: 100
          ));
          await _uploadToDriveFile(api, photos[i]);
        }
      }

      await _uploadToDriveRaw(api, _metaFileName, utf8.encode(jsonEncode(meta.toJson())), 'application/json');
      await _deleteFromDriveIfExists(api, _progressFlag);
    } finally {
      authClient.close();
    }
  }

  Future<void> _restoreFromGoogleDrive(String photoDirPath, String tempDbPath, void Function(BackupProgress)? onProgress) async {
    final account = await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
    if (account == null) throw BackupException(BackupExceptionType.permission, "Google 登入失敗");
    final authClient = await _getGoogleAuthClient(account);
    try {
      final api = drive.DriveApi(authClient);

      final flagList = await api.files.list(q: "name = '$_progressFlag' and 'appDataFolder' in parents", spaces: 'appDataFolder');
      if (flagList.files != null && flagList.files!.isNotEmpty) {
        final res = await api.files.get(flagList.files!.first.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
        final data = await _readMediaBytes(res);
        final startedAt = DateTime.parse(jsonDecode(utf8.decode(data))['startedAt']);
        if (DateTime.now().difference(startedAt).inHours < 2) {
          throw BackupException(BackupExceptionType.incomplete, "雲端備份正在進行中，請稍後再試。");
        }
      }

      final List<drive.File> allFiles = [];
      String? pageToken;
      do {
        final list = await api.files.list(q: "'appDataFolder' in parents", spaces: 'appDataFolder', pageSize: 1000, pageToken: pageToken);
        if (list.files != null) allFiles.addAll(list.files!);
        pageToken = list.nextPageToken;
      } while (pageToken != null);

      if (allFiles.isEmpty) throw BackupException(BackupExceptionType.incomplete, "雲端資料夾為空");

      int count = 0;
      for (var driveFile in allFiles) {
        count++;
        final name = driveFile.name!;
        onProgress?.call(BackupProgress(message: "下載中 ($count/${allFiles.length})", current: count, total: allFiles.length));

        if (name == _metaFileName || name == _progressFlag) continue;

        final res = await api.files.get(driveFile.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
        String savePath = (name == _dbFileName) ? tempDbPath : p.join(photoDirPath, name);

        // 🚀 優化：不再使用 _readMediaBytes 一口氣讀入記憶體
        // 而是直接將雲端 Stream 寫入檔案，這對 100MB+ 的資料庫非常重要
        final file = File(savePath);
        final sink = file.openWrite();
        await res.stream.pipe(sink); // 自動管理記憶體與關閉串流
      }
    } finally {
      authClient.close();
    }
  }

  // --- [ 5. iCloud 實作 ] ---

  Future<void> _backupToICloud(File dbFile, List<File> photos, BackupMetadata meta, void Function(BackupProgress)? onProgress) async {
    await _assertICloudAvailable();
    final tempDir = await getTemporaryDirectory();

    onProgress?.call(BackupProgress(message: "建立同步標記...", current: 10, total: 100));
    final flagFile = File(p.join(tempDir.path, _progressFlag));
    await flagFile.writeAsString(jsonEncode({'startedAt': DateTime.now().toIso8601String()}));
    await ICloudStorage.upload(containerId: _iCloudContainer, filePath: flagFile.path, destinationRelativePath: _progressFlag);

    final cloudFiles = await ICloudStorage.gather(containerId: _iCloudContainer);
    for (final f in cloudFiles) {
      if (p.basename(f.relativePath) != _progressFlag) {
        await ICloudStorage.delete(containerId: _iCloudContainer, relativePath: f.relativePath);
      }
    }

    onProgress?.call(BackupProgress(message: "上傳資料庫...", current: 30, total: 100));
    await ICloudStorage.upload(containerId: _iCloudContainer, filePath: dbFile.path, destinationRelativePath: _dbFileName);

    for (int i = 0; i < photos.length; i++) {
      onProgress?.call(BackupProgress(message: "上傳照片 (${i+1}/${photos.length})", current: 30 + ((i / photos.length) * 60).toInt(), total: 100));
      await ICloudStorage.upload(containerId: _iCloudContainer, filePath: photos[i].path, destinationRelativePath: p.basename(photos[i].path));
    }

    final metaFile = File(p.join(tempDir.path, _metaFileName));
    await metaFile.writeAsString(jsonEncode(meta.toJson()));
    await ICloudStorage.upload(containerId: _iCloudContainer, filePath: metaFile.path, destinationRelativePath: _metaFileName);
    await ICloudStorage.delete(containerId: _iCloudContainer, relativePath: _progressFlag);
  }

  Future<void> _restoreFromICloud(String photoDirPath, String tempDbPath, void Function(BackupProgress)? onProgress) async {
    await _assertICloudAvailable();
    final files = await ICloudStorage.gather(containerId: _iCloudContainer);

    final flagMatches = files.where((f) => p.basename(f.relativePath) == _progressFlag);
    if (flagMatches.isNotEmpty) {
      final tempDir = await getTemporaryDirectory();
      final localFlag = p.join(tempDir.path, 'flag_check.json');
      await ICloudStorage.download(containerId: _iCloudContainer, relativePath: _progressFlag, destinationFilePath: localFlag);
      final startedAt = DateTime.parse(jsonDecode(await File(localFlag).readAsString())['startedAt']);
      if (DateTime.now().difference(startedAt).inHours < 2) {
        throw BackupException(BackupExceptionType.incomplete, "雲端備份尚未完成，請稍候。");
      }
    }

    int count = 0;
    for (final file in files) {
      count++;
      final name = p.basename(file.relativePath);
      onProgress?.call(BackupProgress(message: "下載中 ($count/${files.length})", current: count, total: files.length));

      if (name == _metaFileName || name == _progressFlag) continue;
      final savePath = (name == _dbFileName) ? tempDbPath : p.join(photoDirPath, name);
      await ICloudStorage.download(containerId: _iCloudContainer, relativePath: file.relativePath, destinationFilePath: savePath);
    }
  }

  // --- [ 6. 核心系統：災難還原 & Shadow DB ] ---

  Future<void> _hotSwapDatabase(String tempDbPath) async {
    final docDir = await getApplicationDocumentsDirectory();
    final actualDbPath = p.join(docDir.path, _dbFileName);
    final shadowPath = "$actualDbPath.shadow";

    await isar.close();
    await Future.delayed(const Duration(milliseconds: 300)); // 確保 OS 釋放文件鎖

    final actualFile = File(actualDbPath);
    if (await actualFile.exists()) {
      await actualFile.rename(shadowPath); // 先備份舊的，防止新 DB 毀損
    }

    try {
      // 2. 移動下載的檔案到正式位置
      await File(tempDbPath).copy(actualDbPath);

      // 3. 嘗試開啟新資料庫
      isar = await isarFactory();

      // 🚀 關鍵：通知全局（Provider/GetIt）資料庫實體已更新
      onDbSwapped?.call(isar);

      // 成功後清理
      final shadowFile = File(shadowPath);
      if (await shadowFile.exists()) await shadowFile.delete();
      if (await File(tempDbPath).exists()) await File(tempDbPath).delete();
    } catch (e) {
      // 4. 災難回滾：如果新 DB 開不起來，換回舊的
      final shadowFile = File(shadowPath);
      if (await shadowFile.exists()) {
        await shadowFile.rename(actualDbPath);
        isar = await isarFactory(); // 重新載入舊實體
      }
      throw BackupException(BackupExceptionType.unknown, "資料庫切換失敗，已還原舊數據", e);
    }
  }

  Future<void> _safeClearLocalPhotos(String photoDirPath) async {
    final dir = Directory(photoDirPath);
    if (await dir.exists()) {
      final backupPath = "${dir.path}_backup";
      final backupDir = Directory(backupPath);
      if (await backupDir.exists()) await backupDir.delete(recursive: true);
      await dir.rename(backupPath);
    }
    await dir.create(recursive: true);
  }

  // --- [ 7. 工具與輔助 ] ---

  Future<List<int>> _readMediaBytes(drive.Media res) async {
    final List<int> data = [];
    int totalBytes = 0;
    const int maxSizeBytes = 200 * 1024 * 1024;
    await for (var chunk in res.stream) {
      totalBytes += chunk.length;
      if (totalBytes > maxSizeBytes) throw BackupException(BackupExceptionType.storage, "檔案超過 200MB");
      data.addAll(chunk);
    }
    return data;
  }

  Future<auth.AuthClient> _getGoogleAuthClient(GoogleSignInAccount account) async {
    final headers = await account.authHeaders;
    return auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken('Bearer', headers['Authorization']!.split(' ').last, DateTime.now().toUtc().add(const Duration(minutes: 55))),
        null, [drive.DriveApi.driveAppdataScope],
      ),
    );
  }

  Future<BackupMetadata?> _getGoogleMeta() async {
    final account = await googleSignIn.signInSilently();
    if (account == null) return null;
    final authClient = await _getGoogleAuthClient(account);
    try {
      final api = drive.DriveApi(authClient);
      final list = await api.files.list(q: "name = '$_metaFileName' and 'appDataFolder' in parents", spaces: 'appDataFolder');
      if (list.files == null || list.files!.isEmpty) return null;
      final res = await api.files.get(list.files!.first.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      return BackupMetadata.fromJson(jsonDecode(utf8.decode(await _readMediaBytes(res))));
    } catch (_) {
      return null;
    } finally {
      authClient.close();
    }
  }

  Future<BackupMetadata?> _getICloudMeta() async {
    try {
      final files = await ICloudStorage.gather(containerId: _iCloudContainer);
      final meta = files.where((f) => p.basename(f.relativePath) == _metaFileName);
      if (meta.isEmpty) return null;
      final tempDir = await getTemporaryDirectory();
      final dest = p.join(tempDir.path, 'temp_meta.json');
      await ICloudStorage.download(containerId: _iCloudContainer, relativePath: meta.first.relativePath, destinationFilePath: dest);
      return BackupMetadata.fromJson(jsonDecode(await File(dest).readAsString()));
    } catch (_) {
      return null;
    }
  }

  Future<void> _uploadToDriveRaw(drive.DriveApi api, String name, List<int> bytes, String mime) async {
    await _deleteFromDriveIfExists(api, name);
    final driveFile = drive.File()..name = name..parents = ['appDataFolder'];
    await api.files.create(driveFile, uploadMedia: drive.Media(Stream.value(bytes), bytes.length, contentType: mime));
  }

  Future<void> _uploadToDriveFile(drive.DriveApi api, File file) async {
    final name = (p.basename(file.path) == 'temp_for_upload.isar') ? _dbFileName : p.basename(file.path);

    // 🚀 優化：改用 Stream 上傳，不佔用 RAM 空間
    final media = drive.Media(
      file.openRead(),
      await file.length(),
      contentType: 'application/octet-stream',
    );

    await _deleteFromDriveIfExists(api, name);
    final driveFile = drive.File()..name = name..parents = ['appDataFolder'];
    await api.files.create(driveFile, uploadMedia: media);
  }

  Future<void> _deleteFromDriveIfExists(drive.DriveApi api, String name) async {
    final list = await api.files.list(q: "name = '$name' and 'appDataFolder' in parents", spaces: 'appDataFolder');
    if (list.files != null) { for (var f in list.files!) { await api.files.delete(f.id!); } }
  }

  Future<void> _clearAppDataFolder(drive.DriveApi api, {bool excludeFlag = false}) async {
    final list = await api.files.list(spaces: 'appDataFolder');
    if (list.files == null) return;
    for (var f in list.files!) {
      if (excludeFlag && f.name == _progressFlag) continue;
      try { await api.files.delete(f.id!); } catch (_) {}
    }
  }


  Future<void> _verifyRestoredDatabase(String dbPath) async {
    final file = File(dbPath);
    if (!await file.exists() || await file.length() < 32 * 1024) throw BackupException(BackupExceptionType.unknown, "數據庫檔案毀損");
  }

  Future<void> _assertICloudAvailable() async {
    try { await ICloudStorage.gather(containerId: _iCloudContainer); }
    catch (e) { throw BackupException(BackupExceptionType.permission, "iCloud 服務不可用", e); }
  }

  BackupException _parseException(Object e) {
    if (e is BackupException) return e;

    final msg = e.toString().toLowerCase();
    debugPrint("🚀 捕捉到原始錯誤訊息: $msg"); // 開發時建議留著，方便觀察 ClientException 的具體內容

    // 1. 🚀 新增：檢測 Google Drive 空間不足 (Status 403/507 或包含 quota/insufficient)
    if (msg.contains('insufficientstorage') ||
        msg.contains('quota') ||
        msg.contains('storagefull') ||
        msg.contains('507') ||
        (msg.contains('403') && msg.contains('limit'))) {
      return BackupException(
          BackupExceptionType.storage,
          "您的雲端空間已滿，請清理 Google Drive 或 iCloud 後再試一次。",
          e
      );
    }

    // 2. 檢測帳號權限問題
    if (msg.contains('sign_in_failed') ||
        msg.contains('401') ||
        msg.contains('unauthorized')) {
      return BackupException(
          BackupExceptionType.permission,
          "帳號登入失效，請重新登入 Google 帳號。",
          e
      );
    }

    // 3. 處理截圖中的 ClientException
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('clientexception') ||
        msg.contains('connection failed')) {
      return BackupException(
          BackupExceptionType.network,
          "網路連線不穩定，建議切換至 Wi-Fi 環境。",
          e
      );
    }

    // 4. 其他未知錯誤
    return BackupException(BackupExceptionType.unknown, "處理備份時遇到非預期錯誤", e);
  }
} // 🚀 類別正確結束位置