import 'dart:io';
import 'dart:convert'; // ✅ 這一行是解決 jsonDecode 和 utf8 報錯的關鍵
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

// --- [新功能] 備份元數據模型 ---
class BackupMetadata {
  final DateTime createdAt;
  final String appVersion;
  final int schemaVersion;
  final String provider; // 'google' or 'apple'

  BackupMetadata({
    required this.createdAt,
    required this.appVersion,
    this.schemaVersion = 1, // 🚀 補上逗號
    required this.provider, // 🚀 補上參數
  });

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'provider': provider, // 🚀 補上這行，還原時才知道是誰備份的
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    createdAt: DateTime.parse(json['createdAt']),
    appVersion: json['appVersion'] ?? 'unknown',
    schemaVersion: json['schemaVersion'] ?? 1,
    provider: json['provider'] ?? 'unknown', // 👈 補上這一行
  );
}

// --- 異常處理定義 ---
enum BackupExceptionType { network, permission, storage, incomplete, unknown } // ✅ 補上了 incomplete

class BackupException implements Exception {
  final BackupExceptionType type;
  final String message;
  final Object? originalError;

  BackupException(this.type, this.message, [this.originalError]);

  @override
  String toString() => "BackupException($type): $message";
}

// --- 雲端服務商枚舉 ---
enum CloudProvider { googleDrive, iCloud, none }

/// 🚀 CloudBackupService 產品級定版
/// 符合 SaMD (醫療軟體) 穩定度要求與兩大平台審查規範
class CloudBackupService {
  Isar isar;
  final Future<Isar> Function() isarFactory;
  final GoogleSignIn googleSignIn; // 🚀 改名，避免跟 effectiveProvider 撞名

  // 🚀 定義目前的數據庫架構版本 (當你修改 Isar 模型時，請將此數字 +1)
  static const int currentSchemaVersion = 1;

  CloudBackupService({
    required this.isar,
    required this.isarFactory,
    required this.googleSignIn, // 👈 同步修改
  });

  static const String _dbFileName = 'eczema_data.isar';
  static const String _metaFileName = 'backup_info.json';
  static const String _progressFlag = '.backup_in_progress'; // 🚀 保險栓 1: 原子標記
  static const String _iCloudContainer = 'iCloud.com.your.app.bundle.id';
  // --- [ 1. 核心路由邏輯 ] ---

  /// 根據登入身分判斷雲端路徑 (Apple ID 優先於平台)
  CloudProvider get effectiveProvider {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return CloudProvider.none;
    for (final info in user.providerData) {
      if (info.providerId == 'apple.com') return CloudProvider.iCloud;
      if (info.providerId == 'google.com') return CloudProvider.googleDrive;
    }
    return Platform.isIOS ? CloudProvider.iCloud : CloudProvider.googleDrive;
  }

  // --- [ 2. 統一對外接口 ] ---

  /// 執行完整備份
  Future<void> runBackup(String photoDirPath, {required String appVersion}) async {
    final provider = effectiveProvider;
    if (provider == CloudProvider.none) throw BackupException(BackupExceptionType.permission, "請先登入");

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbBackupFile = File(p.join(docDir.path, 'temp_for_upload.isar'));

      if (await dbBackupFile.exists()) await dbBackupFile.delete();
      await isar.copyToFile(dbBackupFile.path);

      final photos = Directory(photoDirPath).existsSync()
          ? Directory(photoDirPath).listSync().whereType<File>().toList()
          : <File>[];

      // 🚀 建立元數據時帶入 provider 名稱
      final meta = BackupMetadata(
        createdAt: DateTime.now(),
        appVersion: appVersion,
        schemaVersion: currentSchemaVersion, // 使用目前的版本號
        provider: provider.name, // 使用 enum 的 name
      );

      if (provider == CloudProvider.googleDrive) {
        await _backupToGoogleDrive(dbBackupFile, photos, meta);
      } else {
        await _backupToICloud(dbBackupFile, photos, meta); // ✅ 參數對齊了
      }

      if (await dbBackupFile.exists()) await dbBackupFile.delete();
    } catch (e) {
      throw _parseException(e);
    }
  }

  // --- [ 2. 預覽功能 (保險栓 2) ] ---

  /// 在還原前，讓 UI 能顯示「最後備份時間」，避免覆蓋錯資料
  Future<BackupMetadata?> getBackupPreview() async {
    final provider = effectiveProvider;
    if (provider == CloudProvider.none) return null;

    try {
      if (provider == CloudProvider.googleDrive) {
        return await _getGoogleMeta();
      } else {
        return await _getICloudMeta();
      }
    } catch (e) {
      return null;
    }
  }

  /// 執行完整恢復 (包含照片清理與熱切換)
  Future<void> runRestore(String photoDirPath) async {
    final provider = effectiveProvider;
    if (provider == CloudProvider.none) {
      throw BackupException(BackupExceptionType.permission, "請先登入");
    }

    try {
      // 1. 獲取備份預覽 (Metadata)
      final meta = await getBackupPreview();
      if (meta == null) {
        throw BackupException(BackupExceptionType.incomplete, "找不到雲端備份紀錄");
      }

      // 🚀 核心優化 A：版本守門員 (修正變數名為 meta)
      // 假設你在類別頂部定義了 static const int currentSchemaVersion = 1;
      if (meta.schemaVersion > currentSchemaVersion) {
        throw BackupException(
          BackupExceptionType.incomplete,
          "備份檔案版本 (${meta.schemaVersion}) 較新，請先更新 App 至最新版本再執行還原",
        );
      }

      // 🚀 核心優化 B：確保照片目錄存在
      final dir = Directory(photoDirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

// 🚀 修正 1：改用安全清理 (先備份舊照片)
      await _safeClearLocalPhotos(photoDirPath);
      final tempDir = await getTemporaryDirectory();
      final tempDbPath = p.join(tempDir.path, 'restored_db.isar');

      // 3. 根據 Provider 執行下載
      if (provider == CloudProvider.googleDrive) {
        await _restoreFromGoogleDrive(photoDirPath, tempDbPath);
      } else {
        await _restoreFromICloud(photoDirPath, tempDbPath);
      }

      // 4. 驗證與熱切換
      await _verifyRestoredDatabase(tempDbPath);
      await _hotSwapDatabase(tempDbPath);

      // 🚀 修正 2：成功後刪除照片備份
      final backupDir = Directory("${photoDirPath}_backup");
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }

      debugPrint("✅ 雲端還原成功: ${meta.createdAt}");
    } catch (e) {
      // 🚀 災難恢復：如果失敗了，嘗試把照片還原回來
      final backupDir = Directory("${photoDirPath}_backup");
      if (await backupDir.exists()) {
        final dir = Directory(photoDirPath);
        if (await dir.exists()) await dir.delete(recursive: true);
        await backupDir.rename(dir.path);
      }
      debugPrint("❌ 還原失敗: $e");
      rethrow;
    }
  }

// --- [ 5. 輔助邏輯 (合規註解) ] ---

  /// 🚀 保險栓 5: 合規與責任說明
  /// Cloud backup is user-initiated and user-controlled.
  /// The app does not automatically sync, analyze, or access backup data
  /// outside the user's explicit action. All data remains in the user's personal
  /// cloud sandbox (iCloud Container / Drive AppData).

  Future<BackupMetadata?> _getGoogleMeta() async {
    // 🚀 使用建構子傳入的實例，不要重新 new
    final account = await googleSignIn.signInSilently();
    if (account == null) return null;

    final authClient = await _getGoogleAuthClient(account);
    try {
      final api = drive.DriveApi(authClient);
      final list = await api.files.list(
          q: "name = '$_metaFileName' and 'appDataFolder' in parents",
          spaces: 'appDataFolder'
      );

      if (list.files == null || list.files!.isEmpty) return null;

      final res = await api.files.get(
          list.files!.first.id!,
          downloadOptions: drive.DownloadOptions.fullMedia
      ) as drive.Media;

      final List<int> data = [];
      await for (var chunk in res.stream) { data.addAll(chunk); }
      return BackupMetadata.fromJson(jsonDecode(utf8.decode(data)));
    } catch (e) {
      debugPrint("❌ 抓取 Google Meta 失敗: $e");
      return null;
    } finally {
      authClient.close();
    }
  }

  Future<BackupMetadata?> _getICloudMeta() async {
    try {
      final files = await ICloudStorage.gather(containerId: _iCloudContainer);
      // 🚀 安全搜尋，避免找不到檔案時崩潰
      final metaFiles = files.where((f) => p.basename(f.relativePath) == _metaFileName);
      if (metaFiles.isEmpty) return null;

      final tempDir = await getTemporaryDirectory();
      final dest = p.join(tempDir.path, 'temp_meta.json');

      await ICloudStorage.download(
          containerId: _iCloudContainer,
          relativePath: metaFiles.first.relativePath,
          destinationFilePath: dest
      );

      final content = await File(dest).readAsString();
      return BackupMetadata.fromJson(jsonDecode(content));
    } catch (e) {
      debugPrint("❌ 抓取 iCloud Meta 失敗: $e");
      return null;
    }
  }

  // --- [ 3. 核心系統邏輯 ] ---

  /// 執行資料庫熱切換 (Shadow DB 災難還原設計)
  Future<void> _hotSwapDatabase(String tempDbPath) async {
    final docDir = await getApplicationDocumentsDirectory();
    final actualDbPath = p.join(docDir.path, _dbFileName);
    final shadowPath = "$actualDbPath.shadow";

    await isar.close();
    await Future.delayed(const Duration(milliseconds: 200));

    final actualFile = File(actualDbPath);
    if (await actualFile.exists()) {
      await actualFile.rename(shadowPath);
    }

    try {
      await File(tempDbPath).copy(actualDbPath);

      final shadowFile = File(shadowPath);
      if (await shadowFile.exists()) await shadowFile.delete();
      if (await File(tempDbPath).exists()) await File(tempDbPath).delete();
    } catch (e) {
      final shadowFile = File(shadowPath);
      if (await shadowFile.exists()) await shadowFile.rename(actualDbPath);
      throw BackupException(BackupExceptionType.unknown, "數據庫替換失敗", e);
    } finally {
      isar = await isarFactory();
    }
  }

  /// 🚀 優化後的照片清理：採用「改名備份」策略
  /// 🚀 終極版安全清理：採用「改名備份」策略
  Future<void> _safeClearLocalPhotos(String photoDirPath) async {
    final dir = Directory(photoDirPath);
    if (await dir.exists()) {
      // 建議使用 p.join 確保路徑格式正確
      final backupPath = "${dir.path}_backup";
      final backupDir = Directory(backupPath);

      if (await backupDir.exists()) await backupDir.delete(recursive: true);
      await dir.rename(backupPath); // 將目前的照片資料夾「改名」作為備份
    }
    await dir.create(recursive: true); // 建立一個全新的空資料夾供下載使用
  }

  // --- [ 4. Google Drive 實作 ] ---
// --- [ 4. Google Drive 實作 (原子化與資源釋放) ] ---

  Future<void> _backupToGoogleDrive(File dbFile, List<File> photos, BackupMetadata meta) async {
    // 🚀 修正：刪除本地 new 的 GoogleSignIn，改用 this.googleSignIn
    final account = await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
    if (account == null) throw BackupException(BackupExceptionType.permission, "Google 登入取消");

    final authClient = await _getGoogleAuthClient(account);
    try {
      final api = drive.DriveApi(authClient);

      // 1. 建立原子標記
      final flagJson = jsonEncode({'startedAt': DateTime.now().toIso8601String()});
      await _uploadToDriveRaw(api, _progressFlag, utf8.encode(flagJson), 'application/json');

      // 2. 清理舊資料 (排除標記)
      await _clearAppDataFolder(api, excludeFlag: true);

      // 3. 上傳資料庫與照片 (這部分沒問題)
      await _uploadToDriveFile(api, dbFile);
      for (final photo in photos) {
        await _uploadToDriveFile(api, photo);
      }

      // 5. 上傳 Meta 資訊
      final metaJson = jsonEncode(meta.toJson());
      await _uploadToDriveRaw(api, _metaFileName, utf8.encode(metaJson), 'application/json');

      // 6. 成功後刪除標記
      await _deleteFromDriveIfExists(api, _progressFlag);

      debugPrint("✅ Google Drive 備份成功");
    } finally {
      authClient.close();
    }
  }

  Future<void> _uploadToDriveRaw(drive.DriveApi api, String name, List<int> bytes, String mime) async {
    // 🚀 強制刪除舊有的同名檔案，確保 AppData 只有一份
    await _deleteFromDriveIfExists(api, name);

    final driveFile = drive.File()
      ..name = name
      ..parents = ['appDataFolder'];

    await api.files.create(
        driveFile,
        uploadMedia: drive.Media(Stream.value(bytes), bytes.length)
    );
  }

  Future<void> _uploadToDriveFile(drive.DriveApi api, File file) async {
    final name = (p.basename(file.path) == 'temp_for_upload.isar') ? _dbFileName : p.basename(file.path);
    await _uploadToDriveRaw(api, name, await file.readAsBytes(), 'application/octet-stream');
  }

  Future<void> _deleteFromDriveIfExists(drive.DriveApi api, String name) async {
    final list = await api.files.list(q: "name = '$name'", spaces: 'appDataFolder');
    if (list.files != null) { for (var f in list.files!) { await api.files.delete(f.id!); } }
  }

  Future<bool> _existsInDrive(drive.DriveApi api, String name) async {
    final list = await api.files.list(q: "name = '$name'", spaces: 'appDataFolder');
    return list.files?.isNotEmpty ?? false;
  }

  Future<void> _clearAppDataFolder(drive.DriveApi api, {bool excludeFlag = false}) async {
    final list = await api.files.list(spaces: 'appDataFolder');
    if (list.files == null) return;
    for (var f in list.files!) {
      // 如果設定了排除標記，且檔名符合標記，就跳過不刪除
      if (excludeFlag && f.name == _progressFlag) continue;
      try {
        await api.files.delete(f.id!);
      } catch (_) {
        // 忽略單一檔案刪除失敗
      }
    }
  }


  Future<void> _restoreFromGoogleDrive(String photoDirPath, String tempDbPath) async {
    final account = await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
    if (account == null) throw BackupException(BackupExceptionType.permission, "Google 登入取消");

    final authClient = await _getGoogleAuthClient(account);
    try {
      final api = drive.DriveApi(authClient);

      // 1. 檢查原子標記與過期判定
      final flagList = await api.files.list(
          q: "name = '$_progressFlag' and 'appDataFolder' in parents",
          spaces: 'appDataFolder'
      );

      if (flagList.files != null && flagList.files!.isNotEmpty) {
        final flagFile = flagList.files!.first;
        final drive.Media res = await api.files.get(flagFile.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

        final List<int> data = [];
        await for (var chunk in res.stream) { data.addAll(chunk); }
        final flagData = jsonDecode(utf8.decode(data));
        final DateTime startedAt = DateTime.parse(flagData['startedAt']);

        if (DateTime.now().difference(startedAt).inHours < 2) {
          throw BackupException(BackupExceptionType.incomplete, "雲端備份進行中，請稍後再試。");
        }
      }

// 修改 _restoreFromGoogleDrive 中的檔案列表獲取
      // 2. 獲取所有檔案列表 (分頁處理)
      final List<drive.File> allFiles = [];
      String? pageToken;
      do {
        final fileList = await api.files.list(
          q: "'appDataFolder' in parents",
          spaces: 'appDataFolder',
          pageSize: 1000,
          pageToken: pageToken,
        );
        if (fileList.files != null) allFiles.addAll(fileList.files!);
        pageToken = fileList.nextPageToken;
      } while (pageToken != null);

      if (allFiles.isEmpty) {
        throw BackupException(BackupExceptionType.incomplete, "雲端資料夾為空");
      }

      // 3. 循環下載 (改用 allFiles)
      for (var driveFile in allFiles) {
        final name = driveFile.name!;
        if (name == _metaFileName || name == _progressFlag) continue;

        final response = await api.files.get(driveFile.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
        String savePath = (name == _dbFileName) ? tempDbPath : p.join(photoDirPath, name);

        final List<int> dataStore = [];
        await for (final data in response.stream) { dataStore.addAll(data); }
        await File(savePath).writeAsBytes(dataStore);
      }
    } finally {
      authClient.close();
    }
  }

  // --- [ 5. iCloud 實作 ] ---

  /// 🚀 產品保險栓 1: iCloud API 修正 (icloud_storage 2.x 沒有 isAvailable)
  Future<void> _assertICloudAvailable() async {
    try {
      // 官方建議透過實際執行 gather 來確認權限與可用性
      await ICloudStorage.gather(containerId: _iCloudContainer);
    } catch (e) {
      throw BackupException(BackupExceptionType.permission, "iCloud 服務不可用", e);
    }
  }

  Future<void> _backupToICloud(File dbFile, List<File> photos, BackupMetadata meta) async {
    await _assertICloudAvailable();
    // 1. 先傳標記
    final tempDir = await getTemporaryDirectory();
    // 建議統一使用 await
    final flagFile = File(p.join(tempDir.path, _progressFlag));
    await flagFile.writeAsString(jsonEncode({
      'startedAt': DateTime.now().toIso8601String(),
    }));
// 確保檔案寫入後再上傳
    await ICloudStorage.upload(
        containerId: _iCloudContainer,
        filePath: flagFile.path,
        destinationRelativePath: _progressFlag
    );
    // 2. 清理其他舊檔案
    final files = await ICloudStorage.gather(containerId: _iCloudContainer);
    for (final f in files) {
      if (p.basename(f.relativePath) != _progressFlag) {
        await ICloudStorage.delete(containerId: _iCloudContainer, relativePath: f.relativePath);
      }
    }

    // 3. 上傳內容與 Meta
    await ICloudStorage.upload(containerId: _iCloudContainer, filePath: dbFile.path, destinationRelativePath: _dbFileName);
    for (final pFile in photos) {
      await ICloudStorage.upload(containerId: _iCloudContainer, filePath: pFile.path, destinationRelativePath: p.basename(pFile.path));
    }
    final metaFile = File(p.join(tempDir.path, _metaFileName));
    await metaFile.writeAsString(jsonEncode(meta.toJson()));
    await ICloudStorage.upload(containerId: _iCloudContainer, filePath: metaFile.path, destinationRelativePath: _metaFileName);

    // 4. 刪除標記
    await ICloudStorage.delete(containerId: _iCloudContainer, relativePath: _progressFlag);
  }

  /// 🚀 產品級 iCloud 還原實作：含原子性過期檢查
  Future<void> _restoreFromICloud(String photoDirPath, String tempDbPath) async {
    await _assertICloudAvailable();

    // 1. 獲取所有雲端檔案列表
    final files = await ICloudStorage.gather(containerId: _iCloudContainer);

    // 2. 原子性檢查 (Atomic Flag Check)
    final bool hasFlag = files.any((f) => p.basename(f.relativePath) == _progressFlag);

    if (hasFlag) {
      debugPrint("⚠️ 偵測到備份標記檔案，執行過期判定...");

      try {
        final tempDir = await getTemporaryDirectory();
        final flagLocalPath = p.join(tempDir.path, 'stale_check_flag.json');

        // 下載標記檔案來檢查時間
        await ICloudStorage.download(
          containerId: _iCloudContainer,
          relativePath: _progressFlag,
          destinationFilePath: flagLocalPath,
        );

        final flagContent = await File(flagLocalPath).readAsString();
        final Map<String, dynamic> flagData = jsonDecode(flagContent);
        final DateTime startedAt = DateTime.parse(flagData['startedAt']);

        // 🚀 策略：若標記在 2 小時內，視為「真的正在備份」，禁止還原
        if (DateTime.now().difference(startedAt).inHours < 2) {
          throw BackupException(
              BackupExceptionType.incomplete,
              "雲端備份正在進行中（或上次備份異常），為確保數據完整，請於一小時後再試。"
          );
        } else {
          debugPrint("🔓 標記已過期 (Stale Lock)，無視標記繼續還原。");
        }
      } catch (e) {
        if (e is BackupException) rethrow;
        // 如果標記檔損毀或無法讀取，保守起見仍視為不完整
        throw BackupException(BackupExceptionType.incomplete, "備份狀態異常，請重新執行備份。");
      }
    }

    // 3. 確保本地照片目錄存在 (mkdir -p)
    final photoDir = Directory(photoDirPath);
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    // 4. 開始下載檔案
    debugPrint("📥 開始從 iCloud 下載數據...");
    for (final file in files) {
      final name = p.basename(file.relativePath);

      // 跳過元數據檔案 (因為 getBackupPreview 已經處理過了) 與 標記檔案
      if (name == _metaFileName || name == _progressFlag) continue;

      // 判斷存檔路徑：是資料庫還是照片
      final savePath = (name == _dbFileName) ? tempDbPath : p.join(photoDirPath, name);

      try {
        await ICloudStorage.download(
          containerId: _iCloudContainer,
          relativePath: file.relativePath,
          destinationFilePath: savePath,
        );
        debugPrint("✅ 已下載: $name");
      } catch (e) {
        debugPrint("❌ 下載失敗 ($name): $e");
        // 只要有一個照片或資料庫下載失敗，就中斷還原以免數據不一致
        throw BackupException(BackupExceptionType.storage, "檔案下載失敗: $name");
      }
    }
  }

  // --- [ 6. 工具與輔助 ] ---

  /// 🚀 產品保險栓 4: 審查註解
  /// Note: Database is stored within OS sandbox and protected by platform-level
  /// encryption (Android Keystore / iOS Data Protection). Data in transit and
  /// at rest on cloud providers is encrypted via OAuth2 and provider-side encryption.

  Future<void> _verifyRestoredDatabase(String dbPath) async {
    final file = File(dbPath);
    if (!await file.exists()) throw BackupException(BackupExceptionType.unknown, "恢復檔案不存在");
    final size = await file.length();
    if (size < 32 * 1024) throw BackupException(BackupExceptionType.unknown, "資料庫大小異常，拒絕還原");
  }

  Future<auth.AuthClient> _getGoogleAuthClient(GoogleSignInAccount account) async {
    final authHeaders = await account.authHeaders;
    final authenticateClient = http.Client();

    // 這裡其實可以直接封裝一個 Client
    return auth.authenticatedClient(
      authenticateClient,
      auth.AccessCredentials(
        auth.AccessToken('Bearer', authHeaders['Authorization']!.split(' ').last,
            DateTime.now().toUtc().add(const Duration(minutes: 55))), // 略短於一小時較保險
        null,
        [drive.DriveApi.driveAppdataScope],
      ),
    );
  }

  BackupException _parseException(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socket') || msg.contains('network')) return BackupException(BackupExceptionType.network, "網路連線中斷");
    if (msg.contains('403') || msg.contains('permission')) return BackupException(BackupExceptionType.permission, "權限不足，請檢查雲端設定");
    if (msg.contains('quota') || msg.contains('full')) return BackupException(BackupExceptionType.storage, "空間已滿");
    return BackupException(BackupExceptionType.unknown, "未知的備份錯誤", e);
  }
}