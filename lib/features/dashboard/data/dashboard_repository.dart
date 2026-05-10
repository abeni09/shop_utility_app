import 'package:isar/isar.dart';
import 'package:shopsync/features/dashboard/data/daily_log_model.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';
import 'package:shopsync/features/products/data/product_model.dart';

class DashboardRepository {
  final Isar isar;

  DashboardRepository(this.isar);

  Future<DailyLog> getOrCreateDailyLog(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    var log = await isar.dailyLogs.filter().dateEqualTo(startOfDay).findFirst();

    if (log == null) {
      log = DailyLog()..date = startOfDay;
      await isar.writeTxn(() async {
        await isar.dailyLogs.put(log!);
      });
    }
    return log;
  }

  Future<void> recalculateDailyStats(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final orders = await isar.customerOrders
        .filter()
        .dueDateGreaterThan(
          startOfDay.subtract(const Duration(milliseconds: 1)),
        )
        .and()
        .dueDateLessThan(endOfDay)
        .statusEqualTo(OrderStatus.sold)
        .and()
        .isVoidEqualTo(false)
        .findAll();

    double totalSales = 0;
    double totalProfit = 0;

    for (var order in orders) {
      final revenue = order.amount * order.sellingPriceAtTime;
      final cost = order.amount * order.costPriceAtTime;
      totalSales += revenue;
      totalProfit += (revenue - cost);
    }

    final log = await getOrCreateDailyLog(date);
    log.totalSales = totalSales;
    log.totalProfit = totalProfit;

    await isar.writeTxn(() async {
      await isar.dailyLogs.put(log);
    });
  }

  Future<void> recalculateSupplierOrders(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get all stocks for the day
    final stocks = await isar.dailyStocks
        .filter()
        .dateBetween(startOfDay, endOfDay)
        .findAll();

    double totalCost = 0;
    for (var stock in stocks) {
      final product = await isar.products.get(stock.productId);
      if (product != null) {
        totalCost += stock.receivedQuantity * product.costPrice;
      }
    }

    final log = await getOrCreateDailyLog(date);
    log.totalSupplierOrders = totalCost;

    await isar.writeTxn(() async {
      await isar.dailyLogs.put(log);
    });
  }

  Stream<DailyLog?> watchDailyLog(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    return isar.dailyLogs
        .filter()
        .dateEqualTo(startOfDay)
        .watch(fireImmediately: true)
        .map((list) => list.isEmpty ? null : list.first);
  }

  Future<Map<String, double>> getProfitForRange(
    DateTime start,
    DateTime end,
  ) async {
    final logs = await isar.dailyLogs
        .filter()
        .dateGreaterThan(start.subtract(const Duration(milliseconds: 1)))
        .and()
        .dateLessThan(end.add(const Duration(days: 1)))
        .findAll();

    double totalSales = 0;
    double totalProfit = 0;

    for (var log in logs) {
      totalSales += log.totalSales;
      totalProfit += log.totalProfit;
    }

    return {'sales': totalSales, 'profit': totalProfit};
  }
}
