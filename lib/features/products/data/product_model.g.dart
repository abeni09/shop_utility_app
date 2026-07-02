// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProductCollection on Isar {
  IsarCollection<Product> get products => this.collection();
}

const ProductSchema = CollectionSchema(
  name: r'Product',
  id: -6222113721139403729,
  properties: {
    r'costPrice': PropertySchema(
      id: 0,
      name: r'costPrice',
      type: IsarType.double,
    ),
    r'hasQuota': PropertySchema(
      id: 1,
      name: r'hasQuota',
      type: IsarType.bool,
    ),
    r'holidayQuota': PropertySchema(
      id: 2,
      name: r'holidayQuota',
      type: IsarType.double,
    ),
    r'imagePath': PropertySchema(
      id: 3,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'isVoid': PropertySchema(
      id: 4,
      name: r'isVoid',
      type: IsarType.bool,
    ),
    r'lastUpdated': PropertySchema(
      id: 5,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'minStockThreshold': PropertySchema(
      id: 6,
      name: r'minStockThreshold',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 7,
      name: r'name',
      type: IsarType.string,
    ),
    r'overQuotaCostPrice': PropertySchema(
      id: 8,
      name: r'overQuotaCostPrice',
      type: IsarType.double,
    ),
    r'sellingPrice': PropertySchema(
      id: 9,
      name: r'sellingPrice',
      type: IsarType.double,
    ),
    r'shelfLifeDays': PropertySchema(
      id: 10,
      name: r'shelfLifeDays',
      type: IsarType.long,
    ),
    r'supplierId': PropertySchema(
      id: 11,
      name: r'supplierId',
      type: IsarType.long,
    ),
    r'weekdayQuota': PropertySchema(
      id: 12,
      name: r'weekdayQuota',
      type: IsarType.double,
    ),
    r'weekendQuota': PropertySchema(
      id: 13,
      name: r'weekendQuota',
      type: IsarType.double,
    )
  },
  estimateSize: _productEstimateSize,
  serialize: _productSerialize,
  deserialize: _productDeserialize,
  deserializeProp: _productDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _productGetId,
  getLinks: _productGetLinks,
  attach: _productAttach,
  version: '3.1.0+1',
);

int _productEstimateSize(
  Product object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.imagePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _productSerialize(
  Product object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.costPrice);
  writer.writeBool(offsets[1], object.hasQuota);
  writer.writeDouble(offsets[2], object.holidayQuota);
  writer.writeString(offsets[3], object.imagePath);
  writer.writeBool(offsets[4], object.isVoid);
  writer.writeDateTime(offsets[5], object.lastUpdated);
  writer.writeLong(offsets[6], object.minStockThreshold);
  writer.writeString(offsets[7], object.name);
  writer.writeDouble(offsets[8], object.overQuotaCostPrice);
  writer.writeDouble(offsets[9], object.sellingPrice);
  writer.writeLong(offsets[10], object.shelfLifeDays);
  writer.writeLong(offsets[11], object.supplierId);
  writer.writeDouble(offsets[12], object.weekdayQuota);
  writer.writeDouble(offsets[13], object.weekendQuota);
}

Product _productDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Product();
  object.costPrice = reader.readDouble(offsets[0]);
  object.hasQuota = reader.readBool(offsets[1]);
  object.holidayQuota = reader.readDoubleOrNull(offsets[2]);
  object.id = id;
  object.imagePath = reader.readStringOrNull(offsets[3]);
  object.isVoid = reader.readBool(offsets[4]);
  object.lastUpdated = reader.readDateTimeOrNull(offsets[5]);
  object.minStockThreshold = reader.readLong(offsets[6]);
  object.name = reader.readString(offsets[7]);
  object.overQuotaCostPrice = reader.readDoubleOrNull(offsets[8]);
  object.sellingPrice = reader.readDouble(offsets[9]);
  object.shelfLifeDays = reader.readLong(offsets[10]);
  object.supplierId = reader.readLongOrNull(offsets[11]);
  object.weekdayQuota = reader.readDoubleOrNull(offsets[12]);
  object.weekendQuota = reader.readDoubleOrNull(offsets[13]);
  return object;
}

P _productDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _productGetId(Product object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _productGetLinks(Product object) {
  return [];
}

void _productAttach(IsarCollection<dynamic> col, Id id, Product object) {
  object.id = id;
}

extension ProductByIndex on IsarCollection<Product> {
  Future<Product?> getByName(String name) {
    return getByIndex(r'name', [name]);
  }

  Product? getByNameSync(String name) {
    return getByIndexSync(r'name', [name]);
  }

  Future<bool> deleteByName(String name) {
    return deleteByIndex(r'name', [name]);
  }

  bool deleteByNameSync(String name) {
    return deleteByIndexSync(r'name', [name]);
  }

  Future<List<Product?>> getAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndex(r'name', values);
  }

  List<Product?> getAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'name', values);
  }

  Future<int> deleteAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'name', values);
  }

  int deleteAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'name', values);
  }

  Future<Id> putByName(Product object) {
    return putByIndex(r'name', object);
  }

  Id putByNameSync(Product object, {bool saveLinks = true}) {
    return putByIndexSync(r'name', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByName(List<Product> objects) {
    return putAllByIndex(r'name', objects);
  }

  List<Id> putAllByNameSync(List<Product> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'name', objects, saveLinks: saveLinks);
  }
}

extension ProductQueryWhereSort on QueryBuilder<Product, Product, QWhere> {
  QueryBuilder<Product, Product, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProductQueryWhere on QueryBuilder<Product, Product, QWhereClause> {
  QueryBuilder<Product, Product, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Product, Product, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Product, Product, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Product, Product, QAfterWhereClause> idBetween(
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

  QueryBuilder<Product, Product, QAfterWhereClause> nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterWhereClause> nameNotEqualTo(
      String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ProductQueryFilter
    on QueryBuilder<Product, Product, QFilterCondition> {
  QueryBuilder<Product, Product, QAfterFilterCondition> costPriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'costPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> costPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'costPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> costPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'costPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> costPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'costPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> hasQuotaEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasQuota',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> holidayQuotaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'holidayQuota',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      holidayQuotaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'holidayQuota',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> holidayQuotaEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'holidayQuota',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> holidayQuotaGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'holidayQuota',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> holidayQuotaLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'holidayQuota',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> holidayQuotaBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'holidayQuota',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathEqualTo(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathGreaterThan(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathLessThan(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathBetween(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathStartsWith(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathEndsWith(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathContains(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathMatches(
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

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> isVoidEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isVoid',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> lastUpdatedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastUpdated',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> lastUpdatedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastUpdated',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> lastUpdatedEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> lastUpdatedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> lastUpdatedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> lastUpdatedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUpdated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      minStockThresholdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minStockThreshold',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      minStockThresholdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minStockThreshold',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      minStockThresholdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minStockThreshold',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      minStockThresholdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minStockThreshold',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      overQuotaCostPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'overQuotaCostPrice',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      overQuotaCostPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'overQuotaCostPrice',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      overQuotaCostPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'overQuotaCostPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      overQuotaCostPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'overQuotaCostPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      overQuotaCostPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'overQuotaCostPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      overQuotaCostPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'overQuotaCostPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> sellingPriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellingPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> sellingPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sellingPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> sellingPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sellingPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> sellingPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sellingPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> shelfLifeDaysEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shelfLifeDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      shelfLifeDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shelfLifeDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> shelfLifeDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shelfLifeDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> shelfLifeDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shelfLifeDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> supplierIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'supplierId',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> supplierIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'supplierId',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> supplierIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierId',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> supplierIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supplierId',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> supplierIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supplierId',
        value: value,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> supplierIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supplierId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> weekdayQuotaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weekdayQuota',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      weekdayQuotaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weekdayQuota',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> weekdayQuotaEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weekdayQuota',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> weekdayQuotaGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weekdayQuota',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> weekdayQuotaLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weekdayQuota',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> weekdayQuotaBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weekdayQuota',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> weekendQuotaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weekendQuota',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition>
      weekendQuotaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weekendQuota',
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> weekendQuotaEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weekendQuota',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> weekendQuotaGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weekendQuota',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> weekendQuotaLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weekendQuota',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Product, Product, QAfterFilterCondition> weekendQuotaBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weekendQuota',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension ProductQueryObject
    on QueryBuilder<Product, Product, QFilterCondition> {}

extension ProductQueryLinks
    on QueryBuilder<Product, Product, QFilterCondition> {}

extension ProductQuerySortBy on QueryBuilder<Product, Product, QSortBy> {
  QueryBuilder<Product, Product, QAfterSortBy> sortByCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByCostPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByHasQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasQuota', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByHasQuotaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasQuota', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByHolidayQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'holidayQuota', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByHolidayQuotaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'holidayQuota', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByIsVoid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoid', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByIsVoidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoid', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByMinStockThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minStockThreshold', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByMinStockThresholdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minStockThreshold', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByOverQuotaCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overQuotaCostPrice', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByOverQuotaCostPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overQuotaCostPrice', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortBySellingPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortBySellingPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByShelfLifeDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shelfLifeDays', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByShelfLifeDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shelfLifeDays', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByWeekdayQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekdayQuota', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByWeekdayQuotaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekdayQuota', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByWeekendQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendQuota', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> sortByWeekendQuotaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendQuota', Sort.desc);
    });
  }
}

extension ProductQuerySortThenBy
    on QueryBuilder<Product, Product, QSortThenBy> {
  QueryBuilder<Product, Product, QAfterSortBy> thenByCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByCostPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPrice', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByHasQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasQuota', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByHasQuotaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasQuota', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByHolidayQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'holidayQuota', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByHolidayQuotaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'holidayQuota', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByIsVoid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoid', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByIsVoidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoid', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByMinStockThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minStockThreshold', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByMinStockThresholdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minStockThreshold', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByOverQuotaCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overQuotaCostPrice', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByOverQuotaCostPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overQuotaCostPrice', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenBySellingPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenBySellingPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPrice', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByShelfLifeDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shelfLifeDays', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByShelfLifeDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shelfLifeDays', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenBySupplierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierId', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByWeekdayQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekdayQuota', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByWeekdayQuotaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekdayQuota', Sort.desc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByWeekendQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendQuota', Sort.asc);
    });
  }

  QueryBuilder<Product, Product, QAfterSortBy> thenByWeekendQuotaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekendQuota', Sort.desc);
    });
  }
}

extension ProductQueryWhereDistinct
    on QueryBuilder<Product, Product, QDistinct> {
  QueryBuilder<Product, Product, QDistinct> distinctByCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'costPrice');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByHasQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasQuota');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByHolidayQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'holidayQuota');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByImagePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByIsVoid() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isVoid');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByMinStockThreshold() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minStockThreshold');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByOverQuotaCostPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'overQuotaCostPrice');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctBySellingPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sellingPrice');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByShelfLifeDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shelfLifeDays');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctBySupplierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierId');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByWeekdayQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weekdayQuota');
    });
  }

  QueryBuilder<Product, Product, QDistinct> distinctByWeekendQuota() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weekendQuota');
    });
  }
}

extension ProductQueryProperty
    on QueryBuilder<Product, Product, QQueryProperty> {
  QueryBuilder<Product, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Product, double, QQueryOperations> costPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'costPrice');
    });
  }

  QueryBuilder<Product, bool, QQueryOperations> hasQuotaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasQuota');
    });
  }

  QueryBuilder<Product, double?, QQueryOperations> holidayQuotaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'holidayQuota');
    });
  }

  QueryBuilder<Product, String?, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<Product, bool, QQueryOperations> isVoidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isVoid');
    });
  }

  QueryBuilder<Product, DateTime?, QQueryOperations> lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<Product, int, QQueryOperations> minStockThresholdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minStockThreshold');
    });
  }

  QueryBuilder<Product, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Product, double?, QQueryOperations>
      overQuotaCostPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'overQuotaCostPrice');
    });
  }

  QueryBuilder<Product, double, QQueryOperations> sellingPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sellingPrice');
    });
  }

  QueryBuilder<Product, int, QQueryOperations> shelfLifeDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shelfLifeDays');
    });
  }

  QueryBuilder<Product, int?, QQueryOperations> supplierIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierId');
    });
  }

  QueryBuilder<Product, double?, QQueryOperations> weekdayQuotaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weekdayQuota');
    });
  }

  QueryBuilder<Product, double?, QQueryOperations> weekendQuotaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weekendQuota');
    });
  }
}
