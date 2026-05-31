import 'package:isar/isar.dart';

part 'supplier_settlement_model.g.dart';

@collection
class SupplierSettlement {
  Id id = Isar.autoIncrement;

  late int supplierId;
  late double amount;
  late DateTime date;
  String? imagePath;
}
