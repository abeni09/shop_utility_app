import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/dashboard/data/daily_log_model.dart';
import 'package:shopsync/features/dashboard/data/dashboard_repository.dart';
import 'package:shopsync/main.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return DashboardRepository(dbService.isar);
});

final dailyLogProvider = StreamProvider<DailyLog?>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.watchDailyLog(DateTime.now());
});

final weeklyProfitProvider = FutureProvider<Map<String, double>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 7));
  return repository.getProfitForRange(start, now);
});

final monthlyProfitProvider = FutureProvider<Map<String, double>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 30));
  return repository.getProfitForRange(start, now);
});
final customDateProfitProvider = FutureProvider.family<Map<String, double>,
    ({DateTime start, DateTime end})>((ref, range) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getProfitForRange(range.start, range.end);
});
final dailyLogsProvider = FutureProvider.family<List<DailyLog>,
    ({DateTime start, DateTime end})>((ref, range) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDailyLogsForRange(range.start, range.end);
});
