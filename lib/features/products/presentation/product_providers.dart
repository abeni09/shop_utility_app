import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/products/data/product_model.dart';
import 'package:shopsync/features/products/data/product_repository.dart';
import 'package:shopsync/main.dart';

import 'package:shopsync/features/dashboard/presentation/ui_providers.dart';

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
