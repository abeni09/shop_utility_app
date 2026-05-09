import 'package:isar/isar.dart';
import 'package:shopsync/features/products/data/product_model.dart';

class ProductRepository {
  final Isar isar;

  ProductRepository(this.isar);

  Future<List<Product>> getAllProducts() async {
    return await isar.products.where().findAll();
  }

  Future<void> saveProduct(Product product) async {
    await isar.writeTxn(() async {
      await isar.products.put(product);
    });
  }

  Future<void> deleteProduct(Id id) async {
    await isar.writeTxn(() async {
      await isar.products.delete(id);
    });
  }

  Stream<List<Product>> watchProducts() {
    return isar.products.where().watch(fireImmediately: true);
  }
}
