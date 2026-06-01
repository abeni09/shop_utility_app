import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/orders/data/order_repository.dart';
import 'package:isar/isar.dart';
import 'package:shopsync/features/orders/data/addon_model.dart';
import 'package:shopsync/features/orders/data/addon_repository.dart';
import 'package:shopsync/main.dart';

import 'package:shopsync/features/dashboard/presentation/dashboard_providers.dart';
import 'package:shopsync/features/suppliers/presentation/supplier_list_screen.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final dashboardRepo = ref.watch(dashboardRepositoryProvider);
  final backupService = ref.watch(backupServiceProvider);
  final supplierRepo = ref.watch(supplierRepositoryProvider);
  return OrderRepository(
    dbService.isar,
    dashboardRepo,
    backupService,
    supplierRepo,
  );
});

final addonRepositoryProvider = Provider<AddonRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final backupService = ref.watch(backupServiceProvider);
  return AddonRepository(dbService.isar, backupService);
});

final addonsProvider = StreamProvider<List<Addon>>((ref) {
  final repository = ref.watch(addonRepositoryProvider);
  return repository.watchAddons();
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final ordersProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final date = ref.watch(selectedDateProvider);
  final showVoided = ref.watch(showVoidedOrdersProvider);
  final repository = ref.watch(orderRepositoryProvider);
  return repository.watchOrdersForDate(date, includeVoided: showVoided);
});

final ordersForDateProvider =
    StreamProvider.family<
      List<CustomerOrder>,
      ({DateTime date, bool includeVoided})
    >((ref, arg) {
      final repository = ref.watch(orderRepositoryProvider);
      return repository.watchOrdersForDate(
        arg.date,
        includeVoided: arg.includeVoided,
      );
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

final outstandingCreditOrdersProvider = StreamProvider<List<CustomerOrder>>((
  ref,
) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.isar.customerOrders
      .filter()
      .paymentMethodEqualTo(PaymentMethod.credit)
      .statusEqualTo(OrderStatus.sold)
      .isVoidEqualTo(false)
      .watch(fireImmediately: true);
});
