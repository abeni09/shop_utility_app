import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';
import 'package:shopsync/features/products/data/daily_stock_repository.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
import 'package:shopsync/features/products/presentation/product_providers.dart';
import 'package:shopsync/main.dart';

final dailyStockRepositoryProvider = Provider<DailyStockRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final backupService = ref.watch(backupServiceProvider);
  return DailyStockRepository(dbService.isar, backupService);
});

final dailyStockProvider = StreamProvider.family<List<DailyStock>, DateTime>((
  ref,
  date,
) {
  final repository = ref.watch(dailyStockRepositoryProvider);
  return repository.watchDailyStock(date);
});

final allDailyStockProvider = StreamProvider<List<DailyStock>>((ref) {
  final repository = ref.watch(dailyStockRepositoryProvider);
  // Watch everything to handle carryover
  return repository.isar.dailyStocks.where().watch(fireImmediately: true);
});

final allOrdersProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  // Watch all non-voided orders for global reservation awareness
  return repository.isar.customerOrders
      .filter()
      .isVoidEqualTo(false)
      .watch(fireImmediately: true);
});

typedef StockStatus = ({
  double walkInAvailable,
  double physicalRemaining,
  double reserved,
  double totalReceived,
  double totalSold,
});

final walkInAvailabilityProvider =
    Provider.family<AsyncValue<Map<int, StockStatus>>, DateTime>((ref, date) {
  final productsAsync = ref.watch(productsProvider);
  final allStocksAsync = ref.watch(allDailyStockProvider);
  final allOrdersAsync = ref.watch(allOrdersProvider);

  // Normalize the selected date to local midnight
  final localDate = DateTime(date.year, date.month, date.day);
  final calculationDate =
      localDate.add(const Duration(hours: 23, minutes: 59, seconds: 59));

  return productsAsync.when(
    data: (products) => allStocksAsync.when(
      data: (allStocks) => allOrdersAsync.when(
        data: (allOrders) {
          final Map<int, StockStatus> availability = {};

          for (var p in products) {
            if (p.isVoid) continue;

            // 1. Total received up to the selected date
            final receivedUntilDate = allStocks
                .where(
                  (s) =>
                      s.productId == p.id &&
                      s.date.isBefore(
                        calculationDate.add(const Duration(seconds: 1)),
                      ),
                )
                .fold(0.0, (sum, s) => sum + s.receivedQuantity);

            // 2. Total sold up to the selected date (use fulfillment date if sold)
            final soldUntilDate = allOrders
                .where(
                  (o) =>
                      o.productId == p.id &&
                      o.status == OrderStatus.sold &&
                      (o.fulfilledAt ?? o.dueDate).isBefore(
                        calculationDate.add(const Duration(seconds: 1)),
                      ),
                )
                .fold(0.0, (sum, o) => sum + o.amount);

            // 3. Pending orders up to Today (Reservations)
            final totalPending = allOrders
                .where(
                  (o) =>
                      o.productId == p.id &&
                      o.status == OrderStatus.pending &&
                      o.dueDate.isBefore(
                        calculationDate.add(const Duration(seconds: 1)),
                      ),
                )
                .fold(0.0, (sum, o) => sum + o.amount);

            final physicalRemaining = receivedUntilDate - soldUntilDate;

            availability[p.id] = (
              walkInAvailable: (physicalRemaining - totalPending).clamp(
                0,
                double.infinity,
              ),
              physicalRemaining: physicalRemaining.clamp(
                0,
                double.infinity,
              ),
              reserved: totalPending,
              totalReceived: receivedUntilDate,
              totalSold: soldUntilDate,
            );
          }

          return AsyncValue.data(availability);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      ),
      loading: () => const AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
