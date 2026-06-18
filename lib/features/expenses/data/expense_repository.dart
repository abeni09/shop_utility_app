import 'package:isar/isar.dart';
import 'package:shopsync/features/expenses/data/expense_model.dart';
import 'package:shopsync/features/dashboard/data/dashboard_repository.dart';

class ExpenseRepository {
  final Isar isar;
  final DashboardRepository dashboardRepo;

  ExpenseRepository(this.isar, this.dashboardRepo);

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
    await dashboardRepo.recalculateDailyStats(expense.date);
  }

  Future<void> deleteExpense(int id, DateTime date) async {
    await isar.writeTxn(() async {
      await isar.expenses.delete(id);
    });
    await dashboardRepo.recalculateDailyStats(date);
  }
}
