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
    r'answers': PropertySchema(
      id: 0,
      name: r'answers',
      type: IsarType.longList,
    ),
    r'dailyItch': PropertySchema(
      id: 1,
      name: r'dailyItch',
      type: IsarType.long,
    ),
    r'dailySleep': PropertySchema(
      id: 2,
      name: r'dailySleep',
      type: IsarType.long,
    ),
    r'date': PropertySchema(
      id: 3,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'imageConsent': PropertySchema(
      id: 4,
      name: r'imageConsent',
      type: IsarType.bool,
    ),
    r'imagePath': PropertySchema(
      id: 5,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'scaleType': PropertySchema(
      id: 6,
      name: r'scaleType',
      type: IsarType.byte,
      enumMap: _PoemRecordscaleTypeEnumValueMap,
    ),
    r'score': PropertySchema(
      id: 7,
      name: r'score',
      type: IsarType.long,
    ),
    r'severityLabel': PropertySchema(
      id: 8,
      name: r'severityLabel',
      type: IsarType.string,
    ),
    r'totalScore': PropertySchema(
      id: 9,
      name: r'totalScore',
      type: IsarType.long,
    ),
    r'type': PropertySchema(
      id: 10,
      name: r'type',
      type: IsarType.byte,
      enumMap: _PoemRecordtypeEnumValueMap,
    ),
    r'whealsCount': PropertySchema(
      id: 11,
      name: r'whealsCount',
      type: IsarType.long,
    )
  },
  estimateSize: _poemRecordEstimateSize,
  serialize: _poemRecordSerialize,
  deserialize: _poemRecordDeserialize,
  deserializeProp: _poemRecordDeserializeProp,
  idName: r'id',
  indexes: {
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
    final value = object.answers;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.imagePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.severityLabel.length * 3;
  return bytesCount;
}

void _poemRecordSerialize(
  PoemRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLongList(offsets[0], object.answers);
  writer.writeLong(offsets[1], object.dailyItch);
  writer.writeLong(offsets[2], object.dailySleep);
  writer.writeDateTime(offsets[3], object.date);
  writer.writeBool(offsets[4], object.imageConsent);
  writer.writeString(offsets[5], object.imagePath);
  writer.writeByte(offsets[6], object.scaleType.index);
  writer.writeLong(offsets[7], object.score);
  writer.writeString(offsets[8], object.severityLabel);
  writer.writeLong(offsets[9], object.totalScore);
  writer.writeByte(offsets[10], object.type.index);
  writer.writeLong(offsets[11], object.whealsCount);
}

PoemRecord _poemRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PoemRecord();
  object.answers = reader.readLongList(offsets[0]);
  object.dailyItch = reader.readLongOrNull(offsets[1]);
  object.dailySleep = reader.readLongOrNull(offsets[2]);
  object.date = reader.readDateTimeOrNull(offsets[3]);
  object.id = id;
  object.imageConsent = reader.readBoolOrNull(offsets[4]);
  object.imagePath = reader.readStringOrNull(offsets[5]);
  object.scaleType =
      _PoemRecordscaleTypeValueEnumMap[reader.readByteOrNull(offsets[6])] ??
          ScaleType.poem;
  object.score = reader.readLongOrNull(offsets[7]);
  object.type =
      _PoemRecordtypeValueEnumMap[reader.readByteOrNull(offsets[10])] ??
          RecordType.daily;
  object.whealsCount = reader.readLongOrNull(offsets[11]);
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
      return (reader.readLongList(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readBoolOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (_PoemRecordscaleTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          ScaleType.poem) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (_PoemRecordtypeValueEnumMap[reader.readByteOrNull(offset)] ??
          RecordType.daily) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PoemRecordscaleTypeEnumValueMap = {
  'poem': 0,
  'uas7': 1,
  'scorad': 2,
  'adct': 3,
};
const _PoemRecordscaleTypeValueEnumMap = {
  0: ScaleType.poem,
  1: ScaleType.uas7,
  2: ScaleType.scorad,
  3: ScaleType.adct,
};
const _PoemRecordtypeEnumValueMap = {
  'daily': 0,
  'weekly': 1,
};
const _PoemRecordtypeValueEnumMap = {
  0: RecordType.daily,
  1: RecordType.weekly,
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

extension PoemRecordQueryWhereSort
    on QueryBuilder<PoemRecord, PoemRecord, QWhere> {
  QueryBuilder<PoemRecord, PoemRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
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
  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> answersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'answers',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      answersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'answers',
      ));
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
      dailyItchIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dailyItch',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      dailyItchIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dailyItch',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dailyItchEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyItch',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      dailyItchGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyItch',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dailyItchLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyItch',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dailyItchBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyItch',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      dailySleepIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dailySleep',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      dailySleepIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dailySleep',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dailySleepEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailySleep',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      dailySleepGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailySleep',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      dailySleepLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailySleep',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> dailySleepBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailySleep',
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
      severityLabelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'severityLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      severityLabelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'severityLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      severityLabelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'severityLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      severityLabelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'severityLabel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      severityLabelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'severityLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      severityLabelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'severityLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      severityLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'severityLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      severityLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'severityLabel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      severityLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'severityLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      severityLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'severityLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> totalScoreEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalScore',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      totalScoreGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalScore',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      totalScoreLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalScore',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition> totalScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalScore',
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
      whealsCountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'whealsCount',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      whealsCountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'whealsCount',
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      whealsCountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'whealsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      whealsCountGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'whealsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      whealsCountLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'whealsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterFilterCondition>
      whealsCountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'whealsCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
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
  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByDailyItch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyItch', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByDailyItchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyItch', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByDailySleep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailySleep', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByDailySleepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailySleep', Sort.desc);
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

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortBySeverityLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'severityLabel', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortBySeverityLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'severityLabel', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByTotalScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalScore', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByTotalScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalScore', Sort.desc);
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

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByWhealsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whealsCount', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> sortByWhealsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whealsCount', Sort.desc);
    });
  }
}

extension PoemRecordQuerySortThenBy
    on QueryBuilder<PoemRecord, PoemRecord, QSortThenBy> {
  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByDailyItch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyItch', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByDailyItchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyItch', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByDailySleep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailySleep', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByDailySleepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailySleep', Sort.desc);
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

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenBySeverityLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'severityLabel', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenBySeverityLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'severityLabel', Sort.desc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByTotalScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalScore', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByTotalScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalScore', Sort.desc);
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

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByWhealsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whealsCount', Sort.asc);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QAfterSortBy> thenByWhealsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whealsCount', Sort.desc);
    });
  }
}

extension PoemRecordQueryWhereDistinct
    on QueryBuilder<PoemRecord, PoemRecord, QDistinct> {
  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByAnswers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'answers');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByDailyItch() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyItch');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByDailySleep() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailySleep');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
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

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByScaleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scaleType');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'score');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctBySeverityLabel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'severityLabel',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByTotalScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalScore');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<PoemRecord, PoemRecord, QDistinct> distinctByWhealsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'whealsCount');
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

  QueryBuilder<PoemRecord, List<int>?, QQueryOperations> answersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'answers');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> dailyItchProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyItch');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> dailySleepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailySleep');
    });
  }

  QueryBuilder<PoemRecord, DateTime?, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
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

  QueryBuilder<PoemRecord, ScaleType, QQueryOperations> scaleTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scaleType');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> scoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'score');
    });
  }

  QueryBuilder<PoemRecord, String, QQueryOperations> severityLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'severityLabel');
    });
  }

  QueryBuilder<PoemRecord, int, QQueryOperations> totalScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalScore');
    });
  }

  QueryBuilder<PoemRecord, RecordType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<PoemRecord, int?, QQueryOperations> whealsCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'whealsCount');
    });
  }
}
