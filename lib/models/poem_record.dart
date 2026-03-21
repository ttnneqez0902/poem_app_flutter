import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'poem_record.g.dart';

enum RecordType { daily, weekly, biWeekly, monthly }
enum ScaleType { poem, uas7, scorad, adct, phq9, gad7, vas }
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
  bool isSynced = false; // 🚀 補回：相容舊有 UI 邏輯

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
  RecordType type = RecordType.weekly; // 🚀 補回：UI 所需欄位

  int scaleVersion = 1; // 🚀 補回：UI 所需欄位
  int? score;
  List<int> answers = [];
  List<DateTime?>? answerTimestamps; // 🚀 補回：UI 所需欄位

  // --- 🩺 皮膚科專屬欄位 ---
  int? dailyItch;
  int? dailySleep;
  int? whealsCount;

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
      ..syncStatus = SyncStatus.synced
      ..isSynced = true;
  }

  @ignore
  String get severityLabel {
    final s = score ?? 0;
    switch (scaleType) {
      case ScaleType.phq9: return s <= 9 ? "輕微" : "中重度";
      case ScaleType.vas: return s <= 3 ? "輕微" : "劇烈";
      default: return s >= 7 ? "控制不佳" : "控制良好";
    }
  }

  @ignore
  Color get severityColor {
    final s = score ?? 0;
    if (s <= 9) return Colors.green;
    return Colors.red;
  }
}