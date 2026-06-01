import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/dashboard/data/daily_log_model.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';
import 'package:shopsync/features/products/data/stock_adjustment_model.dart';
import 'package:shopsync/features/orders/data/addon_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_settlement_model.dart';
import 'package:shopsync/features/expenses/data/expense_model.dart';

class DatabaseService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
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

      directory: dir.path,
      name: 'shopsync_db',
    );
  }

  // Helper to ensure database is initialized before use
  static Future<DatabaseService> create() async {
    final service = DatabaseService();
    await service.init();
    return service;
  }
}
