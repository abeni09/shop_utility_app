import 'package:isar/isar.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';
import 'package:shopsync/features/products/data/holiday_model.dart';

class HolidayRepository {
  final Isar isar;
  final BackupService backupService;

  HolidayRepository(this.isar, this.backupService);

  Future<List<Holiday>> getAllHolidays() async {
    return await isar.holidays.where().sortByDate().findAll();
  }

  Future<void> saveHoliday(Holiday holiday) async {
    // Normalize date to midnight in local time
    holiday.date = DateTime(holiday.date.year, holiday.date.month, holiday.date.day);
    await isar.writeTxn(() async {
      await isar.holidays.put(holiday);
    });
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Future<void> deleteHoliday(Id id) async {
    await isar.writeTxn(() async {
      await isar.holidays.delete(id);
    });
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Future<bool> isHoliday(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final count = await isar.holidays.filter().dateEqualTo(start).count();
    return count > 0;
  }

  Stream<List<Holiday>> watchHolidays() {
    return isar.holidays.where().sortByDate().watch(fireImmediately: true);
  }
}
