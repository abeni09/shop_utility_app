import 'package:isar/isar.dart';

part 'supplier_model.g.dart';

@collection
class Supplier {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? contact;
  String? account;

  // The balance represents what the shop owes the supplier.
  // Positive = we owe them. Negative = we pre-paid.
  double balance = 0.0;

  DateTime? lastUpdated;

  bool isActive = true;
  bool isVoid = false;

  int paymentTermsDays = 30;
}
