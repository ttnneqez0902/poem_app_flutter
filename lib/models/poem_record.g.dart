// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poem_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPoemRecordCollection on Isar {
  IsarCollection<PoemRecord> get poemRecords => this.collection();
}

const PoemRecordSchema = CollectionSchema(
  name: r'PoemRecord',
  id: 6392487321459090622,
  properties: {
    r'answerTimestamps': PropertySchema(
      id: 0,
      name: r'answerTimestamps',
      type: IsarType.dateTimeList,
    ),
    r'answers': PropertySchema(
      id: 1,
      name: r'answers',
      type: IsarType.longList,
    ),
    r'bowelMovements': PropertySchema(
      id: 2,
      name: r'bowelMovements',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(
      id: 4,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'diastolic': PropertySchema(
      id: 5,
      name: r'diastolic',
      type: IsarType.long,
    ),
    r'flowAmount': PropertySchema(
      id: 6,
      name: r'flowAmount',
      type: IsarType.long,
    ),
    r'headCircumference': PropertySchema(
      id: 7,
      name: r'headCircumference',
      type: IsarType.double,
    ),
    r'height': PropertySchema(
      id: 8,
      name: r'height',
      type: IsarType.double,
    ),
    r'imageConsent': PropertySchema(
      id: 9,
      name: r'imageConsent',
      type: IsarType.bool,
    ),
    r'imagePath': PropertySchema(
      id: 10,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 11,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isPeriodStart': PropertySchema(
      id: 12,
      name: r'isPeriodStart',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 13,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastSyncAttempt': PropertySchema(
      id: 14,
      name: r'lastSyncAttempt',
      type: IsarType.dateTime,
    ),
    r'morningStiffnessMinutes': PropertySchema(
      id: 15,
      name: r'morningStiffnessMinutes',
      type: IsarType.long,
    ),
    r'note': PropertySchema(
      id: 16,
      name: r'note',
      type: IsarType.string,
    ),
    r'pulse': PropertySchema(
      id: 17,
      name: r'pulse',
      type: IsarType.long,
    ),
    r'recordId': PropertySchema(
      id: 18,
      name: r'recordId',
      type: IsarType.string,
    ),
    r'scaleType': PropertySchema(
      id: 19,
      name: r'scaleType',
      type: IsarType.byte,
      enumMap: _PoemRecordscaleTypeEnumValueMap,
    ),
    r'scaleVersion': PropertySchema(
      id: 20,
      name: r'scaleVersion',
      type: IsarType.long,
    ),
    r'score': PropertySchema(
      id: 21,
      name: r'score',
      type: IsarType.long,
    ),
    r'stoolType': PropertySchema(
      id: 22,
      name: r'stoolType',
      type: IsarType.long,
    ),
    r'syncStatus': PropertySchema(
      id: 23,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _PoemRecordsyncStatusEnumValueMap,
    ),
    r'systolic': PropertySchema(
      id: 24,
      name: r'systolic',
      type: IsarType.long,
    ),
    r'targetDate': PropertySchema(
      id: 25,
      name: r'targetDate',
      type: IsarType.dateTime,
    ),
    r'type': PropertySchema(
      id: 26,
      name: r'type',
      type: IsarType.byte,
      enumMap: _PoemRecordtypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 27,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 28,
      name: r'userId',
      type: IsarType.string,
    ),
    r'weight': PropertySchema(
      id: 29,
      name: r'weight',
      type: IsarType.double,
    )
  },
  estimateSize: _poemRecordEstimateSize,
  serialize: _poemRecordSerialize,
  deserialize: _poemRecordDeserialize,
  deserializeProp: _poemRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'recordId': IndexSchema(
      id: 907839981883940929,
      name: r'recordId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'recordId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'userId_scaleType_targetDate': IndexSchema(
      id: -1464736195770669934,
      name: r'userId_scaleType_targetDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'scaleType',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'targetDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'syncStatus': IndexSchema(
      id: 8239539375045684509,
      name: r'syncStatus',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncStatus',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isSynced': IndexSchema(
      id: -39763503327887510,
      name: r'isSynced',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isSynced',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isDeleted': IndexSchema(
      id: -786475870904832312,
      name: r'isDeleted',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isDeleted',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'targetDate': IndexSchema(
      id: 5284734288444860006,
      name: r'targetDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'targetDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'scaleType': IndexSchema(
      id: 2791835589799838754,
      name: r'scaleType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'scaleType',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _poemRecordGetId,
  getLinks: _poemRecordGetLinks,
  attach: _poemRecordAttach,
  version: '3.1.0+1',
);

int _poemRecordEstimateSize(
  PoemRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.answerTimestamps;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  bytesCount += 3 + object.answers.length * 8;
  {
    final value = object.imagePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.recordId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _poemRecordSerialize(
  PoemRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTimeList(offsets[0], object.answerTimestamps);
  writer.writeLongList(offsets[1], object.answers);
  writer.writeLong(offsets[2], object.bowelMovements);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeDateTime(offsets[4], object.date);
  writer.writeLong(offsets[5], object.diastolic);
  writer.writeLong(offsets[6], object.flowAmount);
  writer.writeDouble(offsets[7], object.headCircumference);
  writer.writeDouble(offsets[8], object.height);
  writer.writeBool(offsets[9], object.imageConsent);
  writer.writeString(offsets[10], object.imagePath);
  writer.writeBool(offsets[11], object.isDeleted);
  writer.writeBool(offsets[12], object.isPeriodStart);
  writer.writeBool(offsets[13], object.isSynced);
  writer.writeDateTime(offsets[14], object.lastSyncAttempt);
  writer.writeLong(offsets[15], object.morningStiffnessMinutes);
  writer.writeString(offsets[16], object.note);
  writer.writeLong(offsets[17], object.pulse);
  writer.writeString(offsets[18], object.recordId);
  writer.writeByte(offsets[19], object.scaleType.index);
  writer.writeLong(offsets[20], object.scaleVersion);
  writer.writeLong(offsets[21], object.score);
  writer.writeLong(offsets[22], object.stoolType);
  writer.writeByte(offsets[23], object.syncStatus.index);
  writer.writeLong(offsets[24], object.systolic);
  writer.writeDateTime(offsets[25], object.targetDate);
  writer.writeByte(offsets[26], object.type.index);
  writer.writeDateTime(offsets[27], object.updatedAt);
  writer.writeString(offsets[28], object.userId);
  writer.writeDouble(offsets[29], object.weight);
}

PoemRecord _poemRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PoemRecord();
  object.answerTimestamps = reader.readDateTimeOrNullList(offsets[0]);
  object.answers = reader.readLongList(offsets[1]) ?? [];
  object.bowelMovements = reader.readLongOrNull(offsets[2]);
  object.createdAt = reader.readDateTimeOrNull(offsets[3]);
  object.date = reader.readDateTimeOrNull(offsets[4]);
  object.diastolic = reader.readLongOrNull(offsets[5]);
  object.flowAmount = reader.readLongOrNull(offsets[6]);
  object.headCircumference = reader.readDoubleOrNull(offsets[7]);
  object.height = reader.readDoubleOrNull(offsets[8]);
  object.id = id;
  object.imageConsent = reader.readBoolOrNull(offsets[9]);
  object.imagePath = reader.readStringOrNull(offsets[10]);
  object.isDeleted = reader.readBool(offsets[11]);
  object.isPeriodStart = reader.readBool(offsets[12]);
  object.isSynced = reader.readBool(offsets[13]);
  object.lastSyncAttempt = reader.readDateTimeOrNull(offsets[14]);
  object.morningStiffnessMinutes = reader.readLongOrNull(offsets[15]);
  object.note = reader.readStringOrNull(offsets[16]);
  object.pulse = reader.readLongOrNull(offsets[17]);
  object.recordId = reader.readStringOrNull(offsets[18]);
  object.scaleType =
      _PoemRecordscaleTypeValueEnumMap[reader.readByteOrNull(offsets[19])] ??
          ScaleType.adct;
  object.scaleVersion = reader.readLong(offsets[20]);
  object.score = reader.readLongOrNull(offsets[21]);
  object.stoolType = reader.readLongOrNull(offsets[22]);
  object.syncStatus =
      _PoemRecordsyncStatusValueEnumMap[reader.readByteOrNull(offsets[23])] ??
          SyncStatus.pending;
  object.systolic = reader.readLongOrNull(offsets[24]);
  object.targetDate = reader.readDateTimeOrNull(offsets[25]);
  object.type =
      _PoemRecordtypeValueEnumMap[reader.readByteOrNull(offsets[26])] ??
          RecordType.daily;
  object.updatedAt = reader.readDateTimeOrNull(offsets[27]);
  object.userId = reader.readStringOrNull(offsets[28]);
  object.weight = reader.readDoubleOrNull(offsets[29]);
  return object;
}

P _poemRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNullList(offset)) as P;
    case 1:
      return (reader.readLongList(offset) ?? []) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readBoolOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readLongOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (_PoemRecordscaleTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          ScaleType.adct) as P;
    case 20:
      return (reader.readLong(offset)) as P;
    case 21:
      return (reader.readLongOrNull(offset)) as P;
    case 22:
      return (reader.readLongOrNull(offset)) as P;
    case 23:
      return (_PoemRecordsyncStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncStatus.pending) as P;
    case 24:
      return (reader.readLongOrNull(offset)) as P;
    case 25:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 26:
      return (_PoemRecordtypeValueEnumMap[reader.readByteOrNull(offset)] ??
          RecordType.daily) as P;
    case 27:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 28:
      return (reader.readStringOrNull(offset)) as P;
    case 29:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PoemRecordscaleTypeEnumValueMap = {
  'adct': 0,
  'poem': 1,
  'uas7': 2,
  'scorad': 3,
  'psqi': 4,
  'isi': 5,
  'ess': 6,
  'bp_log': 7,
  'cat': 8,
  'dds': 9,
  'bpi': 10,
  'phq9': 11,
  'gad7': 12,
  'vas': 13,
  'haq': 14,
  'bristol': 15,
  'ibs_sss': 16,
  'cycle': 17,
  'growth': 18,
};
const _PoemRecordscaleTypeValueEnumMap = {
  0: ScaleType.adct,
  1: ScaleType.poem,
  2: ScaleType.uas7,
  3: ScaleType.scorad,
  4: ScaleType.psqi,
  5: ScaleType.isi,
  6: ScaleType.ess,
  7: ScaleType.bp_log,
  8: ScaleType.cat,
  9: ScaleType.dds,
  10: ScaleType.bpi,
  11: ScaleType.phq9,
  12: ScaleType.gad7,
  13: ScaleType.vas,
  14: ScaleType.haq,
  15: ScaleType.bristol,
  16: ScaleType.ibs_sss,
  17: ScaleType.cycle,
  18: ScaleType.growth,
};
const _PoemRecordsyncStatusEnumValueMap = {
  'pending': 0,
  'syncing': 1,
  'synced': 2,
  'failed': 3,
};
const _PoemRecordsyncStatusValueEnumMap = {
  0: SyncStatus.pending,
  1: SyncStatus.syncing,
  2: SyncStatus.synced,
  3: SyncStatus.failed,
};
const _PoemRecordtypeEnumValueMap = {
  'daily': 0,
  'weekly': 1,
  'biWeekly': 2,
  'monthly': 3,
};
const _PoemRecordtypeValueEnumMap = {
  0: RecordType.daily,
  1: RecordType.weekly,
  2: RecordType.biWeekly,
  3: RecordType.monthly,
};

Id _poemRecordGetId(PoemRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _poemRecordGetLinks(PoemRecord object) {
  return [];
}

void _poemRecordAttach(IsarCollection<dynamic> col, Id id, PoemRecord object) {
  object.id = id;
}

extension PoemRecordByIndex on IsarCollection<PoemRecord> {
  Future<PoemRecord?> getByRecordId(String? recordId) {
    return getByIndex(r'recordId', [recordId]);
  }

  PoemRecord? getByRecordIdSync(String? recordId) {
    return getByIndexSync(r'recordId', [recordId]);
  }

  Future<bool> deleteByRecordId(String? recordId) {
    return deleteByIndex(r'recordId', [recordId]);
  }

  bool deleteByRecordIdSync(String? recordId) {
    return deleteByIndexSync(r'recordId', [recordId]);
  }

  Future<List<PoemRecord?>> getAllByRecordId(List<String?> recordIdValues) {
    final values = recordIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'recordId', values);
  }

  List<PoemRecord?> getAllByRecordIdSync(List<String?> recordIdValues) {
    final values = recordIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'recordId', values);
  }

  Future<int> deleteAllByRecordId(List<String?> recordIdValues) {
    final values = recordIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'recordId', values);
  }

  int deleteAllByRecordIdSync(List<String?> recordIdValues) {
    final values = recordIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'recordId', values);
  }

  Future<Id> putByRecordId(PoemRecord object) {
    return putByIndex(r'recordId', object);
  }

  Id putByRecordIdSync(PoemRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'recordId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRecordId(List<PoemRecord> objects) {
    return putAllByIndex(r'recordId', objects);
  }

  List<Id> putAllByRecordIdSync(List<PoemRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'recordId', objects, saveLinks: saveLinks);
  }
}

extension PoemRecordQueryWhereSort
    on QueryBuilder<PoemRecord, PoemRecord, QWhere> {
  QueryBuilder<PoemRecord, PoemRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhere> anySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'syncStatus'),
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhere> anyIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isSynced'),
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhere> anyIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isDeleted'),
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhere> anyTargetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'targetDate'),
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhere> anyScaleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'scaleType'),
      );
    });
  }
}

extension PoemRecordQueryWhere
    on QueryBuilder<PoemRecord, PoemRecord, QWhereClause> {
  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> recordIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'recordId',
        value: [null],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> recordIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'recordId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> recordIdEqualTo(
      String? recordId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'recordId',
        value: [recordId],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> recordIdNotEqualTo(
      String? recordId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordId',
              lower: [],
              upper: [recordId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordId',
              lower: [recordId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordId',
              lower: [recordId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'recordId',
              lower: [],
              upper: [recordId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdIsNullAnyScaleTypeTargetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId_scaleType_targetDate',
        value: [null],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdIsNotNullAnyScaleTypeTargetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId_scaleType_targetDate',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdEqualToAnyScaleTypeTargetDate(String? userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId_scaleType_targetDate',
        value: [userId],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdNotEqualToAnyScaleTypeTargetDate(String? userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdScaleTypeEqualToAnyTargetDate(String? userId, ScaleType scaleType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId_scaleType_targetDate',
        value: [userId, scaleType],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdEqualToScaleTypeNotEqualToAnyTargetDate(
          String? userId, ScaleType scaleType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [userId],
              upper: [userId, scaleType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [userId, scaleType],
              includeLower: false,
              upper: [userId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [userId, scaleType],
              includeLower: false,
              upper: [userId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [userId],
              upper: [userId, scaleType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdEqualToScaleTypeGreaterThanAnyTargetDate(
    String? userId,
    ScaleType scaleType, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId_scaleType_targetDate',
        lower: [userId, scaleType],
        includeLower: include,
        upper: [userId],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdEqualToScaleTypeLessThanAnyTargetDate(
    String? userId,
    ScaleType scaleType, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId_scaleType_targetDate',
        lower: [userId],
        upper: [userId, scaleType],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdEqualToScaleTypeBetweenAnyTargetDate(
    String? userId,
    ScaleType lowerScaleType,
    ScaleType upperScaleType, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId_scaleType_targetDate',
        lower: [userId, lowerScaleType],
        includeLower: includeLower,
        upper: [userId, upperScaleType],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdScaleTypeEqualToTargetDateIsNull(
          String? userId, ScaleType scaleType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId_scaleType_targetDate',
        value: [userId, scaleType, null],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdScaleTypeEqualToTargetDateIsNotNull(
          String? userId, ScaleType scaleType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId_scaleType_targetDate',
        lower: [userId, scaleType, null],
        includeLower: false,
        upper: [
          userId,
          scaleType,
        ],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdScaleTypeTargetDateEqualTo(
          String? userId, ScaleType scaleType, DateTime? targetDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId_scaleType_targetDate',
        value: [userId, scaleType, targetDate],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdScaleTypeEqualToTargetDateNotEqualTo(
          String? userId, ScaleType scaleType, DateTime? targetDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [userId, scaleType],
              upper: [userId, scaleType, targetDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [userId, scaleType, targetDate],
              includeLower: false,
              upper: [userId, scaleType],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [userId, scaleType, targetDate],
              includeLower: false,
              upper: [userId, scaleType],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId_scaleType_targetDate',
              lower: [userId, scaleType],
              upper: [userId, scaleType, targetDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdScaleTypeEqualToTargetDateGreaterThan(
    String? userId,
    ScaleType scaleType,
    DateTime? targetDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId_scaleType_targetDate',
        lower: [userId, scaleType, targetDate],
        includeLower: include,
        upper: [userId, scaleType],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdScaleTypeEqualToTargetDateLessThan(
    String? userId,
    ScaleType scaleType,
    DateTime? targetDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId_scaleType_targetDate',
        lower: [userId, scaleType],
        upper: [userId, scaleType, targetDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      userIdScaleTypeEqualToTargetDateBetween(
    String? userId,
    ScaleType scaleType,
    DateTime? lowerTargetDate,
    DateTime? upperTargetDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId_scaleType_targetDate',
        lower: [userId, scaleType, lowerTargetDate],
        includeLower: includeLower,
        upper: [userId, scaleType, upperTargetDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> syncStatusEqualTo(
      SyncStatus syncStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncStatus',
        value: [syncStatus],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> syncStatusNotEqualTo(
      SyncStatus syncStatus) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [],
              upper: [syncStatus],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [syncStatus],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [syncStatus],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncStatus',
              lower: [],
              upper: [syncStatus],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> syncStatusGreaterThan(
    SyncStatus syncStatus, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncStatus',
        lower: [syncStatus],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> syncStatusLessThan(
    SyncStatus syncStatus, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncStatus',
        lower: [],
        upper: [syncStatus],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> syncStatusBetween(
    SyncStatus lowerSyncStatus,
    SyncStatus upperSyncStatus, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'syncStatus',
        lower: [lowerSyncStatus],
        includeLower: includeLower,
        upper: [upperSyncStatus],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> isSyncedEqualTo(
      bool isSynced) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isSynced',
        value: [isSynced],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> isSyncedNotEqualTo(
      bool isSynced) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [],
              upper: [isSynced],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [isSynced],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [isSynced],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [],
              upper: [isSynced],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> isDeletedEqualTo(
      bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isDeleted',
        value: [isDeleted],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> isDeletedNotEqualTo(
      bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [],
              upper: [isDeleted],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [isDeleted],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [isDeleted],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [],
              upper: [isDeleted],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> dateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [null],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> dateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> dateEqualTo(
      DateTime? date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> dateNotEqualTo(
      DateTime? date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> dateGreaterThan(
    DateTime? date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> dateLessThan(
    DateTime? date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> dateBetween(
    DateTime? lowerDate,
    DateTime? upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> targetDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'targetDate',
        value: [null],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause>
      targetDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetDate',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> targetDateEqualTo(
      DateTime? targetDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'targetDate',
        value: [targetDate],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> targetDateNotEqualTo(
      DateTime? targetDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetDate',
              lower: [],
              upper: [targetDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetDate',
              lower: [targetDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetDate',
              lower: [targetDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'targetDate',
              lower: [],
              upper: [targetDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> targetDateGreaterThan(
    DateTime? targetDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetDate',
        lower: [targetDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> targetDateLessThan(
    DateTime? targetDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetDate',
        lower: [],
        upper: [targetDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> targetDateBetween(
    DateTime? lowerTargetDate,
    DateTime? upperTargetDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'targetDate',
        lower: [lowerTargetDate],
        includeLower: includeLower,
        upper: [upperTargetDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> scaleTypeEqualTo(
      ScaleType scaleType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'scaleType',
        value: [scaleType],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> scaleTypeNotEqualTo(
      ScaleType scaleType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scaleType',
              lower: [],
              upper: [scaleType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scaleType',
              lower: [scaleType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scaleType',
              lower: [scaleType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'scaleType',
              lower: [],
              upper: [scaleType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> scaleTypeGreaterThan(
    ScaleType scaleType, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'scaleType',
        lower: [scaleType],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> scaleTypeLessThan(
    ScaleType scaleType, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'scaleType',
        lower: [],
        upper: [scaleType],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhereClause> scaleTypeBetween(
    ScaleType lowerScaleType,
    ScaleType upperScaleType, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'scaleType',
        lower: [lowerScaleType],
        includeLower: includeLower,
        upper: [upperScaleType],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PoemRecordQueryFilter
    on QueryBuilder<PoemRecord, PoemRecord, QFilterCondition> {
  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'answerTimestamps',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'answerTimestamps',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsElementIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.elementIsNull(
        property: r'answerTimestamps',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsElementIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.elementIsNotNull(
        property: r'answerTimestamps',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsElementEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'answerTimestamps',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsElementGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'answerTimestamps',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsElementLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'answerTimestamps',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsElementBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'answerTimestamps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answerTimestamps',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answerTimestamps',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answerTimestamps',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answerTimestamps',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answerTimestamps',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answerTimestampsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answerTimestamps',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answersElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'answers',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answersElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'answers',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answersElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'answers',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answersElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'answers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> answersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'answers',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      bowelMovementsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bowelMovements',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      bowelMovementsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bowelMovements',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      bowelMovementsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bowelMovements',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      bowelMovementsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bowelMovements',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      bowelMovementsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bowelMovements',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      bowelMovementsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bowelMovements',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> createdAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      diastolicIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'diastolic',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      diastolicIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'diastolic',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> diastolicEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'diastolic',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      diastolicGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'diastolic',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> diastolicLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'diastolic',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> diastolicBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'diastolic',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      flowAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'flowAmount',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      flowAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'flowAmount',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> flowAmountEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flowAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      flowAmountGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flowAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      flowAmountLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flowAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> flowAmountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flowAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      headCircumferenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'headCircumference',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      headCircumferenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'headCircumference',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      headCircumferenceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headCircumference',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      headCircumferenceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'headCircumference',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      headCircumferenceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'headCircumference',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      headCircumferenceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'headCircumference',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> heightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> heightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> heightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> heightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'height',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      imageConsentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imageConsent',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      imageConsentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imageConsent',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      imageConsentEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageConsent',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      imagePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      imagePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> imagePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      imagePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> imagePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> imagePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> imagePathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> imagePathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> isDeletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      isPeriodStartEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPeriodStart',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      lastSyncAttemptIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAttempt',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      lastSyncAttemptIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAttempt',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      lastSyncAttemptEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAttempt',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      lastSyncAttemptGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncAttempt',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      lastSyncAttemptLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncAttempt',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      lastSyncAttemptBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncAttempt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      morningStiffnessMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'morningStiffnessMinutes',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      morningStiffnessMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'morningStiffnessMinutes',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      morningStiffnessMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'morningStiffnessMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      morningStiffnessMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'morningStiffnessMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      morningStiffnessMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'morningStiffnessMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      morningStiffnessMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'morningStiffnessMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> pulseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pulse',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> pulseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pulse',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> pulseEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pulse',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> pulseGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pulse',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> pulseLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pulse',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> pulseBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pulse',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> recordIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recordId',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      recordIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recordId',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> recordIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      recordIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> recordIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> recordIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recordId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      recordIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> recordIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> recordIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recordId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> recordIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recordId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      recordIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordId',
        value: '',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      recordIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recordId',
        value: '',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> scaleTypeEqualTo(
      ScaleType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scaleType',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      scaleTypeGreaterThan(
    ScaleType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scaleType',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> scaleTypeLessThan(
    ScaleType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scaleType',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> scaleTypeBetween(
    ScaleType lower,
    ScaleType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scaleType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      scaleVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scaleVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      scaleVersionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scaleVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      scaleVersionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scaleVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      scaleVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scaleVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> scoreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'score',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> scoreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'score',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> scoreEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'score',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> scoreGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'score',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> scoreLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'score',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> scoreBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'score',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      stoolTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stoolType',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      stoolTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stoolType',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> stoolTypeEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stoolType',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      stoolTypeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stoolType',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> stoolTypeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stoolType',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> stoolTypeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stoolType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> syncStatusEqualTo(
      SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> systolicIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'systolic',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      systolicIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'systolic',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> systolicEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'systolic',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      systolicGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'systolic',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> systolicLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'systolic',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> systolicBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'systolic',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      targetDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetDate',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      targetDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetDate',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> targetDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetDate',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      targetDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetDate',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      targetDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetDate',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> targetDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> typeEqualTo(
      RecordType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> typeGreaterThan(
    RecordType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> typeLessThan(
    RecordType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> typeBetween(
    RecordType lower,
    RecordType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> updatedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> userIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> userIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> userIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> userIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> userIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> userIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> weightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      weightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> weightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> weightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> weightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> weightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension PoemRecordQueryObject
    on QueryBuilder<PoemRecord, PoemRecord, QFilterCondition> {}

extension PoemRecordQueryLinks
    on QueryBuilder<PoemRecord, PoemRecord, QFilterCondition> {}

extension PoemRecordQuerySortBy
    on QueryBuilder<PoemRecord, PoemRecord, QSortBy> {
  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByBowelMovements() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bowelMovements', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy>
      sortByBowelMovementsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bowelMovements', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByDiastolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diastolic', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByDiastolicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diastolic', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByFlowAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flowAmount', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByFlowAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flowAmount', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByHeadCircumference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headCircumference', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy>
      sortByHeadCircumferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headCircumference', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByImageConsent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageConsent', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByImageConsentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageConsent', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByIsPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPeriodStart', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByIsPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPeriodStart', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByLastSyncAttempt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy>
      sortByLastSyncAttemptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy>
      sortByMorningStiffnessMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'morningStiffnessMinutes', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy>
      sortByMorningStiffnessMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'morningStiffnessMinutes', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByPulse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pulse', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByPulseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pulse', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByRecordId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByRecordIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByScaleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleType', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByScaleTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleType', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByScaleVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleVersion', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByScaleVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleVersion', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByStoolType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stoolType', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByStoolTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stoolType', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortBySystolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systolic', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortBySystolicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systolic', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByTargetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDate', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByTargetDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDate', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension PoemRecordQuerySortThenBy
    on QueryBuilder<PoemRecord, PoemRecord, QSortThenBy> {
  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByBowelMovements() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bowelMovements', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy>
      thenByBowelMovementsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bowelMovements', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByDiastolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diastolic', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByDiastolicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diastolic', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByFlowAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flowAmount', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByFlowAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flowAmount', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByHeadCircumference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headCircumference', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy>
      thenByHeadCircumferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headCircumference', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByImageConsent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageConsent', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByImageConsentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageConsent', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByIsPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPeriodStart', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByIsPeriodStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPeriodStart', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByLastSyncAttempt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy>
      thenByLastSyncAttemptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAttempt', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy>
      thenByMorningStiffnessMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'morningStiffnessMinutes', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy>
      thenByMorningStiffnessMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'morningStiffnessMinutes', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByPulse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pulse', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByPulseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pulse', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByRecordId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByRecordIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordId', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByScaleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleType', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByScaleTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleType', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByScaleVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleVersion', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByScaleVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaleVersion', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByStoolType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stoolType', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByStoolTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stoolType', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenBySystolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systolic', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenBySystolicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'systolic', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByTargetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDate', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByTargetDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDate', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension PoemRecordQueryWhereDistinct
    on QueryBuilder<PoemRecord, PoemRecord, QDistinct> {
  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByAnswerTimestamps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'answerTimestamps');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByAnswers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'answers');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByBowelMovements() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bowelMovements');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByDiastolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'diastolic');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByFlowAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flowAmount');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct>
      distinctByHeadCircumference() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'headCircumference');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByImageConsent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageConsent');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByImagePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByIsPeriodStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPeriodStart');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByLastSyncAttempt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAttempt');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct>
      distinctByMorningStiffnessMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'morningStiffnessMinutes');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByPulse() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pulse');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByRecordId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByScaleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scaleType');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByScaleVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scaleVersion');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'score');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByStoolType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stoolType');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctBySystolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'systolic');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByTargetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetDate');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension PoemRecordQueryProperty
    on QueryBuilder<PoemRecord, PoemRecord, QQueryProperty> {
  QueryBuilder<PoemRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PoemRecord, List<DateTime?>?, QQueryOperations>
      answerTimestampsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'answerTimestamps');
    });
  }

  QueryBuilder<PoemRecord, List<int>, QQueryOperations> answersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'answers');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> bowelMovementsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bowelMovements');
    });
  }

  QueryBuilder<PoemRecord, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PoemRecord, DateTime?, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> diastolicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'diastolic');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> flowAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flowAmount');
    });
  }

  QueryBuilder<PoemRecord, double?, QQueryOperations>
      headCircumferenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'headCircumference');
    });
  }

  QueryBuilder<PoemRecord, double?, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<PoemRecord, bool?, QQueryOperations> imageConsentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageConsent');
    });
  }

  QueryBuilder<PoemRecord, String?, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<PoemRecord, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<PoemRecord, bool, QQueryOperations> isPeriodStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPeriodStart');
    });
  }

  QueryBuilder<PoemRecord, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<PoemRecord, DateTime?, QQueryOperations>
      lastSyncAttemptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAttempt');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations>
      morningStiffnessMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'morningStiffnessMinutes');
    });
  }

  QueryBuilder<PoemRecord, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> pulseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pulse');
    });
  }

  QueryBuilder<PoemRecord, String?, QQueryOperations> recordIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordId');
    });
  }

  QueryBuilder<PoemRecord, ScaleType, QQueryOperations> scaleTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scaleType');
    });
  }

  QueryBuilder<PoemRecord, int, QQueryOperations> scaleVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scaleVersion');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> scoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'score');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> stoolTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stoolType');
    });
  }

  QueryBuilder<PoemRecord, SyncStatus, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> systolicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'systolic');
    });
  }

  QueryBuilder<PoemRecord, DateTime?, QQueryOperations> targetDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetDate');
    });
  }

  QueryBuilder<PoemRecord, RecordType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<PoemRecord, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<PoemRecord, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<PoemRecord, double?, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}
