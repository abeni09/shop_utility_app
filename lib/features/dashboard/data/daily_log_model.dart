import 'package:isar/isar.dart';

part 'daily_log_model.g.dart';

@collection
class DailyLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late DateTime date;

  double totalSales = 0.0;
  double totalProfit = 0.0;
  double totalSupplierOrders = 0.0;
}
