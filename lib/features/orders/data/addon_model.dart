import 'package:isar/isar.dart';

part 'addon_model.g.dart';

@collection
class Addon {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;
  late double price; // selling price
  late double cost;  // cost price

  bool isVoid = false;
}
