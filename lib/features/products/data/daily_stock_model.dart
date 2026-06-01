import 'package:isar/isar.dart';

part 'daily_stock_model.g.dart';

@collection
class DailyStock {
  Id id = Isar.autoIncrement;

  int productId = 0;

  @Index()
  DateTime date = DateTime.now();

  double requestedQuantity = 0.0;
  double receivedQuantity = 0.0;

  // Optional: track who delivered it if multiple suppliers
  int? supplierId;
}
