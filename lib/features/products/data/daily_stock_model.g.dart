// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_stock_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyStockCollection on Isar {
  IsarCollection<DailyStock> get dailyStocks => this.collection();
}

const DailyStockSchema = CollectionSchema(
  name: r'DailyStock',
  id: 179604680033595418,
  properties: {
    r'date': PropertySchema(id: 0, name: r'date', type: IsarType.dateTime),
    r'productId': PropertySchema(
      id: 1,
      name: r'productId',
      type: IsarType.long,
    ),
    r'receivedQuantity': PropertySchema(
      id: 2,
      name: r'receivedQuantity',
      type: IsarType.double,
    ),
    r'requestedQuantity': PropertySchema(
      id: 3,
      name: r'requestedQuantity',
      type: IsarType.double,
    ),
    r'supplierId': PropertySchema(
      id: 4,
      name: r'supplierId',
      type: IsarType.long,
    ),
  },
  estimateSize: _dailyStockEstimateSize,
  serialize: _dailyStockSerialize,
  deserialize: _dailyStockDeserialize,
  deserializeProp: _dailyStockDeserializeProp,
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
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyStockGetId,
  getLinks: _dailyStockGetLinks,
  attach: _dailyStockAttach,
  version: '3.1.0+1',
);

int _dailyStockEstimateSize(
  DailyStock object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _dailyStockSerialize(
  DailyStock object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeLong(offsets[1], object.productId);
  writer.writeDouble(offsets[2], object.receivedQuantity);
  writer.writeDouble(offsets[3], object.requestedQuantity);
  writer.writeLong(offsets[4], object.supplierId);
}

DailyStock _dailyStockDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyStock();
  object.date = reader.readDateTime(offsets[0]);
  object.id = id;
  object.productId = reader.readLong(offsets[1]);
  object.receivedQuantity = reader.readDouble(offsets[2]);
  object.requestedQuantity = reader.readDouble(offsets[3]);
  object.supplierId = reader.readLongOrNull(offsets[4]);
  return object;
}

P _dailyStockDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyStockGetId(DailyStock object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyStockGetLinks(DailyStock object) {
  return [];
}

void _dailyStockAttach(IsarCollection<dynamic> col, Id id, DailyStock object) {
  object.id = id;
}

extension DailyStockQueryWhereSort
    on QueryBuilder<DailyStock, DailyStock, QWhere> {
  QueryBuilder<DailyStock, DailyStock, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension DailyStockQueryWhere
    on QueryBuilder<DailyStock, DailyStock, QWhereClause> {
  QueryBuilder<DailyStock, DailyStock, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DailyStock, DailyStock, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterWhereClause> dateEqualTo(
    DateTime date,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'date', value: [date]),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterWhereClause> dateNotEqualTo(
    DateTime date,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date',
                lower: [],
                upper: [date],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date',
                lower: [date],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date',
                lower: [date],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'date',
                lower: [],
                upper: [date],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterWhereClause> dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'date',
          lower: [date],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterWhereClause> dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'date',
          lower: [],
          upper: [date],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'date',
          lower: [lowerDate],
          includeLower: includeLower,
          upper: [upperDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DailyStockQueryFilter
    on QueryBuilder<DailyStock, DailyStock, QFilterCondition> {
  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> dateEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'date', value: value),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'date',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> productIdEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productId', value: value),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  productIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'productId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> productIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'productId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> productIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'productId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  receivedQuantityEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'receivedQuantity',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  receivedQuantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'receivedQuantity',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  receivedQuantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'receivedQuantity',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  receivedQuantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'receivedQuantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  requestedQuantityEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'requestedQuantity',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  requestedQuantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'requestedQuantity',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  requestedQuantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'requestedQuantity',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  requestedQuantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'requestedQuantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  supplierIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'supplierId'),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  supplierIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'supplierId'),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> supplierIdEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'supplierId', value: value),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  supplierIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'supplierId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition>
  supplierIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'supplierId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterFilterCondition> supplierIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'supplierId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DailyStockQueryObject
    on QueryBuilder<DailyStock, DailyStock, QFilterCondition> {}

extension DailyStockQueryLinks
    on QueryBuilder<DailyStock, DailyStock, QFilterCondition> {}

extension DailyStockQuerySortBy
    on QueryBuilder<DailyStock, DailyStock, QSortBy> {
  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> sortByReceivedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedQuantity', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy>
  sortByReceivedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedQuantity', Sort.desc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> sortByRequestedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestedQuantity', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy>
  sortByRequestedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestedQuantity', Sort.desc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> sortBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> sortBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }
}

extension DailyStockQuerySortThenBy
    on QueryBuilder<DailyStock, DailyStock, QSortThenBy> {
  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> thenByReceivedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedQuantity', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy>
  thenByReceivedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedQuantity', Sort.desc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> thenByRequestedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestedQuantity', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy>
  thenByRequestedQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestedQuantity', Sort.desc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> thenBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<DailyStock, DailyStock, QAfterSortBy> thenBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }
}

extension DailyStockQueryWhereDistinct
    on QueryBuilder<DailyStock, DailyStock, QDistinct> {
  QueryBuilder<DailyStock, DailyStock, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<DailyStock, DailyStock, QDistinct> distinctByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId');
    });
  }

  QueryBuilder<DailyStock, DailyStock, QDistinct> distinctByReceivedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receivedQuantity');
    });
  }

  QueryBuilder<DailyStock, DailyStock, QDistinct>
  distinctByRequestedQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requestedQuantity');
    });
  }

  QueryBuilder<DailyStock, DailyStock, QDistinct> distinctBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierId');
    });
  }
}

extension DailyStockQueryProperty
    on QueryBuilder<DailyStock, DailyStock, QQueryProperty> {
  QueryBuilder<DailyStock, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyStock, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailyStock, int, QQueryOperations> productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<DailyStock, double, QQueryOperations>
  receivedQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receivedQuantity');
    });
  }

  QueryBuilder<DailyStock, double, QQueryOperations>
  requestedQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requestedQuantity');
    });
  }

  QueryBuilder<DailyStock, int?, QQueryOperations> supplierIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierId');
    });
  }
}
