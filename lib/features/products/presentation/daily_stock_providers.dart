import 'package:flutter_riverpod/flutter_riverpod.dart';
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

typedef StockStatus = ({
  double walkInAvailable,
  double physicalRemaining,
  double reserved
});

final walkInAvailabilityProvider =
    Provider.family<AsyncValue<Map<int, StockStatus>>, DateTime>((ref, date) {
  final productsAsync = ref.watch(productsProvider);
  final stocksAsync = ref.watch(dailyStockProvider(date));
  final ordersAsync =
      ref.watch(ordersForDateProvider((date: date, includeVoided: false)));

  return productsAsync.when(
    data: (products) => stocksAsync.when(
      data: (stocks) => ordersAsync.when(
        data: (orders) {
          final Map<int, StockStatus> availability = {};

          for (var p in products) {
            if (p.isVoid) continue;

            final received = stocks
                .where((s) => s.productId == p.id)
                .fold(0.0, (sum, s) => sum + s.receivedQuantity);

            final sold = orders
                .where((o) =>
                    o.productId == p.id &&
                    !o.isVoid &&
                    o.status == OrderStatus.sold)
                .fold(0.0, (sum, o) => sum + o.amount);

            final pending = orders
                .where((o) =>
                    o.productId == p.id &&
                    !o.isVoid &&
                    o.status == OrderStatus.pending)
                .fold(0.0, (sum, o) => sum + o.amount);

            availability[p.id] = (
              walkInAvailable: received - (sold + pending),
              physicalRemaining: received - sold,
              reserved: pending,
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
