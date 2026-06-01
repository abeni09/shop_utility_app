import 'package:isar/isar.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';
import 'package:shopsync/features/suppliers/data/supplier_settlement_model.dart';
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

  Future<void> toggleActiveStatus(Id id) async {
    await isar.writeTxn(() async {
      final supplier = await isar.suppliers.get(id);
      if (supplier != null) {
        supplier.isActive = !supplier.isActive;
        await isar.suppliers.put(supplier);
      }
    });
    
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Future<void> voidSupplier(Id id) async {
    await isar.writeTxn(() async {
      final supplier = await isar.suppliers.get(id);
      if (supplier != null) {
        supplier.isVoid = true;
        supplier.isActive = false;
        await isar.suppliers.put(supplier);
      }
    });
    
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Future<void> unvoidSupplier(Id id) async {
    await isar.writeTxn(() async {
      final supplier = await isar.suppliers.get(id);
      if (supplier != null) {
        supplier.isVoid = false;
        supplier.isActive = true;
        await isar.suppliers.put(supplier);
      }
    });
    
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Stream<List<Supplier>> watchSuppliers({bool includeVoided = false}) {
    if (includeVoided) {
      return isar.suppliers.where().watch(fireImmediately: true);
    }
    return isar.suppliers.filter().isVoidEqualTo(false).watch(fireImmediately: true);
  }

  Future<void> recordSettlement(SupplierSettlement settlement) async {
    await isar.writeTxn(() async {
      await isar.supplierSettlements.put(settlement);
    });
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Stream<List<SupplierSettlement>> watchSettlements(int supplierId) {
    return isar.supplierSettlements
        .filter()
        .supplierIdEqualTo(supplierId)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  Future<List<SupplierSettlement>> getSettlementsInRange(
      DateTime from, DateTime to) async {
    return await isar.supplierSettlements
        .filter()
        .dateBetween(from, to)
        .findAll();
  }
}

