import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/data/order_repository.dart';
import 'package:shopsync/main.dart';

import 'package:shopsync/features/dashboard/presentation/dashboard_providers.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final dashboardRepo = ref.watch(dashboardRepositoryProvider);
  return OrderRepository(dbService.isar, dashboardRepo);
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final ordersProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repository.watchOrdersForDate(date);
});
