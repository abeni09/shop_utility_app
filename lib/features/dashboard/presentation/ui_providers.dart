import 'package:flutter_riverpod/flutter_riverpod.dart';

final showArchivedSuppliersProvider = StateProvider<bool>((ref) => false);
final showVoidedProductsProvider = StateProvider<bool>((ref) => false);
final showVoidedOrdersProvider = StateProvider<bool>((ref) => false);
