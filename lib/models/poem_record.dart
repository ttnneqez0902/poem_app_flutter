import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'poem_record.g.dart';

enum RecordType { daily, weekly, biWeekly, monthly }

// 🚀 1. 確保 ScaleType 順序與 HomeScreen 一致，避免索引位移
enum ScaleType {
  adct,
  poem,
  uas7,
  scorad, // 皮膚

  psqi,
  isi,
  ess, // 睡眠

  bp_log,
  cat,
  dds,
  bpi, // 慢性病與疼痛

  phq9,
  gad7, // 心理

  vas,
  haq, // 風濕/疼痛

  bristol,
  ibs_sss, // 腸胃

  cycle, // 女性

  growth, // 兒科

  qolie10,
  lsss, // 神經（永遠加最後）
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

  @Enumerated(EnumType.name)
  @Index()
  SyncStatus syncStatus = SyncStatus.pending;

  @Index()
  bool isSynced = false;

  @Index()
  bool isDeleted = false;

  @Index()
  DateTime? date; // 填寫日期

  @Index()
  DateTime? targetDate; // 追蹤目標日期

  @Enumerated(EnumType.name)
  @Index()
  ScaleType scaleType = ScaleType.adct;

  @Enumerated(EnumType.name)
  RecordType type = RecordType.weekly;

  int scaleVersion = 1;
  int? score; // 大多數量表的總分依舊存這裡
  List<int> answers = [];
  List<DateTime?>? answerTimestamps;

  // --- 🩺 1. 慢性病：血壓與心率 (解決編譯錯誤的關鍵) ---
  int? systolic;   // 🚀 收縮壓 (mmHg)
  int? diastolic;  // 🚀 舒張壓 (mmHg)
  int? pulse;      // 🚀 心率 (bpm)

  // --- 🦴 2. 風濕免疫 / 疼痛專屬 ---
  int? morningStiffnessMinutes;

  // --- 💩 3. 腸胃科專屬 ---
  int? stoolType;
  int? bowelMovements;

  // --- 🌸 4. 女性健康專屬 ---
  bool isPeriodStart = false;
  int? flowAmount;

  // --- 👶 5. 兒科發展專屬 (生長數據) ---
  double? height;
  double? weight;
  double? headCircumference;

  String? note;
  String? imagePath;
  bool imageConsent = true;

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
    updatedAt = DateTime.now(); // 🚀 每次同步前強制更新時間
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
      'imagePath': imagePath,
      // 🚀 補上血壓與生長數據
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'stoolType': stoolType,
      'isPeriodStart': isPeriodStart,
      'height': height,
      'weight': weight,
      'headCircumference': headCircumference,
    };
  }

  static PoemRecord fromFirestore(Map<String, dynamic> map) {
    return PoemRecord()
      ..recordId = map['recordId'] ?? const Uuid().v4()
      ..userId = map['userId']?.toString()
      ..score = (map['score'] as num?)?.toInt()
      ..scaleType = ScaleType.values.firstWhere(
            (e) => e.name == (map['scaleType'] ?? ''),
        orElse: () => ScaleType.adct,
      )
      ..targetDate = map['targetDate'] != null
          ? DateTime.tryParse(map['targetDate'])
          : null
      ..createdAt = map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : DateTime.now()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : DateTime.now()
      ..isDeleted = map['isDeleted'] ?? false
      ..answers = (map['answers'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList()
      ..note = map['note']?.toString()
      ..imagePath = map['imagePath']?.toString()
    // 🚀 補上還原邏輯
      ..systolic = (map['systolic'] as num?)?.toInt()
      ..diastolic = (map['diastolic'] as num?)?.toInt()
      ..pulse = (map['pulse'] as num?)?.toInt()
      ..stoolType = (map['stoolType'] as num?)?.toInt()
      ..isPeriodStart = map['isPeriodStart'] ?? false
      ..height = (map['height'] as num?)?.toDouble()
      ..weight = (map['weight'] as num?)?.toDouble()
      ..headCircumference = (map['headCircumference'] as num?)?.toDouble()
      ..syncStatus = SyncStatus.synced
      ..isSynced = true;
  }

  // 🚀 3. 診斷標籤：根據各科量表自動轉換
  @ignore
  String get severityLabel {
    final s = score ?? 0;
    switch (scaleType) {
      case ScaleType.phq9:
      case ScaleType.gad7:
        if (s >= 15) return "重度";
        if (s >= 10) return "中度";
        if (s >= 5) return "輕度";
        return "正常";
      case ScaleType.psqi:
        return s > 5 ? "品質不佳" : "優良";
      case ScaleType.bp_log:
        final sys = systolic ?? 0;
        final dia = diastolic ?? 0;
        if (sys >= 140 || dia >= 90) return "血壓偏高"; // 🚀 兩者其一超標即警示
        if (sys < 90 || dia < 60) return "血壓偏低";
        return "正常";
      case ScaleType.vas:
        if (s >= 7) return "劇烈";
        if (s >= 4) return "中度";
        return "輕微";
      case ScaleType.bristol:
        if (stoolType == 3 || stoolType == 4) return "理想";
        if ((stoolType ?? 4) <= 2) return "便秘";
        return "腹瀉";
      case ScaleType.growth:
        return "數據紀錄";
      case ScaleType.qolie10:
        if (s >= 31) return "生活影響較大";
        if (s >= 21) return "中度影響";
        return "影響輕微";
      case ScaleType.lsss:
        if (s >= 20) return "發作影響明顯";
        if (s >= 10) return "中度影響";
        return "控制穩定";
      default:
        return s >= 16 ? "控制不佳" : "控制良好";
    }
  }

  @ignore
  Color get severityColor {
    final s = score ?? 0;
    // 藍色系：成長數據、經期
    if (scaleType == ScaleType.growth || scaleType == ScaleType.cycle) return Colors.blue;

    // 警戒色系
    switch (scaleType) {
      case ScaleType.phq9:
      case ScaleType.gad7:
      case ScaleType.psqi:
      case ScaleType.bp_log:
        return (severityLabel.contains("重") ||
            severityLabel.contains("高") ||
            severityLabel.contains("不佳"))
            ? Colors.red
            : Colors.green;

      case ScaleType.qolie10:
      case ScaleType.lsss:
        return severityLabel.contains("影響")
            ? Colors.orange
            : Colors.green;

      default:
        return s >= 16 ? Colors.red : Colors.green;
    }
  }
}