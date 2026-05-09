import 'package:isar/isar.dart';
import 'package:isar/isar.dart';
import 'customer_order_model.dart';
import 'package:shopsync/features/dashboard/data/dashboard_repository.dart';

import 'package:shopsync/features/orders/data/customer_order_model.dart';

class OrderRepository {
  final Isar isar;
  final DashboardRepository dashboardRepo;

  OrderRepository(this.isar, this.dashboardRepo);

  Future<List<CustomerOrder>> getOrdersForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await isar.customerOrders
        .filter()
        .dueDateGreaterThan(
          startOfDay.subtract(const Duration(milliseconds: 1)),
        )
        .and()
        .dueDateLessThan(endOfDay)
        .findAll();
  }

  Future<void> saveOrder(CustomerOrder order) async {
    await isar.writeTxn(() async {
      await isar.customerOrders.put(order);
    });
  }

  Future<void> updateOrderStatus(Id id, OrderStatus status) async {
    await isar.writeTxn(() async {
      final order = await isar.customerOrders.get(id);
      if (order != null) {
        order.status = status;
        order.fulfilledAt = status == OrderStatus.sold ? DateTime.now() : null;
        await isar.customerOrders.put(order);
      }
    });
    // Trigger dashboard recalculation
    final order = await isar.customerOrders.get(id);
    if (order != null) {
      await dashboardRepo.recalculateDailyStats(order.dueDate);
    }
  }

  Stream<List<CustomerOrder>> watchOrdersForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return isar.customerOrders
        .filter()
        .dueDateGreaterThan(
          startOfDay.subtract(const Duration(milliseconds: 1)),
        )
        .and()
        .dueDateLessThan(endOfDay)
        .watch(fireImmediately: true);
  }
}
