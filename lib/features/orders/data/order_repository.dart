import 'package:isar/isar.dart';
import 'customer_order_model.dart';
import 'package:shopsync/features/dashboard/data/dashboard_repository.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';
import 'package:shopsync/features/suppliers/data/supplier_repository.dart';
import 'package:shopsync/features/products/data/product_model.dart';

class OrderRepository {
  final Isar isar;
  final DashboardRepository dashboardRepo;
  final BackupService backupService;
  final SupplierRepository supplierRepo;

  OrderRepository(
    this.isar,
    this.dashboardRepo,
    this.backupService,
    this.supplierRepo,
  );

  Future<List<CustomerOrder>> getOrdersForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    print(
      'DEBUG: Fetching orders between ${startOfDay.toIso8601String()} and ${endOfDay.toIso8601String()}',
    );

    return await isar.customerOrders
        .filter()
        .dueDateBetween(startOfDay, endOfDay)
        .findAll();
  }

  Future<void> saveOrder(CustomerOrder order) async {
    print(
      'DEBUG: Saving order for ${order.customerName}, amount: ${order.amount}, status: ${order.status}',
    );

    CustomerOrder? oldOrder;
    if (order.id != 0 && order.id != Isar.autoIncrement) {
      oldOrder = await isar.customerOrders.get(order.id);
    }
    final oldStatus = oldOrder?.status;
    final oldIsVoid = oldOrder?.isVoid ?? false;
    final oldAddonCost = oldOrder?.addonCost;
    final oldAddonAmount = oldOrder?.addonAmount;

    await isar.writeTxn(() async {
      final id = await isar.customerOrders.put(order);
      print('DEBUG: Order saved with ID: $id');
    });

    double oldAddonTotal = 0.0;
    if (oldStatus == OrderStatus.sold && !oldIsVoid) {
      oldAddonTotal = (oldAddonAmount ?? 0.0) * (oldAddonCost ?? 0.0);
    }
    double newAddonTotal = 0.0;
    if (order.status == OrderStatus.sold && !order.isVoid) {
      newAddonTotal = (order.addonAmount ?? 0.0) * (order.addonCost ?? 0.0);
    }
    final delta = newAddonTotal - oldAddonTotal;
    if (delta != 0.0) {
      final product = await isar.products.get(order.productId);
      if (product != null && product.supplierId != null) {
        await supplierRepo.updateBalance(product.supplierId!, delta);
      }
    }

    if (order.status == OrderStatus.sold && !order.isVoid) {
      await dashboardRepo.recalculateDailyStats(order.dueDate);
    }

    // Auto-Sync trigger
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Future<void> updateOrderStatus(Id id, OrderStatus status) async {
    final oldOrder = await isar.customerOrders.get(id);
    if (oldOrder == null) return;

    final oldStatus = oldOrder.status;
    final oldIsVoid = oldOrder.isVoid;
    final oldAddonCost = oldOrder.addonCost;
    final oldAddonAmount = oldOrder.addonAmount;
    final oldProductId = oldOrder.productId;

    await isar.writeTxn(() async {
      final order = await isar.customerOrders.get(id);
      if (order != null) {
        order.status = status;
        order.fulfilledAt = status == OrderStatus.sold ? DateTime.now() : null;
        await isar.customerOrders.put(order);
      }
    });

    double oldAddonTotal = 0.0;
    if (oldStatus == OrderStatus.sold && !oldIsVoid) {
      oldAddonTotal = (oldAddonAmount ?? 0.0) * (oldAddonCost ?? 0.0);
    }
    double newAddonTotal = 0.0;
    if (status == OrderStatus.sold && !oldIsVoid) {
      newAddonTotal = (oldAddonAmount ?? 0.0) * (oldAddonCost ?? 0.0);
    }
    final delta = newAddonTotal - oldAddonTotal;
    if (delta != 0.0) {
      final product = await isar.products.get(oldProductId);
      if (product != null && product.supplierId != null) {
        await supplierRepo.updateBalance(product.supplierId!, delta);
      }
    }

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
    final oldOrder = await isar.customerOrders.get(id);
    if (oldOrder == null) return;

    final oldStatus = oldOrder.status;
    final oldIsVoid = oldOrder.isVoid;
    final oldAddonCost = oldOrder.addonCost;
    final oldAddonAmount = oldOrder.addonAmount;
    final oldProductId = oldOrder.productId;

    await isar.writeTxn(() async {
      final order = await isar.customerOrders.get(id);
      if (order != null) {
        order.isVoid = true;
        await isar.customerOrders.put(order);
      }
    });

    double oldAddonTotal = 0.0;
    if (oldStatus == OrderStatus.sold && !oldIsVoid) {
      oldAddonTotal = (oldAddonAmount ?? 0.0) * (oldAddonCost ?? 0.0);
    }
    double newAddonTotal = 0.0;
    final delta = newAddonTotal - oldAddonTotal;
    if (delta != 0.0) {
      final product = await isar.products.get(oldProductId);
      if (product != null && product.supplierId != null) {
        await supplierRepo.updateBalance(product.supplierId!, delta);
      }
    }

    final order = await isar.customerOrders.get(id);
    if (order != null) {
      await dashboardRepo.recalculateDailyStats(order.dueDate);
      await backupService.markLocalChanged();
      await backupService.autoBackupIfPossible();
    }
  }

  Future<void> unvoidOrder(Id id) async {
    final oldOrder = await isar.customerOrders.get(id);
    if (oldOrder == null) return;

    final oldStatus = oldOrder.status;
    final oldAddonCost = oldOrder.addonCost;
    final oldAddonAmount = oldOrder.addonAmount;
    final oldProductId = oldOrder.productId;

    await isar.writeTxn(() async {
      final order = await isar.customerOrders.get(id);
      if (order != null) {
        order.isVoid = false;
        await isar.customerOrders.put(order);
      }
    });

    double oldAddonTotal = 0.0;
    double newAddonTotal = 0.0;
    if (oldStatus == OrderStatus.sold) {
      newAddonTotal = (oldAddonAmount ?? 0.0) * (oldAddonCost ?? 0.0);
    }
    final delta = newAddonTotal - oldAddonTotal;
    if (delta != 0.0) {
      final product = await isar.products.get(oldProductId);
      if (product != null && product.supplierId != null) {
        await supplierRepo.updateBalance(product.supplierId!, delta);
      }
    }

    final order = await isar.customerOrders.get(id);
    if (order != null) {
      await dashboardRepo.recalculateDailyStats(order.dueDate);
      await backupService.markLocalChanged();
      await backupService.autoBackupIfPossible();
    }
  }

  Stream<List<CustomerOrder>> watchOrdersForDate(
    DateTime date, {
    bool includeVoided = false,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    var query = isar.customerOrders.filter().dueDateBetween(
      startOfDay,
      endOfDay,
    );

    if (!includeVoided) {
      query = query.and().isVoidEqualTo(false);
    }

    return query.watch(fireImmediately: true);
  }

  Future<void> resetProductHistory(int productId) async {
    await isar.writeTxn(() async {
      final orders = await isar.customerOrders
          .filter()
          .productIdEqualTo(productId)
          .findAll();
      for (var order in orders) {
        order.isVoid = true;
        await isar.customerOrders.put(order);
      }
    });
    await backupService.markLocalChanged();
  }

  Future<List<CustomerOrder>> getAllOrdersInRange(
    DateTime from,
    DateTime to,
  ) async {
    return await isar.customerOrders
        .filter()
        .dueDateBetween(from, to)
        .isVoidEqualTo(false)
        .findAll();
  }
}
