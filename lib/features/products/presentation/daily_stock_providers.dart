import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';
import 'package:shopsync/features/products/data/daily_stock_repository.dart';
import 'package:shopsync/features/orders/presentation/order_providers.dart';
import 'package:shopsync/features/orders/data/customer_order_model.dart';
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

final walkInAvailabilityProvider =
    Provider.family<AsyncValue<Map<int, double>>, DateTime>((ref, date) {
      final stocksAsync = ref.watch(dailyStockProvider(date));
      final ordersAsync = ref.watch(ordersProvider);

      return stocksAsync.whenData((stocks) {
        return ordersAsync.maybeWhen(
          data: (orders) {
            final Map<int, double> availability = {};

            for (var stock in stocks) {
              final orderedQty = orders
                  .where((o) => o.productId == stock.productId && !o.isVoid)
                  .fold(0.0, (sum, o) => sum + o.amount);

              availability[stock.productId] =
                  stock.receivedQuantity - orderedQty;
            }

            return availability;
          },
          orElse: () => <int, double>{},
        );
      });
    });
