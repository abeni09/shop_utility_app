import 'package:isar/isar.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';

class SupplierRepository {
  final Isar isar;
  final BackupService backupService;

  SupplierRepository(this.isar, this.backupService);

  Future<List<Supplier>> getAllSuppliers() async {
    return await isar.suppliers.where().findAll();
  }

  Future<void> saveSupplier(Supplier supplier) async {
    await isar.writeTxn(() async {
      await isar.suppliers.put(supplier);
    });
    
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Future<void> updateBalance(Id id, double delta) async {
    await isar.writeTxn(() async {
      final supplier = await isar.suppliers.get(id);
      if (supplier != null) {
        supplier.balance += delta;
        await isar.suppliers.put(supplier);
      }
    });
    
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Stream<List<Supplier>> watchSuppliers() {
    return isar.suppliers.where().watch(fireImmediately: true);
  }
}
