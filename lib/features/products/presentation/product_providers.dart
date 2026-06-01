import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/data/product_repository.dart';
import 'package:shopsync/main.dart';

import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';

enum ProductSortType { nameAsc, nameDesc, priceAsc, priceDesc, oldest, newest }

final productSortTypeProvider = StateProvider<ProductSortType>(
  (ref) => ProductSortType.newest,
);

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final backupService = ref.watch(backupServiceProvider);
  return ProductRepository(dbService.isar, backupService);
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  final showVoided = ref.watch(showVoidedProductsProvider);
  return repository.watchProducts(includeVoided: showVoided);
});

final sortedProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final sortType = ref.watch(productSortTypeProvider);

  return productsAsync.whenData((products) {
    final sorted = List<Product>.from(products);
    switch (sortType) {
      case ProductSortType.nameAsc:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case ProductSortType.nameDesc:
        sorted.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case ProductSortType.priceAsc:
        sorted.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case ProductSortType.priceDesc:
        sorted.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
      case ProductSortType.oldest:
        sorted.sort((a, b) => a.id.compareTo(b.id));
        break;
      case ProductSortType.newest:
        sorted.sort((a, b) => b.id.compareTo(a.id));
        break;
    }
    return sorted;
  });
});
