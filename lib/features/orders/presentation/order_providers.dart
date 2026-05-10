import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/data/order_repository.dart';
import 'package:shopsync/main.dart';

import 'package:shopsync/features/dashboard/presentation/dashboard_providers.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final dashboardRepo = ref.watch(dashboardRepositoryProvider);
  final backupService = ref.watch(backupServiceProvider);
  return OrderRepository(dbService.isar, dashboardRepo, backupService);
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final ordersProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final date = ref.watch(selectedDateProvider);
  final showVoided = ref.watch(showVoidedOrdersProvider);
  return ref.watch(ordersForDateProvider((date: date, includeVoided: showVoided)).stream);
});

final ordersForDateProvider = StreamProvider.family<List<CustomerOrder>, ({DateTime date, bool includeVoided})>((ref, arg) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.watchOrdersForDate(arg.date, includeVoided: arg.includeVoided);
});

final filteredOrdersProvider = Provider<List<CustomerOrder>>((ref) {
  final orders = ref.watch(ordersProvider).value ?? [];
  final filter = ref.watch(orderFilterProvider);

  switch (filter) {
    case OrderFilter.active:
      return orders.where((o) => o.status == OrderStatus.pending).toList();
    case OrderFilter.completed:
      return orders.where((o) => o.status == OrderStatus.sold).toList();
    case OrderFilter.all:
      return orders;
  }
});
