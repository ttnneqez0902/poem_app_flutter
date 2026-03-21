import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'poem_record.g.dart';

enum RecordType { daily, weekly, biWeekly, monthly }

// 🚀 擴充：加入四大科別量表
enum ScaleType {
  poem, uas7, scorad, adct, phq9, gad7, // 皮膚與情緒
  vas, haq,                             // 風濕免疫
  bristol, ibs_sss,                     // 腸胃科
  cycle,                                // 女性健康
  growth                                // 兒科發展
}

enum SyncStatus { pending, syncing, synced, failed }

@collection
class PoemRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? recordId;

  @Index(composite: [CompositeIndex('scaleType'), CompositeIndex('targetDate')])
  String? userId;

  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastSyncAttempt;

  @enumerated
  @Index()
  SyncStatus syncStatus = SyncStatus.pending;

  @Index()
  bool isSynced = false;

  @Index()
  bool isDeleted = false;

  @Index()
  DateTime? date;
  @Index()
  DateTime? targetDate;

  @enumerated
  @Index()
  ScaleType scaleType = ScaleType.adct;

  @enumerated
  RecordType type = RecordType.weekly;

  int scaleVersion = 1;
  int? score; // 大多數量表的總分依舊存這裡
  List<int> answers = [];
  List<DateTime?>? answerTimestamps;

  // --- 🩺 1. 皮膚科專屬 (原本的) ---
  int? dailyItch;
  int? dailySleep;
  int? whealsCount;

  // --- 🦴 2. 風濕免疫 / 疼痛專屬 ---
  // VAS 直接用 score (0-10) 即可
  int? morningStiffnessMinutes; // 晨間僵硬分鐘數

  // --- 💩 3. 腸胃科專屬 ---
  int? stoolType; // 🚀 布里斯托糞便分類 (1-7)
  int? bowelMovements; // 排便次數

  // --- 🌸 4. 女性健康專屬 ---
  bool isPeriodStart = false; // 🚀 經期開始標記
  int? flowAmount; // 經血量評估 (1-5)

  // --- 👶 5. 兒科發展專屬 (生長曲線) ---
  double? height; // 🚀 身高 (cm)
  double? weight; // 🚀 體重 (kg)
  double? headCircumference; // 🚀 頭圍 (cm)

  String? note;
  String? imagePath;
  bool? imageConsent = true;

  @ignore
  int get totalScore => score ?? 0;

  void ensureId() {
    recordId ??= const Uuid().v4();
    createdAt ??= DateTime.now();
    updatedAt ??= DateTime.now();
  }

  // 🚀 修正：toFirestore 必須補上新欄位
  Map<String, dynamic> toFirestore() {
    ensureId();
    return {
      'recordId': recordId,
      'userId': userId,
      'score': score,
      'scaleType': scaleType.name,
      'targetDate': targetDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'answers': answers,
      'note': note,
      // 🚀 新增欄位同步
      'stoolType': stoolType,
      'isPeriodStart': isPeriodStart,
      'height': height,
      'weight': weight,
      'headCircumference': headCircumference,
    };
  }

  static PoemRecord fromFirestore(Map<String, dynamic> map) {
    return PoemRecord()
      ..recordId = map['recordId']
      ..userId = map['userId']
      ..score = map['score']
      ..scaleType = ScaleType.values.firstWhere((e) => e.name == map['scaleType'], orElse: () => ScaleType.adct)
      ..targetDate = map['targetDate'] != null ? DateTime.parse(map['targetDate']) : null
      ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now()
      ..isDeleted = map['isDeleted'] ?? false
      ..answers = List<int>.from(map['answers'] ?? [])
      ..note = map['note']
    // 🚀 新增欄位還原
      ..stoolType = map['stoolType']
      ..isPeriodStart = map['isPeriodStart'] ?? false
      ..height = (map['height'] as num?)?.toDouble()
      ..weight = (map['weight'] as num?)?.toDouble()
      ..headCircumference = (map['headCircumference'] as num?)?.toDouble()
      ..syncStatus = SyncStatus.synced
      ..isSynced = true;
  }

  // 🚀 修正：擴充判定邏輯
  @ignore
  String get severityLabel {
    final s = score ?? 0;
    switch (scaleType) {
      case ScaleType.phq9: return s <= 9 ? "輕微" : "中重度";
      case ScaleType.vas:
        if (s <= 3) return "輕微";
        if (s <= 6) return "中度";
        return "劇烈";
      case ScaleType.bristol:
        if (stoolType == 3 || stoolType == 4) return "理想";
        if (stoolType! <= 2) return "便秘";
        return "腹瀉";
      case ScaleType.growth:
        return "生長紀錄";
      default: return s >= 7 ? "控制不佳" : "控制良好";
    }
  }

  @ignore
  Color get severityColor {
    final s = score ?? 0;
    if (scaleType == ScaleType.growth || scaleType == ScaleType.cycle) return Colors.blue;
    if (s <= 9) return Colors.green;
    return Colors.red;
  }
}