import 'package:isar/isar.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';
import 'package:shopsync/features/products/data/stock_adjustment_model.dart';

class StockAdjustmentRepository {
  final Isar isar;
  final BackupService backupService;

  StockAdjustmentRepository(this.isar, this.backupService);

  Stream<List<StockAdjustment>> watchAdjustments() {
    return isar.stockAdjustments.where().sortByDateDesc().watch(fireImmediately: true);
  }

  Future<void> saveAdjustment(StockAdjustment adjustment) async {
    adjustment.lastUpdated = DateTime.now();
    await isar.writeTxn(() async {
      await isar.stockAdjustments.put(adjustment);
    });
    await backupService.forceSyncCheck();
  }

  Future<void> deleteAdjustment(Id id) async {
    await isar.writeTxn(() async {
      await isar.stockAdjustments.delete(id);
    });
    await backupService.forceSyncCheck();
  }
}
