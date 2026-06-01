import 'package:isar/isar.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';

class ProductRepository {
  final Isar isar;
  final BackupService backupService;

  ProductRepository(this.isar, this.backupService);

  Future<List<Product>> getAllProducts() async {
    return await isar.products.where().findAll();
  }

  Future<void> saveProduct(Product product) async {
    await isar.writeTxn(() async {
      await isar.products.put(product);
    });

    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Future<void> voidProduct(Id id) async {
    await isar.writeTxn(() async {
      final product = await isar.products.get(id);
      if (product != null) {
        product.isVoid = true;
        await isar.products.put(product);
      }
    });

    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Future<void> unvoidProduct(Id id) async {
    await isar.writeTxn(() async {
      final product = await isar.products.get(id);
      if (product != null) {
        product.isVoid = false;
        await isar.products.put(product);
      }
    });

    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Stream<List<Product>> watchProducts({bool includeVoided = false}) {
    if (includeVoided) {
      return isar.products.where().watch(fireImmediately: true);
    }
    return isar.products
        .filter()
        .isVoidEqualTo(false)
        .watch(fireImmediately: true);
  }
}
