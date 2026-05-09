import 'package:isar/isar.dart';
import 'package:shopsync/features/suppliers/data/supplier_model.dart';

class SupplierRepository {
  final Isar isar;

  SupplierRepository(this.isar);

  Future<List<Supplier>> getAllSuppliers() async {
    return await isar.suppliers.where().findAll();
  }

  Future<void> saveSupplier(Supplier supplier) async {
    await isar.writeTxn(() async {
      await isar.suppliers.put(supplier);
    });
  }

  Future<void> updateBalance(Id id, double delta) async {
    await isar.writeTxn(() async {
      final supplier = await isar.suppliers.get(id);
      if (supplier != null) {
        supplier.balance += delta;
        await isar.suppliers.put(supplier);
      }
    });
  }

  Stream<List<Supplier>> watchSuppliers() {
    return isar.suppliers.where().watch(fireImmediately: true);
  }
}
