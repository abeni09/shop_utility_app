import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/main.dart';
import 'package:shopsync/features/expenses/data/expense_model.dart';
import 'package:shopsync/features/expenses/data/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ExpenseRepository(dbService.isar);
});

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) async* {
  final repo = ref.watch(expenseRepositoryProvider);

  // Emit initial state
  yield await repo.getAllExpenses();

  // Watch database changes and yield new data
  await for (final _ in repo.watchExpenses()) {
    yield await repo.getAllExpenses();
  }
});

// A convenient provider that watches the stream and defaults to an empty list
final expensesProvider = Provider<List<Expense>>((ref) {
  return ref.watch(expensesStreamProvider).value ?? const [];
});

// Family provider to calculate active expenses on a specific date
final expensesOnDateProvider = Provider.family<List<Expense>, DateTime>((
  ref,
  targetDate,
) {
  final allExpenses = ref.watch(expensesProvider);
  final target = DateTime(targetDate.year, targetDate.month, targetDate.day);

  return allExpenses.where((expense) {
    final expDate = DateTime(
      expense.date.year,
      expense.date.month,
      expense.date.day,
    );
    if (target.isBefore(expDate)) {
      return false; // Cannot start before creation date
    }

    switch (expense.recurrence) {
      case ExpenseRecurrence.none:
        return target.year == expDate.year &&
            target.month == expDate.month &&
            target.day == expDate.day;
      case ExpenseRecurrence.daily:
        return true;
      case ExpenseRecurrence.weekly:
        return target.weekday == expDate.weekday;
      case ExpenseRecurrence.monthly:
        return target.day == expDate.day;
      case ExpenseRecurrence.yearly:
        return target.day == expDate.day && target.month == expDate.month;
    }
  }).toList();
});
