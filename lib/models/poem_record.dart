import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'poem_record.g.dart';

enum RecordType { daily, weekly, biWeekly, monthly }

// 多科別量表架構
enum ScaleType {
  // 皮膚科
  poem, uas7, scorad, adct,
  // 身心科
  phq9, gad7,
  // 疼痛科
  vas
}

@collection
class PoemRecord {
  Id id = Isar.autoIncrement;

  // 👤 使用者識別：用於 Firebase 安全規則過濾
  @Index()
  String? userId;

  // 📅 時間軸
  @Index()
  DateTime? date;       // 實際存檔時間 (System Time)

  @Index()
  DateTime? targetDate; // 歸屬日期 (使用者選定的紀錄日)

  @Index()
  bool isSynced = false;

  // 🚀 唯一 UUID：確保換手機同步時，同一筆紀錄不會因 ID 不同而重複
  @Index(unique: true)
  String? recordId;

  // 🚀 版本控制：若未來量表題目修改，可用此欄位做數據遷移
  int scaleVersion = 1;

  @enumerated
  @Index()
  ScaleType scaleType = ScaleType.adct;

  @enumerated
  RecordType type = RecordType.weekly;

  // --- 📊 核心數據 ---
  int? score;

  // 🚀 建議給予初始值 [] 而非使用 late，以確保 Isar 讀取安全
  List<int> answers = [];

  // 🚀 每題作答時間：臨床心理研究可用於評估受試者對題目的反應(猶豫)時間
  List<DateTime?>? answerTimestamps;

  // --- 🩺 皮膚科專屬 (保存在同一張表以利跨科分析) ---
  int? dailyItch;
  int? dailySleep;
  int? whealsCount;

  // --- 📷 圖片與備註 ---
  String? imagePath;
  bool? imageConsent = true;
  String? note;

  int get totalScore => score ?? 0;

  // 🚀 確保 ID 存在 (在 save 前呼叫)
  void ensureId() {
    recordId ??= const Uuid().v4();
  }

  // 🚀 備份邏輯：轉為雲端 JSON
  Map<String, dynamic> toFirestore() {
    ensureId();
    return {
      'recordId': recordId,
      'userId': userId,
      'score': score,
      'scaleType': scaleType.name,
      'type': type.name,
      'date': date?.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'answers': answers,
      'answerTimestamps': answerTimestamps
          ?.map((e) => e?.toIso8601String())
          .toList(),
      'imageConsent': imageConsent,
      'note': note,
      'dailyItch': dailyItch,
      'dailySleep': dailySleep,
      'whealsCount': whealsCount,
      'scaleVersion': scaleVersion,
    };
  }

  // 🚀 還原邏輯：從雲端 JSON 轉回 Isar 物件 (還原功能必備)
  static PoemRecord fromFirestore(Map<String, dynamic> map) {
    return PoemRecord()
      ..recordId = map['recordId']
      ..userId = map['userId']
      ..score = map['score']
      ..scaleType = ScaleType.values.firstWhere((e) => e.name == map['scaleType'], orElse: () => ScaleType.adct)
      ..type = RecordType.values.firstWhere((e) => e.name == map['type'])
      ..date = map['date'] != null ? DateTime.parse(map['date']) : null
      ..targetDate = map['targetDate'] != null ? DateTime.parse(map['targetDate']) : null
      ..answers = List<int>.from(map['answers'] ?? [])
      ..answerTimestamps = (map['answerTimestamps'] as List?)
          ?.map((e) => e != null ? DateTime.parse(e) : null)
          .toList()
      ..imageConsent = map['imageConsent']
      ..note = map['note']
      ..dailyItch = map['dailyItch']
      ..dailySleep = map['dailySleep']
      ..whealsCount = map['whealsCount']
      ..scaleVersion = map['scaleVersion'] ?? 1
      ..isSynced = true; // 從雲端抓回來的當然已經同步了
  }

  // 🚀 臨床嚴重度自動判斷標籤
  String get severityLabel {
    final s = score ?? 0;

    switch (scaleType) {
      case ScaleType.adct:
        return s >= 7 ? "控制不佳" : "控制良好";
      case ScaleType.uas7:
        if (s >= 28) return "嚴重活性";
        if (s >= 16) return "中度活性";
        return "輕微/無活性";
      case ScaleType.poem:
        if (s <= 2) return "無或極輕微";
        if (s <= 7) return "輕微";
        if (s <= 16) return "中度";
        if (s <= 24) return "重度";
        return "極重度";
      case ScaleType.phq9:
        if (s <= 4) return "無或極輕微";
        if (s <= 9) return "輕度憂鬱";
        if (s <= 14) return "中度憂鬱";
        if (s <= 19) return "中重度憂鬱";
        return "重度憂鬱";
      case ScaleType.gad7:
        if (s <= 4) return "無或極輕微";
        if (s <= 9) return "輕度焦慮";
        if (s <= 14) return "中度焦慮";
        return "重度焦慮";
      case ScaleType.vas:
        if (s == 0) return "無痛";
        if (s <= 3) return "輕微疼痛";
        if (s <= 6) return "中度疼痛";
        return "劇烈疼痛";
      default:
        return "已紀錄";
    }
  }

  // 🎨 UI 狀態顏色聯動
  @ignore
  Color get severityColor {
    final s = score ?? 0;

    // 身心科使用警示色系
    if (scaleType == ScaleType.phq9 || scaleType == ScaleType.gad7) {
      if (s <= 9) return Colors.green;
      if (s <= 14) return Colors.orange;
      return Colors.red;
    }

    // 疼痛量表使用溫度感色系
    if (scaleType == ScaleType.vas) {
      if (s <= 3) return Colors.green;
      if (s <= 6) return Colors.orange;
      return Colors.red;
    }

    // 皮膚科預設專業藍色系
    return Colors.blue;
  }
}