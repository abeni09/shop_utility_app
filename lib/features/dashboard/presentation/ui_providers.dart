import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

final showArchivedSuppliersProvider = StateProvider<bool>((ref) => false);
final showVoidedProductsProvider = StateProvider<bool>((ref) => false);
final showVoidedOrdersProvider = StateProvider<bool>((ref) => false);

enum OrderFilter { active, completed, all }

final orderFilterProvider =
    StateProvider<OrderFilter>((ref) => OrderFilter.active);

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
