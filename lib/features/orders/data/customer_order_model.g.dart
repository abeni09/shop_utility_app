// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_order_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomerOrderCollection on Isar {
  IsarCollection<CustomerOrder> get customerOrders => this.collection();
}

const CustomerOrderSchema = CollectionSchema(
  name: r'CustomerOrder',
  id: 7813251628506524948,
  properties: {
    r'addonAmount': PropertySchema(
      id: 0,
      name: r'addonAmount',
      type: IsarType.double,
    ),
    r'addonCost': PropertySchema(
      id: 1,
      name: r'addonCost',
      type: IsarType.double,
    ),
    r'addonName': PropertySchema(
      id: 2,
      name: r'addonName',
      type: IsarType.string,
    ),
    r'addonPrice': PropertySchema(
      id: 3,
      name: r'addonPrice',
      type: IsarType.double,
    ),
    r'advancePayment': PropertySchema(
      id: 4,
      name: r'advancePayment',
      type: IsarType.double,
    ),
    r'amount': PropertySchema(
      id: 5,
      name: r'amount',
      type: IsarType.double,
    ),
    r'costPriceAtTime': PropertySchema(
      id: 6,
      name: r'costPriceAtTime',
      type: IsarType.double,
    ),
    r'customerName': PropertySchema(
      id: 7,
      name: r'customerName',
      type: IsarType.string,
    ),
    r'dueDate': PropertySchema(
      id: 8,
      name: r'dueDate',
      type: IsarType.dateTime,
    ),
    r'fulfilledAt': PropertySchema(
      id: 9,
      name: r'fulfilledAt',
      type: IsarType.dateTime,
    ),
    r'isVoid': PropertySchema(
      id: 10,
      name: r'isVoid',
      type: IsarType.bool,
    ),
    r'note': PropertySchema(
      id: 11,
      name: r'note',
      type: IsarType.string,
    ),
    r'paymentMethod': PropertySchema(
      id: 12,
      name: r'paymentMethod',
      type: IsarType.byte,
      enumMap: _CustomerOrderpaymentMethodEnumValueMap,
    ),
    r'phoneNumber': PropertySchema(
      id: 13,
      name: r'phoneNumber',
      type: IsarType.string,
    ),
    r'productId': PropertySchema(
      id: 14,
      name: r'productId',
      type: IsarType.long,
    ),
    r'sellingPriceAtTime': PropertySchema(
      id: 15,
      name: r'sellingPriceAtTime',
      type: IsarType.double,
    ),
    r'status': PropertySchema(
      id: 16,
      name: r'status',
      type: IsarType.byte,
      enumMap: _CustomerOrderstatusEnumValueMap,
    )
  },
  estimateSize: _customerOrderEstimateSize,
  serialize: _customerOrderSerialize,
  deserialize: _customerOrderDeserialize,
  deserializeProp: _customerOrderDeserializeProp,
  idName: r'id',
  indexes: {
    r'dueDate': IndexSchema(
      id: -7871003637559820552,
      name: r'dueDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dueDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _customerOrderGetId,
  getLinks: _customerOrderGetLinks,
  attach: _customerOrderAttach,
  version: '3.1.0+1',
);

int _customerOrderEstimateSize(
  CustomerOrder object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.addonName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.customerName.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.phoneNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _customerOrderSerialize(
  CustomerOrder object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.addonAmount);
  writer.writeDouble(offsets[1], object.addonCost);
  writer.writeString(offsets[2], object.addonName);
  writer.writeDouble(offsets[3], object.addonPrice);
  writer.writeDouble(offsets[4], object.advancePayment);
  writer.writeDouble(offsets[5], object.amount);
  writer.writeDouble(offsets[6], object.costPriceAtTime);
  writer.writeString(offsets[7], object.customerName);
  writer.writeDateTime(offsets[8], object.dueDate);
  writer.writeDateTime(offsets[9], object.fulfilledAt);
  writer.writeBool(offsets[10], object.isVoid);
  writer.writeString(offsets[11], object.note);
  writer.writeByte(offsets[12], object.paymentMethod.index);
  writer.writeString(offsets[13], object.phoneNumber);
  writer.writeLong(offsets[14], object.productId);
  writer.writeDouble(offsets[15], object.sellingPriceAtTime);
  writer.writeByte(offsets[16], object.status.index);
}

CustomerOrder _customerOrderDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomerOrder();
  object.addonAmount = reader.readDoubleOrNull(offsets[0]);
  object.addonCost = reader.readDoubleOrNull(offsets[1]);
  object.addonName = reader.readStringOrNull(offsets[2]);
  object.addonPrice = reader.readDoubleOrNull(offsets[3]);
  object.advancePayment = reader.readDouble(offsets[4]);
  object.amount = reader.readDouble(offsets[5]);
  object.costPriceAtTime = reader.readDouble(offsets[6]);
  object.customerName = reader.readString(offsets[7]);
  object.dueDate = reader.readDateTime(offsets[8]);
  object.fulfilledAt = reader.readDateTimeOrNull(offsets[9]);
  object.id = id;
  object.isVoid = reader.readBool(offsets[10]);
  object.note = reader.readStringOrNull(offsets[11]);
  object.paymentMethod = _CustomerOrderpaymentMethodValueEnumMap[
          reader.readByteOrNull(offsets[12])] ??
      PaymentMethod.cash;
  object.phoneNumber = reader.readStringOrNull(offsets[13]);
  object.productId = reader.readLong(offsets[14]);
  object.sellingPriceAtTime = reader.readDouble(offsets[15]);
  object.status =
      _CustomerOrderstatusValueEnumMap[reader.readByteOrNull(offsets[16])] ??
          OrderStatus.pending;
  return object;
}

P _customerOrderDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (_CustomerOrderpaymentMethodValueEnumMap[
              reader.readByteOrNull(offset)] ??
          PaymentMethod.cash) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (_CustomerOrderstatusValueEnumMap[reader.readByteOrNull(offset)] ??
          OrderStatus.pending) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CustomerOrderpaymentMethodEnumValueMap = {
  'cash': 0,
  'mobile': 1,
  'credit': 2,
};
const _CustomerOrderpaymentMethodValueEnumMap = {
  0: PaymentMethod.cash,
  1: PaymentMethod.mobile,
  2: PaymentMethod.credit,
};
const _CustomerOrderstatusEnumValueMap = {
  'pending': 0,
  'sold': 1,
  'cancelled': 2,
};
const _CustomerOrderstatusValueEnumMap = {
  0: OrderStatus.pending,
  1: OrderStatus.sold,
  2: OrderStatus.cancelled,
};

Id _customerOrderGetId(CustomerOrder object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _customerOrderGetLinks(CustomerOrder object) {
  return [];
}

void _customerOrderAttach(
    IsarCollection<dynamic> col, Id id, CustomerOrder object) {
  object.id = id;
}

extension CustomerOrderQueryWhereSort
    on QueryBuilder<CustomerOrder, CustomerOrder, QWhere> {
  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhere> anyDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dueDate'),
      );
    });
  }
}

extension CustomerOrderQueryWhere
    on QueryBuilder<CustomerOrder, CustomerOrder, QWhereClause> {
  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhereClause> idBetween(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhereClause> dueDateEqualTo(
      DateTime dueDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dueDate',
        value: [dueDate],
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhereClause>
      dueDateNotEqualTo(DateTime dueDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueDate',
              lower: [],
              upper: [dueDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueDate',
              lower: [dueDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueDate',
              lower: [dueDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueDate',
              lower: [],
              upper: [dueDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhereClause>
      dueDateGreaterThan(
    DateTime dueDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueDate',
        lower: [dueDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhereClause> dueDateLessThan(
    DateTime dueDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueDate',
        lower: [],
        upper: [dueDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterWhereClause> dueDateBetween(
    DateTime lowerDueDate,
    DateTime upperDueDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueDate',
        lower: [lowerDueDate],
        includeLower: includeLower,
        upper: [upperDueDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CustomerOrderQueryFilter
    on QueryBuilder<CustomerOrder, CustomerOrder, QFilterCondition> {
  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'addonAmount',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'addonAmount',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addonAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'addonAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'addonAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'addonAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonCostIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'addonCost',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonCostIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'addonCost',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonCostEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addonCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonCostGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'addonCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonCostLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'addonCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonCostBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'addonCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'addonName',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'addonName',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'addonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'addonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'addonName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'addonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'addonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'addonName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'addonName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addonName',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'addonName',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'addonPrice',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'addonPrice',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addonPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'addonPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'addonPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      addonPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'addonPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      advancePaymentEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'advancePayment',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      advancePaymentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'advancePayment',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      advancePaymentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'advancePayment',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      advancePaymentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'advancePayment',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      costPriceAtTimeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'costPriceAtTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      costPriceAtTimeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'costPriceAtTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      costPriceAtTimeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'costPriceAtTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      costPriceAtTimeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'costPriceAtTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      customerNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      customerNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      customerNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      customerNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      customerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      customerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      customerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      customerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      customerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerName',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      customerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customerName',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      dueDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      dueDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      dueDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      dueDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dueDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      fulfilledAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fulfilledAt',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      fulfilledAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fulfilledAt',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      fulfilledAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fulfilledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      fulfilledAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fulfilledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      fulfilledAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fulfilledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      fulfilledAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fulfilledAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      isVoidEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isVoid',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition> noteEqualTo(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      noteGreaterThan(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      noteLessThan(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition> noteBetween(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      noteStartsWith(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      noteEndsWith(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition> noteMatches(
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

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      paymentMethodEqualTo(PaymentMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      paymentMethodGreaterThan(
    PaymentMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      paymentMethodLessThan(
    PaymentMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      paymentMethodBetween(
    PaymentMethod lower,
    PaymentMethod upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentMethod',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'phoneNumber',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'phoneNumber',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'phoneNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'phoneNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'phoneNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phoneNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      phoneNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'phoneNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      productIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      productIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productId',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      productIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productId',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      productIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      sellingPriceAtTimeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sellingPriceAtTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      sellingPriceAtTimeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sellingPriceAtTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      sellingPriceAtTimeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sellingPriceAtTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      sellingPriceAtTimeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sellingPriceAtTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      statusEqualTo(OrderStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      statusGreaterThan(
    OrderStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      statusLessThan(
    OrderStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterFilterCondition>
      statusBetween(
    OrderStatus lower,
    OrderStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CustomerOrderQueryObject
    on QueryBuilder<CustomerOrder, CustomerOrder, QFilterCondition> {}

extension CustomerOrderQueryLinks
    on QueryBuilder<CustomerOrder, CustomerOrder, QFilterCondition> {}

extension CustomerOrderQuerySortBy
    on QueryBuilder<CustomerOrder, CustomerOrder, QSortBy> {
  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByAddonAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonAmount', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByAddonAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonAmount', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByAddonCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonCost', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByAddonCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonCost', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByAddonName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonName', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByAddonNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonName', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByAddonPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonPrice', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByAddonPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonPrice', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByAdvancePayment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'advancePayment', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByAdvancePaymentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'advancePayment', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByCostPriceAtTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPriceAtTime', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByCostPriceAtTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPriceAtTime', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByFulfilledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fulfilledAt', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByFulfilledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fulfilledAt', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByIsVoid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoid', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByIsVoidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoid', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByPhoneNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phoneNumber', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByPhoneNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phoneNumber', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortBySellingPriceAtTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPriceAtTime', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      sortBySellingPriceAtTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPriceAtTime', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension CustomerOrderQuerySortThenBy
    on QueryBuilder<CustomerOrder, CustomerOrder, QSortThenBy> {
  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByAddonAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonAmount', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByAddonAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonAmount', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByAddonCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonCost', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByAddonCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonCost', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByAddonName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonName', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByAddonNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonName', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByAddonPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonPrice', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByAddonPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addonPrice', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByAdvancePayment() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'advancePayment', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByAdvancePaymentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'advancePayment', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByCostPriceAtTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPriceAtTime', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByCostPriceAtTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPriceAtTime', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByFulfilledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fulfilledAt', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByFulfilledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fulfilledAt', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByIsVoid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoid', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByIsVoidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isVoid', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByPhoneNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phoneNumber', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByPhoneNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phoneNumber', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenBySellingPriceAtTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPriceAtTime', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy>
      thenBySellingPriceAtTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sellingPriceAtTime', Sort.desc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension CustomerOrderQueryWhereDistinct
    on QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> {
  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct>
      distinctByAddonAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'addonAmount');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByAddonCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'addonCost');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByAddonName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'addonName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByAddonPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'addonPrice');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct>
      distinctByAdvancePayment() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'advancePayment');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct>
      distinctByCostPriceAtTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'costPriceAtTime');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByCustomerName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueDate');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct>
      distinctByFulfilledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fulfilledAt');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByIsVoid() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isVoid');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct>
      distinctByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentMethod');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByPhoneNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phoneNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct>
      distinctBySellingPriceAtTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sellingPriceAtTime');
    });
  }

  QueryBuilder<CustomerOrder, CustomerOrder, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }
}

extension CustomerOrderQueryProperty
    on QueryBuilder<CustomerOrder, CustomerOrder, QQueryProperty> {
  QueryBuilder<CustomerOrder, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CustomerOrder, double?, QQueryOperations> addonAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addonAmount');
    });
  }

  QueryBuilder<CustomerOrder, double?, QQueryOperations> addonCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addonCost');
    });
  }

  QueryBuilder<CustomerOrder, String?, QQueryOperations> addonNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addonName');
    });
  }

  QueryBuilder<CustomerOrder, double?, QQueryOperations> addonPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addonPrice');
    });
  }

  QueryBuilder<CustomerOrder, double, QQueryOperations>
      advancePaymentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'advancePayment');
    });
  }

  QueryBuilder<CustomerOrder, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<CustomerOrder, double, QQueryOperations>
      costPriceAtTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'costPriceAtTime');
    });
  }

  QueryBuilder<CustomerOrder, String, QQueryOperations> customerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerName');
    });
  }

  QueryBuilder<CustomerOrder, DateTime, QQueryOperations> dueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueDate');
    });
  }

  QueryBuilder<CustomerOrder, DateTime?, QQueryOperations>
      fulfilledAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fulfilledAt');
    });
  }

  QueryBuilder<CustomerOrder, bool, QQueryOperations> isVoidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isVoid');
    });
  }

  QueryBuilder<CustomerOrder, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<CustomerOrder, PaymentMethod, QQueryOperations>
      paymentMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentMethod');
    });
  }

  QueryBuilder<CustomerOrder, String?, QQueryOperations> phoneNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phoneNumber');
    });
  }

  QueryBuilder<CustomerOrder, int, QQueryOperations> productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<CustomerOrder, double, QQueryOperations>
      sellingPriceAtTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sellingPriceAtTime');
    });
  }

  QueryBuilder<CustomerOrder, OrderStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}
