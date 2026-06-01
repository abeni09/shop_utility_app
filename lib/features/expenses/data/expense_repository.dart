import 'package:isar/isar.dart';
import 'package:shopsync/features/expenses/data/expense_model.dart';

class ExpenseRepository {
  final Isar isar;

  ExpenseRepository(this.isar);

  Future<List<Expense>> getAllExpenses() async {
    return isar.expenses.where().findAll();
  }

  Stream<void> watchExpenses() {
    return isar.expenses.watchLazy();
  }

  Future<void> saveExpense(Expense expense) async {
    await isar.writeTxn(() async {
      await isar.expenses.put(expense);
    });
  }

  Future<void> deleteExpense(int id) async {
    await isar.writeTxn(() async {
      await isar.expenses.delete(id);
    });
  }
}
