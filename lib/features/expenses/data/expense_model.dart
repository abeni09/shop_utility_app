import 'package:isar/isar.dart';

part 'expense_model.g.dart';

enum ExpenseRecurrence { none, daily, weekly, monthly, yearly }

@collection
class Expense {
  Id id = Isar.autoIncrement;

  late String description;
  late double amount;
  late DateTime date;

  @enumerated
  late ExpenseRecurrence recurrence = ExpenseRecurrence.none;

  DateTime? lastUpdated;
}
