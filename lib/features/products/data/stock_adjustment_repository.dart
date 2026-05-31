import 'package:isar/isar.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';
import 'package:shopsync/features/products/data/stock_adjustment_model.dart';
import 'package:shopsync/features/dashboard/data/dashboard_repository.dart';

class StockAdjustmentRepository {
  final Isar isar;
  final BackupService backupService;
  final DashboardRepository dashboardRepo;

  StockAdjustmentRepository(this.isar, this.backupService, this.dashboardRepo);

  Stream<List<StockAdjustment>> watchAdjustments() {
    return isar.stockAdjustments.where().sortByDateDesc().watch(fireImmediately: true);
  }

  Future<void> saveAdjustment(StockAdjustment adjustment) async {
    adjustment.lastUpdated = DateTime.now();
    await isar.writeTxn(() async {
      await isar.stockAdjustments.put(adjustment);
    });
    await dashboardRepo.recalculateDailyStats(adjustment.date);
    await backupService.forceSyncCheck();
  }

  Future<void> deleteAdjustment(Id id) async {
    final adj = await isar.stockAdjustments.get(id);
    final date = adj?.date;
    await isar.writeTxn(() async {
      await isar.stockAdjustments.delete(id);
    });
    if (date != null) {
      await dashboardRepo.recalculateDailyStats(date);
    }
    await backupService.forceSyncCheck();
  }
}

