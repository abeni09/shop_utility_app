import 'package:isar/isar.dart';

part 'stock_adjustment_model.g.dart';

@collection
class StockAdjustment {
  Id id = Isar.autoIncrement;

  late int productId;
  late DateTime date;
  late double amount; // Positive = gain, negative = loss (damage/consumption)
  late String reason; // e.g., "damage", "self-consumption", "correction"

  DateTime? lastUpdated;
}
