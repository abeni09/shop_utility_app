import 'package:isar/isar.dart';

part 'product_model.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  late double costPrice;
  late double sellingPrice;

  int? supplierId;

  DateTime? lastUpdated;

  bool isVoid = false;

  int minStockThreshold = 5;

  int shelfLifeDays = 30;
}
