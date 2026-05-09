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
