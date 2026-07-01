import 'package:isar/isar.dart';

part 'holiday_model.g.dart';

@collection
class Holiday {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late DateTime date;

  String? name;
}
