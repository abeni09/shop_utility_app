import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shopsync/features/dashboard/data/daily_log_model.dart';
import 'package:shopsync/features/dashboard/data/dashboard_repository.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/data/stock_adjustment_model.dart';
import 'package:shopsync/features/orders/data/addon_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_settlement_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';
import 'package:shopsync/features/expenses/data/expense_model.dart';
import 'package:shopsync/features/expenses/data/expense_repository.dart';

void main() {
  late Isar isar;
  late DashboardRepository dashboardRepo;
  late ExpenseRepository expenseRepo;
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isar_test');
    isar = await Isar.open(
      [
        ProductSchema,
        SupplierSchema,
        CustomerOrderSchema,
        DailyLogSchema,
        DailyStockSchema,
        StockAdjustmentSchema,
        AddonSchema,
        SupplierSettlementSchema,
        ExpenseSchema,
      ],
      directory: tempDir.path,
    );
    dashboardRepo = DashboardRepository(isar);
    expenseRepo = ExpenseRepository(isar, dashboardRepo);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await tempDir.delete(recursive: true);
  });

  test('Recalculate stats handles sales and expenses correctly', () async {
    final date = DateTime(2026, 6, 18);

    // 1. Create a product
    final product = Product()
      ..name = 'Test Product'
      ..costPrice = 100
      ..sellingPrice = 150;
    await isar.writeTxn(() => isar.products.put(product));

    // 2. Create an expense active on this date
    final expense = Expense()
      ..description = 'Rent'
      ..amount = 30
      ..date = date
      ..recurrence = ExpenseRecurrence.none;
    await expenseRepo.saveExpense(expense);

    // 3. Create a normal order
    final order1 = CustomerOrder()
      ..productId = product.id
      ..customerName = 'Test Customer 1'
      ..amount = 2
      ..dueDate = date
      ..status = OrderStatus.sold
      ..paymentMethod = PaymentMethod.cash
      ..costPriceAtTime = product.costPrice
      ..sellingPriceAtTime = product.sellingPrice
      ..advancePayment = 300
      ..fulfilledAt = date;
    await isar.writeTxn(() => isar.customerOrders.put(order1));

    // Recalculate stats
    await dashboardRepo.recalculateDailyStats(date);

    // Check stats
    var log = await isar.dailyLogs.filter().dateEqualTo(date).findFirst();
    expect(log, isNotNull);
    expect(log!.totalSales, 300); // 2 * 150
    expect(log.totalProfit, 70); // (300 - 200) - 30 rent

    // 4. Record a break-even sale
    final order2 = CustomerOrder()
      ..productId = product.id
      ..customerName = 'Test Customer 2'
      ..amount = 1
      ..dueDate = date
      ..status = OrderStatus.sold
      ..paymentMethod = PaymentMethod.cash
      ..costPriceAtTime = product.costPrice
      ..sellingPriceAtTime = product.costPrice // Break-even: sell price = cost price
      ..advancePayment = 100
      ..fulfilledAt = date;
    await isar.writeTxn(() => isar.customerOrders.put(order2));

    await dashboardRepo.recalculateDailyStats(date);

    log = await isar.dailyLogs.filter().dateEqualTo(date).findFirst();
    expect(log!.totalSales, 400); // 300 + 100
    expect(log.totalProfit, 70); // profit stays 70 since break-even sale has 0 profit
  });
}
