import 'package:isar/isar.dart';
import 'customer_order_model.dart';
import 'package:shopsync/features/dashboard/data/dashboard_repository.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';

class OrderRepository {
  final Isar isar;
  final DashboardRepository dashboardRepo;
  final BackupService backupService;

  OrderRepository(this.isar, this.dashboardRepo, this.backupService);

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
    print('DEBUG: Saving order for ${order.customerName}, amount: ${order.amount}, status: ${order.status}');
    await isar.writeTxn(() async {
      final id = await isar.customerOrders.put(order);
      print('DEBUG: Order saved with ID: $id');
    });
    
    // Auto-Sync trigger
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
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
      
      // Auto-Sync trigger
      await backupService.markLocalChanged();
      backupService.autoBackupIfPossible();
    }
  }

  Future<void> voidOrder(Id id) async {
    await isar.writeTxn(() async {
      final order = await isar.customerOrders.get(id);
      if (order != null) {
        order.isVoid = true;
        await isar.customerOrders.put(order);
      }
    });

    final order = await isar.customerOrders.get(id);
    if (order != null) {
      await dashboardRepo.recalculateDailyStats(order.dueDate);
      await backupService.markLocalChanged();
      backupService.autoBackupIfPossible();
    }
  }

  Future<void> unvoidOrder(Id id) async {
    await isar.writeTxn(() async {
      final order = await isar.customerOrders.get(id);
      if (order != null) {
        order.isVoid = false;
        await isar.customerOrders.put(order);
      }
    });

    final order = await isar.customerOrders.get(id);
    if (order != null) {
      await dashboardRepo.recalculateDailyStats(order.dueDate);
      await backupService.markLocalChanged();
      backupService.autoBackupIfPossible();
    }
  }

  Stream<List<CustomerOrder>> watchOrdersForDate(
    DateTime date, {
    bool includeVoided = false,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    var query = isar.customerOrders.filter().dueDateGreaterThan(
          startOfDay.subtract(const Duration(milliseconds: 1)),
        ).and().dueDateLessThan(endOfDay);

    if (!includeVoided) {
      query = query.and().isVoidEqualTo(false);
    }

    return query.watch(fireImmediately: true);
  }
}
