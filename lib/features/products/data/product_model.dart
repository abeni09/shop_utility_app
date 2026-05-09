import 'package:isar/isar.dart';

part 'product_model.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  late String unit; // e.g., "piece", "kg", "packet"

  late double costPrice;
  late double sellingPrice;

  int? supplierId;

  DateTime? lastUpdated;
}
