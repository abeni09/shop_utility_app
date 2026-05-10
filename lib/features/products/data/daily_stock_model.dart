import 'package:isar/isar.dart';

part 'daily_stock_model.g.dart';

@collection
class DailyStock {
  Id id = Isar.autoIncrement;

  late int productId;
  
  @Index()
  late DateTime date;

  late double receivedQuantity;
  
  // Optional: track who delivered it if multiple suppliers
  int? supplierId;
}
