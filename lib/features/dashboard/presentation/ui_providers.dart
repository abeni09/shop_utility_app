import 'package:flutter_riverpod/flutter_riverpod.dart';

final showArchivedSuppliersProvider = StateProvider<bool>((ref) => false);
final showVoidedProductsProvider = StateProvider<bool>((ref) => false);
final showVoidedOrdersProvider = StateProvider<bool>((ref) => false);

enum OrderFilter { active, completed, all }
final orderFilterProvider = StateProvider<OrderFilter>((ref) => OrderFilter.active);
