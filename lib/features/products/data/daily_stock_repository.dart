import 'package:isar/isar.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';
import 'package:shopsync/features/products/data/daily_stock_model.dart';

class DailyStockRepository {
  final Isar isar;
  final BackupService backupService;

  DailyStockRepository(this.isar, this.backupService);

  Stream<List<DailyStock>> watchDailyStock(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return isar.dailyStocks
        .filter()
        .dateBetween(start, end)
        .watch(fireImmediately: true);
  }

  Future<void> saveDailyStock(DailyStock stock) async {
    await isar.writeTxn(() async {
      await isar.dailyStocks.put(stock);
    });
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Future<DailyStock?> getStockForProduct(int productId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return await isar.dailyStocks
        .filter()
        .productIdEqualTo(productId)
        .and()
        .dateBetween(start, end)
        .findFirst();
  }

  Future<void> resetProductHistory(int productId) async {
    await isar.writeTxn(() async {
      await isar.dailyStocks.filter().productIdEqualTo(productId).deleteAll();
    });
    await backupService.markLocalChanged();
  }
}
